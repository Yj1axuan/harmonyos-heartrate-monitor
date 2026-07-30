import {
  AppColors,
  THEME_COLOR_PRESETS,
  THEME_MODE_OPTIONS,
  THEME_SOURCE_OPTIONS,
  THEME_STYLE_OPTIONS,
  ThemeColorPreset,
  ThemeModeOption,
  ThemeMode,
  ThemeSourceOption,
  ThemeSource,
  ThemeStyleOption,
  ThemeStyle,
  generateThemePalette,
  themeHexToHsv,
  themeHsvToHex
} from '../theme/AppTheme';
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
        .fontColor(AppColors.PRIMARY)
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
        .fontColor(AppColors.PRIMARY)
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
  icon: string = '•';
  title: string = '';
  subtitle: string = '';
  valueText: string = '';
  onDecrease: () => void = () => {};
  onIncrease: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(22)
        .fontColor(AppColors.PRIMARY)
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
struct SettingChoiceRow {
  icon: string = '•';
  title: string = '';
  subtitle: string = '';
  @Prop selected: boolean = false;
  onTap: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(20)
        .fontColor(this.selected ? AppColors.WHITE : AppColors.PRIMARY)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.selected ? AppColors.PRIMARY : AppColors.PRIMARY_SOFT)
        .borderRadius(21)
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.selected ? '✓' : '')
        .fontSize(18)
        .fontColor(AppColors.PRIMARY)
        .width(28)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.selected ? AppColors.PRIMARY_SOFT : Color.Transparent)
    .borderRadius(20)
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct SettingsPage {
  @ObjectLink state: SettingsUiState;
  showFullscreenModeEntry: boolean = false;
  onOpenAbout: () => void = () => {};
  onOpenThemeSettings: () => void = () => {};
  onOpenFullScreen: () => void = () => {};
  onThemeSourceChange: (value: ThemeSource) => void = (_value: ThemeSource) => {};
  onThemeModeChange: (value: ThemeMode) => void = (_value: ThemeMode) => {};
  onThemeColorChange: (value: string) => void = (_value: string) => {};
  onThemeStyleChange: (value: ThemeStyle) => void = (_value: ThemeStyle) => {};
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
  onFullscreenSoundModeChange: (value: string) => void = (_value: string) => {};
  onFullscreenDisplayColorChange: (value: string) => void = (_value: string) => {};
  @State private pickerHue: number = 220;
  @State private pickerSaturation: number = 58;
  @State private pickerValue: number = 66;

  aboutToAppear(): void {
    this.syncPickerFromColor(this.state.themeColor);
  }

  private syncPickerFromColor(color: string): void {
    const hsv = themeHexToHsv(color);
    this.pickerHue = Math.round(hsv.h);
    this.pickerSaturation = Math.round(hsv.s * 100);
    this.pickerValue = Math.round(hsv.v * 100);
  }

  private commitPickerColor(): void {
    const color = themeHsvToHex(this.pickerHue, this.pickerSaturation / 100, this.pickerValue / 100);
    this.onThemeSourceChange('custom');
    this.onThemeColorChange(color);
  }

  private selectThemeColor(color: string): void {
    this.syncPickerFromColor(color);
    this.onThemeSourceChange('custom');
    this.onThemeColorChange(color);
  }

  private themePreviewPrimary(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).primary;
  }

  private themePreviewSecondary(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).secondary;
  }

  private themePreviewBackground(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).background;
  }

  private normalizedColor(color: string): string {
    return color.toUpperCase();
  }

  private isPresetSelected(color: string): boolean {
    return this.state.themeSource === 'custom' && this.normalizedColor(this.state.themeColor) === this.normalizedColor(color);
  }

  private nextFullscreenSoundMode(): string {
    if (this.state.fullscreenSoundMode === 'off') {
      return 'zh';
    }
    if (this.state.fullscreenSoundMode === 'zh') {
      return 'en';
    }
    return 'off';
  }

  private nextFullscreenDisplayColor(): string {
    if (this.state.fullscreenDisplayColor === 'red') {
      return 'green';
    }
    if (this.state.fullscreenDisplayColor === 'green') {
      return 'cyan';
    }
    return 'red';
  }

  private soundModeLabel(): string {
    if (this.state.fullscreenSoundMode === 'off') {
      return '关闭';
    }
    if (this.state.fullscreenSoundMode === 'en') {
      return '英文提示音';
    }
    return '中文提示音';
  }

  private colorLabel(): string {
    if (this.state.fullscreenDisplayColor === 'green') {
      return '绿色';
    }
    if (this.state.fullscreenDisplayColor === 'cyan') {
      return '青色';
    }
    return '红色';
  }

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

  @Builder
  private colorChip(name: string, color: string) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(this.isPresetSelected(color) ? '✓' : '')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
      }
      .width(44)
      .height(44)
      .backgroundColor(color)
      .borderRadius(22)
      .border({ width: this.isPresetSelected(color) ? 3 : 1, color: this.isPresetSelected(color) ? AppColors.TEXT : AppColors.DIVIDER })
      Text(name)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width(54)
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.selectThemeColor(color);
    })
  }

  @Builder
  private styleChip(value: ThemeStyle, title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(this.state.themeStyle === value ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.state.themeStyle === value ? AppColors.WHITE : AppColors.TEXT)
      .height(36)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.state.themeStyle === value ? AppColors.PRIMARY : AppColors.PRIMARY_SOFT)
      .borderRadius(18)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.onThemeStyleChange(value);
      })
  }

  @Builder
  private previewBlock(title: string, color: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
      Blank()
      Text(color)
        .fontSize(11)
        .fontColor(AppColors.TEXT)
    }
    .width('31%')
    .height(74)
    .padding(10)
    .backgroundColor(color)
    .borderRadius(18)
    .border({ width: 1, color: AppColors.DIVIDER })
  }

  @Builder
  private themeSection() {
    this.sectionTitle('主题设置')
    Column({ space: 10 }) {
      Text('主题来源')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)
        .width('100%')
      ForEach(THEME_SOURCE_OPTIONS, (item: ThemeSourceOption) => {
        SettingChoiceRow({ icon: item.value === 'system' ? '◎' : '◉', title: item.title, subtitle: item.subtitle,
          selected: this.state.themeSource === item.value,
          onTap: () => { this.onThemeSourceChange(item.value); } })
      }, (item: ThemeSourceOption) => item.value)

      Text('明暗模式')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)
        .width('100%')
        .margin({ top: 4 })
      ForEach(THEME_MODE_OPTIONS, (item: ThemeModeOption) => {
        SettingChoiceRow({ icon: item.value === 'dark' ? '☾' : '☀', title: item.title, subtitle: item.subtitle,
          selected: this.state.themeMode === item.value,
          onTap: () => { this.onThemeModeChange(item.value); } })
      }, (item: ThemeModeOption) => item.value)

      Text('主题颜色')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)
        .width('100%')
        .margin({ top: 4 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(THEME_COLOR_PRESETS, (preset: ThemeColorPreset) => {
          this.colorChip(preset.name, preset.hex)
        }, (preset: ThemeColorPreset) => preset.hex)
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('HSV 自定义颜色')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT)
          Blank()
          Text(this.state.themeColor)
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        Text('色相 ' + Math.round(this.pickerHue).toString())
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
        Slider({ value: this.pickerHue, min: 0, max: 360, step: 1 })
          .selectedColor(AppColors.PRIMARY)
          .onChange((value: number) => {
            this.pickerHue = value;
            this.commitPickerColor();
          })
        Text('饱和度 ' + Math.round(this.pickerSaturation).toString() + '%')
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
        Slider({ value: this.pickerSaturation, min: 0, max: 100, step: 1 })
          .selectedColor(AppColors.PRIMARY)
          .onChange((value: number) => {
            this.pickerSaturation = value;
            this.commitPickerColor();
          })
        Text('明度 ' + Math.round(this.pickerValue).toString() + '%')
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
        Slider({ value: this.pickerValue, min: 0, max: 100, step: 1 })
          .selectedColor(AppColors.PRIMARY)
          .onChange((value: number) => {
            this.pickerValue = value;
            this.commitPickerColor();
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(AppColors.SURFACE_STRONG)
      .borderRadius(20)

      Row({ space: 8 }) {
        this.previewBlock('主色', this.themePreviewPrimary())
        this.previewBlock('辅助色', this.themePreviewSecondary())
        this.previewBlock('背景色', this.themePreviewBackground())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text('配色风格')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)
        .width('100%')
        .margin({ top: 4 })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(THEME_STYLE_OPTIONS, (item: ThemeStyleOption) => {
          this.styleChip(item.value, item.title)
        }, (item: ThemeStyleOption) => item.value)
      }
      .width('100%')
      Text('当前配色会应用到按钮、开关、卡片、背景、文字和底部导航。')
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
        .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
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
          SettingSwitchRow({ icon: '▣', title: '记录历史数据', subtitle: '将心率数据保存到历史记录',
            checked: this.state.recordHistory, onChange: (value: boolean) => { this.onRecordHistoryChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '♥', title: '心跳动画效果', subtitle: '显示实时心跳动画',
            checked: this.state.heartbeatAnimation, onChange: (value: boolean) => { this.onHeartbeatAnimationChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '⌁', title: '显示速度(GPS)', subtitle: '通过 GPS 获取当前移动速度',
            checked: this.state.displaySpeed, onChange: (value: boolean) => { this.onDisplaySpeedChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '◌', title: '退出应用隐藏后台卡片', subtitle: '在多任务界面隐藏应用预览',
            checked: this.state.hideFromRecents, onChange: (value: boolean) => { this.onHideFromRecentsChange(value); } })
          this.line()
          if (this.showFullscreenModeEntry) {
            SettingLinkRow({ icon: '⛶', title: '全屏模式', subtitle: '进入心率全屏显示界面',
              onTap: () => { this.onOpenFullScreen(); } })
            this.line()
          }
          SettingLinkRow({ icon: '♪', title: '全屏提示音', subtitle: this.soundModeLabel(),
            onTap: () => { this.onFullscreenSoundModeChange(this.nextFullscreenSoundMode()); } })
          this.line()
          SettingLinkRow({ icon: '◐', title: '全屏显示颜色', subtitle: this.colorLabel(),
            onTap: () => { this.onFullscreenDisplayColorChange(this.nextFullscreenDisplayColor()); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('主题设置')
        Column() {
          SettingLinkRow({ icon: '◉', title: '主题设置', subtitle: '主题来源、明暗模式、颜色和配色风格',
            onTap: () => { this.onOpenThemeSettings(); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('设备连接')
        Column() {
          SettingSwitchRow({ icon: '☑', title: '启动时连接收藏设备', subtitle: '启动应用后自动连接首选设备',
            checked: this.state.autoConnect, onChange: (value: boolean) => { this.onAutoConnectChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '↻', title: '断开后自动重连', subtitle: '连接断开后自动尝试重新连接',
            checked: this.state.autoReconnect, onChange: (value: boolean) => { this.onAutoReconnectChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '☁', title: '后台监测', subtitle: '连接后允许后台连续监测',
            checked: this.state.backgroundMonitoring, onChange: (value: boolean) => { this.onBackgroundMonitoringChange(value); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('心率预警')
        Column() {
          SettingSwitchRow({ icon: '!', title: '心率预警', subtitle: '超过阈值并持续指定时间后提醒',
            checked: this.state.heartRateAlert, onChange: (value: boolean) => { this.onHeartRateAlertChange(value); } })
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
          this.line()
          SettingSwitchRow({ icon: '铃', title: '通知提醒', subtitle: '心率异常时发送系统通知',
            checked: this.state.alertNotification, onChange: (value: boolean) => { this.onAlertNotificationChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '声', title: '声音提醒', subtitle: '跟随系统通知声音策略',
            checked: this.state.alertSound, onChange: (value: boolean) => { this.onAlertSoundChange(value); } })
          this.line()
          SettingSwitchRow({ icon: '震', title: '振动提醒', subtitle: '心率异常时触发振动',
            checked: this.state.alertVibration, onChange: (value: boolean) => { this.onAlertVibrationChange(value); } })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('数据与服务')
        Column() {
          SettingLinkRow({ icon: '↔', title: 'HTTP / WebSocket 服务', subtitle: '向局域网提供实时心率数据' })
          this.line()
          SettingLinkRow({ icon: '↗', title: 'Webhook 设置', subtitle: '将心率状态推送到远程服务' })
        }
        .width('100%')
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        this.sectionTitle('其他')
        Column() {
          SettingLinkRow({ icon: 'ⓘ', title: '详细信息', subtitle: '版本、隐私与开源协议',
            onTap: () => { this.onOpenAbout(); } })
          this.line()
          SettingLinkRow({ icon: '▣', title: '后台运行说明', subtitle: '查看后台任务运行状态' })
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
export struct ThemeSettingsPage {
  @ObjectLink state: SettingsUiState;
  onBack: () => void = () => {};
  onThemeSourceChange: (value: ThemeSource) => void = (_value: ThemeSource) => {};
  onThemeModeChange: (value: ThemeMode) => void = (_value: ThemeMode) => {};
  onThemeColorChange: (value: string) => void = (_value: string) => {};
  onThemeStyleChange: (value: ThemeStyle) => void = (_value: ThemeStyle) => {};
  @State private pickerHue: number = 220;
  @State private pickerSaturation: number = 58;
  @State private pickerValue: number = 66;

  aboutToAppear(): void {
    this.syncPickerFromColor(this.state.themeColor);
  }

  private syncPickerFromColor(color: string): void {
    const hsv = themeHexToHsv(color);
    this.pickerHue = Math.round(hsv.h);
    this.pickerSaturation = Math.round(hsv.s * 100);
    this.pickerValue = Math.round(hsv.v * 100);
  }

  private commitPickerColor(): void {
    const color = themeHsvToHex(this.pickerHue, this.pickerSaturation / 100, this.pickerValue / 100);
    this.onThemeSourceChange('custom');
    this.onThemeColorChange(color);
  }

  private selectThemeColor(color: string): void {
    this.syncPickerFromColor(color);
    this.onThemeSourceChange('custom');
    this.onThemeColorChange(color);
  }

  private themePreviewPrimary(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).primary;
  }

  private themePreviewSecondary(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).secondary;
  }

  private themePreviewBackground(): string {
    return generateThemePalette({ source: this.state.themeSource, mode: this.state.themeMode, color: this.state.themeColor, style: this.state.themeStyle }).background;
  }

  private normalizedColor(color: string): string {
    return color.toUpperCase();
  }

  private isPresetSelected(color: string): boolean {
    return this.state.themeSource === 'custom' && this.normalizedColor(this.state.themeColor) === this.normalizedColor(color);
  }

  @Builder
  private colorChip(name: string, color: string) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(this.isPresetSelected(color) ? '✓' : '')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
      }
      .width(44)
      .height(44)
      .backgroundColor(color)
      .borderRadius(22)
      .border({ width: this.isPresetSelected(color) ? 3 : 1, color: this.isPresetSelected(color) ? AppColors.TEXT : AppColors.DIVIDER })
      Text(name)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width(54)
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.selectThemeColor(color);
    })
  }

  @Builder
  private styleChip(value: ThemeStyle, title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(this.state.themeStyle === value ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.state.themeStyle === value ? AppColors.WHITE : AppColors.TEXT)
      .height(36)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.state.themeStyle === value ? AppColors.PRIMARY : AppColors.PRIMARY_SOFT)
      .borderRadius(18)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.onThemeStyleChange(value);
      })
  }

  @Builder
  private previewBlock(title: string, color: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
      Blank()
      Text(color)
        .fontSize(11)
        .fontColor(AppColors.TEXT)
    }
    .width('31%')
    .height(74)
    .padding(10)
    .backgroundColor(color)
    .borderRadius(18)
    .border({ width: 1, color: AppColors.DIVIDER })
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row({ space: 12 }) {
          Text('‹')
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
          Text('主题设置')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
        }
        .width('100%')

        Column({ space: 10 }) {
          Text('主题来源')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .width('100%')
          ForEach(THEME_SOURCE_OPTIONS, (item: ThemeSourceOption) => {
            SettingChoiceRow({ icon: item.value === 'system' ? '◎' : '◉', title: item.title, subtitle: item.subtitle,
              selected: this.state.themeSource === item.value,
              onTap: () => { this.onThemeSourceChange(item.value); } })
          }, (item: ThemeSourceOption) => item.value)

          Text('明暗模式')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .width('100%')
            .margin({ top: 4 })
          ForEach(THEME_MODE_OPTIONS, (item: ThemeModeOption) => {
            SettingChoiceRow({ icon: item.value === 'dark' ? '☾' : '☀', title: item.title, subtitle: item.subtitle,
              selected: this.state.themeMode === item.value,
              onTap: () => { this.onThemeModeChange(item.value); } })
          }, (item: ThemeModeOption) => item.value)

          Text('主题颜色')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .width('100%')
            .margin({ top: 4 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(THEME_COLOR_PRESETS, (preset: ThemeColorPreset) => {
              this.colorChip(preset.name, preset.hex)
            }, (preset: ThemeColorPreset) => preset.hex)
          }
          .width('100%')

          Column({ space: 8 }) {
            Row() {
              Text('HSV 自定义颜色')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT)
              Blank()
              Text(this.state.themeColor)
                .fontSize(12)
                .fontColor(AppColors.TEXT_MUTED)
            }
            .width('100%')
            Text('色相 ' + Math.round(this.pickerHue).toString())
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
            Slider({ value: this.pickerHue, min: 0, max: 360, step: 1 })
              .selectedColor(AppColors.PRIMARY)
              .onChange((value: number) => {
                this.pickerHue = value;
                this.commitPickerColor();
              })
            Text('饱和度 ' + Math.round(this.pickerSaturation).toString() + '%')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
            Slider({ value: this.pickerSaturation, min: 0, max: 100, step: 1 })
              .selectedColor(AppColors.PRIMARY)
              .onChange((value: number) => {
                this.pickerSaturation = value;
                this.commitPickerColor();
              })
            Text('明度 ' + Math.round(this.pickerValue).toString() + '%')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
            Slider({ value: this.pickerValue, min: 0, max: 100, step: 1 })
              .selectedColor(AppColors.PRIMARY)
              .onChange((value: number) => {
                this.pickerValue = value;
                this.commitPickerColor();
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.SURFACE_STRONG)
          .borderRadius(20)

          Row({ space: 8 }) {
            this.previewBlock('主色', this.themePreviewPrimary())
            this.previewBlock('辅助色', this.themePreviewSecondary())
            this.previewBlock('背景色', this.themePreviewBackground())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Text('配色风格')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .width('100%')
            .margin({ top: 4 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(THEME_STYLE_OPTIONS, (item: ThemeStyleOption) => {
              this.styleChip(item.value, item.title)
            }, (item: ThemeStyleOption) => item.value)
          }
          .width('100%')
          Text('当前配色会应用到按钮、开关、卡片、背景、文字和底部导航。')
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')
        .padding(14)
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

@Component
export struct AboutPage {
  onBack: () => void = () => {};

  @Builder
  private aboutRow(icon: string, title: string, subtitle: string) {
    Row({ space: 14 }) {
      Text(icon)
        .fontSize(22)
        .fontColor(AppColors.PRIMARY)
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
          Text('‹')
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

        Column() {
          this.aboutRow('♥', '心率监控器', 'BLE 标准心率设备实时监测')
          Divider().color(AppColors.DIVIDER).margin({ left: 72 })
          this.aboutRow('版', '版本', '1.0.0')
          Divider().color(AppColors.DIVIDER).margin({ left: 72 })
          this.aboutRow('隐', '隐私', '心率数据仅按设置保存在本机')
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
