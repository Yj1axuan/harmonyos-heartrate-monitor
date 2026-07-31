import { SettingsUiState } from '../state/SettingsUiState';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';

export class SettingsViewModel {
  readonly state: SettingsUiState = new SettingsUiState();
  private preferencesPort: AppPreferencesPort | undefined = undefined;
  private onSettingsChanged: (settings: SettingsUiState) => void = (_settings: SettingsUiState) => {};

  constructor(preferencesPort?: AppPreferencesPort, onSettingsChanged?: (settings: SettingsUiState) => void) {
    this.preferencesPort = preferencesPort;
    if (onSettingsChanged !== undefined) {
      this.onSettingsChanged = onSettingsChanged;
    }
  }

  async load(): Promise<void> {
    if (this.preferencesPort === undefined) {
      return;
    }
    const settings = await this.preferencesPort.loadSettings();
    this.state.themeSource = settings.themeSource;
    this.state.themeMode = settings.themeMode;
    this.state.themeColor = settings.themeColor;
    this.state.themeStyle = settings.themeStyle;
    this.state.recordHistory = settings.recordHistory;
    this.state.heartbeatAnimation = settings.heartbeatAnimation;
    this.state.displaySpeed = settings.displaySpeed;
    this.state.hideFromRecents = settings.hideFromRecents;
    this.state.autoConnect = settings.autoConnect;
    this.state.autoReconnect = settings.autoReconnect;
    this.state.backgroundMonitoring = settings.backgroundMonitoring;
    this.state.heartRateAlert = settings.heartRateAlert;
    this.state.lowBpmThreshold = settings.lowBpmThreshold;
    this.state.highBpmThreshold = settings.highBpmThreshold;
    this.state.alertDurationSeconds = settings.alertDurationSeconds;
    this.state.alertNotification = settings.alertNotification;
    this.state.alertVibration = settings.alertVibration;
    this.state.alertSound = settings.alertSound;
    this.state.fullscreenSoundMode = settings.fullscreenSoundMode;
    this.state.fullscreenDisplayColor = settings.fullscreenDisplayColor;
    this.onSettingsChanged(this.state);
  }

  setThemeSource(value: 'system' | 'custom'): void {
    this.state.themeSource = value;
    this.save();
  }

  setThemeMode(value: 'system' | 'light' | 'dark'): void {
    this.state.themeMode = value;
    this.save();
  }

  setThemeColor(value: string): void {
    this.state.themeColor = value;
    this.save();
  }

  setThemeStyle(value: 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit'): void {
    this.state.themeStyle = value;
    this.save();
  }

  setRecordHistory(value: boolean): void {
    this.state.recordHistory = value;
    this.save();
  }

  setHeartbeatAnimation(value: boolean): void {
    this.state.heartbeatAnimation = value;
    this.save();
  }

  setDisplaySpeed(value: boolean): void {
    this.state.displaySpeed = value;
    this.save();
  }

  setHideFromRecents(value: boolean): void {
    this.state.hideFromRecents = value;
    this.save();
  }

  setAutoConnect(value: boolean): void {
    this.state.autoConnect = value;
    this.save();
  }

  setAutoReconnect(value: boolean): void {
    this.state.autoReconnect = value;
    this.save();
  }

  setBackgroundMonitoring(value: boolean): void {
    this.state.backgroundMonitoring = value;
    this.save();
  }

  setHeartRateAlert(value: boolean): void {
    this.state.heartRateAlert = value;
    this.save();
  }

  setLowBpmThreshold(value: number): void {
    this.state.lowBpmThreshold = Math.max(30, Math.min(value, this.state.highBpmThreshold - 1));
    this.save();
  }

  setHighBpmThreshold(value: number): void {
    this.state.highBpmThreshold = Math.min(240, Math.max(value, this.state.lowBpmThreshold + 1));
    this.save();
  }

  setAlertDurationSeconds(value: number): void {
    this.state.alertDurationSeconds = Math.max(3, Math.min(value, 300));
    this.save();
  }

  setAlertNotification(value: boolean): void {
    this.state.alertNotification = value;
    this.save();
  }

  setAlertVibration(value: boolean): void {
    this.state.alertVibration = value;
    this.save();
  }

  setAlertSound(value: boolean): void {
    this.state.alertSound = value;
    this.save();
  }

  setFullscreenSoundMode(value: string): void {
    this.state.fullscreenSoundMode = value;
    this.save();
  }

  setFullscreenDisplayColor(value: string): void {
    if (value === 'red' || value === 'green' || value === 'cyan' || value === 'yellow' || value === 'purple' || value === 'white') {
      this.state.fullscreenDisplayColor = value;
    } else {
      this.state.fullscreenDisplayColor = 'red';
    }
    this.save();
  }

  private save(): void {
    if (this.preferencesPort !== undefined) {
      void this.preferencesPort.saveSettings(this.state);
    }
    this.onSettingsChanged(this.state);
  }
}
