import { HeartRateParser } from '../../domain/HeartRateParser';
import {
  BleHeartRatePort,
  DeviceListener,
  DisconnectListener,
  HeartRateDevice,
  MeasurementListener
} from '../../domain/port/BleHeartRatePort';
import { HeartRateMeasurement } from '../../domain/model/HeartRateMeasurement';

type MockDeviceScenario = 'normal' | 'unstable' | 'timeout' | 'unsupported';

interface MockDeviceProfile {
  id: string;
  name: string;
  rssi: number;
  deviceKind: string;
  scenario: MockDeviceScenario;
}

export class MockBleHeartRateAdapter implements BleHeartRatePort {
  private static readonly SCAN_EMIT_DELAY_MS: number = 220;
  private static readonly MEASUREMENT_INTERVAL_MS: number = 1200;
  private static readonly UNSTABLE_DISCONNECT_MS: number = 14000;
  private static readonly RECONNECT_GRACE_MS: number = 2500;
  private static readonly CONNECTION_TIMEOUT_MS: number = 3500;

  private readonly profiles: MockDeviceProfile[] = [
    { id: 'MOCK-HEART-STRAP-001', name: '模拟心率胸带', rssi: -44, deviceKind: 'ble', scenario: 'normal' },
    { id: 'MOCK-SPORT-WATCH-002', name: '模拟运动手表', rssi: -52, deviceKind: 'watch', scenario: 'unstable' },
    { id: 'MOCK-TIMEOUT-BAND-003', name: '模拟超时设备', rssi: -66, deviceKind: 'ble', scenario: 'timeout' },
    { id: 'MOCK-LEGACY-SPEAKER-004', name: '模拟不支持心率设备', rssi: -71, deviceKind: 'classic', scenario: 'unsupported' }
  ];

  private devices: HeartRateDevice[] = [];
  private deviceListener: DeviceListener = (_devices: HeartRateDevice[]) => {};
  private measurementListener: MeasurementListener = (_measurement) => {};
  private disconnectListener: DisconnectListener = (_reason: string) => {};
  private scanning: boolean = false;
  private scanTimers: number[] = [];
  private connectedProfile: MockDeviceProfile | undefined = undefined;
  private measurementTimer: number | undefined = undefined;
  private disconnectTimer: number | undefined = undefined;
  private reconnectReadyTimer: number | undefined = undefined;
  private tickCount: number = 0;
  private allowReconnect: boolean = true;

  async getKnownDevices(): Promise<HeartRateDevice[]> {
    return this.profiles.map((profile: MockDeviceProfile) => this.profileToDevice(profile));
  }

  async startScan(listener: DeviceListener): Promise<void> {
    this.deviceListener = listener;
    this.scanning = true;
    this.devices = [];
    this.clearScanTimers();
    this.profiles.forEach((profile: MockDeviceProfile, index: number) => {
      const timer = setTimeout(() => {
        if (!this.scanning) {
          return;
        }
        this.addOrUpdateDevice(this.profileToDevice(profile));
        this.deviceListener(this.devices.slice());
      }, MockBleHeartRateAdapter.SCAN_EMIT_DELAY_MS * (index + 1)) as number;
      this.scanTimers.push(timer);
    });
    this.deviceListener(this.devices.slice());
  }

  async stopScan(): Promise<void> {
    this.scanning = false;
    this.clearScanTimers();
  }

  async connect(deviceId: string): Promise<void> {
    const profile = this.profileById(deviceId);
    if (profile === undefined) {
      throw new Error('未找到模拟设备');
    }

    this.stopMeasurementLoop();
    this.stopDisconnectTimer();
    this.connectedProfile = profile;
    this.allowReconnect = profile.scenario !== 'timeout';

    if (profile.scenario === 'timeout') {
      await this.delay(MockBleHeartRateAdapter.CONNECTION_TIMEOUT_MS);
      this.connectedProfile = undefined;
      throw new Error('BLE connection timeout');
    }

    if (profile.scenario === 'unsupported') {
      await this.delay(600);
      this.connectedProfile = undefined;
      throw new Error('设备不支持标准心率服务');
    }

    await this.delay(450);
    this.startMeasurementLoop();
    if (profile.scenario === 'unstable') {
      this.scheduleForcedDisconnect();
    }
  }

  async disconnect(): Promise<void> {
    this.allowReconnect = false;
    this.stopMeasurementLoop();
    this.stopDisconnectTimer();
    this.connectedProfile = undefined;
    this.clearReconnectReadyTimer();
  }

  setMeasurementListener(listener: MeasurementListener): void {
    this.measurementListener = listener;
  }

  setDisconnectListener(listener: DisconnectListener): void {
    this.disconnectListener = listener;
  }

  private startMeasurementLoop(): void {
    this.tickCount = 0;
    this.stopMeasurementLoop();
    this.measurementTimer = setInterval(() => {
      if (this.connectedProfile === undefined) {
        return;
      }
      const measurement = this.buildMeasurement();
      this.measurementListener(measurement);
      this.tickCount += 1;
    }, MockBleHeartRateAdapter.MEASUREMENT_INTERVAL_MS) as number;
    const initial = this.buildMeasurement();
    this.measurementListener(initial);
  }

  private stopMeasurementLoop(): void {
    if (this.measurementTimer !== undefined) {
      clearInterval(this.measurementTimer);
      this.measurementTimer = undefined;
    }
  }

  private scheduleForcedDisconnect(): void {
    this.stopDisconnectTimer();
    this.disconnectTimer = setTimeout(() => {
      if (this.connectedProfile === undefined) {
        return;
      }
      this.stopMeasurementLoop();
      this.connectedProfile = undefined;
      this.disconnectListener('模拟设备已断开');
      if (this.allowReconnect) {
        this.clearReconnectReadyTimer();
        this.reconnectReadyTimer = setTimeout(() => {
          this.reconnectReadyTimer = undefined;
        }, MockBleHeartRateAdapter.RECONNECT_GRACE_MS) as number;
      }
    }, MockBleHeartRateAdapter.UNSTABLE_DISCONNECT_MS) as number;
  }

  private stopDisconnectTimer(): void {
    if (this.disconnectTimer !== undefined) {
      clearTimeout(this.disconnectTimer);
      this.disconnectTimer = undefined;
    }
  }

  private clearReconnectReadyTimer(): void {
    if (this.reconnectReadyTimer !== undefined) {
      clearTimeout(this.reconnectReadyTimer);
      this.reconnectReadyTimer = undefined;
    }
  }

  private clearScanTimers(): void {
    this.scanTimers.forEach((timer: number) => {
      clearTimeout(timer);
    });
    this.scanTimers = [];
  }

  private profileById(deviceId: string): MockDeviceProfile | undefined {
    return this.profiles.find((profile: MockDeviceProfile) => profile.id === deviceId);
  }

  private profileToDevice(profile: MockDeviceProfile): HeartRateDevice {
    return {
      id: profile.id,
      name: profile.name,
      rssi: profile.rssi,
      deviceKind: profile.deviceKind
    };
  }

  private addOrUpdateDevice(device: HeartRateDevice): void {
    const index = this.devices.findIndex((item: HeartRateDevice) => item.id === device.id);
    if (index >= 0) {
      this.devices[index] = device;
      return;
    }
    this.devices.push(device);
  }

  private buildMeasurement(): HeartRateMeasurement {
    const bpm = this.randomBpm();
    const rr1 = Math.max(1, Math.round((60 / bpm) * 1024));
    const rr2 = Math.max(1, Math.round(rr1 * (0.96 + Math.random() * 0.08)));
    const use16Bit = this.tickCount % 3 === 2;
    const packet = this.buildHeartRatePacket(bpm, use16Bit, [rr1, rr2]);
    return HeartRateParser.parse(packet);
  }

  private buildHeartRatePacket(bpm: number, use16Bit: boolean, rrIntervals: number[]): Uint8Array {
    const flags = (use16Bit ? 0x01 : 0x00) | 0x04 | 0x10;
    const values: number[] = [flags];
    if (use16Bit) {
      values.push(bpm & 0xFF, (bpm >> 8) & 0xFF);
    } else {
      values.push(bpm & 0xFF);
    }
    rrIntervals.forEach((rr: number) => {
      values.push(rr & 0xFF, (rr >> 8) & 0xFF);
    });
    return new Uint8Array(values);
  }

  private randomBpm(): number {
    const base = 60 + Math.floor(Math.random() * 121);
    const swing = Math.floor(Math.sin(Date.now() / 900) * 8);
    return Math.max(60, Math.min(180, base + swing));
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
