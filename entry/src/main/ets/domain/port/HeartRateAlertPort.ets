import { Context } from '@kit.AbilityKit';
import { SettingsUiState } from '../../application/state/SettingsUiState';

export enum HeartRateAlertType {
  None = 'none',
  Low = 'low',
  High = 'high'
}

export interface HeartRateAlertEvent {
  type: HeartRateAlertType;
  bpm: number;
  threshold: number;
  durationSeconds: number;
  deviceName: string;
  occurredAt: number;
}

export interface HeartRateBackgroundMonitorPort {
  requestNotificationPermission(context: Context): Promise<void>;
  startBackgroundMonitoring(context: Context): Promise<void>;
  stopBackgroundMonitoring(context: Context): Promise<void>;
  publishAlert(event: HeartRateAlertEvent, settings: SettingsUiState): Promise<void>;
}
