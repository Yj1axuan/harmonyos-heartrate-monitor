import { HeartRateMeasurement } from '../model/HeartRateMeasurement';

export interface HeartRateDevice {
  id: string;
  name: string;
  rssi: number;
  deviceKind?: string;
}

export type DeviceListener = (devices: HeartRateDevice[]) => void;
export type MeasurementListener = (measurement: HeartRateMeasurement) => void;
export type DisconnectListener = (reason: string) => void;

export interface BleHeartRatePort {
  getKnownDevices(): Promise<HeartRateDevice[]>;
  startScan(listener: DeviceListener): Promise<void>;
  stopScan(): Promise<void>;
  connect(deviceId: string): Promise<void>;
  disconnect(): Promise<void>;
  setMeasurementListener(listener: MeasurementListener): void;
  setDisconnectListener(listener: DisconnectListener): void;
}

