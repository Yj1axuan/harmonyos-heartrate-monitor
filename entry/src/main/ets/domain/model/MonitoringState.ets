export enum MonitoringState {
  Idle = 'idle',
  Scanning = 'scanning',
  Connecting = 'connecting',
  Connected = 'connected',
  Reconnecting = 'reconnecting',
  Failed = 'failed'
}

export interface HeartRateSnapshot {
  state: MonitoringState;
  bpm: number;
  deviceId: string;
  deviceName: string;
  updatedAt: number;
}

