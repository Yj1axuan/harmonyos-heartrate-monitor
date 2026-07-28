import { AppColors } from '../theme/AppTheme';
import { HeartRateUiState } from '../../application/state/HeartRateUiState';

@Component
export struct HomePage {
  @ObjectLink state: HeartRateUiState;
  onConnectionToggle: () => void = () => {};

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

      Text(this.state.connected ? 'MAX 90' : 'MAX --')
        .fontSize(15)
        .fontColor(AppColors.TEXT_MUTED)
        .position({ right: 14, top: 14 })
      Text(this.state.connected ? 'MIN 79' : 'MIN --')
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
        .commands('M 42 112 L 72 118 L 102 110 L 140 114 L 178 120 L 214 111 L 247 101 L 274 78 L 310 62')
        .fill(Color.Transparent)
        .stroke(this.state.connected ? '#E43D3D' : '#A8ABB2')
        .strokeWidth(4)
        .width('100%')
        .height(158)

      Text(this.state.connected ? 'Max 90' : '等待数据')
        .fontSize(12)
        .fontColor(this.state.connected ? '#E43D3D' : AppColors.TEXT_MUTED)
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

        this.actionRow('⌁', this.state.connected ? '已连接设备 ' + this.state.deviceName : '可用设备', AppColors.SURFACE,
          AppColors.TEXT, () => {})

        if (this.state.connected) {
          this.actionRow('⛶', '进入全屏模式', AppColors.PRIMARY_SOFT, '#344C8B', () => {})
        }

        Row({ space: 10 }) {
          Text(this.state.connected ? '⌁' : '⌕')
            .fontSize(21)
            .fontColor(AppColors.WHITE)
          Text(this.state.connected ? '断开连接' : '扫描设备')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.WHITE)
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.state.connected ? AppColors.ERROR : AppColors.PRIMARY)
        .borderRadius(28)
        .onClick(() => {
          this.onConnectionToggle();
        })
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
