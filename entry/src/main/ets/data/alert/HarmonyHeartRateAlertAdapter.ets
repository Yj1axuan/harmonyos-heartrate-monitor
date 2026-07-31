import { Context, Want, WantAgent } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';
import notificationManager from '@ohos.notificationManager';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import vibrator from '@ohos.vibrator';
import wantAgent from '@ohos.app.ability.wantAgent';
import audio from '@ohos.multimedia.audio';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { HeartRateAlertEvent, HeartRateAlertType, HeartRateBackgroundMonitorPort } from '../../domain/port/HeartRateAlertPort';

const ALERT_NOTIFICATION_ID = 18037;
const BACKGROUND_REQUEST_CODE = 18038;

export class HarmonyHeartRateAlertAdapter implements HeartRateBackgroundMonitorPort {
  private backgroundRunning: boolean = false;
  private soundPlaying: boolean = false;

  async requestNotificationPermission(_context: Context): Promise<void> {
    try {
      await notificationManager.requestEnableNotification();
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
    } catch (_error) {
    }
  }

  async startBackgroundMonitoring(context: Context): Promise<void> {
    if (this.backgroundRunning) {
      return;
    }
    try {
      const agent = await this.createWantAgent(context);
      await backgroundTaskManager.startBackgroundRunning(
        context,
        backgroundTaskManager.BackgroundMode.BLUETOOTH_INTERACTION,
        agent
      );
      this.backgroundRunning = true;
    } catch (_error) {
      this.backgroundRunning = false;
    }
  }

  async stopBackgroundMonitoring(context: Context): Promise<void> {
    if (!this.backgroundRunning) {
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
    } catch (_error) {
    }
    this.backgroundRunning = false;
  }

  async publishAlert(event: HeartRateAlertEvent, settings: SettingsUiState): Promise<void> {
    if (settings.alertNotification) {
      await this.publishNotification(event, settings);
    }
    if (settings.alertSound) {
      await this.playAlertSound(event.type);
    }
    if (settings.alertVibration) {
      await this.vibrate();
    }
  }

  private async createWantAgent(context: Context): Promise<WantAgent> {
    const abilityContext = context as common.UIAbilityContext;
    const want: Want = {
      bundleName: abilityContext.abilityInfo.bundleName,
      abilityName: abilityContext.abilityInfo.name
    };
    const info: wantAgent.WantAgentInfo = {
      wants: [want],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: BACKGROUND_REQUEST_CODE,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    return wantAgent.getWantAgent(info);
  }

  private async publishNotification(event: HeartRateAlertEvent, settings: SettingsUiState): Promise<void> {
    try {
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
      const title = event.type === HeartRateAlertType.High ? '心率过高预警' : '心率过低预警';
      const text = event.deviceName.length > 0 ?
        event.deviceName + ' 当前 ' + event.bpm + ' bpm，已持续 ' + event.durationSeconds + ' 秒' :
        '当前 ' + event.bpm + ' bpm，已持续 ' + event.durationSeconds + ' 秒';
      const request: notificationManager.NotificationRequest = {
        id: ALERT_NOTIFICATION_ID,
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text,
            additionalText: settings.alertSound ? '声音提醒已开启' : '声音提醒已关闭'
          }
        }
      };
      await notificationManager.publish(request);
    } catch (_error) {
    }
  }

  private async playAlertSound(type: HeartRateAlertType): Promise<void> {
    if (type === HeartRateAlertType.High) {
      await this.playToneSequence([880, 1100, 880], [110, 140, 110]);
      return;
    }
    await this.playToneSequence([660, 520, 660], [130, 160, 130]);
  }

  private async playToneSequence(frequencies: number[], durations: number[]): Promise<void> {
    for (let index = 0; index < frequencies.length; index++) {
      await this.playTone(frequencies[index], durations[index]);
    }
  }

  private async playTone(frequency: number, durationMs: number): Promise<void> {
    if (this.soundPlaying) {
      return;
    }
    this.soundPlaying = true;
    try {
      const renderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
          rendererFlags: 0
        }
      });
      const sampleRate = 44100;
      const sampleCount = Math.floor(sampleRate * durationMs / 1000);
      const buffer = new ArrayBuffer(sampleCount * 2);
      const view = new DataView(buffer);
      for (let index = 0; index < sampleCount; index++) {
        const envelope = Math.sin(Math.PI * index / sampleCount);
        const value = Math.round(Math.sin((2 * Math.PI * frequency * index) / sampleRate) * 12000 * envelope);
        view.setInt16(index * 2, value, true);
      }
      await renderer.start();
      await renderer.write(buffer);
      await renderer.stop();
      await renderer.release();
    } catch (_error) {
    } finally {
      this.soundPlaying = false;
    }
  }

  private async vibrate(): Promise<void> {
    try {
      await vibrator.startVibration(
        {
          type: 'time',
          duration: 800
        },
        {
          usage: 'alarm'
        }
      );
    } catch (_error) {
    }
  }
}
