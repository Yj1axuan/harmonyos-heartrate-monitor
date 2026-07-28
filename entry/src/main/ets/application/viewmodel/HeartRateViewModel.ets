import { HeartRateSnapshot } from '../../domain/model/MonitoringState';
import { HeartRateUiState } from '../state/HeartRateUiState';
import { ObserveHeartRateUseCase } from '../usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../usecase/ToggleHeartRateConnectionUseCase';

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
  }

  async toggleConnection(): Promise<void> {
    await this.toggleHeartRateConnection.execute(this.state.monitoringState);
  }

  private applySnapshot(snapshot: HeartRateSnapshot): void {
    this.state.monitoringState = snapshot.state;
    this.state.bpm = snapshot.bpm;
    this.state.deviceId = snapshot.deviceId;
    this.state.deviceName = snapshot.deviceName;
    this.state.updatedAt = snapshot.updatedAt;
  }
}
