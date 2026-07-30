
export type ThemeSource = 'system' | 'custom';
export type ThemeMode = 'system' | 'light' | 'dark';
export type ThemeStyle = 'soft' | 'vivid' | 'expressive' | 'neutral' | 'monochrome' | 'fidelity' | 'content' | 'rainbow' | 'fruit';

export interface ThemeConfig {
  source: ThemeSource;
  mode: ThemeMode;
  color: string;
  style: ThemeStyle;
}

export interface ThemePalette {
  background: string;
  surface: string;
  surfaceStrong: string;
  primary: string;
  primarySoft: string;
  secondary: string;
  secondarySoft: string;
  heart: string;
  heartSoft: string;
  error: string;
  text: string;
  textMuted: string;
  divider: string;
  white: string;
}

export class ThemeSourceOption {
  value: ThemeSource;
  title: string;
  subtitle: string;

  constructor(value: ThemeSource, title: string, subtitle: string) {
    this.value = value;
    this.title = title;
    this.subtitle = subtitle;
  }
}

export class ThemeModeOption {
  value: ThemeMode;
  title: string;
  subtitle: string;

  constructor(value: ThemeMode, title: string, subtitle: string) {
    this.value = value;
    this.title = title;
    this.subtitle = subtitle;
  }
}

export class ThemeColorPreset {
  name: string;
  hex: string;

  constructor(name: string, hex: string) {
    this.name = name;
    this.hex = hex;
  }
}

export class ThemeStyleOption {
  value: ThemeStyle;
  title: string;
  subtitle: string;

  constructor(value: ThemeStyle, title: string, subtitle: string) {
    this.value = value;
    this.title = title;
    this.subtitle = subtitle;
  }
}

class ThemeStyleRule {
  saturation: number;
  brightness: number;
  hueShift: number;
  backgroundMix: number;
  surfaceMix: number;
  secondaryShift: number;

  constructor(saturation: number, brightness: number, hueShift: number, backgroundMix: number, surfaceMix: number,
    secondaryShift: number) {
    this.saturation = saturation;
    this.brightness = brightness;
    this.hueShift = hueShift;
    this.backgroundMix = backgroundMix;
    this.surfaceMix = surfaceMix;
    this.secondaryShift = secondaryShift;
  }
}

export class RgbColor {
  r: number;
  g: number;
  b: number;

  constructor(r: number, g: number, b: number) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}

export class HsvColor {
  h: number;
  s: number;
  v: number;

  constructor(h: number, s: number, v: number) {
    this.h = h;
    this.s = s;
    this.v = v;
  }
}

export const THEME_SOURCE_OPTIONS: ThemeSourceOption[] = [
  new ThemeSourceOption('system', '系统动态主题', '跟随系统或壁纸配色'),
  new ThemeSourceOption('custom', '自定义主题', '使用用户选择的主题色')
];

export const THEME_MODE_OPTIONS: ThemeModeOption[] = [
  new ThemeModeOption('system', '跟随系统', '自动匹配浅色或深色'),
  new ThemeModeOption('light', '固定亮色', '始终使用浅色模式'),
  new ThemeModeOption('dark', '固定暗色', '始终使用深色模式')
];

export const THEME_COLOR_PRESETS: ThemeColorPreset[] = [
  new ThemeColorPreset('红', '#F04444'),
  new ThemeColorPreset('橙', '#F28C28'),
  new ThemeColorPreset('黄', '#E9C12C'),
  new ThemeColorPreset('绿', '#3DBB6D'),
  new ThemeColorPreset('青', '#2FB8C8'),
  new ThemeColorPreset('蓝', '#4F7CFF'),
  new ThemeColorPreset('紫', '#8A5CFF'),
  new ThemeColorPreset('粉', '#E95EAD')
];

export const THEME_STYLE_OPTIONS: ThemeStyleOption[] = [
  new ThemeStyleOption('soft', '柔和', '低饱和、柔和舒展'),
  new ThemeStyleOption('vivid', '鲜艳', '更高对比与明度'),
  new ThemeStyleOption('expressive', '表现力', '平衡且有个性'),
  new ThemeStyleOption('neutral', '中性', '更克制的综合色彩'),
  new ThemeStyleOption('monochrome', '单色', '围绕单一主题色展开'),
  new ThemeStyleOption('fidelity', '保真', '尽量保持原始色相'),
  new ThemeStyleOption('content', '内容', '偏内容阅读的配色'),
  new ThemeStyleOption('rainbow', '彩虹', '更活跃的综合色盘'),
  new ThemeStyleOption('fruit', '水果沙拉', '暖色活力感更强')
];

const DEFAULT_LIGHT_BASE = '#5269A8';

export class AppColors {
  static BACKGROUND: string = '#FAF8FD';
  static SURFACE: string = '#F0EFF4';
  static SURFACE_STRONG: string = '#E8E8EF';
  static PRIMARY: string = '#5269A8';
  static PRIMARY_SOFT: string = '#DDE4FF';
  static HEART: string = '#F04444';
  static HEART_SOFT: string = '#F39AA2';
  static ERROR: string = '#C52A22';
  static TEXT: string = '#17181C';
  static TEXT_MUTED: string = '#62656E';
  static DIVIDER: string = '#FFFFFF';
  static WHITE: string = '#FFFFFF';
  static SECONDARY: string = '#7B86C8';
  static SECONDARY_SOFT: string = '#E7EBFF';
  static DARK_BAR_CONTENT: boolean = false;
  private static SYSTEM_DYNAMIC_COLOR: string = DEFAULT_LIGHT_BASE;
  static themeConfig: ThemeConfig = {
    source: 'system',
    mode: 'system',
    color: DEFAULT_LIGHT_BASE,
    style: 'expressive'
  };

  static applyTheme(config: ThemeConfig): void {
    AppColors.themeConfig = {
      source: config.source,
      mode: config.mode,
      color: normalizeHex(config.color.length > 0 ? config.color : DEFAULT_LIGHT_BASE),
      style: config.style
    };
    const effectiveMode = AppColors.resolveEffectiveMode(AppColors.themeConfig.mode);
    const baseColor = AppColors.themeConfig.source === 'custom'
      ? AppColors.themeConfig.color
      : AppColors.SYSTEM_DYNAMIC_COLOR;
    const palette = buildPalette(baseColor, effectiveMode, AppColors.themeConfig.style);
    AppColors.BACKGROUND = palette.background;
    AppColors.SURFACE = palette.surface;
    AppColors.SURFACE_STRONG = palette.surfaceStrong;
    AppColors.PRIMARY = palette.primary;
    AppColors.PRIMARY_SOFT = palette.primarySoft;
    AppColors.HEART = palette.heart;
    AppColors.HEART_SOFT = palette.heartSoft;
    AppColors.ERROR = palette.error;
    AppColors.TEXT = palette.text;
    AppColors.TEXT_MUTED = palette.textMuted;
    AppColors.DIVIDER = palette.divider;
    AppColors.WHITE = palette.white;
    AppColors.SECONDARY = palette.secondary;
    AppColors.SECONDARY_SOFT = palette.secondarySoft;
    AppColors.DARK_BAR_CONTENT = luminance(palette.background) > 0.55;
  }

  static setSystemDynamicColor(color: string): void {
    AppColors.SYSTEM_DYNAMIC_COLOR = normalizeHex(color);
  }

  static systemDynamicColor(): string {
    return AppColors.SYSTEM_DYNAMIC_COLOR;
  }

  static resolveEffectiveMode(mode: ThemeMode): 'light' | 'dark' {
    if (mode === 'light' || mode === 'dark') {
      return mode;
    }

    return 'light';
  }

  static currentThemeSurface(): string {
    return AppColors.SURFACE;
  }
}

export function generateThemePalette(config: ThemeConfig): ThemePalette {
  const effectiveMode = AppColors.resolveEffectiveMode(config.mode);
  const baseColor = config.source === 'custom'
    ? normalizeHex(config.color)
    : AppColors.systemDynamicColor();
  return buildPalette(baseColor, effectiveMode, config.style);
}

export function themeHexToHsv(hex: string): HsvColor {
  return rgbToHsv(hexToRgb(hex));
}

export function themeHsvToHex(h: number, s: number, v: number): string {
  return rgbToHexFromHsv(h, s, v).toUpperCase();
}

function buildPalette(baseColor: string, effectiveMode: 'light' | 'dark', style: ThemeStyle): ThemePalette {
  const rule = styleRule(style);
  const base = adjustColor(baseColor, rule.hueShift, rule.saturation, rule.brightness);
  const secondary = adjustColor(baseColor, rule.hueShift + rule.secondaryShift, Math.max(0.15, rule.saturation * 0.88), Math.max(0.88, rule.brightness * 0.98));
  const backgroundBase = effectiveMode === 'dark' ? '#0F1117' : '#FAF8FD';
  const surfaceBase = effectiveMode === 'dark' ? '#171B24' : '#F0EFF4';
  const surfaceStrongBase = effectiveMode === 'dark' ? '#202634' : '#E8E8EF';
  const text = effectiveMode === 'dark' ? '#F4F6FB' : '#17181C';
  const textMuted = effectiveMode === 'dark' ? '#B7BED2' : '#62656E';
  const divider = effectiveMode === 'dark' ? '#2A3142' : '#FFFFFF';
  const primarySoftMix = effectiveMode === 'dark' ? 0.22 : 0.84;
  const secondarySoftMix = effectiveMode === 'dark' ? 0.24 : 0.86;
  const background = mix(backgroundBase, base, rule.backgroundMix);
  const surface = mix(surfaceBase, base, rule.surfaceMix);
  const surfaceStrong = mix(surfaceStrongBase, secondary, rule.surfaceMix + 0.02);
  const primarySoft = mix(base, '#FFFFFF', primarySoftMix);
  const secondarySoft = mix(secondary, '#FFFFFF', secondarySoftMix);
  const heart = base;
  const heartSoft = mix(base, '#FFFFFF', effectiveMode === 'dark' ? 0.32 : 0.54);
  return {
    background: normalizeHex(background),
    surface: normalizeHex(surface),
    surfaceStrong: normalizeHex(surfaceStrong),
    primary: normalizeHex(base),
    primarySoft: normalizeHex(primarySoft),
    secondary: normalizeHex(secondary),
    secondarySoft: normalizeHex(secondarySoft),
    heart: normalizeHex(heart),
    heartSoft: normalizeHex(heartSoft),
    error: effectiveMode === 'dark' ? '#FF6D66' : '#C52A22',
    text: normalizeHex(text),
    textMuted: normalizeHex(textMuted),
    divider: normalizeHex(divider),
    white: '#FFFFFF'
  };
}

function styleRule(style: ThemeStyle): ThemeStyleRule {
  switch (style) {
    case 'soft':
      return new ThemeStyleRule(0.72, 1.05, 0, 0.03, 0.06, 18);
    case 'vivid':
      return new ThemeStyleRule(1.14, 1.08, 0, 0.02, 0.05, 28);
    case 'neutral':
      return new ThemeStyleRule(0.68, 0.98, -4, 0.03, 0.06, 12);
    case 'monochrome':
      return new ThemeStyleRule(0.24, 1.0, 0, 0.018, 0.045, 0);
    case 'fidelity':
      return new ThemeStyleRule(0.92, 1.0, 0, 0.022, 0.05, 22);
    case 'content':
      return new ThemeStyleRule(0.82, 0.99, -2, 0.028, 0.05, 16);
    case 'rainbow':
      return new ThemeStyleRule(1.0, 1.04, 26, 0.02, 0.05, 78);
    case 'fruit':
      return new ThemeStyleRule(0.94, 1.08, 42, 0.02, 0.05, 58);
    case 'expressive':
    default:
      return new ThemeStyleRule(0.98, 1.02, 0, 0.025, 0.05, 24);
  }
}

function normalizeHex(value: string): string {
  if (!value || value.length === 0) {
    return '#000000';
  }
  let hex = value.trim();
  if (!hex.startsWith('#')) {
    hex = '#' + hex;
  }
  if (hex.length === 4) {
    const r = hex.charAt(1);
    const g = hex.charAt(2);
    const b = hex.charAt(3);
    return '#' + r + r + g + g + b + b;
  }
  return hex.substring(0, 7).toUpperCase();
}

function mix(a: string, b: string, ratio: number): string {
  const left = hexToRgb(a);
  const right = hexToRgb(b);
  const weight = clamp(ratio, 0, 1);
  const red = Math.round(left.r * (1 - weight) + right.r * weight);
  const green = Math.round(left.g * (1 - weight) + right.g * weight);
  const blue = Math.round(left.b * (1 - weight) + right.b * weight);
  return rgbToHex(red, green, blue);
}

function adjustColor(color: string, hueShift: number, saturationFactor: number, brightnessFactor: number): string {
  const hsv = rgbToHsv(hexToRgb(color));
  const adjusted = new HsvColor((hsv.h + hueShift + 360) % 360, clamp(hsv.s * saturationFactor, 0, 1),
    clamp(hsv.v * brightnessFactor, 0, 1));
  return rgbToHexFromHsv(adjusted.h, adjusted.s, adjusted.v);
}

function hexToRgb(hex: string): RgbColor {
  const normalized = normalizeHex(hex).substring(1);
  return new RgbColor(parseInt(normalized.substring(0, 2), 16), parseInt(normalized.substring(2, 4), 16),
    parseInt(normalized.substring(4, 6), 16));
}

function rgbToHex(r: number, g: number, b: number): string {
  return '#' + toHex(r) + toHex(g) + toHex(b);
}

function toHex(value: number): string {
  const hex = clamp(Math.round(value), 0, 255).toString(16);
  return hex.length === 1 ? '0' + hex : hex;
}

function rgbToHsv(rgb: RgbColor): HsvColor {
  const r = rgb.r / 255;
  const g = rgb.g / 255;
  const b = rgb.b / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;
  let h = 0;
  if (delta > 0) {
    if (max === r) {
      h = 60 * (((g - b) / delta) % 6);
    } else if (max === g) {
      h = 60 * (((b - r) / delta) + 2);
    } else {
      h = 60 * (((r - g) / delta) + 4);
    }
  }
  if (h < 0) {
    h += 360;
  }
  const s = max === 0 ? 0 : delta / max;
  return new HsvColor(h, s, max);
}

function rgbToHexFromHsv(h: number, s: number, v: number): string {
  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;
  let r = 0;
  let g = 0;
  let b = 0;
  if (h < 60) {
    r = c; g = x; b = 0;
  } else if (h < 120) {
    r = x; g = c; b = 0;
  } else if (h < 180) {
    r = 0; g = c; b = x;
  } else if (h < 240) {
    r = 0; g = x; b = c;
  } else if (h < 300) {
    r = x; g = 0; b = c;
  } else {
    r = c; g = 0; b = x;
  }
  return rgbToHex((r + m) * 255, (g + m) * 255, (b + m) * 255);
}

function luminance(hex: string): number {
  const rgb = hexToRgb(hex);
  const r = channel(rgb.r);
  const g = channel(rgb.g);
  const b = channel(rgb.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function channel(value: number): number {
  const normalized = value / 255;
  return normalized <= 0.03928 ? normalized / 12.92 : Math.pow((normalized + 0.055) / 1.055, 2.4);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

