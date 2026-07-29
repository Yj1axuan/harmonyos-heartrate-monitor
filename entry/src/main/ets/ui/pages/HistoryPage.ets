import { AppColors } from '../theme/AppTheme';
import { FavoriteDevice, HistoryDetail, HistorySummary, SessionPreview } from '../../application/model/HistoryUiModels';

@Component
export struct HistoryPage {
  @Prop summary: HistorySummary = { sessionCount: 0, monitoringMinutes: 0, averageBpm: 0 };
  @Prop sessions: SessionPreview[] = [];
  @Prop detail: HistoryDetail | undefined = undefined;
  onRefresh: () => void = () => {};
  onOpenDetail: (sessionId: number) => void = (_sessionId: number) => {};
  onCloseDetail: () => void = () => {};
  onDeleteSession: (sessionId: number) => void = (_sessionId: number) => {};

  @Builder
  private sessionCard(session: SessionPreview) {
    Row({ space: 10 }) {
      Column({ space: 5 }) {
        Text(session.device)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(session.time)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
        Text(session.stats)
          .fontSize(11)
          .fontColor('#898B93')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack() {
        Divider().color('#D1D2D8').position({ top: 18 })
        Path()
          .commands(session.path)
          .fill(Color.Transparent)
          .stroke(AppColors.PRIMARY)
          .strokeWidth(2)
          .width(80)
          .height(36)
      }
      .width(80)
      .height(36)

      Text('›')
        .fontSize(28)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .height(88)
    .padding({ left: 16, right: 14 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
    .onClick(() => {
      this.onOpenDetail(session.id);
    })
  }

  build() {
    if (this.detail !== undefined) {
      this.detailPage(this.detail)
    } else {
      this.listPage()
    }
  }

  @Builder
  private listPage() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('历史记录')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
          Blank()
          Text('⌕')
            .fontSize(22)
            .fontColor(AppColors.TEXT)
            .width(42)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.SURFACE)
            .borderRadius(21)
            .onClick(this.onRefresh)
        }
        .width('100%')
        .margin({ bottom: 6 })

        Row() {
          Column({ space: 3 }) {
            Text(this.summary.sessionCount.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
            Text('监测会话')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('33%')
          Column({ space: 3 }) {
            Text(this.summary.monitoringMinutes.toLocaleString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
            Text('监测分钟')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('34%')
          Column({ space: 3 }) {
            Text(this.summary.averageBpm.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.HEART)
            Text('平均 BPM')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('33%')
        }
        .width('100%')
        .height(88)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(28)

        if (this.sessions.length > 0) {
          ForEach(this.sessions, (session: SessionPreview) => {
            this.sessionCard(session)
          }, (session: SessionPreview) => session.id.toString())
        } else {
          Column({ space: 8 }) {
            Text('暂无历史记录')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Text('连接心率设备并收到数据后会自动保存')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .width('100%')
          .height(180)
          .justifyContent(FlexAlign.Center)
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

  @Builder
  private detailPage(detail: HistoryDetail) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(32)
          .fontColor(AppColors.TEXT)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(this.onCloseDetail)
        Text('历史详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
        Blank()
        Text('删除')
          .fontSize(14)
          .fontColor(AppColors.ERROR)
          .width(58)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(18)
          .onClick(() => {
            this.onDeleteSession(detail.sessionId);
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Text(detail.device)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
          .width('100%')
        Text(detail.time)
          .fontSize(14)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
        Text(detail.stats)
          .fontSize(13)
          .fontColor(AppColors.TEXT_MUTED)
          .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(22)

      Scroll() {
        Column({ space: 8 }) {
          ForEach(detail.records, (record: string) => {
            Text(record)
              .fontSize(15)
              .fontColor(AppColors.TEXT)
              .width('100%')
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .backgroundColor(AppColors.SURFACE)
              .borderRadius(14)
          }, (record: string) => record)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}

@Component
export struct FavoritePage {
  @Prop devices: FavoriteDevice[] = [];
  onRemove: (deviceId: string) => void = (_deviceId: string) => {};

  @Builder
  private deviceCard(device: FavoriteDevice, primary: boolean) {
    Row({ space: 14 }) {
      Text('⌁')
        .fontSize(24)
        .fontColor(AppColors.PRIMARY)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(24)
      Column({ space: 4 }) {
        Row({ space: 7 }) {
          Text(device.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (primary) {
            Text('自动连接')
              .fontSize(10)
              .fontColor('#344C8B')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(AppColors.PRIMARY_SOFT)
              .borderRadius(5)
          }
        }
        Text(device.id)
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('⌫')
        .fontSize(22)
        .fontColor(AppColors.ERROR)
        .onClick(() => {
          this.onRemove(device.id);
        })
    }
    .width('100%')
    .height(78)
    .padding({ left: 14, right: 16 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(28)
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('收藏设备')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
        Blank()
        Text('⌫')
          .fontSize(22)
          .fontColor(AppColors.ERROR)
          .width(42)
          .height(42)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(21)
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.devices.length > 0) {
        ForEach(this.devices, (device: FavoriteDevice, index: number) => {
          this.deviceCard(device, index === 0)
        }, (device: FavoriteDevice) => device.id)
      } else {
        Column({ space: 8 }) {
          Text('暂无收藏设备')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT)
          Text('连接成功的心率设备会自动加入收藏')
            .fontSize(14)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .height(160)
        .justifyContent(FlexAlign.Center)
      }

      Text('收藏设备会显示在扫描结果顶部，并可用于启动时自动连接。')
        .fontSize(13)
        .fontColor(AppColors.TEXT_MUTED)
        .padding({ left: 8, right: 8, top: 8 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 94 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
