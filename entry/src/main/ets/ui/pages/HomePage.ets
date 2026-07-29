import { AppColors } from '../theme/AppTheme';
import { HeartRateUiState } from '../../application/state/HeartRateUiState';

@Component
export struct HomePage {
  @ObjectLink state: HeartRateUiState;
  onOpenDevices: () => void = () => {};
  onDisconnect: () => void = () => {};

  private availableBluetoothCount(): number {
    return this.state.devices.length;
  }

  private chartPath(): string {
    const samples = this.state.samples;
    if (!this.state.connected || samples.length === 0) {
      return '';
    }
    const minBpm = this.state.minBpm > 0 ? this.state.minBpm : 60;
    const maxBpm = this.state.maxBpm > minBpm ? this.state.maxBpm : minBpm + 20;
    const range = Math.max(1, maxBpm - minBpm);
    const width = 268;
    const height = 96;
    const left = 42;
    const top = 42;
    let path = '';
    samples.forEach((bpm: number, index: number) => {
      const x = samples.length === 1 ? left : left + Math.floor((width * index) / (samples.length - 1));
      const y = top + height - Math.floor(((bpm - minBpm) * height) / range);
      path += (index === 0 ? 'M ' : ' L ') + x.toString() + ' ' + y.toString();
    });
    return path;
  }

  @Builder
  private heartRateCard() {
    Stack({ alignContent: Alignment.Center }) {
      Text('♥')
        .fontSize(132)
        .fontColor(AppColors.HEART_SOFT)
        .opacity(0.9)

      Row({ space: 5 }) {
        Text(this.state.connected ? this.state.bpm.toString() : '--')
          .fontSize(62)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
        Text('bpm')
          .fontSize(18)
          .fontColor(AppColors.TEXT)
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 16 })
      }

      Text(this.state.connected && this.state.maxBpm > 0 ? 'MAX ' + this.state.maxBpm.toString() : 'MAX --')
        .fontSize(15)
        .fontColor(AppColors.TEXT_MUTED)
        .position({ right: 14, top: 14 })
      Text(this.state.connected && this.state.minBpm > 0 ? 'MIN ' + this.state.minBpm.toString() : 'MIN --')
        .fontSize(15)
        .fontColor(AppColors.TEXT_MUTED)
        .position({ right: 14, bottom: 14 })
    }
    .height(168)
    .layoutWeight(1)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
  }

  @Builder
  private speedCard() {
    Column() {
      Text('速度')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
        .width('100%')
      Blank()
      Text('--')
        .fontSize(36)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
      Blank()
      Text('km/h')
        .fontSize(15)
        .fontColor(AppColors.TEXT_MUTED)
        .width('100%')
        .textAlign(TextAlign.End)
    }
    .width(116)
    .height(168)
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
  }

  @Builder
  private realtimeChart() {
    Stack() {
      Column() {
        Divider()
          .strokeWidth(1)
          .color('#CBCBD2')
          .lineCap(LineCapStyle.Round)
        Blank()
        Divider()
          .strokeWidth(1)
          .color('#CBCBD2')
          .lineCap(LineCapStyle.Round)
        Blank()
        Divider()
          .strokeWidth(1)
          .color('#CBCBD2')
          .lineCap(LineCapStyle.Round)
        Blank()
        Divider()
          .strokeWidth(1)
          .color('#CBCBD2')
          .lineCap(LineCapStyle.Round)
      }
      .height(158)
      .padding({ left: 34, right: 10, top: 12, bottom: 10 })

      Row() {
        Text('100\n\n90\n\n80\n\n70')
          .fontSize(11)
          .lineHeight(36)
          .fontColor(AppColors.TEXT_MUTED)
        Blank()
      }
      .width('100%')
      .height(158)
      .padding({ left: 8, top: 5 })

      Path()
        .commands(this.chartPath())
        .fill(Color.Transparent)
        .stroke(this.state.connected && this.state.samples.length > 0 ? '#E43D3D' : '#A8ABB2')
        .strokeWidth(4)
        .width('100%')
        .height(158)

      Text(this.state.connected && this.state.maxBpm > 0 ? 'Max ' + this.state.maxBpm.toString() : '等待数据')
        .fontSize(12)
        .fontColor(this.state.connected && this.state.maxBpm > 0 ? '#E43D3D' : AppColors.TEXT_MUTED)
        .position({ left: 48, top: 39 })
    }
    .width('100%')
    .height(158)
    .padding(8)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
  }

  @Builder
  private actionRow(icon: string, title: string, background: string, color: string, onClick: () => void) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(22)
        .fontColor(color)
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('›')
        .fontSize(28)
        .fontColor(color)
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor(background)
    .borderRadius(27)
    .onClick(onClick)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('心率监控器')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
          Blank()
          Row({ space: 6 }) {
            Text('♥')
              .fontSize(30)
              .fontColor(this.state.connected ? '#FF251A' : '#A8ABB2')
            Text(this.state.connected ? this.state.bpm.toString() : '--')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.state.connected ? '#FF251A' : '#A8ABB2')
          }
          Text('↗')
            .fontSize(25)
            .fontColor(AppColors.WHITE)
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(23)
            .margin({ left: 10 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 10 }) {
          this.heartRateCard()
          this.speedCard()
        }
        .width('100%')

        this.realtimeChart()

        this.actionRow('⌁', this.state.connected ? '已连接设备 ' + this.state.deviceName :
          (this.state.scanning ? '正在扫描蓝牙设备' :
            (this.availableBluetoothCount() > 0 ? '发现 ' + this.availableBluetoothCount().toString() + ' 台蓝牙设备' : '可用蓝牙设备')),
          AppColors.SURFACE,
          AppColors.TEXT, this.onOpenDevices)

        if (this.state.statusMessage.length > 0) {
          Text(this.state.statusMessage)
            .fontSize(13)
            .fontColor(this.state.failed ? AppColors.ERROR : AppColors.TEXT_MUTED)
            .width('100%')
            .padding({ left: 4, right: 4 })
        }

        if (this.state.connected) {
          this.actionRow('⛶', '进入全屏模式', AppColors.PRIMARY_SOFT, '#344C8B', () => {})

          Row({ space: 10 }) {
            Text('⌁')
              .fontSize(21)
              .fontColor(AppColors.WHITE)
            Text('断开连接')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.WHITE)
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(AppColors.ERROR)
          .borderRadius(28)
          .onClick(this.onDisconnect)
        }

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
