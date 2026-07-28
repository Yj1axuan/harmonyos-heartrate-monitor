import { HeartRateRepository, SnapshotListener } from '../../domain/HeartRateRepository';
import { HeartRateSnapshot } from '../../domain/model/MonitoringState';

export class ObserveHeartRateUseCase {
  private repository: HeartRateRepository;

  constructor(repository: HeartRateRepository) {
    this.repository = repository;
  }

  execute(listener: SnapshotListener): void {
    this.repository.observe(listener);
  }

  current(): HeartRateSnapshot {
    return this.repository.currentSnapshot();
  }
}
