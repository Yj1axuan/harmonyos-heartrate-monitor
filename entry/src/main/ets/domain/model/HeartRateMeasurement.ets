export interface HeartRateMeasurement {
  bpm: number;
  rrIntervals: number[];
  sensorContactSupported: boolean;
  sensorContact: boolean;
  energyExpended?: number;
}

export const EMPTY_HEART_RATE_MEASUREMENT: HeartRateMeasurement = {
  bpm: 0,
  rrIntervals: [],
  sensorContactSupported: false,
  sensorContact: false
};

