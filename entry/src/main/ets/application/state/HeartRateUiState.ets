import { MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

@Observed
export class HeartRateUiState {
  monitoringState: MonitoringState = MonitoringState.Idle;
  bpm: number = 0;
  minBpm: number = 0;
  maxBpm: number = 0;
  samples: number[] = [];
  lastMeasurementAt: number = 0;
  deviceId: string = '';
  deviceName: string = '';
  updatedAt: number = 0;
  devices: HeartRateDevice[] = [];
  statusMessage: string = '';

  get connected(): boolean {
    return this.monitoringState === MonitoringState.Connected;
  }

  get scanning(): boolean {
    return this.monitoringState === MonitoringState.Scanning;
  }

  get failed(): boolean {
    return this.monitoringState === MonitoringState.Failed;
  }
}
