@Observed
export class SettingsUiState {
  themeSource: 'system' | 'custom' = 'system';
  themeMode: 'system' | 'light' | 'dark' = 'system';
  themeColor: string = '#5269A8';
  themeStyle: 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit' = 'expressive';
  recordHistory: boolean = true;
  heartbeatAnimation: boolean = true;
  displaySpeed: boolean = false;
  hideFromRecents: boolean = false;
  autoConnect: boolean = false;
  autoReconnect: boolean = true;
  backgroundMonitoring: boolean = true;
  heartRateAlert: boolean = true;
  lowBpmThreshold: number = 50;
  highBpmThreshold: number = 160;
  alertDurationSeconds: number = 10;
  alertNotification: boolean = true;
  alertVibration: boolean = true;
  alertSound: boolean = true;
  fullscreenSoundMode: string = 'zh';
  fullscreenDisplayColor: string = 'red';
}
