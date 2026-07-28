export interface BluetoothPermissionPort {
  ensureGranted(): Promise<boolean>;
}
