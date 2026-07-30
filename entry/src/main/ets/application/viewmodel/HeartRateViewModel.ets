import { HeartRateSnapshot } from '../../domain/model/MonitoringState';
import { HeartRateUiState } from '../state/HeartRateUiState';
import { ObserveHeartRateUseCase } from '../usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../usecase/ToggleHeartRateConnectionUseCase';
import { MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

export class HeartRateViewModel {
  private static readonly MAX_SAMPLE_COUNT: number = 60;
  readonly state: HeartRateUiState = new HeartRateUiState();
  private observeHeartRate: ObserveHeartRateUseCase;
  private toggleHeartRateConnection: ToggleHeartRateConnectionUseCase;
  private onStateChanged: (state: HeartRateUiState) => void = (_state: HeartRateUiState) => {};

  constructor(
    observeHeartRate: ObserveHeartRateUseCase,
    toggleHeartRateConnection: ToggleHeartRateConnectionUseCase
  ) {
    this.observeHeartRate = observeHeartRate;
    this.toggleHeartRateConnection = toggleHeartRateConnection;
    this.applySnapshot(this.observeHeartRate.current());
    this.observeHeartRate.execute((snapshot: HeartRateSnapshot) => {
      this.applySnapshot(snapshot);
    });
    this.observeHeartRate.observeDevices((devices: HeartRateDevice[]) => {
      this.state.devices = devices;
    });
  }

  setStateListener(listener: (state: HeartRateUiState) => void): void {
    this.onStateChanged = listener;
    this.onStateChanged(this.state);
  }

  async toggleConnection(): Promise<void> {
    if (this.state.scanning) {
      return;
    }
    this.state.statusMessage = '';
    this.state.devices = [];
    try {
      const devices: HeartRateDevice[] =
        await this.toggleHeartRateConnection.execute(this.state.monitoringState);
      if (!this.state.connected) {
        this.state.devices = devices;
        if (this.state.devices.length === 0) {
          this.state.statusMessage = '未发现蓝牙设备，请确认设备已开启广播或处于配对模式后重试';
        }
      }
    } catch (_error) {
      this.state.monitoringState = MonitoringState.Failed;
      this.state.statusMessage = '扫描失败，请检查蓝牙权限和系统蓝牙开关';
    }
  }

  async connectDevice(device: HeartRateDevice): Promise<void> {
    if (this.state.scanning) {
      return;
    }
    if (this.state.connected && this.state.deviceId === device.id) {
      this.state.statusMessage = '已连接：' + device.name;
      return;
    }
    this.state.statusMessage = '正在连接：' + device.name;
    try {
      await this.toggleHeartRateConnection.connect(device);
      this.state.statusMessage = '连接成功：' + device.name;
    } catch (error) {
      this.state.monitoringState = MonitoringState.Failed;
      const reason = error instanceof Error ? error.message : String(error);
      this.state.statusMessage = reason.length > 0 ?
        '连接失败：' + device.name + '（' + reason + '）' : '连接失败：' + device.name;
    }
  }

  async loadKnownDevices(): Promise<void> {
    if (this.state.scanning) {
      return;
    }
    this.state.statusMessage = '';
    try {
      const devices = await this.toggleHeartRateConnection.loadKnownDevices();
      if (devices.length > 0) {
        this.state.devices = this.mergeDevices(this.state.devices, devices);
        return;
      }
      if (this.state.devices.length === 0) {
        this.state.statusMessage = '未发现已配对蓝牙设备，可点击刷新查找附近设备';
      }
    } catch (_error) {
      this.state.monitoringState = MonitoringState.Failed;
      this.state.statusMessage = '加载蓝牙设备失败，请检查蓝牙权限和系统蓝牙开关';
    }
  }

  async startDeviceDiscovery(): Promise<void> {
    if (this.state.scanning) {
      return;
    }
    this.state.statusMessage = '';
    this.state.devices = [];
    try {
      await this.toggleHeartRateConnection.startDeviceDiscovery();
    } catch (_error) {
      this.state.monitoringState = MonitoringState.Failed;
      this.state.statusMessage = '扫描失败，请检查蓝牙权限和系统蓝牙开关';
    }
  }

  async stopDeviceDiscovery(): Promise<void> {
    if (!this.state.scanning) {
      return;
    }
    await this.toggleHeartRateConnection.stopDeviceDiscovery();
  }

  async refreshDeviceDiscovery(): Promise<void> {
    if (this.state.scanning) {
      return;
    }
    this.state.statusMessage = '';
    this.state.devices = [];
    try {
      const devices = await this.toggleHeartRateConnection.refreshDeviceDiscovery();
      this.state.devices = devices;
      if (this.state.devices.length === 0) {
        this.state.statusMessage = '未发现蓝牙设备，请确认设备已开启并处于可发现状态';
      }
    } catch (_error) {
      this.state.monitoringState = MonitoringState.Failed;
      this.state.statusMessage = '刷新失败，请检查蓝牙权限和系统蓝牙开关';
    }
  }

  private applySnapshot(snapshot: HeartRateSnapshot): void {
    this.state.monitoringState = snapshot.state;
    this.state.bpm = snapshot.bpm;
    this.state.deviceId = snapshot.deviceId;
    this.state.deviceName = snapshot.deviceName;
    this.state.updatedAt = snapshot.updatedAt;
    if (snapshot.state !== MonitoringState.Connected) {
      this.resetMeasurements();
      this.onStateChanged(this.state);
      return;
    }
    if (snapshot.bpm > 0) {
      this.recordMeasurement(snapshot.bpm, snapshot.updatedAt);
    }
    this.onStateChanged(this.state);
  }

  private recordMeasurement(bpm: number, updatedAt: number): void {
    if (this.state.minBpm === 0 || bpm < this.state.minBpm) {
      this.state.minBpm = bpm;
    }
    if (bpm > this.state.maxBpm) {
      this.state.maxBpm = bpm;
    }
    const samples = this.state.samples.slice();
    samples.push(bpm);
    if (samples.length > HeartRateViewModel.MAX_SAMPLE_COUNT) {
      samples.shift();
    }
    this.state.samples = samples;
    this.state.lastMeasurementAt = updatedAt;
  }

  private resetMeasurements(): void {
    this.state.minBpm = 0;
    this.state.maxBpm = 0;
    this.state.samples = [];
    this.state.lastMeasurementAt = 0;
  }

  private mergeDevices(currentDevices: HeartRateDevice[], nextDevices: HeartRateDevice[]): HeartRateDevice[] {
    const mergedDevices: HeartRateDevice[] = currentDevices.slice();
    nextDevices.forEach((device: HeartRateDevice) => {
      const index = mergedDevices.findIndex((item: HeartRateDevice) => item.id === device.id);
      if (index >= 0) {
        mergedDevices[index] = {
          id: device.id,
          name: device.name.length > 0 ? device.name : mergedDevices[index].name,
          rssi: device.rssi,
          deviceKind: device.deviceKind
        };
        return;
      }
      mergedDevices.push(device);
    });
    return mergedDevices;
  }
}
