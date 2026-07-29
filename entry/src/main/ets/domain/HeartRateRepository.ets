import { HeartRateSnapshot } from './model/MonitoringState';
import { HeartRateDevice } from './port/BleHeartRatePort';

export type SnapshotListener = (snapshot: HeartRateSnapshot) => void;
export type DevicesListener = (devices: HeartRateDevice[]) => void;

export interface HeartRateRepository {
  loadKnownDevices(): Promise<HeartRateDevice[]>;
  scan(): Promise<HeartRateDevice[]>;
  startDeviceDiscovery(): Promise<void>;
  stopDeviceDiscovery(): Promise<void>;
  connect(device: HeartRateDevice): Promise<void>;
  disconnect(): Promise<void>;
  observe(listener: SnapshotListener): void;
  observeDevices(listener: DevicesListener): void;
  currentSnapshot(): HeartRateSnapshot;
}
