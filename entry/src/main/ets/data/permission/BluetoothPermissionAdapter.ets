import { abilityAccessCtrl, Context, Permissions } from '@kit.AbilityKit';
import { BluetoothPermissionPort } from '../../domain/port/BluetoothPermissionPort';

const ACCESS_BLUETOOTH: Permissions = 'ohos.permission.ACCESS_BLUETOOTH';

export class BluetoothPermissionAdapter implements BluetoothPermissionPort {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async ensureGranted(): Promise<boolean> {
    const manager = abilityAccessCtrl.createAtManager();
    const result = await manager.requestPermissionsFromUser(this.context, [ACCESS_BLUETOOTH]);
    return result.authResults.length === 1 && result.authResults[0] === 0;
  }
}
