import relationalStore from '@ohos.data.relationalStore';
import { Context } from '@kit.AbilityKit';
import { HeartRateRecord, HeartRateSession, HeartRateStorePort } from '../../domain/port/HeartRateStorePort';

const DB_NAME = 'heart_rate_history.db';
const TABLE_SESSIONS = 'monitoring_sessions';
const TABLE_RECORDS = 'heart_rate_records';

export class HarmonyHeartRateStoreAdapter implements HeartRateStorePort {
  private context: Context;
  private store: relationalStore.RdbStore | undefined = undefined;

  constructor(context: Context) {
    this.context = context;
  }

  async createSession(deviceName: string, startTime: number): Promise<number> {
    const store = await this.rdbStore();
    const values: relationalStore.ValuesBucket = {};
    values.device_name = deviceName;
    values.start_time = startTime;
    const id = await store.insert(TABLE_SESSIONS, values);
    return Number(id);
  }

  async closeSession(sessionId: number, endTime: number): Promise<void> {
    const store = await this.rdbStore();
    const predicates = new relationalStore.RdbPredicates(TABLE_SESSIONS);
    predicates.equalTo('id', sessionId);
    const values: relationalStore.ValuesBucket = {};
    values.end_time = endTime;
    await store.update(values, predicates);
  }

  async appendRecords(records: HeartRateRecord[]): Promise<void> {
    if (records.length === 0) {
      return;
    }
    const store = await this.rdbStore();
    const values: relationalStore.ValuesBucket[] = [];
    records.forEach((record: HeartRateRecord) => {
      const value: relationalStore.ValuesBucket = {};
      value.session_id = record.sessionId;
      value.timestamp = record.timestamp;
      value.heart_rate = record.heartRate;
      values.push(value);
    });
    await store.batchInsert(TABLE_RECORDS, values);
  }

  async listSessions(): Promise<HeartRateSession[]> {
    const store = await this.rdbStore();
    const resultSet = await store.querySql(
      'SELECT id, device_name, start_time, end_time FROM monitoring_sessions ORDER BY start_time DESC'
    );
    const sessions: HeartRateSession[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const endTimeIndex = resultSet.getColumnIndex('end_time');
        const session: HeartRateSession = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          deviceName: resultSet.getString(resultSet.getColumnIndex('device_name')),
          startTime: resultSet.getLong(resultSet.getColumnIndex('start_time'))
        };
        if (!resultSet.isColumnNull(endTimeIndex)) {
          session.endTime = resultSet.getLong(endTimeIndex);
        }
        sessions.push(session);
      }
    } finally {
      resultSet.close();
    }
    return sessions;
  }

  async listRecords(sessionId: number): Promise<HeartRateRecord[]> {
    const store = await this.rdbStore();
    const resultSet = await store.querySql(
      'SELECT session_id, timestamp, heart_rate FROM heart_rate_records WHERE session_id = ? ORDER BY timestamp ASC',
      [sessionId]
    );
    const records: HeartRateRecord[] = [];
    try {
      while (resultSet.goToNextRow()) {
        records.push({
          sessionId: resultSet.getLong(resultSet.getColumnIndex('session_id')),
          timestamp: resultSet.getLong(resultSet.getColumnIndex('timestamp')),
          heartRate: resultSet.getLong(resultSet.getColumnIndex('heart_rate'))
        });
      }
    } finally {
      resultSet.close();
    }
    return records;
  }

  async deleteSession(sessionId: number): Promise<void> {
    const store = await this.rdbStore();
    const recordPredicates = new relationalStore.RdbPredicates(TABLE_RECORDS);
    recordPredicates.equalTo('session_id', sessionId);
    await store.delete(recordPredicates);
    const sessionPredicates = new relationalStore.RdbPredicates(TABLE_SESSIONS);
    sessionPredicates.equalTo('id', sessionId);
    await store.delete(sessionPredicates);
  }

  private async rdbStore(): Promise<relationalStore.RdbStore> {
    if (this.store !== undefined) {
      return this.store;
    }
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.store = await relationalStore.getRdbStore(this.context, config);
    await this.createTables(this.store);
    return this.store;
  }

  private async createTables(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS monitoring_sessions (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'device_name TEXT NOT NULL, ' +
        'start_time INTEGER NOT NULL, ' +
        'end_time INTEGER)'
    );
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS heart_rate_records (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'session_id INTEGER NOT NULL, ' +
        'timestamp INTEGER NOT NULL, ' +
        'heart_rate INTEGER NOT NULL)'
    );
    await store.executeSql(
      'CREATE INDEX IF NOT EXISTS idx_heart_rate_records_session_time ' +
        'ON heart_rate_records(session_id, timestamp)'
    );
  }
}
