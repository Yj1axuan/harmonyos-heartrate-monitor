import { HeartRateViewModel } from '../../application/viewmodel/HeartRateViewModel';
import { HistoryViewModel } from '../../application/viewmodel/HistoryViewModel';
import { SettingsViewModel } from '../../application/viewmodel/SettingsViewModel';
import { ObserveHeartRateUseCase } from '../../application/usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../../application/usecase/ToggleHeartRateConnectionUseCase';
import { PreviewHeartRateRepository } from '../../data/repository/PreviewHeartRateRepository';
import { HeartRateRepository } from '../../domain/HeartRateRepository';
import { Context } from '@kit.AbilityKit';
import { HarmonyBleHeartRateAdapter } from '../../data/ble/HarmonyBleHeartRateAdapter';
import { BluetoothPermissionAdapter } from '../../data/permission/BluetoothPermissionAdapter';
import { HarmonyHeartRateRepository } from '../../data/repository/HarmonyHeartRateRepository';

export class AppContainer {
  private static heartRateRepository: HeartRateRepository = new PreviewHeartRateRepository();

  static initialize(context: Context): void {
    AppContainer.heartRateRepository = new HarmonyHeartRateRepository(
      new HarmonyBleHeartRateAdapter(),
      new BluetoothPermissionAdapter(context)
    );
  }

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
