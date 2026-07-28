import { HeartRateSnapshot } from './model/MonitoringState';
import { HeartRateDevice } from './port/BleHeartRatePort';

export type SnapshotListener = (snapshot: HeartRateSnapshot) => void;

export interface HeartRateRepository {
  scan(): Promise<HeartRateDevice[]>;
  connect(device: HeartRateDevice): Promise<void>;
  disconnect(): Promise<void>;
  observe(listener: SnapshotListener): void;
  currentSnapshot(): HeartRateSnapshot;
}
