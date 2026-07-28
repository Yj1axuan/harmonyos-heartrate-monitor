import { AppColors } from '../ui/theme/AppTheme';
import { HomePage } from '../ui/pages/HomePage';
import { FavoritePage, HistoryPage } from '../ui/pages/HistoryPage';
import { AboutPage, SettingsPage } from '../ui/pages/SettingsPage';
import { AppContainer } from '../core/di/AppContainer';
import { HeartRateUiState } from '../application/state/HeartRateUiState';
import { SettingsUiState } from '../application/state/SettingsUiState';
import { HeartRateViewModel } from '../application/viewmodel/HeartRateViewModel';
import { HistoryViewModel } from '../application/viewmodel/HistoryViewModel';
import { SettingsViewModel } from '../application/viewmodel/SettingsViewModel';

@Entry
@Component
struct Index {
  private heartRateViewModel: HeartRateViewModel = AppContainer.createHeartRateViewModel();
  private historyViewModel: HistoryViewModel = AppContainer.createHistoryViewModel();
  private settingsViewModel: SettingsViewModel = AppContainer.createSettingsViewModel();
  @State private heartRateState: HeartRateUiState = this.heartRateViewModel.state;
  @State private settingsState: SettingsUiState = this.settingsViewModel.state;
  @State private selectedTab: number = 0;
  @State private showAbout: boolean = false;

  @Builder
  private navItem(index: number, icon: string, title: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(26)
        .fontColor(this.selectedTab === index ? AppColors.PRIMARY : '#3F4149')
      Text(title)
        .fontSize(12)
        .fontWeight(this.selectedTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.selectedTab === index ? AppColors.PRIMARY : '#3F4149')
    }
    .width('25%')
    .height(58)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.selectedTab === index ? '#E4E4EA' : Color.Transparent)
    .borderRadius(26)
    .onClick(() => {
      this.selectedTab = index;
    })
  }

  @Builder
  private bottomNavigation() {
    Row() {
      this.navItem(0, '⌂', '首页')
      this.navItem(1, '◷', '历史')
      this.navItem(2, '☆', '收藏')
      this.navItem(3, '⚙', '设置')
    }
    .width('calc(100% - 28vp)')
    .height(66)
    .padding(4)
    .margin({ left: 14, right: 14, bottom: 10 })
    .backgroundColor('#F8F7FAF2')
    .border({ width: 1, color: '#FFFFFFCC' })
    .borderRadius(34)
    .shadow({ radius: 18, color: '#25000000', offsetY: 5 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.showAbout) {
        AboutPage({
          onBack: () => {
            this.showAbout = false;
          }
        })
      } else {
        if (this.selectedTab === 0) {
          HomePage({
            state: this.heartRateState,
            onConnectionToggle: () => {
              this.heartRateViewModel.toggleConnection();
            }
          })
        } else if (this.selectedTab === 1) {
          HistoryPage({
            summary: this.historyViewModel.summary,
            sessions: this.historyViewModel.sessions
          })
        } else if (this.selectedTab === 2) {
          FavoritePage({ devices: this.historyViewModel.favoriteDevices })
        } else {
          SettingsPage({
            state: this.settingsState,
            onRecordHistoryChange: (value: boolean) => { this.settingsViewModel.setRecordHistory(value); },
            onHeartbeatAnimationChange: (value: boolean) => { this.settingsViewModel.setHeartbeatAnimation(value); },
            onDisplaySpeedChange: (value: boolean) => { this.settingsViewModel.setDisplaySpeed(value); },
            onHideFromRecentsChange: (value: boolean) => { this.settingsViewModel.setHideFromRecents(value); },
            onAutoConnectChange: (value: boolean) => { this.settingsViewModel.setAutoConnect(value); },
            onAutoReconnectChange: (value: boolean) => { this.settingsViewModel.setAutoReconnect(value); },
            onOpenAbout: () => {
              this.showAbout = true;
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
