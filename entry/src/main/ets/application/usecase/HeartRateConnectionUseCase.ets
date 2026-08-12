import { HeartRateRepository } from '../../domain/HeartRateRepository';
import { MonitoringState } from '../../domain/model/MonitoringState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';

export class HeartRateConnectionUseCase {
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

  async connect(device: HeartRateDevice): Promise<void> {
    await this.repository.connect(device);
  }

  async loadKnownDevices(): Promise<HeartRateDevice[]> {
    return await this.repository.loadKnownDevices();
  }

  async startDeviceDiscovery(): Promise<void> {
    await this.repository.startDeviceDiscovery();
  }

  async stopDeviceDiscovery(): Promise<void> {
    await this.repository.stopDeviceDiscovery();
  }

  async refreshDeviceDiscovery(): Promise<HeartRateDevice[]> {
    return await this.repository.scan();
  }
}
