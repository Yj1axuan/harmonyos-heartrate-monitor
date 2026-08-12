import { AppColors } from '../ui/theme/AppTheme';
import { HomePage } from '../ui/pages/HomePage';
import { FullScreenPage } from '../ui/pages/FullScreenPage';
import { DeviceListPage } from '../ui/pages/DeviceListPage';
import { FavoritePage, HistoryPage } from '../ui/pages/HistoryPage';
import { AboutPage, SettingsPage, ThemeSettingsPage } from '../ui/pages/SettingsPage';
import { AppContainer } from '../core/di/AppContainer';
import { HeartRateUiState } from '../application/state/HeartRateUiState';
import { SettingsUiState } from '../application/state/SettingsUiState';
import { HeartRateViewModel } from '../application/viewmodel/HeartRateViewModel';
import { HistoryViewModel } from '../application/viewmodel/HistoryViewModel';
import { SettingsViewModel } from '../application/viewmodel/SettingsViewModel';
import { HeartRateDevice } from '../domain/port/BleHeartRatePort';
import { FavoriteDevice, HistoryDetail, HistorySummary, SessionPreview } from '../application/model/HistoryUiModels';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct MainPage {
  private heartRateViewModel: HeartRateViewModel = AppContainer.createHeartRateViewModel();
  private historyViewModel: HistoryViewModel = AppContainer.createHistoryViewModel();
  private settingsViewModel: SettingsViewModel = AppContainer.createSettingsViewModel();
  @State private heartRateState: HeartRateUiState = this.heartRateViewModel.state;
  @State private settingsState: SettingsUiState = this.settingsViewModel.state;
  @State private historySummary: HistorySummary = this.historyViewModel.summary;
  @State private historySessions: SessionPreview[] = this.historyViewModel.sessions;
  @State private historyDetail: HistoryDetail | undefined = this.historyViewModel.selectedDetail;
  @State private favoriteDevices: FavoriteDevice[] = this.historyViewModel.favoriteDevices;
  @State private selectedTab: number = 0;
  @State private showAbout: boolean = false;
  @State private showThemeSettings: boolean = false;
  @State private showDevices: boolean = false;
  @State private showFullScreen: boolean = false;
  @State private exitDialogShowing: boolean = false;
  @State private themeRevision: number = 0;

  aboutToAppear(): void {
    AppContainer.setThemeChangedListener(() => {
      this.themeRevision = this.themeRevision + 1;
    });
    void this.loadPersistedState();
  }

  private async loadPersistedState(): Promise<void> {
    await this.settingsViewModel.load();
    this.syncSettingsState();
    await this.historyViewModel.load();
    this.syncHistoryState();
    await this.restoreAutoConnect();
  }

  private async connectSelectedDevice(device: HeartRateDevice): Promise<void> {
    await this.heartRateViewModel.connectDevice(device);
    if (this.heartRateState.connected && this.heartRateState.deviceId === device.id) {
      await this.historyViewModel.addFavoriteDevice({ id: device.id, name: device.name });
      this.syncHistoryState();
      this.showDevices = false;
    }
  }

  private async refreshHistory(): Promise<void> {
    await this.historyViewModel.load();
    this.syncHistoryState();
  }

  private async openHistoryDetail(sessionId: number): Promise<void> {
    await this.historyViewModel.openDetail(sessionId);
    this.syncHistoryState();
  }

  private async deleteHistorySession(sessionId: number): Promise<void> {
    await this.historyViewModel.deleteSession(sessionId);
    this.syncHistoryState();
  }

  private async removeFavoriteDevice(deviceId: string): Promise<void> {
    await this.historyViewModel.removeFavoriteDevice(deviceId);
    this.syncHistoryState();
    this.ensureAutoConnectHasFavoriteDevice();
  }

  private async setPrimaryFavoriteDevice(deviceId: string): Promise<void> {
    await this.historyViewModel.setPrimaryFavoriteDevice(deviceId);
    this.syncHistoryState();
  }

  private ensureAutoConnectHasFavoriteDevice(): void {
    if (this.favoriteDevices.length === 0 && this.settingsState.autoConnect) {
      this.settingsViewModel.setAutoConnect(false);
      this.syncSettingsState();
    }
  }

  private async restoreAutoConnect(): Promise<void> {
    this.ensureAutoConnectHasFavoriteDevice();
    if (!this.settingsState.autoConnect || this.historyViewModel.favoriteDevices.length === 0) {
      return;
    }
    const favorite = this.historyViewModel.favoriteDevices[0];
    await this.heartRateViewModel.connectDevice(this.toHeartRateDevice(favorite.id, favorite.name));
  }

  private toHeartRateDevice(id: string, name: string): HeartRateDevice {
    return {
      id: id,
      name: name,
      rssi: -127,
      deviceKind: 'ble'
    };
  }

  private syncSettingsState(): void {
    this.settingsState = this.settingsViewModel.state;
    AppContainer.applyTheme(this.settingsState);
    this.themeRevision = this.themeRevision + 1;
  }

  private syncHistoryState(): void {
    this.historySummary = this.historyViewModel.summary;
    this.historySessions = this.historyViewModel.sessions;
    this.historyDetail = this.historyViewModel.selectedDetail;
    this.favoriteDevices = this.historyViewModel.favoriteDevices;
  }

  onBackPress(): boolean {
    if (this.showFullScreen) {
      void this.exitFullScreen();
      return true;
    }
    if (this.showDevices) {
      this.heartRateViewModel.stopDeviceDiscovery();
      this.showDevices = false;
      return true;
    }
    if (this.showAbout) {
      this.showAbout = false;
      return true;
    }
    if (this.showThemeSettings) {
      this.showThemeSettings = false;
      return true;
    }
    if (this.historyDetail !== undefined) {
      this.historyViewModel.closeDetail();
      this.syncHistoryState();
      return true;
    }
    this.showExitConfirmDialog();
    return true;
  }

  private showExitConfirmDialog(): void {
    if (this.exitDialogShowing) {
      return;
    }
    this.exitDialogShowing = true;
    AlertDialog.show({
      title: '退出程序',
      message: '确定要退出心率监控器吗？',
      width: 300,
      autoCancel: false,
      primaryButton: {
        value: '取消',
        action: () => {
          this.exitDialogShowing = false;
        }
      },
      secondaryButton: {
        value: '确定',
        fontColor: AppColors.ERROR,
        action: () => {
          this.exitDialogShowing = false;
          void this.exitApplication();
        }
      },
      cancel: () => {
        this.exitDialogShowing = false;
      }
    });
  }

  private async exitApplication(): Promise<void> {
    try {
      if (this.showFullScreen) {
        await this.exitFullScreen();
      }
      if (this.heartRateState.connected) {
        await this.heartRateViewModel.toggleConnection();
      }
      const context = getContext(this) as common.UIAbilityContext;
      await context.terminateSelf();
    } catch (_error) {
    }
  }

  private async enterFullScreen(): Promise<void> {
    if (!this.heartRateState.connected) {
      return;
    }
    this.showFullScreen = true;
    await AppContainer.setImmersiveMode(true);
  }

  private async exitFullScreen(): Promise<void> {
    this.showFullScreen = false;
    await AppContainer.setImmersiveMode(false);
  }

  @Builder
  private navItem(index: number, icon: string, title: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(26)
        .fontColor(this.selectedTab === index ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
      Text(title)
        .fontSize(12)
        .fontWeight(this.selectedTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.selectedTab === index ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
    }
    .width('25%')
    .height(58)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.selectedTab === index ? AppColors.PRIMARY_SOFT : Color.Transparent)
    .borderRadius(26)
    .onClick(() => {
      this.selectedTab = index;
      if (index === 1) {
        void this.refreshHistory();
      }
    })
  }

  @Builder
  private bottomNavigation() {
    Row() {
      this.navItem(0, '♥', '首页')
      this.navItem(1, '◷', '历史')
      this.navItem(2, '☆', '收藏')
      this.navItem(3, '⚙', '设置')
    }
    .width('calc(100% - 28vp)')
    .height(66)
    .padding(4)
    .margin({ left: 14, right: 14, bottom: 10 })
    .backgroundColor(AppColors.SURFACE)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(34)
    .shadow({ radius: 18, color: '#25000000', offsetY: 5 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.showDevices) {
        DeviceListPage({
          state: this.heartRateState,
          onBack: () => {
            this.heartRateViewModel.stopDeviceDiscovery();
            this.showDevices = false;
          },
          onRefresh: () => {
            this.heartRateViewModel.refreshDeviceDiscovery();
          },
          onSelect: (device: HeartRateDevice) => {
            void this.connectSelectedDevice(device);
          }
        })
      } else if (this.showAbout) {
        AboutPage({
          onBack: () => {
            this.showAbout = false;
          }
        })
      } else if (this.showThemeSettings) {
        ThemeSettingsPage({
          state: this.settingsState,
          onBack: () => {
            this.showThemeSettings = false;
          },
          onThemeSourceChange: (value: 'system' | 'custom') => { this.settingsViewModel.setThemeSource(value); this.syncSettingsState(); },
          onThemeModeChange: (value: 'system' | 'light' | 'dark') => { this.settingsViewModel.setThemeMode(value); this.syncSettingsState(); },
          onThemeColorChange: (value: string) => { this.settingsViewModel.setThemeColor(value); this.syncSettingsState(); },
          onThemeStyleChange: (value: 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit') => { this.settingsViewModel.setThemeStyle(value); this.syncSettingsState(); }
        })
      } else if (this.showFullScreen) {
        FullScreenPage({
          state: this.heartRateState,
          settings: this.settingsState,
          onExit: (_reason: string) => {
            void this.exitFullScreen();
          }
        })
      } else {
        if (this.selectedTab === 0) {
          HomePage({
            state: this.heartRateState,
            showSpeed: this.settingsState.displaySpeed,
            onOpenDevices: () => {
              this.showDevices = true;
              if (this.heartRateState.devices.length === 0) {
                this.heartRateViewModel.loadKnownDevices();
              }
            },
            onOpenFullScreen: () => {
              void this.enterFullScreen();
            },
            onDisconnect: () => {
              if (this.showFullScreen) {
                void this.exitFullScreen();
              }
              this.heartRateViewModel.toggleConnection();
            }
          })
        } else if (this.selectedTab === 1) {
          HistoryPage({
            summary: this.historySummary,
            sessions: this.historySessions,
            detail: this.historyDetail,
            onRefresh: () => {
              void this.refreshHistory();
            },
            onOpenDetail: (sessionId: number) => {
              void this.openHistoryDetail(sessionId);
            },
            onCloseDetail: () => {
              this.historyViewModel.closeDetail();
              this.syncHistoryState();
            },
            onDeleteSession: (sessionId: number) => {
              void this.deleteHistorySession(sessionId);
            }
          })
        } else if (this.selectedTab === 2) {
          FavoritePage({
            devices: this.favoriteDevices,
            onRemove: (deviceId: string) => {
              void this.removeFavoriteDevice(deviceId);
            },
            onMakePrimary: (deviceId: string) => {
              void this.setPrimaryFavoriteDevice(deviceId);
            }
          })
        } else {
          SettingsPage({
            state: this.settingsState,
            showFullscreenModeEntry: this.heartRateState.connected,
            connectedDeviceName: this.heartRateState.connected ? this.heartRateState.deviceName : '',
            favoriteDeviceCount: this.favoriteDevices.length,
            primaryFavoriteDeviceName: this.favoriteDevices.length > 0 ? this.favoriteDevices[0].name : '',
            onOpenFullScreen: () => {
              void this.enterFullScreen();
            },
            onThemeSourceChange: (value: 'system' | 'custom') => { this.settingsViewModel.setThemeSource(value); this.syncSettingsState(); },
            onThemeModeChange: (value: 'system' | 'light' | 'dark') => { this.settingsViewModel.setThemeMode(value); this.syncSettingsState(); },
            onThemeColorChange: (value: string) => { this.settingsViewModel.setThemeColor(value); this.syncSettingsState(); },
            onThemeStyleChange: (value: 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit') => { this.settingsViewModel.setThemeStyle(value); this.syncSettingsState(); },
            onRecordHistoryChange: (value: boolean) => { this.settingsViewModel.setRecordHistory(value); this.syncSettingsState(); },
            onHeartbeatAnimationChange: (value: boolean) => { this.settingsViewModel.setHeartbeatAnimation(value); this.syncSettingsState(); },
            onDisplaySpeedChange: (value: boolean) => { this.settingsViewModel.setDisplaySpeed(value); this.syncSettingsState(); },
            onHideFromRecentsChange: (value: boolean) => { this.settingsViewModel.setHideFromRecents(value); this.syncSettingsState(); },
            onAutoConnectChange: (value: boolean) => { this.settingsViewModel.setAutoConnect(value); this.syncSettingsState(); },
            onAutoReconnectChange: (value: boolean) => { this.settingsViewModel.setAutoReconnect(value); this.syncSettingsState(); },
            onBackgroundMonitoringChange: (value: boolean) => { this.settingsViewModel.setBackgroundMonitoring(value); this.syncSettingsState(); },
            onHeartRateAlertChange: (value: boolean) => { this.settingsViewModel.setHeartRateAlert(value); this.syncSettingsState(); },
            onLowBpmThresholdChange: (value: number) => { this.settingsViewModel.setLowBpmThreshold(value); this.syncSettingsState(); },
            onHighBpmThresholdChange: (value: number) => { this.settingsViewModel.setHighBpmThreshold(value); this.syncSettingsState(); },
            onAlertDurationSecondsChange: (value: number) => { this.settingsViewModel.setAlertDurationSeconds(value); this.syncSettingsState(); },
            onAlertNotificationChange: (value: boolean) => { this.settingsViewModel.setAlertNotification(value); this.syncSettingsState(); },
            onAlertVibrationChange: (value: boolean) => { this.settingsViewModel.setAlertVibration(value); this.syncSettingsState(); },
            onAlertSoundChange: (value: boolean) => { this.settingsViewModel.setAlertSound(value); this.syncSettingsState(); },
            onFullscreenSoundModeChange: (value: string) => { this.settingsViewModel.setFullscreenSoundMode(value); this.syncSettingsState(); },
            onFullscreenDisplayColorChange: (value: string) => { this.settingsViewModel.setFullscreenDisplayColor(value); this.syncSettingsState(); },
            onOpenThemeSettings: () => {
              this.showThemeSettings = true;
            },
            onOpenAbout: () => {
              this.showAbout = true;
            },
            onOpenDevices: () => {
              this.showDevices = true;
              if (this.heartRateState.devices.length === 0) {
                this.heartRateViewModel.loadKnownDevices();
              }
            },
            onOpenFavorites: () => {
              this.selectedTab = 2;
            }
          })
        }
        this.bottomNavigation()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
