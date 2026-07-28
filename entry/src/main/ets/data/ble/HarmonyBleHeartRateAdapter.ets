import { ble, connection } from '@kit.ConnectivityKit';
import { util } from '@kit.ArkTS';
import {
  BleHeartRatePort,
  DeviceListener,
  DisconnectListener,
  HeartRateDevice,
  MeasurementListener
} from '../../domain/port/BleHeartRatePort';

export class HarmonyBleHeartRateAdapter implements BleHeartRatePort {
  private devices: HeartRateDevice[] = [];
  private deviceListener: DeviceListener = (_devices: HeartRateDevice[]) => {};
  private scanning: boolean = false;

  private scanCallback = (results: Array<ble.ScanResult>): void => {
    results.forEach((result: ble.ScanResult) => {
      const device: HeartRateDevice = {
        id: result.deviceId,
        name: this.resolveDeviceName(result),
        rssi: result.rssi
      };
      this.addOrUpdateDevice(device);
    });
    this.devices.sort((left: HeartRateDevice, right: HeartRateDevice) => right.rssi - left.rssi);
    this.deviceListener(this.devices.slice());
  };

  async startScan(listener: DeviceListener): Promise<void> {
    if (this.scanning) {
      return;
    }
    this.devices = [];
    this.deviceListener = listener;
    this.addConnectedDevices();
    ble.on('BLEDeviceFind', this.scanCallback);
    try {
      const options: ble.ScanOptions = {
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_LATENCY,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };
      // null requests an unfiltered scan; the native API rejects an empty filter array.
      ble.startBLEScan(null, options);
      this.scanning = true;
    } catch (error) {
      ble.off('BLEDeviceFind', this.scanCallback);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(String(error));
    }
  }

  async stopScan(): Promise<void> {
    if (!this.scanning) {
      return;
    }
    ble.stopBLEScan();
    ble.off('BLEDeviceFind', this.scanCallback);
    this.scanning = false;
  }

  async connect(_deviceId: string): Promise<void> {
    throw new Error('BLE GATT connection is not implemented yet');
  }

  async disconnect(): Promise<void> {
    await this.stopScan();
  }

  setMeasurementListener(_listener: MeasurementListener): void {}

  setDisconnectListener(_listener: DisconnectListener): void {}

  private addConnectedDevices(): void {
    const connectedDeviceIds = ble.getConnectedBLEDevices();
    connectedDeviceIds.forEach((deviceId: string) => {
      let deviceName = '';
      try {
        deviceName = connection.getRemoteDeviceName(deviceId);
      } catch (_error) {
        deviceName = '';
      }
      this.addOrUpdateDevice({
        id: deviceId,
        name: deviceName.length > 0 ? deviceName : this.createFallbackName(deviceId),
        rssi: -127
      });
    });
    if (this.devices.length > 0) {
      this.deviceListener(this.devices.slice());
    }
  }

  private addOrUpdateDevice(device: HeartRateDevice): void {
    const index = this.devices.findIndex((item: HeartRateDevice) => item.id === device.id);
    if (index >= 0) {
      const current = this.devices[index];
      this.devices[index] = {
        id: device.id,
        name: device.name.length > 0 ? device.name : current.name,
        rssi: device.rssi
      };
      return;
    }
    this.devices.push({
      id: device.id,
      name: device.name.length > 0 ? device.name : this.createFallbackName(device.id),
      rssi: device.rssi
    });
  }

  private resolveDeviceName(result: ble.ScanResult): string {
    if (result.deviceName.length > 0) {
      return result.deviceName;
    }
    const advertisedName = this.readAdvertisedName(result.data);
    if (advertisedName.length > 0) {
      return advertisedName;
    }
    try {
      const remoteName = connection.getRemoteDeviceName(result.deviceId);
      if (remoteName.length > 0) {
        return remoteName;
      }
    } catch (_error) {
    }
    return this.createFallbackName(result.deviceId);
  }

  private readAdvertisedName(data: ArrayBuffer): string {
    const bytes = new Uint8Array(data);
    let offset = 0;
    let shortenedName = '';
    while (offset < bytes.length) {
      const fieldLength = bytes[offset];
      if (fieldLength === 0) {
        break;
      }
      const fieldEnd = offset + fieldLength + 1;
      if (fieldEnd > bytes.length || fieldLength < 1) {
        break;
      }
      const fieldType = bytes[offset + 1];
      if (fieldType === 0x08 || fieldType === 0x09) {
        try {
          const nameBytes = bytes.slice(offset + 2, fieldEnd);
          const name = util.TextDecoder.create('utf-8').decodeToString(nameBytes).trim();
          if (fieldType === 0x09 && name.length > 0) {
            return name;
          }
          if (name.length > 0) {
            shortenedName = name;
          }
        } catch (_error) {
        }
      }
      offset = fieldEnd;
    }
    return shortenedName;
  }

  private createFallbackName(deviceId: string): string {
    const suffixStart = Math.max(0, deviceId.length - 5);
    return 'BLE 设备 ' + deviceId.substring(suffixStart);
  }
}
