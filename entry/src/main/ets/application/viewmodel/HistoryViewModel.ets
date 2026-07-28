import { FavoriteDevice, HistorySummary, SessionPreview } from '../model/HistoryUiModels';

export class HistoryViewModel {
  readonly summary: HistorySummary = {
    sessionCount: 3,
    monitoringMinutes: 1021,
    averageBpm: 84
  };

  readonly sessions: SessionPreview[] = [
    {
      id: 1,
      device: 'HUAWEI Band HR',
      time: '2026-07-28 12:29 - 12:36',
      stats: '平均 84  ·  最低 79  ·  最高 90  ·  412 条',
      path: 'M 4 27 L 16 24 L 28 30 L 40 20 L 52 22 L 64 12 L 76 17'
    },
    {
      id: 2,
      device: 'Heart Rate Sensor',
      time: '2026-07-27 21:04 - 21:28',
      stats: '平均 76  ·  最低 68  ·  最高 87  ·  938 条',
      path: 'M 4 22 L 16 14 L 28 19 L 40 9 L 52 24 L 64 18 L 76 26'
    },
    {
      id: 3,
      device: 'HUAWEI Band HR',
      time: '2026-07-26 08:12 - 08:47',
      stats: '平均 92  ·  最低 82  ·  最高 114  ·  1260 条',
      path: 'M 4 29 L 16 23 L 28 25 L 40 18 L 52 8 L 64 12 L 76 5'
    }
  ];

  readonly favoriteDevices: FavoriteDevice[] = [
    { id: 'F8:3A:7B:21:91:04', name: 'HUAWEI Band HR' },
    { id: 'C1:4D:22:87:6A:10', name: 'Heart Rate Sensor' }
  ];
}
