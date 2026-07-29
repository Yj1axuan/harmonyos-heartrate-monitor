import { FavoriteDevice, HistoryDetail, HistorySummary, SessionPreview } from '../model/HistoryUiModels';
import { HeartRateRecord, HeartRateSession, HeartRateStorePort } from '../../domain/port/HeartRateStorePort';
import { AppPreferencesPort } from '../../domain/port/AppPreferencesPort';

export class HistoryViewModel {
  summary: HistorySummary = {
    sessionCount: 0,
    monitoringMinutes: 0,
    averageBpm: 0
  };

  sessions: SessionPreview[] = [];
  selectedDetail: HistoryDetail | undefined = undefined;
  favoriteDevices: FavoriteDevice[] = [];
  private storePort: HeartRateStorePort;
  private preferencesPort: AppPreferencesPort;

  constructor(storePort: HeartRateStorePort, preferencesPort: AppPreferencesPort) {
    this.storePort = storePort;
    this.preferencesPort = preferencesPort;
  }

  async load(): Promise<void> {
    this.favoriteDevices = await this.preferencesPort.listFavoriteDevices();
    const sessions = await this.storePort.listSessions();
    const previews: SessionPreview[] = [];
    let totalBpm = 0;
    let totalRecords = 0;
    let totalMinutes = 0;

    for (let index = 0; index < sessions.length; index++) {
      const session = sessions[index];
      const records = await this.storePort.listRecords(session.id);
      previews.push(this.createSessionPreview(session, records));
      totalMinutes += this.sessionMinutes(session);
      records.forEach((record: HeartRateRecord) => {
        totalBpm += record.heartRate;
        totalRecords++;
      });
    }

    this.sessions = previews;
    this.summary = {
      sessionCount: sessions.length,
      monitoringMinutes: totalMinutes,
      averageBpm: totalRecords > 0 ? Math.round(totalBpm / totalRecords) : 0
    };
  }

  async openDetail(sessionId: number): Promise<void> {
    const sessions = await this.storePort.listSessions();
    const index = sessions.findIndex((session: HeartRateSession) => session.id === sessionId);
    if (index < 0) {
      this.selectedDetail = undefined;
      return;
    }
    const session = sessions[index];
    const records = await this.storePort.listRecords(sessionId);
    this.selectedDetail = {
      sessionId: session.id,
      device: session.deviceName,
      time: this.formatTimeRange(session),
      stats: this.formatStats(records),
      records: records.map((record: HeartRateRecord) =>
        this.formatClock(record.timestamp) + '  ' + record.heartRate.toString() + ' bpm')
    };
  }

  closeDetail(): void {
    this.selectedDetail = undefined;
  }

  async deleteSession(sessionId: number): Promise<void> {
    await this.storePort.deleteSession(sessionId);
    this.selectedDetail = undefined;
    await this.load();
  }

  async removeFavoriteDevice(deviceId: string): Promise<void> {
    this.favoriteDevices = this.favoriteDevices.filter((device: FavoriteDevice) => device.id !== deviceId);
    await this.preferencesPort.saveFavoriteDevices(this.favoriteDevices);
  }

  async addFavoriteDevice(device: FavoriteDevice): Promise<void> {
    const exists = this.favoriteDevices.findIndex((item: FavoriteDevice) => item.id === device.id) >= 0;
    if (!exists) {
      this.favoriteDevices = [device].concat(this.favoriteDevices);
      await this.preferencesPort.saveFavoriteDevices(this.favoriteDevices);
    }
  }

  private createSessionPreview(session: HeartRateSession, records: HeartRateRecord[]): SessionPreview {
    return {
      id: session.id,
      device: session.deviceName,
      time: this.formatTimeRange(session),
      stats: this.formatStats(records),
      path: this.createSparklinePath(records)
    };
  }

  private formatStats(records: HeartRateRecord[]): string {
    if (records.length === 0) {
      return '暂无心率记录';
    }
    let min = records[0].heartRate;
    let max = records[0].heartRate;
    let total = 0;
    records.forEach((record: HeartRateRecord) => {
      min = Math.min(min, record.heartRate);
      max = Math.max(max, record.heartRate);
      total += record.heartRate;
    });
    return '平均 ' + Math.round(total / records.length).toString() +
      '  ·  最低 ' + min.toString() +
      '  ·  最高 ' + max.toString() +
      '  ·  ' + records.length.toString() + ' 条';
  }

  private createSparklinePath(records: HeartRateRecord[]): string {
    if (records.length === 0) {
      return '';
    }
    const points = this.downsampleRecords(records, 8);
    let min = points[0].heartRate;
    let max = points[0].heartRate;
    points.forEach((record: HeartRateRecord) => {
      min = Math.min(min, record.heartRate);
      max = Math.max(max, record.heartRate);
    });
    const range = Math.max(1, max - min);
    let path = '';
    points.forEach((record: HeartRateRecord, index: number) => {
      const x = points.length === 1 ? 4 : 4 + Math.floor((72 * index) / (points.length - 1));
      const y = 31 - Math.floor(((record.heartRate - min) * 26) / range);
      path += (index === 0 ? 'M ' : ' L ') + x.toString() + ' ' + y.toString();
    });
    return path;
  }

  private downsampleRecords(records: HeartRateRecord[], targetCount: number): HeartRateRecord[] {
    if (records.length <= targetCount) {
      return records;
    }
    const result: HeartRateRecord[] = [];
    for (let index = 0; index < targetCount; index++) {
      const sourceIndex = Math.floor((records.length - 1) * index / (targetCount - 1));
      result.push(records[sourceIndex]);
    }
    return result;
  }

  private sessionMinutes(session: HeartRateSession): number {
    const endTime = session.endTime !== undefined ? session.endTime : Date.now();
    return Math.max(0, Math.round((endTime - session.startTime) / 60000));
  }

  private formatTimeRange(session: HeartRateSession): string {
    const endTime = session.endTime !== undefined ? session.endTime : Date.now();
    return this.formatDateTime(session.startTime) + ' - ' + this.formatClock(endTime);
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.getFullYear().toString() + '-' +
      this.pad2(date.getMonth() + 1) + '-' +
      this.pad2(date.getDate()) + ' ' +
      this.pad2(date.getHours()) + ':' +
      this.pad2(date.getMinutes());
  }

  private formatClock(timestamp: number): string {
    const date = new Date(timestamp);
    return this.pad2(date.getHours()) + ':' + this.pad2(date.getMinutes()) + ':' + this.pad2(date.getSeconds());
  }

  private pad2(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }
}
