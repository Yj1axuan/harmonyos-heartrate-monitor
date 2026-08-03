import { DevicesListener, HeartRateRepository, SnapshotListener } from '../../domain/HeartRateRepository';
import { HeartRateSnapshot, MonitoringState } from '../../domain/model/MonitoringState';
import { BleHeartRatePort, HeartRateDevice } from '../../domain/port/BleHeartRatePort';
import { BluetoothPermissionPort } from '../../domain/port/BluetoothPermissionPort';
import { HeartRateMeasurement } from '../../domain/model/HeartRateMeasurement';
import { HeartRateRecord, HeartRateStorePort } from '../../domain/port/HeartRateStorePort';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { Context } from '@kit.AbilityKit';
import { HeartRateAlertEvent, HeartRateAlertType, HeartRateBackgroundMonitorPort } from '../../domain/port/HeartRateAlertPort';

const SCAN_DURATION_MS = 8000;
const RECORD_BATCH_SIZE = 10;

export class HarmonyHeartRateRepository implements HeartRateRepository {
  private blePort: BleHeartRatePort;
  private permissionPort: BluetoothPermissionPort;
  private storePort: HeartRateStorePort;
  private listener: SnapshotListener = (_snapshot: HeartRateSnapshot) => {};
  private devicesListener: DevicesListener = (_devices: HeartRateDevice[]) => {};
  private discoveredDevices: HeartRateDevice[] = [];
  private currentSessionId: number = 0;
  private pendingRecords: HeartRateRecord[] = [];
  private settings: SettingsUiState = new SettingsUiState();
  private appContext: Context | undefined = undefined;
  private alertPort: HeartRateBackgroundMonitorPort | undefined = undefined;
  private abnormalType: HeartRateAlertType = HeartRateAlertType.None;
  private abnormalStartedAt: number = 0;
  private alertPublished: boolean = false;
  private lastConnectedDevice: HeartRateDevice | undefined = undefined;
  private reconnecting: boolean = false;
  private snapshot: HeartRateSnapshot = {
    state: MonitoringState.Idle,
    bpm: 0,
    deviceId: '',
    deviceName: '',
    updatedAt: Date.now()
  };

  constructor(
    blePort: BleHeartRatePort,
    permissionPort: BluetoothPermissionPort,
    storePort: HeartRateStorePort,
    appContext?: Context,
    alertPort?: HeartRateBackgroundMonitorPort
  ) {
    this.blePort = blePort;
    this.permissionPort = permissionPort;
    this.storePort = storePort;
    this.appContext = appContext;
    this.alertPort = alertPort;
    this.blePort.setMeasurementListener((measurement: HeartRateMeasurement) => {
      this.handleMeasurement(measurement);
    });
    this.blePort.setDisconnectListener((_reason: string) => {
      this.handleDisconnect();
    });
  }

  async loadKnownDevices(): Promise<HeartRateDevice[]> {
    const granted = await this.permissionPort.ensureGranted();
    if (!granted) {
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw new Error('Bluetooth permission denied');
    }

    this.discoveredDevices = await this.blePort.getKnownDevices();
    this.devicesListener(this.discoveredDevices);
    return this.discoveredDevices;
  }

  async scan(): Promise<HeartRateDevice[]> {
    const granted = await this.permissionPort.ensureGranted();
    if (!granted) {
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw new Error('Bluetooth permission denied');
    }

    this.updateSnapshot(MonitoringState.Scanning, 0, '', '');
    this.discoveredDevices = [];
    try {
      await this.blePort.startScan((devices: HeartRateDevice[]) => {
        this.discoveredDevices = devices;
        this.devicesListener(devices);
      });
      await this.waitForScanWindow();
      return this.discoveredDevices;
    } catch (error) {
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw error instanceof Error ? error : new Error(String(error));
    } finally {
      await this.blePort.stopScan();
      if (this.snapshot.state === MonitoringState.Scanning) {
        this.updateSnapshot(MonitoringState.Idle, 0, '', '');
      }
    }
  }

  async startDeviceDiscovery(): Promise<void> {
    const granted = await this.permissionPort.ensureGranted();
    if (!granted) {
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw new Error('Bluetooth permission denied');
    }

    this.discoveredDevices = [];
    this.updateSnapshot(MonitoringState.Scanning, 0, '', '');
    await this.blePort.startScan((devices: HeartRateDevice[]) => {
      this.discoveredDevices = devices;
      this.devicesListener(devices);
    });
  }

  async stopDeviceDiscovery(): Promise<void> {
    await this.blePort.stopScan();
    if (this.snapshot.state === MonitoringState.Scanning) {
      this.updateSnapshot(MonitoringState.Idle, 0, '', '');
    }
  }

  async connect(device: HeartRateDevice): Promise<void> {
    this.updateSnapshot(MonitoringState.Connecting, 0, device.id, device.name);
    try {
      await this.blePort.connect(device.id);
      this.lastConnectedDevice = device;
      if (this.settings.recordHistory) {
        this.currentSessionId = await this.storePort.createSession(device.name, Date.now());
      }
      this.pendingRecords = [];
      this.resetAlertState();
      await this.requestAlertNotificationPermissionIfNeeded();
      await this.startBackgroundMonitoringIfNeeded();
      this.updateSnapshot(MonitoringState.Connected, this.snapshot.bpm, device.id, device.name);
    } catch (error) {
      await this.cleanupFailedConnection();
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  async disconnect(): Promise<void> {
    this.lastConnectedDevice = undefined;
    await this.closeCurrentSession();
    await this.blePort.disconnect();
    await this.stopBackgroundMonitoring();
    this.resetAlertState();
    this.updateSnapshot(MonitoringState.Idle, 0, '', '');
  }

  updateSettings(settings: SettingsUiState): void {
    const shouldRequestNotificationPermission = settings.alertNotification && !this.settings.alertNotification;
    this.settings = settings;
    if (!settings.heartRateAlert) {
      this.resetAlertState();
    }
    if (shouldRequestNotificationPermission) {
      void this.requestAlertNotificationPermissionIfNeeded();
    }
    if (this.snapshot.state === MonitoringState.Connected) {
      if (settings.backgroundMonitoring) {
        void this.startBackgroundMonitoringIfNeeded();
      } else {
        void this.stopBackgroundMonitoring();
      }
    }
  }

  observe(listener: SnapshotListener): void {
    this.listener = listener;
  }

  observeDevices(listener: DevicesListener): void {
    this.devicesListener = listener;
  }

  currentSnapshot(): HeartRateSnapshot {
    return this.snapshot;
  }

  private waitForScanWindow(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, SCAN_DURATION_MS);
    });
  }

  private updateSnapshot(state: MonitoringState, bpm: number, deviceId: string, deviceName: string): void {
    this.snapshot = {
      state: state,
      bpm: bpm,
      deviceId: deviceId,
      deviceName: deviceName,
      updatedAt: Date.now()
    };
    this.listener(this.snapshot);
  }

  private handleMeasurement(measurement: HeartRateMeasurement): void {
    if (measurement.bpm <= 0 || this.snapshot.state !== MonitoringState.Connected) {
      return;
    }
    this.appendPendingRecord(measurement.bpm);
    this.evaluateAlert(measurement.bpm, Date.now());
    this.updateSnapshot(
      MonitoringState.Connected,
      measurement.bpm,
      this.snapshot.deviceId,
      this.snapshot.deviceName
    );
  }

  private handleDisconnect(): void {
    if (this.snapshot.state === MonitoringState.Connected || this.snapshot.state === MonitoringState.Connecting ||
      this.snapshot.state === MonitoringState.Reconnecting) {
      void this.closeCurrentSession();
      void this.stopBackgroundMonitoring();
      this.resetAlertState();
      if (this.settings.autoReconnect && this.lastConnectedDevice !== undefined) {
        void this.reconnectLastDevice();
        return;
      }
      this.updateSnapshot(MonitoringState.Idle, 0, '', '');
    }
  }

  private appendPendingRecord(bpm: number): void {
    if (this.currentSessionId <= 0) {
      return;
    }
    this.pendingRecords.push({
      sessionId: this.currentSessionId,
      timestamp: Date.now(),
      heartRate: bpm
    });
    if (this.pendingRecords.length >= RECORD_BATCH_SIZE) {
      void this.flushPendingRecords();
    }
  }

  private async flushPendingRecords(): Promise<void> {
    if (this.pendingRecords.length === 0) {
      return;
    }
    const records = this.pendingRecords.slice();
    this.pendingRecords = [];
    await this.storePort.appendRecords(records);
  }

  private async closeCurrentSession(): Promise<void> {
    if (this.currentSessionId <= 0) {
      return;
    }
    const sessionId = this.currentSessionId;
    this.currentSessionId = 0;
    await this.flushPendingRecords();
    await this.storePort.closeSession(sessionId, Date.now());
  }

  private async reconnectLastDevice(): Promise<void> {
    if (this.reconnecting || this.lastConnectedDevice === undefined) {
      return;
    }
    this.reconnecting = true;
    const device = this.lastConnectedDevice;
    this.updateSnapshot(MonitoringState.Reconnecting, 0, device.id, device.name);
    try {
      await this.blePort.connect(device.id);
      if (this.settings.recordHistory) {
        this.currentSessionId = await this.storePort.createSession(device.name, Date.now());
      }
      this.pendingRecords = [];
      this.resetAlertState();
      await this.requestAlertNotificationPermissionIfNeeded();
      await this.startBackgroundMonitoringIfNeeded();
      this.updateSnapshot(MonitoringState.Connected, 0, device.id, device.name);
    } catch (_error) {
      await this.cleanupFailedConnection();
      this.updateSnapshot(MonitoringState.Idle, 0, '', '');
    } finally {
      this.reconnecting = false;
    }
  }

  private async startBackgroundMonitoringIfNeeded(): Promise<void> {
    if (!this.settings.backgroundMonitoring || this.appContext === undefined || this.alertPort === undefined) {
      return;
    }
    await this.alertPort.startBackgroundMonitoring(this.appContext);
  }

  private async requestAlertNotificationPermissionIfNeeded(): Promise<void> {
    if (!this.settings.alertNotification || this.appContext === undefined || this.alertPort === undefined) {
      return;
    }
    await this.alertPort.requestNotificationPermission(this.appContext);
  }

  private async stopBackgroundMonitoring(): Promise<void> {
    if (this.appContext === undefined || this.alertPort === undefined) {
      return;
    }
    await this.alertPort.stopBackgroundMonitoring(this.appContext);
  }

  private async cleanupFailedConnection(): Promise<void> {
    this.lastConnectedDevice = undefined;
    try {
      await this.closeCurrentSession();
    } catch (_error) {
      this.currentSessionId = 0;
    }
    this.pendingRecords = [];
    this.resetAlertState();
    try {
      await this.blePort.disconnect();
    } catch (_error) {
    }
    try {
      await this.stopBackgroundMonitoring();
    } catch (_error) {
    }
  }

  private evaluateAlert(bpm: number, timestamp: number): void {
    if (!this.settings.heartRateAlert) {
      this.resetAlertState();
      return;
    }
    const alertType = this.resolveAlertType(bpm);
    if (alertType === HeartRateAlertType.None) {
      this.resetAlertState();
      return;
    }
    if (alertType !== this.abnormalType) {
      this.abnormalType = alertType;
      this.abnormalStartedAt = timestamp;
      this.alertPublished = false;
      return;
    }
    const durationMs = Math.max(3, this.settings.alertDurationSeconds) * 1000;
    if (this.alertPublished || timestamp - this.abnormalStartedAt < durationMs) {
      return;
    }
    this.alertPublished = true;
    const event: HeartRateAlertEvent = {
      type: alertType,
      bpm: bpm,
      threshold: alertType === HeartRateAlertType.High ? this.settings.highBpmThreshold : this.settings.lowBpmThreshold,
      durationSeconds: Math.floor((timestamp - this.abnormalStartedAt) / 1000),
      deviceName: this.snapshot.deviceName,
      occurredAt: timestamp
    };
    if (this.alertPort !== undefined) {
      void this.alertPort.publishAlert(event, this.settings);
    }
  }

  private resolveAlertType(bpm: number): HeartRateAlertType {
    if (bpm > this.settings.highBpmThreshold) {
      return HeartRateAlertType.High;
    }
    if (bpm < this.settings.lowBpmThreshold) {
      return HeartRateAlertType.Low;
    }
    return HeartRateAlertType.None;
  }

  private resetAlertState(): void {
    this.abnormalType = HeartRateAlertType.None;
    this.abnormalStartedAt = 0;
    this.alertPublished = false;
  }
}
