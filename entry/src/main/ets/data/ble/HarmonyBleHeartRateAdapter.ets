import { ble, connection } from '@kit.ConnectivityKit';
import { util } from '@kit.ArkTS';
import { HeartRateParser } from '../../domain/HeartRateParser';
import {
  BleHeartRatePort,
  DeviceListener,
  DisconnectListener,
  HeartRateDevice,
  MeasurementListener
} from '../../domain/port/BleHeartRatePort';

export class HarmonyBleHeartRateAdapter implements BleHeartRatePort {
  private static readonly CONNECTION_TIMEOUT_MS: number = 12000;
  private static readonly HEART_RATE_SERVICE_UUID: string = '180d';
  private static readonly HEART_RATE_SERVICE_UUID_REVERSED: string = '0d18';
  private static readonly HEART_RATE_MEASUREMENT_UUID: string = '2a37';
  private static readonly MAJOR_COMPUTER: number = 0x0100;
  private static readonly MAJOR_PHONE: number = 0x0200;
  private static readonly MAJOR_WEARABLE: number = 0x0700;
  private static readonly MAJOR_HEALTH: number = 0x0900;
  private devices: HeartRateDevice[] = [];
  private deviceListener: DeviceListener = (_devices: HeartRateDevice[]) => {};
  private scanning: boolean = false;
  private classicScanning: boolean = false;
  private activeGattClient: ble.GattClientDevice | undefined = undefined;
  private activeConnectionResolver: ((result: boolean) => void) | undefined = undefined;
  private activeConnectionRejecter: ((error: Error) => void) | undefined = undefined;
  private activeConnectionDeviceId: string = '';
  private activeHeartRateCharacteristic: ble.BLECharacteristic | undefined = undefined;
  private measurementListener: MeasurementListener = (_measurement) => {};
  private disconnectListener: DisconnectListener = (_reason: string) => {};
  private deviceNames: Map<string, string> = new Map<string, string>();
  private resolvingDeviceNames: Set<string> = new Set<string>();

  private scanCallback = (results: Array<ble.ScanResult>): void => {
    results.forEach((result: ble.ScanResult) => {
      const deviceName = this.resolveDeviceName(result);
      const advertisesHeartRate = this.advertisesHeartRateService(result.data);
      const device: HeartRateDevice = {
        id: result.deviceId,
        name: deviceName.length > 0 ? deviceName :
          (advertisesHeartRate ? this.createHeartRateFallbackName(result.deviceId) : ''),
        rssi: result.rssi,
        deviceKind: advertisesHeartRate ? 'heart-rate' : this.resolveBleDeviceKind(result.deviceId, deviceName)
      };
      this.addOrUpdateDevice(device, advertisesHeartRate || this.isLikelySupportedWearable(device.name));
      this.refreshDeviceName(result.deviceId);
    });
    this.deviceListener(this.devices.slice());
  };

  private discoveryCallback = (results: Array<connection.DiscoveryResult>): void => {
    results.forEach((result: connection.DiscoveryResult) => {
      const systemName = this.readKnownDeviceName(result.deviceId);
      const deviceName = systemName.length > 0 ? systemName : this.cleanDeviceName(result.deviceName);
      const deviceKind = this.resolveDeviceKind(result.deviceId, result.deviceClass);
      this.addOrUpdateDevice({
        id: result.deviceId,
        name: deviceName.length > 0 ? deviceName : this.createClassicFallbackName(result.deviceId, result.deviceClass),
        rssi: result.rssi,
        deviceKind: deviceKind
      }, deviceKind === 'watch' || deviceKind === 'band' || this.isLikelySupportedWearable(deviceName));
    });
    this.deviceListener(this.devices.slice());
  };

  private bluetoothDeviceFindCallback = (deviceIds: Array<string>): void => {
    deviceIds.forEach((deviceId: string) => {
      const deviceName = this.readKnownDeviceName(deviceId);
      const deviceKind = this.resolveDeviceKind(deviceId);
      this.addOrUpdateDevice({
        id: deviceId,
        name: deviceName.length > 0 ? deviceName : this.createClassicFallbackName(deviceId),
        rssi: -126,
        deviceKind: deviceKind
      }, deviceKind === 'watch' || deviceKind === 'band' || this.isLikelySupportedWearable(deviceName));
      this.refreshDeviceName(deviceId);
    });
    this.deviceListener(this.devices.slice());
  };

  async getKnownDevices(): Promise<HeartRateDevice[]> {
    this.addPairedDevices(false);
    this.addConnectedDevices(false);
    return this.devices.slice();
  }

  async startScan(listener: DeviceListener): Promise<void> {
    if (this.scanning) {
      this.deviceListener = listener;
      this.deviceListener(this.devices.slice());
      return;
    }
    this.devices = [];
    this.deviceListener = listener;
    this.addPairedDevices();
    this.addConnectedDevices();
    ble.on('BLEDeviceFind', this.scanCallback);
    try {
      const options: ble.ScanOptions = {
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_LATENCY,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };
      // null requests an unfiltered scan; the native API rejects an empty filter array.
      ble.startBLEScan(null, options);
      this.startClassicDiscovery();
      this.scanning = true;
    } catch (error) {
      ble.off('BLEDeviceFind', this.scanCallback);
      try {
        connection.off('discoveryResult', this.discoveryCallback);
        connection.off('bluetoothDeviceFind', this.bluetoothDeviceFindCallback);
      } catch (_offError) {
      }
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
    if (this.classicScanning) {
      try {
        connection.stopBluetoothDiscovery();
      } catch (_error) {
      }
      this.classicScanning = false;
    }
    try {
      connection.off('discoveryResult', this.discoveryCallback);
      connection.off('bluetoothDeviceFind', this.bluetoothDeviceFindCallback);
    } catch (_error) {
    }
    this.scanning = false;
  }

  async connect(deviceId: string): Promise<void> {
    await this.stopActiveGattClient();
    const client = ble.createGattClientDevice(deviceId);
    this.activeGattClient = client;
    this.activeConnectionDeviceId = deviceId;

    await new Promise<void>((resolve: () => void, reject: (error: Error) => void) => {
      const timeoutId = setTimeout(() => {
        void this.stopActiveGattClient();
        reject(new Error('BLE connection timeout'));
      }, HarmonyBleHeartRateAdapter.CONNECTION_TIMEOUT_MS);
      this.activeConnectionResolver = (result: boolean) => {
        clearTimeout(timeoutId);
        this.activeConnectionResolver = undefined;
        this.activeConnectionRejecter = undefined;
        if (result) {
          resolve();
          return;
        }
        reject(new Error('BLE connection failed'));
      };
      this.activeConnectionRejecter = (error: Error) => {
        clearTimeout(timeoutId);
        this.activeConnectionResolver = undefined;
        this.activeConnectionRejecter = undefined;
        reject(error);
      };

      try {
        client.on('BLEConnectionStateChange', this.connectionStateCallback);
        client.connect();
      } catch (error) {
        clearTimeout(timeoutId);
        this.cleanupActiveGattClient();
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    });

    const heartRateCharacteristic = await this.findHeartRateMeasurementCharacteristic(client);
    if (heartRateCharacteristic === undefined) {
      await this.stopActiveGattClient();
      throw new Error('设备不支持标准心率服务');
    }
    this.activeHeartRateCharacteristic = heartRateCharacteristic;
    client.on('BLECharacteristicChange', this.characteristicChangeCallback);
    await client.setCharacteristicChangeNotification(heartRateCharacteristic, true);
  }

  async disconnect(): Promise<void> {
    await this.stopActiveGattClient();
    await this.stopScan();
  }

  setMeasurementListener(listener: MeasurementListener): void {
    this.measurementListener = listener;
  }

  setDisconnectListener(listener: DisconnectListener): void {
    this.disconnectListener = listener;
  }

  private connectionStateCallback = (state: ble.BLEConnectionChangeState): void => {
    if (this.activeConnectionDeviceId.length > 0 && state.deviceId !== this.activeConnectionDeviceId) {
      return;
    }
    if (state.state === 2) {
      if (this.activeConnectionResolver) {
        this.activeConnectionResolver(true);
      }
      return;
    }
    if (state.state === 0 || state.state === 3) {
      if (this.activeConnectionRejecter) {
        this.activeConnectionRejecter(new Error('BLE connection failed'));
        return;
      }
      if (this.activeConnectionDeviceId.length > 0) {
        this.disconnectListener('BLE 设备已断开');
      }
      this.cleanupActiveGattClient();
    }
  };

  private characteristicChangeCallback = (characteristic: ble.BLECharacteristic): void => {
    if (!this.isHeartRateCharacteristic(characteristic.characteristicUuid)) {
      return;
    }
    const data = new Uint8Array(characteristic.characteristicValue);
    const measurement = HeartRateParser.parse(data);
    if (measurement.bpm > 0) {
      this.measurementListener(measurement);
    }
  };

  private async stopActiveGattClient(): Promise<void> {
    if (this.activeGattClient === undefined) {
      return;
    }
    if (this.activeHeartRateCharacteristic !== undefined) {
      try {
        await this.activeGattClient.setCharacteristicChangeNotification(this.activeHeartRateCharacteristic, false);
      } catch (_error) {
      }
    }
    try {
      this.activeGattClient.off('BLECharacteristicChange', this.characteristicChangeCallback);
    } catch (_error) {
    }
    try {
      this.activeGattClient.off('BLEConnectionStateChange', this.connectionStateCallback);
    } catch (_error) {
    }
    try {
      this.activeGattClient.disconnect();
    } catch (_error) {
    }
    try {
      this.activeGattClient.close();
    } catch (_error) {
    }
    this.cleanupActiveGattClient();
  }

  private cleanupActiveGattClient(): void {
    this.activeGattClient = undefined;
    this.activeConnectionDeviceId = '';
    this.activeHeartRateCharacteristic = undefined;
    this.activeConnectionResolver = undefined;
    this.activeConnectionRejecter = undefined;
  }

  private startClassicDiscovery(): void {
    try {
      connection.on('discoveryResult', this.discoveryCallback);
    } catch (_error) {
    }
    try {
      connection.on('bluetoothDeviceFind', this.bluetoothDeviceFindCallback);
    } catch (_error) {
    }
    this.restartClassicDiscovery();
  }

  private restartClassicDiscovery(): void {
    try {
      if (connection.isBluetoothDiscovering()) {
        return;
      }
    } catch (_error) {
    }
    try {
      connection.startBluetoothDiscovery();
      this.classicScanning = true;
    } catch (_error) {
    }
  }

  private addPairedDevices(notify: boolean = true): void {
    try {
      const pairedDeviceIds = connection.getPairedDevices();
      pairedDeviceIds.forEach((deviceId: string) => {
        const deviceName = this.readSystemDeviceName(deviceId);
        const deviceKind = this.resolveDeviceKind(deviceId);
        this.addOrUpdateDevice({
          id: deviceId,
          name: deviceName.length > 0 ? deviceName : this.createClassicFallbackName(deviceId),
          rssi: -128,
          deviceKind: deviceKind
        }, deviceKind === 'watch' || deviceKind === 'band' || this.isLikelySupportedWearable(deviceName));
      });
    } catch (_error) {
    }
    if (notify && this.devices.length > 0) {
      this.deviceListener(this.devices.slice());
    }
  }

  private addConnectedDevices(notify: boolean = true): void {
    const connectedDeviceIds = ble.getConnectedBLEDevices();
    connectedDeviceIds.forEach((deviceId: string) => {
      const deviceName = this.readKnownDeviceName(deviceId);
      const deviceKind = this.resolveDeviceKind(deviceId);
      this.addOrUpdateDevice({
        id: deviceId,
        name: deviceName.length > 0 ? deviceName : this.createClassicFallbackName(deviceId),
        rssi: -127,
        deviceKind: deviceKind
      }, deviceKind === 'watch' || deviceKind === 'band' || this.isLikelySupportedWearable(deviceName));
      this.refreshDeviceName(deviceId);
    });
    if (notify && this.devices.length > 0) {
      this.deviceListener(this.devices.slice());
    }
  }

  private addOrUpdateDevice(device: HeartRateDevice, allowFallbackName: boolean = false): void {
    const index = this.devices.findIndex((item: HeartRateDevice) => item.id === device.id);
    if (index >= 0) {
      const current = this.devices[index];
      this.devices[index] = {
        id: device.id,
        name: this.chooseBestName(device.id, current.name, device.name),
        rssi: device.rssi,
        deviceKind: this.chooseBestDeviceKind(current.deviceKind, device.deviceKind)
      };
      return;
    }
    if (!this.isResolvedName(device.id, device.name) && !allowFallbackName) {
      return;
    }
    this.devices.push({
      id: device.id,
      name: this.safeDisplayName(device),
      rssi: device.rssi,
      deviceKind: device.deviceKind
    });
  }

  private resolveDeviceName(result: ble.ScanResult): string {
    const knownName = this.readKnownDeviceName(result.deviceId);
    if (knownName.length > 0) {
      return knownName;
    }
    const systemName = this.readSystemDeviceName(result.deviceId);
    if (systemName.length > 0) {
      return systemName;
    }
    const scanResultName = this.cleanDeviceName(result.deviceName);
    if (scanResultName.length > 0) {
      return scanResultName;
    }
    const advertisedName = this.readAdvertisedName(result.data);
    if (advertisedName.length > 0) {
      return advertisedName;
    }
    return '';
  }

  private async refreshDeviceName(deviceId: string): Promise<void> {
    if (this.resolvingDeviceNames.has(deviceId)) {
      return;
    }
    this.resolvingDeviceNames.add(deviceId);
    let deviceName = this.readKnownDeviceName(deviceId);
    try {
      if (deviceName.length === 0) {
        deviceName = await this.readGattDeviceName(deviceId);
      }
      if (deviceName.length === 0) {
        return;
      }

      this.deviceNames.set(deviceId, deviceName);
      const index = this.devices.findIndex((item: HeartRateDevice) => item.id === deviceId);
      if (index < 0) {
        this.addOrUpdateDevice({
          id: deviceId,
          name: deviceName,
          rssi: -127,
          deviceKind: this.resolveBleDeviceKind(deviceId, deviceName)
        }, this.isLikelySupportedWearable(deviceName));
        this.deviceListener(this.devices.slice());
        return;
      }

      const current = this.devices[index];
      const nextName = this.chooseBestName(deviceId, current.name, deviceName);
      if (nextName === current.name) {
        return;
      }

      this.devices[index] = {
        id: current.id,
        name: nextName,
        rssi: current.rssi,
        deviceKind: current.deviceKind
      };
      this.deviceListener(this.devices.slice());
    } finally {
      this.resolvingDeviceNames.delete(deviceId);
    }
  }

  private async readGattDeviceName(deviceId: string): Promise<string> {
    let client: ble.GattClientDevice | undefined = undefined;
    try {
      client = ble.createGattClientDevice(deviceId);
      const deviceName = await client.getDeviceName();
      return this.cleanDeviceName(deviceName);
    } catch (_error) {
      return '';
    } finally {
      if (client !== undefined) {
        try {
          client.close();
        } catch (_closeError) {
        }
      }
    }
  }

  private readKnownDeviceName(deviceId: string): string {
    const cachedName = this.deviceNames.get(deviceId);
    if (cachedName !== undefined && cachedName.length > 0) {
      return cachedName;
    }

    const systemName = this.readSystemDeviceName(deviceId);
    if (systemName.length > 0) {
      this.deviceNames.set(deviceId, systemName);
      return systemName;
    }

    const pairedName = this.readPairedDeviceName(deviceId);
    if (pairedName.length > 0) {
      this.deviceNames.set(deviceId, pairedName);
      return pairedName;
    }

    return '';
  }

  private readPairedDeviceName(deviceId: string): string {
    try {
      const pairedDeviceIds = connection.getPairedDevices();
      const exactIndex = pairedDeviceIds.findIndex((pairedDeviceId: string) => pairedDeviceId === deviceId);
      if (exactIndex >= 0) {
        return this.readSystemDeviceName(pairedDeviceIds[exactIndex]);
      }

      const suffix = this.deviceSuffix(deviceId);
      let matchedName = '';
      let matchedCount = 0;
      pairedDeviceIds.forEach((pairedDeviceId: string) => {
        if (this.deviceSuffix(pairedDeviceId) === suffix) {
          const name = this.readSystemDeviceName(pairedDeviceId);
          if (name.length > 0) {
            matchedName = name;
            matchedCount++;
          }
        }
      });
      return matchedCount === 1 ? matchedName : '';
    } catch (_error) {
      return '';
    }
  }

  private readSystemDeviceName(deviceId: string): string {
    try {
      // On API 16+, the default result is the same alias used by system Bluetooth settings.
      const systemName = this.cleanDeviceName(connection.getRemoteDeviceName(deviceId, true));
      if (systemName.length > 0) {
        return systemName;
      }
    } catch (_error) {
    }
    try {
      const systemName = this.cleanDeviceName(connection.getRemoteDeviceName(deviceId, false));
      if (systemName.length > 0) {
        return systemName;
      }
    } catch (_error) {
    }
    try {
      const systemName = this.cleanDeviceName(connection.getRemoteDeviceName(deviceId));
      if (systemName.length > 0) {
        return systemName;
      }
    } catch (_error) {
    }
    return '';
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
          const name = this.decodeDeviceName(nameBytes);
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

  private decodeDeviceName(nameBytes: Uint8Array): string {
    const encodings: Array<string> = ['utf-8', 'utf-16le', 'gb18030', 'gbk'];
    let fallbackName = '';
    for (let index = 0; index < encodings.length; index++) {
      const decodedName = this.decodeDeviceNameWithEncoding(nameBytes, encodings[index]);
      if (decodedName.length === 0) {
        continue;
      }
      if (this.containsChinese(decodedName)) {
        return decodedName;
      }
      if (fallbackName.length === 0 && this.isReadableName(decodedName)) {
        fallbackName = decodedName;
      }
    }
    return fallbackName;
  }

  private decodeDeviceNameWithEncoding(nameBytes: Uint8Array, encoding: string): string {
    try {
      const decodedName = util.TextDecoder.create(encoding, { fatal: true }).decodeToString(nameBytes);
      return this.cleanDeviceName(decodedName);
    } catch (_error) {
      return '';
    }
  }

  private createFallbackName(deviceId: string): string {
    return 'BLE 设备 ' + this.deviceSuffix(deviceId);
  }

  private createHeartRateFallbackName(deviceId: string): string {
    return '心率设备 ' + this.deviceSuffix(deviceId);
  }

  private createClassicFallbackName(deviceId: string, deviceClass?: connection.DeviceClass): string {
    let currentDeviceClass: connection.DeviceClass | undefined = deviceClass;
    if (currentDeviceClass === undefined) {
      currentDeviceClass = this.readDeviceClass(deviceId);
    }
    if (currentDeviceClass === undefined) {
      return '';
    }

    const prefix = this.classicFallbackPrefix(currentDeviceClass);
    if (prefix.length === 0) {
      return '';
    }
    return prefix + ' ' + this.deviceSuffix(deviceId);
  }

  private chooseBestName(deviceId: string, currentName: string, nextName: string): string {
    const cleanNextName = this.cleanDeviceName(nextName);
    if (cleanNextName.length === 0) {
      return currentName;
    }
    if (currentName.length === 0 || this.isFallbackName(deviceId, currentName)) {
      return cleanNextName;
    }
    return currentName;
  }

  private chooseBestDeviceKind(currentKind?: string, nextKind?: string): string {
    if (currentKind === 'heart-rate' || nextKind === 'heart-rate') {
      return 'heart-rate';
    }
    if (currentKind === 'band' || nextKind === 'band') {
      return 'band';
    }
    if (nextKind !== undefined && nextKind.length > 0 && nextKind !== 'ble') {
      return nextKind;
    }
    if (currentKind !== undefined && currentKind.length > 0) {
      return currentKind;
    }
    return nextKind !== undefined && nextKind.length > 0 ? nextKind : 'ble';
  }

  private cleanDeviceName(deviceName: string): string {
    if (deviceName === null || deviceName === undefined) {
      return '';
    }
    let cleanName = '';
    for (let index = 0; index < deviceName.length; index++) {
      const code = deviceName.charCodeAt(index);
      if (code === 0 || code === 0xFFFD || (code < 0x20 && code !== 0x09)) {
        continue;
      }
      cleanName += deviceName.charAt(index);
    }
    return cleanName.trim();
  }

  private isFallbackName(deviceId: string, deviceName: string): boolean {
    const suffix = this.deviceSuffix(deviceId);
    return deviceName === this.createFallbackName(deviceId) || deviceName === this.createHeartRateFallbackName(deviceId) ||
      deviceName === '手机设备 ' + suffix || deviceName === '平板设备 ' + suffix || deviceName === '运动手表 ' + suffix;
  }

  private readDeviceClass(deviceId: string): connection.DeviceClass | undefined {
    try {
      return connection.getRemoteDeviceClass(deviceId);
    } catch (_error) {
      return undefined;
    }
  }

  private classicFallbackPrefix(deviceClass: connection.DeviceClass): string {
    const deviceKind = this.classicDeviceKind(deviceClass);
    if (deviceKind === 'phone') {
      return '手机设备';
    }
    if (deviceKind === 'tablet') {
      return '平板设备';
    }
    if (deviceKind === 'watch') {
      return '运动手表';
    }
    return '';
  }

  private resolveDeviceKind(deviceId: string, deviceClass?: connection.DeviceClass): string {
    let currentDeviceClass: connection.DeviceClass | undefined = deviceClass;
    if (currentDeviceClass === undefined) {
      currentDeviceClass = this.readDeviceClass(deviceId);
    }
    if (currentDeviceClass === undefined) {
      return 'ble';
    }
    const deviceKind = this.classicDeviceKind(currentDeviceClass);
    return deviceKind.length > 0 ? deviceKind : 'classic';
  }

  private resolveBleDeviceKind(deviceId: string, deviceName: string): string {
    const kindByName = this.deviceKindByName(deviceName);
    if (kindByName.length > 0) {
      return kindByName;
    }
    return this.resolveDeviceKind(deviceId);
  }

  private deviceKindByName(deviceName: string): string {
    const name = this.cleanDeviceName(deviceName).toLowerCase();
    if (name.length === 0) {
      return '';
    }
    if (name.includes('heart') || name.includes('hrm') || name.includes('h10') || name.includes('h9') ||
      name.includes('h7') || name.includes('oh1') || name.includes('verity') || name.includes('coospo') ||
      name.includes('magene') || name.includes('wahoo') || name.includes('tickr') || name.includes('polar') ||
      name.includes('garmin hrm')) {
      return 'heart-rate';
    }
    if (name.includes('band') || name.includes('手环') || name.includes('mi smart') || name.includes('mi band') ||
      name.includes('huawei band') || name.includes('honor band') || name.includes('amazfit band')) {
      return 'band';
    }
    if (name.includes('watch') || name.includes('手表') || name.includes('amazfit') || name.includes('zepp') ||
      name.includes('garmin') || name.includes('coros') || name.includes('suunto') || name.includes('fitbit') ||
      name.includes('galaxy watch') || name.includes('huawei watch') || name.includes('honor watch') ||
      name.includes('oppo watch') || name.includes('realme watch')) {
      return 'watch';
    }
    return '';
  }

  private isLikelySupportedWearable(deviceName: string): boolean {
    return this.deviceKindByName(deviceName).length > 0;
  }

  private safeDisplayName(device: HeartRateDevice): string {
    const cleanName = this.cleanDeviceName(device.name);
    if (cleanName.length > 0) {
      return cleanName;
    }
    if (device.deviceKind === 'heart-rate') {
      return this.createHeartRateFallbackName(device.id);
    }
    if (device.deviceKind === 'band') {
      return '运动手环 ' + this.deviceSuffix(device.id);
    }
    if (device.deviceKind === 'watch') {
      return '运动手表 ' + this.deviceSuffix(device.id);
    }
    return this.createFallbackName(device.id);
  }

  private classicDeviceKind(deviceClass: connection.DeviceClass): string {
    const majorClass = Number(deviceClass.majorClass);
    const classOfDevice = Number(deviceClass.classOfDevice) & 0x1F00;
    if (majorClass === HarmonyBleHeartRateAdapter.MAJOR_PHONE ||
      classOfDevice === HarmonyBleHeartRateAdapter.MAJOR_PHONE) {
      return 'phone';
    }
    if (majorClass === HarmonyBleHeartRateAdapter.MAJOR_COMPUTER ||
      classOfDevice === HarmonyBleHeartRateAdapter.MAJOR_COMPUTER) {
      return 'tablet';
    }
    if (majorClass === HarmonyBleHeartRateAdapter.MAJOR_WEARABLE ||
      majorClass === HarmonyBleHeartRateAdapter.MAJOR_HEALTH ||
      classOfDevice === HarmonyBleHeartRateAdapter.MAJOR_WEARABLE ||
      classOfDevice === HarmonyBleHeartRateAdapter.MAJOR_HEALTH) {
      return 'watch';
    }
    return '';
  }

  private isResolvedName(deviceId: string, deviceName: string): boolean {
    const cleanName = this.cleanDeviceName(deviceName);
    return cleanName.length > 0 && cleanName !== this.createFallbackName(deviceId) && this.isReadableName(cleanName);
  }

  private advertisesHeartRateService(data: ArrayBuffer): boolean {
    const bytes = new Uint8Array(data);
    let offset = 0;
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
      if ((fieldType === 0x02 || fieldType === 0x03 || fieldType === 0x16) &&
        this.contains16BitHeartRateUuid(bytes, offset + 2, fieldEnd)) {
        return true;
      }
      if ((fieldType === 0x06 || fieldType === 0x07 || fieldType === 0x21) &&
        this.contains128BitHeartRateUuid(bytes, offset + 2, fieldEnd)) {
        return true;
      }
      offset = fieldEnd;
    }
    return false;
  }

  private contains16BitHeartRateUuid(bytes: Uint8Array, start: number, end: number): boolean {
    let index = start;
    while (index + 1 < end) {
      const uuid = this.toHexByte(bytes[index]) + this.toHexByte(bytes[index + 1]);
      if (uuid === HarmonyBleHeartRateAdapter.HEART_RATE_SERVICE_UUID_REVERSED) {
        return true;
      }
      index += 2;
    }
    return false;
  }

  private contains128BitHeartRateUuid(bytes: Uint8Array, start: number, end: number): boolean {
    let index = start;
    while (index + 15 < end) {
      let uuid = '';
      for (let byteIndex = index + 15; byteIndex >= index; byteIndex--) {
        uuid += this.toHexByte(bytes[byteIndex]);
      }
      if (uuid.substring(4, 8) === HarmonyBleHeartRateAdapter.HEART_RATE_SERVICE_UUID) {
        return true;
      }
      index += 16;
    }
    return false;
  }

  private toHexByte(value: number): string {
    const hex = value.toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  }

  private containsChinese(deviceName: string): boolean {
    for (let index = 0; index < deviceName.length; index++) {
      const code = deviceName.charCodeAt(index);
      if (code >= 0x4E00 && code <= 0x9FFF) {
        return true;
      }
    }
    return false;
  }

  private isReadableName(deviceName: string): boolean {
    if (deviceName.length === 0) {
      return false;
    }
    let readableCount = 0;
    for (let index = 0; index < deviceName.length; index++) {
      const code = deviceName.charCodeAt(index);
      if ((code >= 0x20 && code <= 0x7E) || (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3000 && code <= 0x9FFF) || (code >= 0xFF00 && code <= 0xFFEF)) {
        readableCount++;
      }
    }
    return readableCount === deviceName.length;
  }

  private deviceSuffix(deviceId: string): string {
    const suffixStart = Math.max(0, deviceId.length - 5);
    return deviceId.substring(suffixStart);
  }

  private async findHeartRateMeasurementCharacteristic(
    client: ble.GattClientDevice
  ): Promise<ble.BLECharacteristic | undefined> {
    try {
      const services = await client.getServices();
      return this.findHeartRateCharacteristic(services);
    } catch (_error) {
      return undefined;
    }
  }

  private findHeartRateCharacteristic(services: Array<ble.GattService>): ble.BLECharacteristic | undefined {
    for (let index = 0; index < services.length; index++) {
      const service = services[index];
      if (this.isHeartRateService(service.serviceUuid)) {
        const characteristic = this.findHeartRateMeasurementCharacteristicInService(service);
        if (characteristic !== undefined) {
          return characteristic;
        }
      }
      if (service.includeServices !== undefined) {
        const characteristic = this.findHeartRateCharacteristic(service.includeServices);
        if (characteristic !== undefined) {
          return characteristic;
        }
      }
    }
    return undefined;
  }

  private findHeartRateMeasurementCharacteristicInService(service: ble.GattService): ble.BLECharacteristic | undefined {
    for (let index = 0; index < service.characteristics.length; index++) {
      const characteristic = service.characteristics[index];
      if (this.isHeartRateCharacteristic(characteristic.characteristicUuid)) {
        return characteristic;
      }
    }
    return undefined;
  }

  private isHeartRateService(uuid: string): boolean {
    const normalizedUuid = this.normalizeUuid(uuid);
    return normalizedUuid === HarmonyBleHeartRateAdapter.HEART_RATE_SERVICE_UUID ||
      normalizedUuid.substring(4, 8) === HarmonyBleHeartRateAdapter.HEART_RATE_SERVICE_UUID;
  }

  private isHeartRateCharacteristic(uuid: string): boolean {
    const normalizedUuid = this.normalizeUuid(uuid);
    return normalizedUuid === HarmonyBleHeartRateAdapter.HEART_RATE_MEASUREMENT_UUID ||
      normalizedUuid.substring(4, 8) === HarmonyBleHeartRateAdapter.HEART_RATE_MEASUREMENT_UUID;
  }

  private normalizeUuid(uuid: string): string {
    return this.cleanDeviceName(uuid).toLowerCase().split('-').join('');
  }
}
