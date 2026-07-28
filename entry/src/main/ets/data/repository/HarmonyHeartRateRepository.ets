import { DevicesListener, HeartRateRepository, SnapshotListener } from '../../domain/HeartRateRepository';
import { HeartRateSnapshot, MonitoringState } from '../../domain/model/MonitoringState';
import { BleHeartRatePort, HeartRateDevice } from '../../domain/port/BleHeartRatePort';
import { BluetoothPermissionPort } from '../../domain/port/BluetoothPermissionPort';

const SCAN_DURATION_MS = 6000;

export class HarmonyHeartRateRepository implements HeartRateRepository {
  private blePort: BleHeartRatePort;
  private permissionPort: BluetoothPermissionPort;
  private listener: SnapshotListener = (_snapshot: HeartRateSnapshot) => {};
  private devicesListener: DevicesListener = (_devices: HeartRateDevice[]) => {};
  private snapshot: HeartRateSnapshot = {
    state: MonitoringState.Idle,
    bpm: 0,
    deviceId: '',
    deviceName: '',
    updatedAt: Date.now()
  };

  constructor(blePort: BleHeartRatePort, permissionPort: BluetoothPermissionPort) {
    this.blePort = blePort;
    this.permissionPort = permissionPort;
  }

  async scan(): Promise<HeartRateDevice[]> {
    const granted = await this.permissionPort.ensureGranted();
    if (!granted) {
      this.updateSnapshot(MonitoringState.Failed, 0, '', '');
      throw new Error('Bluetooth permission denied');
    }

    this.updateSnapshot(MonitoringState.Scanning, 0, '', '');
    let discoveredDevices: HeartRateDevice[] = [];
    try {
      await this.blePort.startScan((devices: HeartRateDevice[]) => {
        discoveredDevices = devices;
        this.devicesListener(devices);
      });
      await this.waitForScanWindow();
      return discoveredDevices;
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

  async connect(device: HeartRateDevice): Promise<void> {
    this.updateSnapshot(MonitoringState.Connecting, 0, device.id, device.name);
    await this.blePort.connect(device.id);
  }

  async disconnect(): Promise<void> {
    await this.blePort.disconnect();
    this.updateSnapshot(MonitoringState.Idle, 0, '', '');
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
}
