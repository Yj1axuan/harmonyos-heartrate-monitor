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
import { HeartRateStorePort } from '../../domain/port/HeartRateStorePort';
import { HarmonyHeartRateStoreAdapter } from '../../data/store/HarmonyHeartRateStoreAdapter';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';
import { HarmonyAppPreferencesAdapter } from '../../data/preferences/HarmonyAppPreferencesAdapter';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { HarmonyHeartRateAlertAdapter } from '../../data/alert/HarmonyHeartRateAlertAdapter';

export class AppContainer {
  private static heartRateRepository: HeartRateRepository = new PreviewHeartRateRepository();
  private static harmonyHeartRateRepository: HarmonyHeartRateRepository | undefined = undefined;
  private static heartRateStore: HeartRateStorePort | undefined = undefined;
  private static preferencesPort: AppPreferencesPort | undefined = undefined;

  static initialize(context: Context): void {
    AppContainer.heartRateStore = new HarmonyHeartRateStoreAdapter(context);
    AppContainer.preferencesPort = new HarmonyAppPreferencesAdapter(context);
    AppContainer.harmonyHeartRateRepository = new HarmonyHeartRateRepository(
      new HarmonyBleHeartRateAdapter(),
      new BluetoothPermissionAdapter(context),
      AppContainer.heartRateStore,
      context,
      new HarmonyHeartRateAlertAdapter()
    );
    AppContainer.heartRateRepository = AppContainer.harmonyHeartRateRepository;
  }

  static createHeartRateViewModel(): HeartRateViewModel {
    return new HeartRateViewModel(
      new ObserveHeartRateUseCase(AppContainer.heartRateRepository),
      new ToggleHeartRateConnectionUseCase(AppContainer.heartRateRepository)
    );
  }

  static createHistoryViewModel(): HistoryViewModel {
    if (AppContainer.heartRateStore === undefined) {
      AppContainer.heartRateStore = new HarmonyHeartRateStoreAdapter(getContext() as Context);
    }
    if (AppContainer.preferencesPort === undefined) {
      AppContainer.preferencesPort = new HarmonyAppPreferencesAdapter(getContext() as Context);
    }
    return new HistoryViewModel(AppContainer.heartRateStore, AppContainer.preferencesPort);
  }

  static createSettingsViewModel(): SettingsViewModel {
    if (AppContainer.preferencesPort === undefined) {
      AppContainer.preferencesPort = new HarmonyAppPreferencesAdapter(getContext() as Context);
    }
    return new SettingsViewModel(AppContainer.preferencesPort, (settings: SettingsUiState) => {
      if (AppContainer.harmonyHeartRateRepository !== undefined) {
        AppContainer.harmonyHeartRateRepository.updateSettings(settings);
      }
    });
  }
}
