import { HeartRateSnapshot } from '../../domain/model/MonitoringState';
import { HeartRateUiState } from '../state/HeartRateUiState';
import { ObserveHeartRateUseCase } from '../usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../usecase/ToggleHeartRateConnectionUseCase';
import { MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

export class HeartRateViewModel {
  readonly state: HeartRateUiState = new HeartRateUiState();
  private observeHeartRate: ObserveHeartRateUseCase;
  private toggleHeartRateConnection: ToggleHeartRateConnectionUseCase;

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
        if (devices.length === 0) {
          this.state.statusMessage = '未发现 BLE 设备，请确认设备已开启广播后重试';
        }
      }
    } catch (_error) {
      this.state.monitoringState = MonitoringState.Failed;
      this.state.statusMessage = '扫描失败，请检查蓝牙权限和系统蓝牙开关';
    }
  }

  private applySnapshot(snapshot: HeartRateSnapshot): void {
    this.state.monitoringState = snapshot.state;
    this.state.bpm = snapshot.bpm;
    this.state.deviceId = snapshot.deviceId;
    this.state.deviceName = snapshot.deviceName;
    this.state.updatedAt = snapshot.updatedAt;
  }
}
