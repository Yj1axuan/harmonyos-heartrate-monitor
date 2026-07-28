import { HeartRateRepository } from '../../domain/HeartRateRepository';
import { MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

export class ToggleHeartRateConnectionUseCase {
  private repository: HeartRateRepository;

  constructor(repository: HeartRateRepository) {
    this.repository = repository;
  }

  async execute(state: MonitoringState): Promise<HeartRateDevice[]> {
    if (state === MonitoringState.Connected || state === MonitoringState.Connecting ||
      state === MonitoringState.Reconnecting) {
      await this.repository.disconnect();
      return [];
    }

    return await this.repository.scan();
  }
}
