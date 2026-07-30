import { HeartRateUiState } from '../../application/state/HeartRateUiState';
import { SettingsUiState } from '../../application/state/SettingsUiState';
import audio from '@ohos.multimedia.audio';

export type FullscreenExitReason = 'back' | 'tap' | 'button' | 'disconnect';

@Component
export struct FullScreenPage {
  @ObjectLink state: HeartRateUiState;
  @ObjectLink settings: SettingsUiState;
  onExit: (reason: FullscreenExitReason) => void = (_reason: FullscreenExitReason) => {};
  @State private waveOffset: number = 0;
  @State private pulseLevel: number = 0;
  @State private beatHandle: number = 0;
  @State private animationHandle: number = 0;
  @State private monitorHandle: number = 0;
  @State private promptState: string = 'none';
  @State private playing: boolean = false;
  @State private isLandscape: boolean = true;

  aboutToAppear(): void {
    this.startTimers();
  }

  aboutToDisappear(): void {
    this.stopTimers();
  }

  private startTimers(): void {
    this.stopTimers();
    this.startBeatLoop();
    this.monitorHandle = setInterval(() => {
      this.monitorState();
    }, 250);
    if (this.settings.heartbeatAnimation) {
      this.animationHandle = setInterval(() => {
        this.waveOffset = this.waveOffset + 16;
        if (this.pulseLevel > 0) {
          this.pulseLevel = Math.max(0, this.pulseLevel - 0.08);
        }
      }, 40);
    }
  }

  private stopTimers(): void {
    if (this.beatHandle !== 0) {
      clearTimeout(this.beatHandle);
      this.beatHandle = 0;
    }
    if (this.animationHandle !== 0) {
      clearInterval(this.animationHandle);
      this.animationHandle = 0;
    }
    if (this.monitorHandle !== 0) {
      clearInterval(this.monitorHandle);
      this.monitorHandle = 0;
    }
  }

  private monitorState(): void {
    const nextState = this.resolvePromptState(this.state.bpm);
    if (nextState !== this.promptState) {
      this.promptState = nextState;
      if (nextState !== 'none') {
        void this.playPromptTone(nextState);
      }
    }
  }

  private startBeatLoop(): void {
    const delay = this.currentBeatDelay();
    this.beatHandle = setTimeout(async () => {
      if (this.state.connected && this.state.bpm > 0) {
        this.pulseLevel = 1;
        if (this.settings.fullscreenSoundMode !== 'off') {
          await this.playBeatTone(this.state.bpm);
        }
      }
      this.startBeatLoop();
    }, delay);
  }

  private currentBeatDelay(): number {
    const bpm = Math.max(30, Math.min(this.state.bpm > 0 ? this.state.bpm : 60, 220));
    return Math.max(220, Math.floor(60000 / bpm));
  }

  private updateLayoutMode(width: number, height: number): void {
    this.isLandscape = width >= height;
  }

  private resolvePromptState(bpm: number): string {
    if (!this.settings.heartRateAlert || bpm <= 0) {
      return 'none';
    }
    if (bpm > this.settings.highBpmThreshold) {
      return 'high';
    }
    if (bpm < this.settings.lowBpmThreshold) {
      return 'low';
    }
    return 'none';
  }

  private async playPromptTone(type: string): Promise<void> {
    if (this.settings.fullscreenSoundMode === 'off') {
      return;
    }
    if (type === 'high') {
      await this.playToneSequence([880, 1100], [100, 120]);
      return;
    }
    await this.playToneSequence([660, 520], [120, 140]);
  }

  private async playBeatTone(bpm: number): Promise<void> {
    if (this.playing) {
      return;
    }
    const base = Math.max(48, Math.min(90, bpm));
    const frequency = this.settings.fullscreenSoundMode === 'en' ? 880 : 740;
    await this.playTone(frequency + (base - 60) * 2, 80);
  }

  private async playToneSequence(frequencies: number[], durations: number[]): Promise<void> {
    for (let i = 0; i < frequencies.length; i++) {
      await this.playTone(frequencies[i], durations[i]);
    }
  }

  private async playTone(frequency: number, durationMs: number): Promise<void> {
    if (this.playing) {
      return;
    }
    this.playing = true;
    try {
      const renderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
          rendererFlags: 0
        }
      });
      const sampleRate = 44100;
      const sampleCount = Math.floor(sampleRate * durationMs / 1000);
      const buffer = new ArrayBuffer(sampleCount * 2);
      const view = new DataView(buffer);
      for (let i = 0; i < sampleCount; i++) {
        const envelope = Math.sin(Math.PI * i / sampleCount);
        const value = Math.round(Math.sin((2 * Math.PI * frequency * i) / sampleRate) * 12000 * envelope);
        view.setInt16(i * 2, value, true);
      }
      await renderer.start();
      await renderer.write(buffer);
      await renderer.stop();
      await renderer.release();
    } catch (_error) {
    } finally {
      this.playing = false;
    }
  }

  private colorHex(): string {
    if (this.settings.fullscreenDisplayColor === 'green') {
      return '#46E08A';
    }
    if (this.settings.fullscreenDisplayColor === 'cyan') {
      return '#49D6FF';
    }
    return '#FF4A4A';
  }

  private wavePath(): string {
    const bpm = this.state.bpm > 0 ? this.state.bpm : 60;
    const period = Math.max(240, 60000 / bpm);
    const width = this.isLandscape ? 720 : 520;
    const height = this.isLandscape ? 220 : 180;
    const baseY = this.isLandscape ? 110 : 90;
    const points = 72;
    let path = '';
    for (let i = 0; i < points; i++) {
      const x = Math.round((width * i) / (points - 1));
      const phase = (((this.waveOffset + (x * period / width)) % period) / period);
      const y = baseY - Math.round(this.ecgValue(phase) * height);
      path += (i === 0 ? 'M ' : ' L ') + x + ' ' + y;
    }
    return path;
  }

  private heartFontSize(): number {
    return this.isLandscape ? 110 : 92;
  }

  private bpmFontSize(): number {
    return this.isLandscape ? 82 : 68;
  }

  private unitFontSize(): number {
    return this.isLandscape ? 22 : 18;
  }

  private waveHeight(): number {
    return this.isLandscape ? 220 : 180;
  }

  private ecgValue(phase: number): number {
    const p = phase;
    if (p < 0.08) {
      return 0.02 * Math.sin(Math.PI * p / 0.08);
    }
    if (p < 0.12) {
      return -0.03 * Math.sin(Math.PI * (p - 0.08) / 0.04);
    }
    if (p < 0.14) {
      return 0.06 * Math.sin(Math.PI * (p - 0.12) / 0.02);
    }
    if (p < 0.16) {
      return 1.05 * Math.sin(Math.PI * (p - 0.14) / 0.02);
    }
    if (p < 0.20) {
      return -0.18 * Math.sin(Math.PI * (p - 0.16) / 0.04);
    }
    if (p < 0.28) {
      return 0.10 * Math.sin(Math.PI * (p - 0.20) / 0.08);
    }
    return 0.03 * Math.sin(Math.PI * (p - 0.28) / 0.72);
  }

  build() {
    Column() {
      Row() {
        Blank()
        Row({ space: 6 }) {
          Text('⛶')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('退出全屏')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .backgroundColor('#2AFFFFFF')
        .borderRadius(18)
        .onClick(() => {
          this.onExit('button');
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ top: 18, right: 18 })

      Blank()
      if (this.isLandscape) {
        Row({ space: 16 }) {
          Text('❤')
            .fontSize(this.heartFontSize())
            .fontColor(this.colorHex())
            .opacity(Math.max(0.5, 0.72 + this.pulseLevel * 0.28))
            .scale({
              x: this.settings.heartbeatAnimation ? 1 + this.pulseLevel * 0.10 : 1,
              y: this.settings.heartbeatAnimation ? 1 + this.pulseLevel * 0.10 : 1
            })
          Column({ space: 6 }) {
            Text(this.state.connected && this.state.bpm > 0 ? this.state.bpm.toString() : '--')
              .fontSize(this.bpmFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colorHex())
            Text('BPM')
              .fontSize(this.unitFontSize())
              .fontWeight(FontWeight.Medium)
              .fontColor('#F0F0F0')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Center)
      } else {
        Column({ space: 14 }) {
          Text('❤')
            .fontSize(this.heartFontSize())
            .fontColor(this.colorHex())
            .opacity(Math.max(0.5, 0.72 + this.pulseLevel * 0.28))
            .scale({
              x: this.settings.heartbeatAnimation ? 1 + this.pulseLevel * 0.10 : 1,
              y: this.settings.heartbeatAnimation ? 1 + this.pulseLevel * 0.10 : 1
            })
          Column({ space: 4 }) {
            Text(this.state.connected && this.state.bpm > 0 ? this.state.bpm.toString() : '--')
              .fontSize(this.bpmFontSize())
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colorHex())
            Text('BPM')
              .fontSize(this.unitFontSize())
              .fontWeight(FontWeight.Medium)
              .fontColor('#F0F0F0')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
      }

      Path()
        .commands(this.state.connected ? this.wavePath() : '')
        .fill(Color.Transparent)
        .stroke(this.colorHex())
        .strokeWidth(4)
        .width('100%')
        .height(this.waveHeight())

      Text(this.state.connected ? this.state.deviceName : '--')
        .fontSize(18)
        .fontColor('#B8BCCC')

      Blank()
      Text('点击屏幕或按返回键退出全屏')
        .fontSize(14)
        .fontColor('#9AA1B5')
        .margin({ bottom: 24 })
    }
      .width('100%')
      .height('100%')
      .padding({ left: 28, right: 28 })
      .backgroundColor('#000000')
      .onAreaChange((_oldArea, newArea) => {
        this.updateLayoutMode(Number(`${newArea.width}`), Number(`${newArea.height}`));
      })
      .onClick(() => {
        this.onExit('tap');
      })
  }
}
