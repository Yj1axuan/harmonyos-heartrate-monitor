export interface HeartRateSession {
  id: number;
  deviceName: string;
  startTime: number;
  endTime?: number;
}

export interface HeartRateRecord {
  sessionId: number;
  timestamp: number;
  heartRate: number;
}

export interface HeartRateStorePort {
  createSession(deviceName: string, startTime: number): Promise<number>;
  closeSession(sessionId: number, endTime: number): Promise<void>;
  appendRecords(records: HeartRateRecord[]): Promise<void>;
  listSessions(): Promise<HeartRateSession[]>;
  listRecords(sessionId: number): Promise<HeartRateRecord[]>;
  deleteSession(sessionId: number): Promise<void>;
}
