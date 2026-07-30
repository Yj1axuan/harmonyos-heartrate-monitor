import preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';
import { FavoriteDevice } from '../../application/model/HistoryUiModels';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';

const PREF_NAME = 'heart_rate_preferences';
const KEY_THEME_SOURCE = 'themeSource';
const KEY_THEME_MODE = 'themeMode';
const KEY_THEME_COLOR = 'themeColor';
const KEY_THEME_STYLE = 'themeStyle';
const KEY_RECORD_HISTORY = 'recordHistory';
const KEY_HEARTBEAT_ANIMATION = 'heartbeatAnimation';
const KEY_DISPLAY_SPEED = 'displaySpeed';
const KEY_HIDE_FROM_RECENTS = 'hideFromRecents';
const KEY_AUTO_CONNECT = 'autoConnect';
const KEY_AUTO_RECONNECT = 'autoReconnect';
const KEY_BACKGROUND_MONITORING = 'backgroundMonitoring';
const KEY_HEART_RATE_ALERT = 'heartRateAlert';
const KEY_LOW_BPM_THRESHOLD = 'lowBpmThreshold';
const KEY_HIGH_BPM_THRESHOLD = 'highBpmThreshold';
const KEY_ALERT_DURATION_SECONDS = 'alertDurationSeconds';
const KEY_ALERT_NOTIFICATION = 'alertNotification';
const KEY_ALERT_VIBRATION = 'alertVibration';
const KEY_ALERT_SOUND = 'alertSound';
const KEY_FULLSCREEN_SOUND_MODE = 'fullscreenSoundMode';
const KEY_FULLSCREEN_DISPLAY_COLOR = 'fullscreenDisplayColor';
const KEY_FAVORITES = 'favoriteDevices';

export class HarmonyAppPreferencesAdapter implements AppPreferencesPort {
  private context: Context;
  private store: preferences.Preferences | undefined = undefined;

  constructor(context: Context) {
    this.context = context;
  }

  async loadSettings(): Promise<SettingsUiState> {
    const store = await this.preferencesStore();
    const state = new SettingsUiState();
    state.themeSource = String(await store.get(KEY_THEME_SOURCE, state.themeSource)) as 'system' | 'custom';
    state.themeMode = String(await store.get(KEY_THEME_MODE, state.themeMode)) as 'system' | 'light' | 'dark';
    state.themeColor = String(await store.get(KEY_THEME_COLOR, state.themeColor));
    state.themeStyle = String(await store.get(KEY_THEME_STYLE, state.themeStyle)) as
      'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit';
    state.recordHistory = Boolean(await store.get(KEY_RECORD_HISTORY, state.recordHistory));
    state.heartbeatAnimation = Boolean(await store.get(KEY_HEARTBEAT_ANIMATION, state.heartbeatAnimation));
    state.displaySpeed = Boolean(await store.get(KEY_DISPLAY_SPEED, state.displaySpeed));
    state.hideFromRecents = Boolean(await store.get(KEY_HIDE_FROM_RECENTS, state.hideFromRecents));
    state.autoConnect = Boolean(await store.get(KEY_AUTO_CONNECT, state.autoConnect));
    state.autoReconnect = Boolean(await store.get(KEY_AUTO_RECONNECT, state.autoReconnect));
    state.backgroundMonitoring = Boolean(await store.get(KEY_BACKGROUND_MONITORING, state.backgroundMonitoring));
    state.heartRateAlert = Boolean(await store.get(KEY_HEART_RATE_ALERT, state.heartRateAlert));
    state.lowBpmThreshold = Number(await store.get(KEY_LOW_BPM_THRESHOLD, state.lowBpmThreshold));
    state.highBpmThreshold = Number(await store.get(KEY_HIGH_BPM_THRESHOLD, state.highBpmThreshold));
    state.alertDurationSeconds = Number(await store.get(KEY_ALERT_DURATION_SECONDS, state.alertDurationSeconds));
    state.alertNotification = Boolean(await store.get(KEY_ALERT_NOTIFICATION, state.alertNotification));
    state.alertVibration = Boolean(await store.get(KEY_ALERT_VIBRATION, state.alertVibration));
    state.alertSound = Boolean(await store.get(KEY_ALERT_SOUND, state.alertSound));
    state.fullscreenSoundMode = String(await store.get(KEY_FULLSCREEN_SOUND_MODE, state.fullscreenSoundMode));
    state.fullscreenDisplayColor = String(await store.get(KEY_FULLSCREEN_DISPLAY_COLOR, state.fullscreenDisplayColor));
    return state;
  }

  async saveSettings(settings: SettingsUiState): Promise<void> {
    const store = await this.preferencesStore();
    await store.put(KEY_THEME_SOURCE, settings.themeSource);
    await store.put(KEY_THEME_MODE, settings.themeMode);
    await store.put(KEY_THEME_COLOR, settings.themeColor);
    await store.put(KEY_THEME_STYLE, settings.themeStyle);
    await store.put(KEY_RECORD_HISTORY, settings.recordHistory);
    await store.put(KEY_HEARTBEAT_ANIMATION, settings.heartbeatAnimation);
    await store.put(KEY_DISPLAY_SPEED, settings.displaySpeed);
    await store.put(KEY_HIDE_FROM_RECENTS, settings.hideFromRecents);
    await store.put(KEY_AUTO_CONNECT, settings.autoConnect);
    await store.put(KEY_AUTO_RECONNECT, settings.autoReconnect);
    await store.put(KEY_BACKGROUND_MONITORING, settings.backgroundMonitoring);
    await store.put(KEY_HEART_RATE_ALERT, settings.heartRateAlert);
    await store.put(KEY_LOW_BPM_THRESHOLD, settings.lowBpmThreshold);
    await store.put(KEY_HIGH_BPM_THRESHOLD, settings.highBpmThreshold);
    await store.put(KEY_ALERT_DURATION_SECONDS, settings.alertDurationSeconds);
    await store.put(KEY_ALERT_NOTIFICATION, settings.alertNotification);
    await store.put(KEY_ALERT_VIBRATION, settings.alertVibration);
    await store.put(KEY_ALERT_SOUND, settings.alertSound);
    await store.put(KEY_FULLSCREEN_SOUND_MODE, settings.fullscreenSoundMode);
    await store.put(KEY_FULLSCREEN_DISPLAY_COLOR, settings.fullscreenDisplayColor);
    await store.flush();
  }

  async listFavoriteDevices(): Promise<FavoriteDevice[]> {
    const store = await this.preferencesStore();
    const rawValue = String(await store.get(KEY_FAVORITES, ''));
    if (rawValue.length === 0) {
      return [];
    }
    const devices: FavoriteDevice[] = [];
    rawValue.split('\n').forEach((line: string) => {
      const separatorIndex = line.indexOf('|');
      if (separatorIndex <= 0) {
        return;
      }
      const id = line.substring(0, separatorIndex);
      const name = line.substring(separatorIndex + 1);
      if (id.length > 0 && name.length > 0) {
        devices.push({ id: id, name: name });
      }
    });
    return devices;
  }

  async saveFavoriteDevices(devices: FavoriteDevice[]): Promise<void> {
    const store = await this.preferencesStore();
    const value = devices.map((device: FavoriteDevice) => device.id + '|' + device.name).join('\n');
    await store.put(KEY_FAVORITES, value);
    await store.flush();
  }

  private async preferencesStore(): Promise<preferences.Preferences> {
    if (this.store !== undefined) {
      return this.store;
    }
    this.store = await preferences.getPreferences(this.context, PREF_NAME);
    return this.store;
  }
}
