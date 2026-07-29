import { HeartRateUiState } from '../../application/state/HeartRateUiState';
import { HeartRateDevice } from '../../domain/port/BleHeartRatePort';
import { AppColors } from '../theme/AppTheme';

@Component
export struct DeviceListPage {
  @ObjectLink state: HeartRateUiState;
  @State private searchVisible: boolean = false;
  @State private searchQuery: string = '';
  onBack: () => void = () => {};
  onRefresh: () => void = () => {};
  onSelect: (device: HeartRateDevice) => void = (_device: HeartRateDevice) => {};

  private visibleDevices(): HeartRateDevice[] {
    const devices = this.state.devices;
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) {
      return devices;
    }
    return devices.filter((device: HeartRateDevice) =>
      device.name.toLowerCase().includes(query));
  }

  private deviceStatus(device: HeartRateDevice): string {
    if (this.state.connected && this.state.deviceId === device.id) {
      return '已连接';
    }
    if (device.rssi === -126) {
      return '已发现';
    }
    if (device.rssi <= -127) {
      return '已配对';
    }
    return device.rssi.toString() + ' dBm';
  }

  private displayDeviceName(device: HeartRateDevice): string {
    return device.name;
  }

  private deviceIcon(device: HeartRateDevice): string {
    if (device.deviceKind === 'phone') {
      return '📱';
    }
    if (device.deviceKind === 'tablet') {
      return '▭';
    }
    if (device.deviceKind === 'watch') {
      return '⌚';
    }
    if (device.name.startsWith('手机设备 ') || device.name.startsWith('平板设备 ')) {
      return device.name.startsWith('手机设备 ') ? '📱' : '▭';
    }
    if (device.name.startsWith('运动手表 ')) {
      return '⌚';
    }
    return '⌁';
  }

  @Builder
  private deviceRow(device: HeartRateDevice) {
    Row({ space: 12 }) {
      Text(this.deviceIcon(device))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(21)

      Text(this.displayDeviceName(device))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.deviceStatus(device))
        .fontSize(12)
        .fontColor(AppColors.TEXT_MUTED)
    }
    .width('100%')
    .height(68)
    .padding({ left: 14, right: 16 })
    .onClick(() => {
      this.onSelect(device);
    })
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(32)
          .fontColor(AppColors.TEXT)
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(this.onBack)
        Text('可用蓝牙设备')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
        Blank()
        if (this.state.scanning) {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(AppColors.PRIMARY)
        }
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 4 }) {
            Text('⟳')
              .fontSize(17)
              .fontColor(AppColors.WHITE)
            Text(this.state.scanning ? '刷新中' : '刷新')
              .fontSize(13)
              .fontColor(AppColors.WHITE)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .width(this.state.scanning ? 82 : 68)
        .height(38)
        .backgroundColor(this.state.scanning ? AppColors.TEXT_MUTED : AppColors.PRIMARY)
        .enabled(!this.state.scanning)
        .onClick(this.onRefresh)
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 4 }) {
            Text(this.searchVisible ? '×' : '⌕')
              .fontSize(this.searchVisible ? 18 : 16)
              .fontColor(AppColors.WHITE)
            Text(this.searchVisible ? '关闭' : '搜索')
              .fontSize(13)
              .fontColor(AppColors.WHITE)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .width(68)
        .height(38)
        .backgroundColor(AppColors.PRIMARY)
        .onClick(() => {
          this.searchVisible = !this.searchVisible;
          if (!this.searchVisible) {
            this.searchQuery = '';
          }
        })
      }
      .width('100%')
      .height(64)

      if (this.searchVisible) {
        TextInput({ placeholder: '输入设备名称', text: this.searchQuery })
          .width('100%')
          .height(46)
          .fontSize(16)
          .fontColor(AppColors.TEXT)
          .placeholderColor(AppColors.TEXT_MUTED)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.searchQuery = value;
          })
      }

      Text(this.state.scanning ? '正在刷新附近的蓝牙设备' : '点击刷新获取附近设备')
        .fontSize(14)
        .fontColor(AppColors.TEXT_MUTED)
        .width('100%')
        .margin({ top: 10, bottom: 10 })

      if (this.visibleDevices().length > 0) {
        Scroll() {
          Column() {
            ForEach(this.visibleDevices(), (device: HeartRateDevice, index: number) => {
              this.deviceRow(device)
              if (index < this.visibleDevices().length - 1) {
                Divider().color(AppColors.DIVIDER).margin({ left: 68 })
              }
            }, (device: HeartRateDevice) => device.id)
          }
          .width('100%')
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        Column({ space: 12 }) {
          if (this.searchQuery.trim().length > 0 && this.visibleDevices().length === 0 && this.state.devices.length > 0) {
            Text('未找到匹配设备')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Text('请尝试输入其他设备名称')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
          } else if (this.state.scanning) {
            Text('正在查找设备...')
              .fontSize(16)
              .fontColor(AppColors.TEXT_MUTED)
          } else if (this.state.devices.length > 0 && this.visibleDevices().length === 0) {
            Text('暂无可连接蓝牙设备')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Text('当前发现的设备暂时无法连接')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
          } else {
            Text('未发现可用蓝牙设备')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Text('请确认设备已开启并处于广播或配对状态')
              .fontSize(14)
              .fontColor(AppColors.TEXT_MUTED)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }

      if (this.state.statusMessage.length > 0) {
        Text(this.state.statusMessage)
          .fontSize(13)
          .fontColor(this.state.failed ? AppColors.ERROR : AppColors.TEXT_MUTED)
          .width('100%')
          .padding({ top: 12, bottom: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor(AppColors.BACKGROUND)
  }
}
