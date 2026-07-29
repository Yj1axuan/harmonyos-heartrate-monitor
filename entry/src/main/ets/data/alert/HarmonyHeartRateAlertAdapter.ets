import { Context, Want, WantAgent } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';
import notificationManager from '@ohos.notificationManager';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import vibrator from '@ohos.vibrator';
import wantAgent from '@ohos.app.ability.wantAgent';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import { HeartRateAlertEvent, HeartRateAlertType, HeartRateBackgroundMonitorPort } from '../../domain/port/HeartRateAlertPort';

const ALERT_NOTIFICATION_ID = 18037;
const BACKGROUND_REQUEST_CODE = 18038;

export class HarmonyHeartRateAlertAdapter implements HeartRateBackgroundMonitorPort {
  private backgroundRunning: boolean = false;

  async requestNotificationPermission(context: Context): Promise<void> {
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
