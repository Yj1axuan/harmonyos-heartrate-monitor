import { FavoriteDevice } from '../../application/model/HistoryUiModels';
import { SettingsUiState } from '../../application/state/SettingsUiState';

export interface AppPreferencesPort {
  loadSettings(): Promise<SettingsUiState>;
  saveSettings(settings: SettingsUiState): Promise<void>;
  listFavoriteDevices(): Promise<FavoriteDevice[]>;
  saveFavoriteDevices(devices: FavoriteDevice[]): Promise<void>;
}
