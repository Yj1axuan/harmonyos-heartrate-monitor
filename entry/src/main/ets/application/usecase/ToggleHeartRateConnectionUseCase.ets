import { HeartRateRepository } from '../../domain/HeartRateRepository';
import { MonitoringState } from '../../domain/model/MonitoringState';

export class ToggleHeartRateConnectionUseCase {
  private repository: HeartRateRepository;

  constructor(repository: HeartRateRepository) {
    this.repository = repository;
  }

  async execute(state: MonitoringState): Promise<void> {
    if (state === MonitoringState.Connected || state === MonitoringState.Connecting ||
      state === MonitoringState.Reconnecting) {
      await this.repository.disconnect();
      return;
    }

    const devices = await this.repository.scan();
    if (devices.length > 0) {
      await this.repository.connect(devices[0]);
    }
  }
}
