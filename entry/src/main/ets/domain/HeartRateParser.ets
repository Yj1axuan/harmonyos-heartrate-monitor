import { EMPTY_HEART_RATE_MEASUREMENT, HeartRateMeasurement } from './model/HeartRateMeasurement';

export class HeartRateParser {
  static parse(data: Uint8Array): HeartRateMeasurement {
    if (data.length < 2) {
      return EMPTY_HEART_RATE_MEASUREMENT;
    }

    const flags = data[0];
    const is16Bit = (flags & 0x01) !== 0;
    const contactStatus = (flags >> 1) & 0x03;
    const hasEnergyExpended = (flags & 0x08) !== 0;
    const hasRrInterval = (flags & 0x10) !== 0;
    let index = 1;
    let bpm = 0;

    if (is16Bit) {
      if (data.length < 3) {
        return EMPTY_HEART_RATE_MEASUREMENT;
      }
      bpm = data[1] | (data[2] << 8);
      index = 3;
    } else {
      bpm = data[1];
      index = 2;
    }

    let energyExpended: number | undefined = undefined;
    if (hasEnergyExpended && data.length >= index + 2) {
      energyExpended = data[index] | (data[index + 1] << 8);
      index += 2;
    }

    const rrIntervals: number[] = [];
    if (hasRrInterval) {
      while (data.length >= index + 2) {
        const raw = data[index] | (data[index + 1] << 8);
        if (raw > 0) {
          rrIntervals.push(raw / 1024.0);
        }
        index += 2;
      }
    }

    return {
      bpm: bpm,
      rrIntervals: rrIntervals,
      sensorContactSupported: contactStatus === 2 || contactStatus === 3,
      sensorContact: contactStatus === 3,
      energyExpended: energyExpended
    };
  }
}

