export interface MonitoringTaskPort {
  startBluetoothMonitoring(): Promise<void>;
  stopBluetoothMonitoring(): Promise<void>;
  isRunning(): boolean;
}

