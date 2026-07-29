export interface SessionPreview {
  id: number;
  device: string;
  time: string;
  stats: string;
  path: string;
}

export interface HistoryDetail {
  sessionId: number;
  device: string;
  time: string;
  stats: string;
  records: string[];
}

export interface FavoriteDevice {
  id: string;
  name: string;
}

export interface HistorySummary {
  sessionCount: number;
  monitoringMinutes: number;
  averageBpm: number;
}
