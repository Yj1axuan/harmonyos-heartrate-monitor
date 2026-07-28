import { MonitoringState } from '../../domain/model/MonitoringState';

@Observed
export class HeartRateUiState {
  monitoringState: MonitoringState = MonitoringState.Idle;
  bpm: number = 0;
  deviceId: string = '';
  deviceName: string = '';
  updatedAt: number = 0;

  get connected(): boolean {
    return this.monitoringState === MonitoringState.Connected;
  }
}
