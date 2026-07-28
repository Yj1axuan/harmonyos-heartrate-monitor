import { SettingsUiState } from '../state/SettingsUiState';

export class SettingsViewModel {
  readonly state: SettingsUiState = new SettingsUiState();

  setRecordHistory(value: boolean): void {
    this.state.recordHistory = value;
  }

  setHeartbeatAnimation(value: boolean): void {
    this.state.heartbeatAnimation = value;
  }

  setDisplaySpeed(value: boolean): void {
    this.state.displaySpeed = value;
  }

  setHideFromRecents(value: boolean): void {
    this.state.hideFromRecents = value;
  }

  setAutoConnect(value: boolean): void {
    this.state.autoConnect = value;
  }

  setAutoReconnect(value: boolean): void {
    this.state.autoReconnect = value;
  }
}
