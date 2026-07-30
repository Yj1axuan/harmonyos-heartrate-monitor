import { HeartRateViewModel } from '../../application/viewmodel/HeartRateViewModel';
import { HistoryViewModel } from '../../application/viewmodel/HistoryViewModel';
import { SettingsViewModel } from '../../application/viewmodel/SettingsViewModel';
import { ObserveHeartRateUseCase } from '../../application/usecase/ObserveHeartRateUseCase';
import { ToggleHeartRateConnectionUseCase } from '../../application/usecase/ToggleHeartRateConnectionUseCase';
import { PreviewHeartRateRepository } from '../../data/repository/PreviewHeartRateRepository';
import { HeartRateRepository } from '../../domain/HeartRateRepository';
import { Context } from '@kit.AbilityKit';
import { HarmonyBleHeartRateAdapter } from '../../data/ble/HarmonyBleHeartRateAdapter';
import { MockBleHeartRateAdapter } from '../../data/ble/MockBleHeartRateAdapter';
import { BluetoothPermissionAdapter } from '../../data/permission/BluetoothPermissionAdapter';
import { HarmonyHeartRateRepository } from '../../data/repository/HarmonyHeartRateRepository';
import { HeartRateStorePort } from '../../domain/port/HeartRateStorePort';
import { HarmonyHeartRateStoreAdapter } from '../../data/store/HarmonyHeartRateStoreAdapter';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';
import { HarmonyAppPreferencesAdapter } from '../../data/preferences/HarmonyAppPreferencesAdapter';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { HarmonyHeartRateAlertAdapter } from '../../data/alert/HarmonyHeartRateAlertAdapter';
import { window } from '@kit.ArkUI';
import { AppColors } from '../../ui/theme/AppTheme';
import wallpaper from '@ohos.wallpaper';

export class AppContainer {
  private static bleMode: 'real' | 'mock' = 'mock';
  private static appContext: Context | undefined = undefined;
  private static heartRateRepository: HeartRateRepository = new PreviewHeartRateRepository();
  private static harmonyHeartRateRepository: HarmonyHeartRateRepository | undefined = undefined;
  private static heartRateStore: HeartRateStorePort | undefined = undefined;
  private static preferencesPort: AppPreferencesPort | undefined = undefined;
  private static windowStage: window.WindowStage | undefined = undefined;
  private static mainWindow: window.Window | undefined = undefined;
  private static latestSettings: SettingsUiState | undefined = undefined;
  private static themeChangedListener: () => void = () => {};
  private static wallpaperListenerRegistered: boolean = false;

  static initialize(context: Context): void {
    AppContainer.appContext = context;
    AppContainer.heartRateStore = new HarmonyHeartRateStoreAdapter(context);
    AppContainer.preferencesPort = new HarmonyAppPreferencesAdapter(context);
    AppContainer.rebuildHeartRateRepository();
    AppContainer.registerWallpaperColorListener();
  }

  static applyTheme(settings: SettingsUiState): void {
    AppContainer.latestSettings = settings;
    AppColors.applyTheme({
      source: settings.themeSource,
      mode: settings.themeMode,
      color: settings.themeColor,
      style: settings.themeStyle
    });
    void AppContainer.applySystemBarTheme();
    void AppContainer.refreshSystemDynamicTheme(settings);
  }

  static setThemeChangedListener(listener: () => void): void {
    AppContainer.themeChangedListener = listener;
  }

  static setBleMode(mode: 'real' | 'mock'): void {
    AppContainer.bleMode = mode;
    if (AppContainer.appContext !== undefined && AppContainer.heartRateStore !== undefined) {
      AppContainer.rebuildHeartRateRepository();
    }
  }

  static setWindowStage(windowStage: window.WindowStage): void {
    AppContainer.windowStage = windowStage;
    void windowStage.getMainWindow().then((mainWindow: window.Window) => {
      AppContainer.mainWindow = mainWindow;
      void AppContainer.applySystemBarTheme();
    });
  }

  static async setImmersiveMode(enabled: boolean): Promise<void> {
    const mainWindow = await AppContainer.ensureMainWindow();
    if (mainWindow === undefined) {
      return;
    }
    try {
      if (enabled) {
        await mainWindow.setPreferredOrientation(window.Orientation.UNSPECIFIED);
        await mainWindow.setWindowLayoutFullScreen(true);
        await mainWindow.setSpecificSystemBarEnabled('status', false);
        await mainWindow.setSpecificSystemBarEnabled('navigation', false);
        await mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false);
        await mainWindow.setWindowKeepScreenOn(true);
      } else {
        await mainWindow.setWindowKeepScreenOn(false);
        await mainWindow.setSpecificSystemBarEnabled('status', true);
        await mainWindow.setSpecificSystemBarEnabled('navigation', true);
        await mainWindow.setSpecificSystemBarEnabled('navigationIndicator', true);
        await mainWindow.setWindowLayoutFullScreen(false);
        await mainWindow.setPreferredOrientation(window.Orientation.UNSPECIFIED);
        await AppContainer.applySystemBarTheme();
      }
    } catch (_error) {
    }
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
      AppContainer.applyTheme(settings);
      if (AppContainer.harmonyHeartRateRepository !== undefined) {
        AppContainer.harmonyHeartRateRepository.updateSettings(settings);
      }
    });
  }

  private static async ensureMainWindow(): Promise<window.Window | undefined> {
    if (AppContainer.mainWindow !== undefined) {
      return AppContainer.mainWindow;
    }
    if (AppContainer.windowStage === undefined) {
      return undefined;
    }
    AppContainer.mainWindow = await AppContainer.windowStage.getMainWindow();
    return AppContainer.mainWindow;
  }

  private static async applySystemBarTheme(): Promise<void> {
    const mainWindow = await AppContainer.ensureMainWindow();
    if (mainWindow === undefined) {
      return;
    }
    try {
      const contentColor = AppColors.DARK_BAR_CONTENT ? '#000000' : '#FFFFFF';
      await mainWindow.setSystemBarProperties({
        statusBarColor: AppColors.BACKGROUND,
        navigationBarColor: AppColors.BACKGROUND,
        isStatusBarLightIcon: !AppColors.DARK_BAR_CONTENT,
        isNavigationBarLightIcon: !AppColors.DARK_BAR_CONTENT,
        statusBarContentColor: contentColor,
        navigationBarContentColor: contentColor
      });
    } catch (_error) {
    }
  }

  private static async refreshSystemDynamicTheme(settings: SettingsUiState): Promise<void> {
    if (settings.themeSource !== 'system') {
      return;
    }
    try {
      const colors = await wallpaper.getColors(wallpaper.WallpaperType.WALLPAPER_SYSTEM);
      AppContainer.applyWallpaperColors(colors);
    } catch (_error) {
    }
  }

  private static registerWallpaperColorListener(): void {
    if (AppContainer.wallpaperListenerRegistered) {
      return;
    }
    AppContainer.wallpaperListenerRegistered = true;
    try {
      wallpaper.on('colorChange', (colors: Array<wallpaper.RgbaColor>, _wallpaperType: wallpaper.WallpaperType) => {
        AppContainer.applyWallpaperColors(colors);
      });
    } catch (_error) {
    }
  }

  private static applyWallpaperColors(colors: Array<wallpaper.RgbaColor>): void {
    if (colors.length === 0) {
      return;
    }
    AppColors.setSystemDynamicColor(AppContainer.rgbaToHex(colors[0]));
    if (AppContainer.latestSettings === undefined || AppContainer.latestSettings.themeSource !== 'system') {
      return;
    }
    AppColors.applyTheme({
      source: AppContainer.latestSettings.themeSource,
      mode: AppContainer.latestSettings.themeMode,
      color: AppContainer.latestSettings.themeColor,
      style: AppContainer.latestSettings.themeStyle
    });
    void AppContainer.applySystemBarTheme();
    AppContainer.themeChangedListener();
  }

  private static rgbaToHex(color: wallpaper.RgbaColor): string {
    return '#' + AppContainer.toHex(color.red) + AppContainer.toHex(color.green) + AppContainer.toHex(color.blue);
  }

  private static toHex(value: number): string {
    const normalized = Math.min(255, Math.max(0, Math.round(value))).toString(16);
    return normalized.length === 1 ? '0' + normalized : normalized;
  }

  private static rebuildHeartRateRepository(): void {
    if (AppContainer.appContext === undefined || AppContainer.heartRateStore === undefined) {
      return;
    }
    const blePort = AppContainer.bleMode === 'mock' ? new MockBleHeartRateAdapter() : new HarmonyBleHeartRateAdapter();
    AppContainer.harmonyHeartRateRepository = new HarmonyHeartRateRepository(
      blePort,
      new BluetoothPermissionAdapter(AppContainer.appContext),
      AppContainer.heartRateStore,
      AppContainer.appContext,
      new HarmonyHeartRateAlertAdapter()
    );
    AppContainer.heartRateRepository = AppContainer.harmonyHeartRateRepository;
  }
}
