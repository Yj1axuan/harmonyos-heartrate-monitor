import { SettingsUiState } from '../state/SettingsUiState';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';

export class SettingsViewModel {
  readonly state: SettingsUiState = new SettingsUiState();
  private static readonly SPEED_DISPLAY_AVAILABLE: boolean = false;
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
    this.applyLoadedSettings(settings);
    this.onSettingsChanged(this.state);
  }

  setThemeSource(value: 'system' | 'custom'): void {
    this.updateState(() => {
      this.state.themeSource = value;
    });
  }

  setThemeMode(value: 'system' | 'light' | 'dark'): void {
    this.updateState(() => {
      this.state.themeMode = value;
    });
  }

  setThemeColor(value: string): void {
    this.updateState(() => {
      this.state.themeColor = value;
    });
  }

  setThemeStyle(value: 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit'): void {
    this.updateState(() => {
      this.state.themeStyle = value;
    });
  }

  setRecordHistory(value: boolean): void {
    this.updateState(() => {
      this.state.recordHistory = value;
    });
  }

  setHeartbeatAnimation(value: boolean): void {
    this.updateState(() => {
      this.state.heartbeatAnimation = value;
    });
  }

  setDisplaySpeed(value: boolean): void {
    this.updateState(() => {
      this.state.displaySpeed = SettingsViewModel.SPEED_DISPLAY_AVAILABLE && value;
    });
  }

  setHideFromRecents(value: boolean): void {
    this.updateState(() => {
      this.state.hideFromRecents = value;
    });
  }

  setAutoConnect(value: boolean): void {
    this.updateState(() => {
      this.state.autoConnect = value;
    });
  }

  setAutoReconnect(value: boolean): void {
    this.updateState(() => {
      this.state.autoReconnect = value;
    });
  }

  setBackgroundMonitoring(value: boolean): void {
    this.updateState(() => {
      this.state.backgroundMonitoring = value;
    });
  }

  setHeartRateAlert(value: boolean): void {
    this.updateState(() => {
      this.state.heartRateAlert = value;
    });
  }

  setLowBpmThreshold(value: number): void {
    this.updateState(() => {
      this.state.lowBpmThreshold = Math.max(30, Math.min(value, this.state.highBpmThreshold - 1));
    });
  }

  setHighBpmThreshold(value: number): void {
    this.updateState(() => {
      this.state.highBpmThreshold = Math.min(240, Math.max(value, this.state.lowBpmThreshold + 1));
    });
  }

  setAlertDurationSeconds(value: number): void {
    this.updateState(() => {
      this.state.alertDurationSeconds = Math.max(3, Math.min(value, 300));
    });
  }

  setAlertNotification(value: boolean): void {
    this.updateState(() => {
      this.state.alertNotification = value;
    });
  }

  setAlertVibration(value: boolean): void {
    this.updateState(() => {
      this.state.alertVibration = value;
    });
  }

  setAlertSound(value: boolean): void {
    this.updateState(() => {
      this.state.alertSound = value;
    });
  }

  setFullscreenSoundMode(value: string): void {
    this.updateState(() => {
      this.state.fullscreenSoundMode = value;
    });
  }

  setFullscreenDisplayColor(value: string): void {
    this.updateState(() => {
      if (value === 'red' || value === 'green' || value === 'cyan' || value === 'yellow' || value === 'purple' || value === 'white') {
        this.state.fullscreenDisplayColor = value;
      } else {
        this.state.fullscreenDisplayColor = 'red';
      }
    });
  }

  private save(): void {
    if (this.preferencesPort !== undefined) {
      void this.preferencesPort.saveSettings(this.state);
    }
    this.onSettingsChanged(this.state);
  }

  private applyLoadedSettings(settings: SettingsUiState): void {
    this.state.themeSource = settings.themeSource;
    this.state.themeMode = settings.themeMode;
    this.state.themeColor = settings.themeColor;
    this.state.themeStyle = settings.themeStyle;
    this.state.recordHistory = settings.recordHistory;
    this.state.heartbeatAnimation = settings.heartbeatAnimation;
    this.state.displaySpeed = SettingsViewModel.SPEED_DISPLAY_AVAILABLE && settings.displaySpeed;
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
  }

  private updateState(update: () => void): void {
    update();
    this.save();
  }
}
