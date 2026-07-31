import { AppColors } from '../theme/AppTheme';
import { HeartRateUiState } from '../../application/state/HeartRateUiState';

@Component
export struct HomePage {
  @ObjectLink state: HeartRateUiState;
  onOpenDevices: () => void = () => {};
  onOpenFullScreen: () => void = () => {};
  onDisconnect: () => void = () => {};

  private bpmText(): string {
    return this.state.connected ? this.state.bpm.toString() : '--';
  }

  private connectionLabel(): string {
    if (this.state.connected) {
      return '已连接 ' + this.state.deviceName;
    }
    if (this.state.scanning) {
      return '正在搜索附近设备';
    }
    if (this.state.failed) {
      return '连接失败，点击重试';
    }
    return '等待选择蓝牙设备';
  }

  private connectionHint(): string {
    if (this.state.connected) {
      return '实时心率正在更新';
    }
    if (this.state.scanning) {
      return '扫描完成后可直接连接';
    }
    return '先连接设备，首页会自动变成实时监测面板';
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
  private statTile(title: string, value: string, hint: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
      Text(hint)
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(22)
  }

  @Builder
  private heartRateCard() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 6 }) {
          Text('实时心率')
            .fontSize(14)
            .fontColor(AppColors.TEXT_MUTED)
          Row({ space: 8 }) {
            Text('♥')
              .fontSize(20)
              .fontColor(this.state.connected ? AppColors.HEART : AppColors.TEXT_MUTED)
            Text(this.connectionLabel())
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        Blank()
        Text(this.state.connected ? '监测中' : '待连接')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.state.connected ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.state.connected ? AppColors.PRIMARY_SOFT : AppColors.SURFACE_STRONG)
          .borderRadius(12)
      }

      Row({ space: 8 }) {
        Text(this.bpmText())
          .fontSize(58)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.state.connected ? AppColors.HEART : AppColors.TEXT)
        Text('bpm')
          .fontSize(18)
          .fontColor(AppColors.TEXT_MUTED)
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 14 })
      }

      Text(this.connectionHint())
        .fontSize(13)
        .fontColor(AppColors.TEXT_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 10 }) {
        this.statTile('最高', this.state.maxBpm > 0 ? this.state.maxBpm.toString() + ' bpm' : '--', '本次连接峰值')
        this.statTile('最低', this.state.minBpm > 0 ? this.state.minBpm.toString() + ' bpm' : '--', '本次连接谷值')
      }
    }
    .height(292)
    .layoutWeight(1)
    .padding(18)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
  }

  @Builder
  private speedCard() {
    Column() {
      Text('GPS 速度')
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
    .height(292)
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
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
      .height(140)
      .padding({ left: 38, right: 10, top: 10, bottom: 2 })

      Column() {
        Text('100')
          .fontSize(11)
          .fontColor(AppColors.TEXT_MUTED)
        Text('90')
          .fontSize(11)
          .fontColor(AppColors.TEXT_MUTED)
        Text('80')
          .fontSize(11)
          .fontColor(AppColors.TEXT_MUTED)
        Text('70')
          .fontSize(11)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .width(30)
      .height(136)
      .justifyContent(FlexAlign.SpaceBetween)
      .position({ left: 6, top: 6 })

      Text('bpm')
        .fontSize(11)
        .fontColor(AppColors.TEXT_MUTED)
        .position({ left: 6, top: 148 })

      Path()
        .commands(this.chartPath())
        .fill(Color.Transparent)
        .stroke(this.state.connected && this.state.samples.length > 0 ? AppColors.HEART : AppColors.TEXT_MUTED)
        .strokeWidth(4)
        .width('100%')
        .height(158)

      Text(this.state.connected && this.state.maxBpm > 0 ? 'Max ' + this.state.maxBpm.toString() : '等待数据')
        .fontSize(12)
        .fontColor(this.state.connected && this.state.maxBpm > 0 ? AppColors.HEART : AppColors.TEXT_MUTED)
        .position({ left: 48, top: 39 })
    }
    .width('100%')
    .height(198)
    .padding(12)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
    .clip(true)
    .margin({ top: 4, bottom: 8 })
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
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
        .fontSize(26)
        .fontColor(color)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(16)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 14 })
    .backgroundColor(background)
    .borderRadius(20)
    .onClick(onClick)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 8 }) {
          Row() {
            Column({ space: 4 }) {
              Text('心率监控器')
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)
              Text('实时监测运动与训练状态')
                .fontSize(13)
                .fontColor(AppColors.TEXT_MUTED)
            }
            .layoutWeight(1)
            Blank()
            Text(this.state.connected ? '实时' : '待机')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.state.connected ? AppColors.WHITE : AppColors.TEXT_MUTED)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(this.state.connected ? AppColors.PRIMARY : AppColors.SURFACE_STRONG)
              .borderRadius(14)
          }
        }

        Row({ space: 10 }) {
          this.heartRateCard()
          this.speedCard()
        }
        .width('100%')
        .margin({ bottom: 6 })

        this.realtimeChart()

        this.actionRow('⌁', this.state.connected ? '已连接设备 ' + this.state.deviceName :
          (this.state.scanning ? '正在扫描蓝牙设备' : '连接蓝牙设备'),
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
          this.actionRow('⛶', '进入全屏模式', AppColors.PRIMARY_SOFT, AppColors.PRIMARY, this.onOpenFullScreen)

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
