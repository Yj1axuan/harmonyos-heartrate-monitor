import { AppColors } from '../theme/AppTheme';
import { SettingsUiState } from '../../application/state/SettingsUiState';

@Component
struct SettingSwitchRow {
  icon: string = '•';
  title: string = '';
  subtitle: string = '';
  @Prop checked: boolean = false;
  onChange: (value: boolean) => void = (_value: boolean) => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(22)
        .fontColor('#3E5798')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(24)
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({ type: ToggleType.Switch, isOn: this.checked })
        .selectedColor(AppColors.PRIMARY)
        .onChange((value: boolean) => {
          this.onChange(value);
        })
    }
    .width('100%')
    .height(76)
    .padding({ left: 14, right: 14 })
  }
}

@Component
struct SettingLinkRow {
  icon: string = '•';
  title: string = '';
  subtitle: string = '';
  onTap: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(22)
        .fontColor('#3E5798')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(24)
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(28)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .height(76)
    .padding({ left: 14, right: 16 })
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
struct SettingStepperRow {
  icon: string = '·';
  title: string = '';
  subtitle: string = '';
  valueText: string = '';
  onDecrease: () => void = () => {};
  onIncrease: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(22)
        .fontColor('#3E5798')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(24)
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Row({ space: 8 }) {
        Text('-')
          .fontSize(20)
          .fontColor(AppColors.PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.PRIMARY_SOFT)
          .borderRadius(16)
          .onClick(() => {
            this.onDecrease();
          })
        Text(this.valueText)
          .fontSize(15)
          .fontColor(AppColors.TEXT)
          .width(76)
          .textAlign(TextAlign.Center)
        Text('+')
          .fontSize(20)
          .fontColor(AppColors.PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.PRIMARY_SOFT)
          .borderRadius(16)
          .onClick(() => {
            this.onIncrease();
          })
      }
    }
    .width('100%')
    .height(76)
    .padding({ left: 14, right: 14 })
  }
}

@Component
export struct SettingsPage {
  @ObjectLink state: SettingsUiState;
  onOpenAbout: () => void = () => {};
  onRecordHistoryChange: (value: boolean) => void = (_value: boolean) => {};
  onHeartbeatAnimationChange: (value: boolean) => void = (_value: boolean) => {};
  onDisplaySpeedChange: (value: boolean) => void = (_value: boolean) => {};
  onHideFromRecentsChange: (value: boolean) => void = (_value: boolean) => {};
  onAutoConnectChange: (value: boolean) => void = (_value: boolean) => {};
  onAutoReconnectChange: (value: boolean) => void = (_value: boolean) => {};
  onBackgroundMonitoringChange: (value: boolean) => void = (_value: boolean) => {};
  onHeartRateAlertChange: (value: boolean) => void = (_value: boolean) => {};
  onLowBpmThresholdChange: (value: number) => void = (_value: number) => {};
  onHighBpmThresholdChange: (value: number) => void = (_value: number) => {};
  onAlertDurationSecondsChange: (value: number) => void = (_value: number) => {};
  onAlertNotificationChange: (value: boolean) => void = (_value: boolean) => {};
  onAlertVibrationChange: (value: boolean) => void = (_value: boolean) => {};
  onAlertSoundChange: (value: boolean) => void = (_value: boolean) => {};

  @Builder
  private sectionTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_MUTED)
      .width('100%')
      .padding({ left: 12, top: 8, bottom: 6 })
  }

  @Builder
  private line() {
    Divider()
      .strokeWidth(1)
      .color(AppColors.DIVIDER)
      .margin({ left: 72 })
  }

  build() {
    Scroll() {
      Column({ space: 6 }) {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .width('100%')
          .margin({ bottom: 12 })

        this.sectionTitle('基础功能')
        Column() {
          SettingSwitchRow({ icon: '◫', title: '记录历史数据', subtitle: '将心率数据保存到历史',
            checked: this.state.recordHistory, onChange: (value: boolean) => { this.onRecordHistoryChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '◎', title: '心跳动画效果', subtitle: '显示实时心跳动画',
            checked: this.state.heartbeatAnimation,
            onChange: (value: boolean) => { this.onHeartbeatAnimationChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '◴', title: '显示时速 (GPS)', subtitle: '通过 GPS 获取当前移动速度',
            checked: this.state.displaySpeed, onChange: (value: boolean) => { this.onDisplaySpeedChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '◉', title: '退出应用隐藏后台', subtitle: '在多任务界面隐藏应用预览',
            checked: this.state.hideFromRecents,
            onChange: (value: boolean) => { this.onHideFromRecentsChange(value); } })
          this.line()
          SettingLinkRow({ icon: '◖', title: '全屏模式', subtitle: '全屏模式的心率播报提示音' })
          this.line()
          SettingLinkRow({ icon: '◍', title: '主题设置', subtitle: '自定义应用配色方案' })
          this.line()
          SettingLinkRow({ icon: '☷', title: '导航样式', subtitle: '导航栏与液态玻璃效果' })
          this.line()
          SettingSwitchRow({ icon: '!', title: '心率预警', subtitle: '超过阈值并持续指定时间后提醒',
            checked: this.state.heartRateAlert,
            onChange: (value: boolean) => { this.onHeartRateAlertChange(value); } })
          this.line()
          SettingStepperRow({ icon: '↑', title: '高心率阈值', subtitle: '高于该数值后开始计时',
            valueText: this.state.highBpmThreshold + ' bpm',
            onDecrease: () => { this.onHighBpmThresholdChange(this.state.highBpmThreshold - 5); },
            onIncrease: () => { this.onHighBpmThresholdChange(this.state.highBpmThreshold + 5); } })
          this.line()
          SettingStepperRow({ icon: '↓', title: '低心率阈值', subtitle: '低于该数值后开始计时',
            valueText: this.state.lowBpmThreshold + ' bpm',
            onDecrease: () => { this.onLowBpmThresholdChange(this.state.lowBpmThreshold - 5); },
            onIncrease: () => { this.onLowBpmThresholdChange(this.state.lowBpmThreshold + 5); } })
          this.line()
          SettingStepperRow({ icon: 's', title: '持续时间', subtitle: '异常持续达到该时间才触发',
            valueText: this.state.alertDurationSeconds + ' 秒',
            onDecrease: () => { this.onAlertDurationSecondsChange(this.state.alertDurationSeconds - 5); },
            onIncrease: () => { this.onAlertDurationSecondsChange(this.state.alertDurationSeconds + 5); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('设备连接')
        Column() {
          SettingSwitchRow({ icon: '★', title: '启动时连接收藏设备', subtitle: '启动应用后自动连接首选设备',
            checked: this.state.autoConnect, onChange: (value: boolean) => { this.onAutoConnectChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '⌁', title: '断开后自动重连', subtitle: '连接断开后自动尝试重新连接',
            checked: this.state.autoReconnect,
            onChange: (value: boolean) => { this.onAutoReconnectChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '☁', title: '后台监测', subtitle: '连接后申请蓝牙后台连续任务',
            checked: this.state.backgroundMonitoring,
            onChange: (value: boolean) => { this.onBackgroundMonitoringChange(value); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('数据与服务')
        Column() {
          SettingLinkRow({ icon: '⌘', title: 'HTTP / WebSocket 服务', subtitle: '向局域网提供实时心率数据' })
          this.line()
          SettingLinkRow({ icon: '↗', title: 'Webhook 设置', subtitle: '将心率状态推送到远程服务' })
          this.line()
          SettingSwitchRow({ icon: '铃', title: '通知提醒', subtitle: '心率异常时发送系统通知',
            checked: this.state.alertNotification,
            onChange: (value: boolean) => { this.onAlertNotificationChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '声', title: '声音提醒', subtitle: '跟随系统通知声音策略',
            checked: this.state.alertSound,
            onChange: (value: boolean) => { this.onAlertSoundChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '震', title: '振动提醒', subtitle: '心率异常时触发振动',
            checked: this.state.alertVibration,
            onChange: (value: boolean) => { this.onAlertVibrationChange(value); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('其他')
        Column() {
          SettingLinkRow({ icon: 'ⓘ', title: '详细信息', subtitle: '版本、隐私与开源协议',
            onTap: () => { this.onOpenAbout(); } })
          this.line()
          SettingLinkRow({ icon: '◇', title: '后台运行说明', subtitle: '查看鸿蒙后台任务运行状态' })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 94 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppColors.BACKGROUND)
  }
}

@Component
export struct AboutPage {
  onBack: () => void = () => {};

  @Builder
  private aboutRow(icon: string, title: string, subtitle: string) {
    Row({ space: 14 }) {
      Text(icon)
        .fontSize(22)
        .fontColor('#3E5798')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(24)
      Column({ space: 3 }) {
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text(subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(28)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .height(78)
    .padding({ left: 14, right: 16 })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Text('←')
            .fontSize(28)
            .fontColor(AppColors.TEXT)
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.SURFACE)
            .borderRadius(23)
            .onClick(() => {
              this.onBack();
            })
          Text('详细信息')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
        }
        .width('100%')

        Column({ space: 12 }) {
          Image($r('app.media.about'))
            .width(74)
            .height(74)
            .borderRadius(18)
          Text('心率监控器')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
          Text('实时监测心率并记录历史数据')
            .fontSize(16)
            .fontColor(AppColors.TEXT_MUTED)
          Text('版本 0.1.0 · HarmonyOS')
            .fontSize(14)
            .fontColor(AppColors.TEXT)
            .padding({ left: 18, right: 18, top: 8, bottom: 8 })
            .backgroundColor('#D6DEF5')
            .borderRadius(20)
        }
        .width('100%')
        .height(270)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#DCE3FF')
        .borderRadius(28)

        Column() {
          this.aboutRow('▣', '查看开源协议', 'MIT 开源许可证')
          Divider().color(AppColors.DIVIDER).margin({ left: 72 })
          this.aboutRow('ⓘ', '隐私政策', '查看应用数据访问与使用说明')
          Divider().color(AppColors.DIVIDER).margin({ left: 72 })
          this.aboutRow('⇩', '检查更新', '获取最新版本信息')
          Divider().color(AppColors.DIVIDER).margin({ left: 72 })
          this.aboutRow('⌂', '访问 GitHub 仓库', '访问项目源代码仓库')
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppColors.BACKGROUND)
  }
}
