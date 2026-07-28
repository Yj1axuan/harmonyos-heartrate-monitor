@Entry
@Component
struct Index {
  @State private selectedTab: number = 0;
  @State private connected: boolean = false;
  @State private bpm: number = 0;

  @Builder
  private tabLabel(title: string, active: boolean) {
    Column({ space: 3 }) {
      Text(active ? '●' : '○')
        .fontSize(14)
        .fontColor(active ? '#D92D4B' : '#7A808A')
      Text(title)
        .fontSize(12)
        .fontColor(active ? '#D92D4B' : '#59606B')
    }
    .width(80)
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private monitoringPage() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('心率监控器')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#171A1F')
          Text(this.connected ? '心率带已连接' : '等待连接心率设备')
            .fontSize(14)
            .fontColor('#69707B')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text(this.connected ? '已连接' : '未连接')
          .fontSize(12)
          .fontColor(this.connected ? '#137A4A' : '#69707B')
          .backgroundColor(this.connected ? '#E7F6EE' : '#EEF0F3')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(6)
      }
      .width('100%')

      Column({ space: 8 }) {
        Text(this.bpm > 0 ? this.bpm.toString() : '--')
          .fontSize(76)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D92D4B')
        Text('BPM')
          .fontSize(15)
          .fontColor('#69707B')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      Button(this.connected ? '断开设备' : '扫描心率设备')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(this.connected ? '#4C535D' : '#D92D4B')
        .borderRadius(8)
        .onClick(() => {
          this.connected = !this.connected;
          this.bpm = this.connected ? 72 : 0;
        })

      Text('当前为界面骨架，下一阶段接入真机 BLE。')
        .fontSize(12)
        .fontColor('#858B94')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 24, bottom: 18 })
    .backgroundColor('#F7F8FA')
  }

  @Builder
  private historyPage() {
    Column({ space: 20 }) {
      Text('历史记录')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .fontColor('#171A1F')
      Column({ space: 12 }) {
        Text('暂无监测记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#30343A')
        Text('连接设备后，心率数据将在这里按会话展示。')
          .fontSize(14)
          .fontColor('#747B85')
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F7F8FA')
  }

  @Builder
  private settingsPage() {
    Column({ space: 0 }) {
      Text('设置')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .fontColor('#171A1F')
        .margin({ bottom: 20 })

      this.settingRow('自动重连', '设备断开后自动尝试恢复连接', true)
      Divider().color('#E3E5E8')
      this.settingRow('后台监测', '使用蓝牙长时任务持续记录', false)
      Divider().color('#E3E5E8')
      this.settingRow('心率预警', '超过阈值时发送通知', false)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F7F8FA')
  }

  @Builder
  private settingRow(title: string, description: string, enabled: boolean) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#25292F')
        Text(description)
          .fontSize(13)
          .fontColor('#777E88')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .enabled(false)
    }
    .width('100%')
    .height(76)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedTab }) {
      TabContent() {
        this.monitoringPage()
      }
      .tabBar(this.tabLabel('监测', this.selectedTab === 0))

      TabContent() {
        this.historyPage()
      }
      .tabBar(this.tabLabel('历史', this.selectedTab === 1))

      TabContent() {
        this.settingsPage()
      }
      .tabBar(this.tabLabel('设置', this.selectedTab === 2))
    }
    .barHeight(58)
    .barBackgroundColor('#FFFFFF')
    .backgroundColor('#F7F8FA')
    .onChange((index: number) => {
      this.selectedTab = index;
    })
  }
}
