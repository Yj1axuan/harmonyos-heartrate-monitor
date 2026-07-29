import { DevicesListener, HeartRateRepository, SnapshotListener } from '../../domain/HeartRateRepository';
import { HeartRateSnapshot, MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

export class PreviewHeartRateRepository implements HeartRateRepository {
  private listener?: SnapshotListener;
  private devicesListener?: DevicesListener;
  private snapshot: HeartRateSnapshot = {
    state: MonitoringState.Connected,
    bpm: 90,
    deviceId: 'F8:3A:7B:21:91:04',
    deviceName: 'HUAWEI Band HR',
    updatedAt: Date.now()
  };

  async loadKnownDevices(): Promise<HeartRateDevice[]> {
    const devices: HeartRateDevice[] = [{ id: 'F8:3A:7B:21:91:04', name: 'HUAWEI Band HR', rssi: -48, deviceKind: 'ble' }];
    if (this.devicesListener) {
      this.devicesListener(devices);
    }
    return devices;
  }

  async scan(): Promise<HeartRateDevice[]> {
    this.updateSnapshot(MonitoringState.Scanning, 0, '', '');
    const devices: HeartRateDevice[] = [{ id: 'F8:3A:7B:21:91:04', name: 'HUAWEI Band HR', rssi: -48, deviceKind: 'ble' }];
    if (this.devicesListener) {
      this.devicesListener(devices);
    }
    return devices;
  }

  async startDeviceDiscovery(): Promise<void> {
    const devices: HeartRateDevice[] = [{ id: 'F8:3A:7B:21:91:04', name: 'HUAWEI Band HR', rssi: -48, deviceKind: 'ble' }];
    this.updateSnapshot(MonitoringState.Scanning, 0, '', '');
    if (this.devicesListener) {
      this.devicesListener(devices);
    }
  }

  async stopDeviceDiscovery(): Promise<void> {
    this.updateSnapshot(MonitoringState.Idle, 0, '', '');
  }

  async connect(device: HeartRateDevice): Promise<void> {
    this.updateSnapshot(MonitoringState.Connecting, 0, device.id, device.name);
    this.updateSnapshot(MonitoringState.Connected, 90, device.id, device.name);
  }

  async disconnect(): Promise<void> {
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

  private updateSnapshot(state: MonitoringState, bpm: number, deviceId: string, deviceName: string): void {
    this.snapshot = {
      state: state,
      bpm: bpm,
      deviceId: deviceId,
      deviceName: deviceName,
      updatedAt: Date.now()
    };
    if (this.listener) {
      this.listener(this.snapshot);
    }
  }
}
