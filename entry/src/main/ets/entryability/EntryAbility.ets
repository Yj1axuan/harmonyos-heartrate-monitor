import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppContainer } from '../core/di/AppContainer';

const DOMAIN = 0x0000;
const TAG = 'HeartRate';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    AppContainer.initialize(this.context);
    hilog.info(DOMAIN, TAG, 'EntryAbility created');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppContainer.setWindowStage(windowStage);
    windowStage.loadContent('pages/MainPage', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load page: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Main page loaded');
    });
  }
}

