import { HeartRateViewModel } from '../../application/viewmodel/HeartRateViewModel';
import { HistoryViewModel } from '../../application/viewmodel/HistoryViewModel';
import { SettingsViewModel } from '../../application/viewmodel/SettingsViewModel';
import { ObserveHeartRateUseCase } from '../../application/usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../../application/usecase/ToggleHeartRateConnectionUseCase';
import { PreviewHeartRateRepository } from '../../data/repository/PreviewHeartRateRepository';
import { HeartRateRepository } from '../../domain/HeartRateRepository';

export class AppContainer {
  private static readonly heartRateRepository: HeartRateRepository = new PreviewHeartRateRepository();

  static createHeartRateViewModel(): HeartRateViewModel {
    return new HeartRateViewModel(
      new ObserveHeartRateUseCase(AppContainer.heartRateRepository),
      new ToggleHeartRateConnectionUseCase(AppContainer.heartRateRepository)
    );
  }

  static createHistoryViewModel(): HistoryViewModel {
    return new HistoryViewModel();
  }

  static createSettingsViewModel(): SettingsViewModel {
    return new SettingsViewModel();
  }
}
