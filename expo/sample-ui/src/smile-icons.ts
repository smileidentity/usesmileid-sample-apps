// Smile ID icons — GENERATED from design/icons/*.svg. Do not edit by hand.
//
// Regenerate with: scripts/generate_expo_icons.py
//
// The path data is carried through verbatim: react-native-svg draws an SVG path directly, so unlike
// the SwiftUI emitter nothing here re-parses one. Each mark keeps its own viewBox and says whether
// its subpaths are stroked or filled, because the design's set is strokes and the Material Symbols
// stand-ins are fills.

/// How one subpath of a mark is painted. The caller supplies the colour; the mark supplies the rest.
export type SmileIconPaint =
  | { readonly kind: 'fill' }
  | { readonly kind: 'stroke'; readonly width: number; readonly round: boolean };

/// One subpath: its path data, how it is painted, and the opacity it inherited from the record.
export type SmileIconPart = {
  readonly d: string;
  readonly paint: SmileIconPaint;
  readonly opacity: number;
};

/// One mark in its own coordinate space, which the renderer maps onto the size a caller asks for.
export type SmileIcon = {
  readonly minX: number;
  readonly minY: number;
  readonly width: number;
  readonly height: number;
  readonly parts: readonly SmileIconPart[];
};

/** Every mark in `design/icons/`, keyed by its file name in camelCase. */
export const smileIcons = {
  agent: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M7.125 8.86667C8.52412 8.86667 9.65833 7.73245 9.65833 6.33333C9.65833 4.93421 8.52412 3.8 7.125 3.8C5.72588 3.8 4.59167 4.93421 4.59167 6.33333C4.59167 7.73245 5.72588 8.86667 7.125 8.86667Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M2.77083 15.0417C3.24583 12.6667 4.9875 11.4 7.125 11.4C7.91667 11.4 8.62917 11.5583 9.2625 11.875", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M11.875 12.6667L13.4583 14.25L16.625 11.0833", paint: { kind: 'stroke', width: 1.58333, round: true }, opacity: 1 },
    ],
  },
  arrowBack: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M13.4583 8.5H3.54163M7.79163 12.75L3.54163 8.5L7.79163 4.25", paint: { kind: 'stroke', width: 1.5, round: true }, opacity: 1 },
    ],
  },
  arrowForward: {
    minX: 0,
    minY: 0,
    width: 9,
    height: 9,
    parts: [
      { d: "M5.66542e-05 4.99203V3.88803H6.69606L3.34806 0.76803L4.10406 2.95639e-05L8.40006 4.09203V4.75203L4.10406 8.85603L3.34806 8.08803L6.67206 4.99203H5.66542e-05Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  biometricKyc: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M16.625 3.5H4.375C3.4085 3.5 2.625 4.2835 2.625 5.25V15.75C2.625 16.7165 3.4085 17.5 4.375 17.5H16.625C17.5915 17.5 18.375 16.7165 18.375 15.75V5.25C18.375 4.2835 17.5915 3.5 16.625 3.5Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M7.43745 10.675C8.5006 10.675 9.36245 9.8131 9.36245 8.74995C9.36245 7.6868 8.5006 6.82495 7.43745 6.82495C6.3743 6.82495 5.51245 7.6868 5.51245 8.74995C5.51245 9.8131 6.3743 10.675 7.43745 10.675Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M4.375 14C4.9 12.425 6.125 11.8125 7.4375 11.8125C8.75 11.8125 9.975 12.425 10.5 14M12.25 7.875H16.625M12.25 11.375H16.625", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
    ],
  },
  check: {
    minX: 0,
    minY: -960,
    width: 960,
    height: 960,
    parts: [
      { d: "M382-240 154-468l57-57 171 171 367-367 57 57-424 424Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  chevron: {
    minX: 0,
    minY: 0,
    width: 14,
    height: 14,
    parts: [
      { d: "M5.25 3.5L8.75 7L5.25 10.5", paint: { kind: 'stroke', width: 1.16667, round: true }, opacity: 1 },
    ],
  },
  chevronDown: {
    minX: 0,
    minY: 0,
    width: 12,
    height: 12,
    parts: [
      { d: "M2 4L6 8L10 4", paint: { kind: 'stroke', width: 2, round: true }, opacity: 1 },
    ],
  },
  consent: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M14.25 2.375H4.75C3.87555 2.375 3.16667 3.08388 3.16667 3.95833V15.0417C3.16667 15.9161 3.87555 16.625 4.75 16.625H14.25C15.1245 16.625 15.8333 15.9161 15.8333 15.0417V3.95833C15.8333 3.08388 15.1245 2.375 14.25 2.375Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M7.125 9.5L8.70833 11.0833L11.875 7.91667", paint: { kind: 'stroke', width: 1.58333, round: true }, opacity: 1 },
    ],
  },
  copy: {
    minX: 0,
    minY: -960,
    width: 960,
    height: 960,
    parts: [
      { d: "M360-240q-33 0-56.5-23.5T280-320v-480q0-33 23.5-56.5T360-880h360q33 0 56.5 23.5T800-800v480q0 33-23.5 56.5T720-240H360Zm0-80h360v-480H360v480ZM200-80q-33 0-56.5-23.5T120-160v-560h80v560h440v80H200Zm160-240v-480 480Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  darkMode: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M9.5 12.6667C11.2489 12.6667 12.6667 11.2489 12.6667 9.5C12.6667 7.7511 11.2489 6.33333 9.5 6.33333C7.7511 6.33333 6.33333 7.7511 6.33333 9.5C6.33333 11.2489 7.7511 12.6667 9.5 12.6667Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M9.5 1.58333V3.16667M9.5 15.8333V17.4167M1.58333 9.5H3.16667M15.8333 9.5H17.4167M3.95833 3.95833L5.14583 5.14583M13.8542 13.8542L15.0417 15.0417M15.0417 3.95833L13.8542 5.14583M5.14583 13.8542L3.95833 15.0417", paint: { kind: 'stroke', width: 1.58333, round: true }, opacity: 1 },
    ],
  },
  docs: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M3.16667 3.16667H11.875L15.8333 7.125V15.8333H3.16667V3.16667Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M6.33333 9.5H12.6667M6.33333 12.6667H10.2917", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  documentVerification: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M15.75 2.625H5.25C4.2835 2.625 3.5 3.4085 3.5 4.375V16.625C3.5 17.5915 4.2835 18.375 5.25 18.375H15.75C16.7165 18.375 17.5 17.5915 17.5 16.625V4.375C17.5 3.4085 16.7165 2.625 15.75 2.625Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M7 7H14M7 10.5H14M7 14H11.375", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
    ],
  },
  enhancedKyc: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M16.625 3.5H4.375C3.4085 3.5 2.625 4.2835 2.625 5.25V15.75C2.625 16.7165 3.4085 17.5 4.375 17.5H16.625C17.5915 17.5 18.375 16.7165 18.375 15.75V5.25C18.375 4.2835 17.5915 3.5 16.625 3.5Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M5.5125 7H15.4875M5.5125 10.5H15.4875M5.5125 14H11.8125", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
    ],
  },
  fieldEmail: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M13.4583 3.54167H3.54167C2.75926 3.54167 2.125 4.17593 2.125 4.95833V12.0417C2.125 12.8241 2.75926 13.4583 3.54167 13.4583H13.4583C14.2407 13.4583 14.875 12.8241 14.875 12.0417V4.95833C14.875 4.17593 14.2407 3.54167 13.4583 3.54167Z", paint: { kind: 'stroke', width: 1.41667, round: false }, opacity: 1 },
      { d: "M2.125 4.95833L8.5 9.20833L14.875 4.95833", paint: { kind: 'stroke', width: 1.41667, round: false }, opacity: 1 },
    ],
  },
  fieldPerson: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M8.5 8.14583C9.86921 8.14583 10.9792 7.03587 10.9792 5.66667C10.9792 4.29746 9.86921 3.1875 8.5 3.1875C7.13079 3.1875 6.02083 4.29746 6.02083 5.66667C6.02083 7.03587 7.13079 8.14583 8.5 8.14583Z", paint: { kind: 'stroke', width: 1.41667, round: false }, opacity: 1 },
      { d: "M3.54167 14.1667C4.10833 11.6167 6.02083 10.2708 8.5 10.2708C10.9792 10.2708 12.8917 11.6167 13.4583 14.1667", paint: { kind: 'stroke', width: 1.41667, round: false }, opacity: 1 },
    ],
  },
  fieldPhone: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M10.625 1.41667H6.375C5.5926 1.41667 4.95833 2.05093 4.95833 2.83333V14.1667C4.95833 14.9491 5.5926 15.5833 6.375 15.5833H10.625C11.4074 15.5833 12.0417 14.9491 12.0417 14.1667V2.83333C12.0417 2.05093 11.4074 1.41667 10.625 1.41667Z", paint: { kind: 'stroke', width: 1.41667, round: false }, opacity: 1 },
      { d: "M7.79167 12.75H9.20833", paint: { kind: 'stroke', width: 1.41667, round: true }, opacity: 1 },
    ],
  },
  flash: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M6.375,1.41667H10.625L9.91667,6.375H12.0417L6.375,15.5833L7.79167,9.20833H4.25L6.375,1.41667Z", paint: { kind: 'stroke', width: 1.5, round: false }, opacity: 1 },
    ],
  },
  instructions: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M9.5 16.625C13.435 16.625 16.625 13.435 16.625 9.5C16.625 5.56497 13.435 2.375 9.5 2.375C5.56497 2.375 2.375 5.56497 2.375 9.5C2.375 13.435 5.56497 16.625 9.5 16.625Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M9.5 6.33333H9.50792M9.5 8.70833V12.6667", paint: { kind: 'stroke', width: 1.58333, round: true }, opacity: 1 },
    ],
  },
  licenses: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M6.33333 2.375H3.95833C3.53841 2.375 3.13568 2.54181 2.83875 2.83875C2.54181 3.13568 2.375 3.53841 2.375 3.95833V6.33333M12.6667 2.375H15.0417C15.4616 2.375 15.8643 2.54181 16.1613 2.83875C16.4582 3.13568 16.625 3.53841 16.625 3.95833V6.33333M6.33333 16.625H3.95833C3.53841 16.625 3.13568 16.4582 2.83875 16.1613C2.54181 15.8643 2.375 15.4616 2.375 15.0417V12.6667M12.6667 16.625H15.0417C15.4616 16.625 15.8643 16.4582 16.1613 16.1613C16.4582 15.8643 16.625 15.4616 16.625 15.0417V12.6667", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  plus: {
    minX: 0,
    minY: -960,
    width: 960,
    height: 960,
    parts: [
      { d: "M440-440H200v-80h240v-240h80v240h240v80H520v240h-80v-240Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  preview: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M15.0417 3.95833H3.95833C3.08388 3.95833 2.375 4.66722 2.375 5.54167V13.4583C2.375 14.3328 3.08388 15.0417 3.95833 15.0417H15.0417C15.9161 15.0417 16.625 14.3328 16.625 13.4583V5.54167C16.625 4.66722 15.9161 3.95833 15.0417 3.95833Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M9.5 11.875C10.8117 11.875 11.875 10.8117 11.875 9.5C11.875 8.18832 10.8117 7.125 9.5 7.125C8.18832 7.125 7.125 8.18832 7.125 9.5C7.125 10.8117 8.18832 11.875 9.5 11.875Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  privacy: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M9.5 2.375L15.0417 4.75V9.5C15.0417 12.6667 12.6667 15.0417 9.5 16.625C6.33333 15.0417 3.95833 12.6667 3.95833 9.5V4.75L9.5 2.375Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  productMark: {
    minX: 0,
    minY: -960,
    width: 960,
    height: 960,
    parts: [
      { d: "M160-80q-33 0-56.5-23.5T80-160v-440q0-33 23.5-56.5T160-680h200v-120q0-33 23.5-56.5T440-880h80q33 0 56.5 23.5T600-800v120h200q33 0 56.5 23.5T880-600v440q0 33-23.5 56.5T800-80H160Zm0-80h640v-440H600q0 33-23.5 56.5T520-520h-80q-33 0-56.5-23.5T360-600H160v440Zm80-80h240v-18q0-17-9.5-31.5T444-312q-20-9-40.5-13.5T360-330q-23 0-43.5 4.5T276-312q-17 8-26.5 22.5T240-258v18Zm320-60h160v-60H560v60Zm-157.5-77.5Q420-395 420-420t-17.5-42.5Q385-480 360-480t-42.5 17.5Q300-445 300-420t17.5 42.5Q335-360 360-360t42.5-17.5ZM560-420h160v-60H560v60ZM440-600h80v-200h-80v200Zm40 220Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  products: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M2.625 8.75L10.5 2.625L18.375 8.75V16.625C18.375 17.0891 18.1906 17.5342 17.8624 17.8624C17.5342 18.1906 17.0891 18.375 16.625 18.375H13.125V13.125H7.875V18.375H4.375C3.91087 18.375 3.46575 18.1906 3.13756 17.8624C2.80937 17.5342 2.625 17.0891 2.625 16.625V8.75Z", paint: { kind: 'stroke', width: 1.83333, round: false }, opacity: 1 },
    ],
  },
  scanGlyph: {
    minX: 0,
    minY: 0,
    width: 279,
    height: 280,
    parts: [
      { d: "M58.125 140H220.875", paint: { kind: 'stroke', width: 6, round: true }, opacity: 0.45 },
      { d: "M34.875 81.6667V58.3333C34.875 52.1449 37.3245 46.21 41.6848 41.8342C46.045 37.4583 51.9587 35 58.125 35H81.375", paint: { kind: 'stroke', width: 6, round: true }, opacity: 0.45 },
      { d: "M34.875 198.333V221.667C34.875 227.855 37.3245 233.79 41.6848 238.166C46.045 242.542 51.9587 245 58.125 245H81.375", paint: { kind: 'stroke', width: 6, round: true }, opacity: 0.45 },
      { d: "M197.625 35H220.875C227.041 35 232.955 37.4583 237.315 41.8342C241.675 46.21 244.125 52.1449 244.125 58.3333V81.6667", paint: { kind: 'stroke', width: 6, round: true }, opacity: 0.45 },
      { d: "M197.625 245H220.875C227.041 245 232.955 242.542 237.315 238.166C241.675 233.79 244.125 227.855 244.125 221.667V198.333", paint: { kind: 'stroke', width: 6, round: true }, opacity: 0.45 },
    ],
  },
  settingScenarios: {
    minX: 0,
    minY: -960,
    width: 960,
    height: 960,
    parts: [
      { d: "M440-120v-240h80v80h320v80H520v80h-80Zm-320-80v-80h240v80H120Zm160-160v-80H120v-80h160v-80h80v240h-80Zm160-80v-80h400v80H440Zm160-160v-240h80v80h160v80H680v80h-80Zm-480-80v-80h400v80H120Z", paint: { kind: 'fill' }, opacity: 1 },
    ],
  },
  settings: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M10.5 13.125C11.9497 13.125 13.125 11.9497 13.125 10.5C13.125 9.05025 11.9497 7.875 10.5 7.875C9.05025 7.875 7.875 9.05025 7.875 10.5C7.875 11.9497 9.05025 13.125 10.5 13.125Z", paint: { kind: 'stroke', width: 1.83333, round: false }, opacity: 1 },
      { d: "M16.625 10.5C16.6168 10.2066 16.5876 9.91419 16.5375 9.625L18.2875 8.3125L16.5375 5.3375L14.525 6.2125C14.0729 5.85209 13.5721 5.5575 13.0375 5.3375L12.775 3.15H9.1L8.8375 5.3375C8.30286 5.5575 7.80205 5.85209 7.35 6.2125L5.3375 5.3375L3.5875 8.3125L5.25 9.625C5.16624 10.2053 5.16624 10.7947 5.25 11.375L3.5 12.6875L5.25 15.6625L7.2625 14.7875C7.71455 15.1479 8.21536 15.4425 8.75 15.6625L9.0125 17.85H11.8125L12.075 15.6625C12.6096 15.4425 13.1104 15.1479 13.5625 14.7875L15.575 15.6625L17.325 12.6875L15.575 11.375C15.6251 11.0858 15.6543 10.7934 15.6625 10.5H16.625Z", paint: { kind: 'stroke', width: 1.83333, round: false }, opacity: 1 },
    ],
  },
  smartSelfieAuth: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M9.625 16.1875C13.2494 16.1875 16.1875 13.2494 16.1875 9.625C16.1875 6.00063 13.2494 3.0625 9.625 3.0625C6.00063 3.0625 3.0625 6.00063 3.0625 9.625C3.0625 13.2494 6.00063 16.1875 9.625 16.1875Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M7 9.625H7.00875M12.25 9.625H12.2588M7 12.25C8.4 13.475 10.85 13.475 12.25 12.25", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M14.4375 14.875L16.1875 16.625L19.25 13.5625", paint: { kind: 'stroke', width: 2.16667, round: true }, opacity: 1 },
    ],
  },
  smartSelfieEnrollment: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M10.5 16.625C14.366 16.625 17.5 13.491 17.5 9.625C17.5 5.75901 14.366 2.625 10.5 2.625C6.63401 2.625 3.5 5.75901 3.5 9.625C3.5 13.491 6.63401 16.625 10.5 16.625Z", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M7.875 9.625H7.88375M13.125 9.625H13.1338M7.875 12.6875C9.3625 14 11.6375 14 13.125 12.6875", paint: { kind: 'stroke', width: 2.16667, round: false }, opacity: 1 },
      { d: "M10.5 1.3125V3.9375", paint: { kind: 'stroke', width: 2.16667, round: true }, opacity: 1 },
    ],
  },
  smile: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M9.5 15.0417C12.9978 15.0417 15.8333 12.2061 15.8333 8.70833C15.8333 5.21053 12.9978 2.375 9.5 2.375C6.0022 2.375 3.16667 5.21053 3.16667 8.70833C3.16667 12.2061 6.0022 15.0417 9.5 15.0417Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
      { d: "M7.125 8.70833H7.13292M11.875 8.70833H11.8829M7.125 11.4792C8.47083 12.6667 10.5292 12.6667 11.875 11.4792", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  support: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M3.16667 9.5C3.16667 7.8203 3.83393 6.20939 5.02166 5.02166C6.20939 3.83393 7.8203 3.16667 9.5 3.16667C11.1797 3.16667 12.7906 3.83393 13.9783 5.02166C15.1661 6.20939 15.8333 7.8203 15.8333 9.5C15.8333 11.1797 15.1661 12.7906 13.9783 13.9783C12.7906 15.1661 11.1797 15.8333 9.5 15.8333H3.16667V9.5Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  terms: {
    minX: 0,
    minY: 0,
    width: 19,
    height: 19,
    parts: [
      { d: "M3.95833 2.375H15.0417V16.625L9.5 14.25L3.95833 16.625V2.375Z", paint: { kind: 'stroke', width: 1.58333, round: false }, opacity: 1 },
    ],
  },
  tokenScan: {
    minX: 0,
    minY: 0,
    width: 16,
    height: 16,
    parts: [
      { d: "M2.66667 5.33333V4C2.66667 3.64638 2.80714 3.30724 3.05719 3.05719C3.30724 2.80714 3.64638 2.66667 4 2.66667H5.33333M10.6667 2.66667H12C12.3536 2.66667 12.6928 2.80714 12.9428 3.05719C13.1929 3.30724 13.3333 3.64638 13.3333 4V5.33333M13.3333 10.6667V12C13.3333 12.3536 13.1929 12.6928 12.9428 12.9428C12.6928 13.1929 12.3536 13.3333 12 13.3333H10.6667M5.33333 13.3333H4C3.64638 13.3333 3.30724 13.1929 3.05719 12.9428C2.80714 12.6928 2.66667 12.3536 2.66667 12V10.6667", paint: { kind: 'stroke', width: 1.83333, round: true }, opacity: 1 },
      { d: "M2.66667 8H13.3333", paint: { kind: 'stroke', width: 1.83333, round: true }, opacity: 1 },
    ],
  },
  trash: {
    minX: 0,
    minY: 0,
    width: 17,
    height: 17,
    parts: [
      { d: "M2.83333,4.95833H14.1667M6.375,4.95833V3.54167C6.375,3.3538 6.44963,3.17364 6.58247,3.0408C6.7153,2.90796 6.89547,2.83333 7.08333,2.83333H9.91667C10.1045,2.83333 10.2847,2.90796 10.4175,3.0408C10.5504,3.17364 10.625,3.3538 10.625,3.54167V4.95833M4.25,4.95833L4.95833,14.1667C4.95833,14.3545 5.03296,14.5347 5.1658,14.6675C5.29864,14.8004 5.4788,14.875 5.66667,14.875H11.3333C11.5212,14.875 11.7014,14.8004 11.8342,14.6675C11.967,14.5347 12.0417,14.3545 12.0417,14.1667L12.75,4.95833", paint: { kind: 'stroke', width: 1.5, round: false }, opacity: 1 },
    ],
  },
  verifications: {
    minX: 0,
    minY: 0,
    width: 21,
    height: 21,
    parts: [
      { d: "M7.875 5.25H17.5M7.875 10.5H17.5M7.875 15.75H17.5", paint: { kind: 'stroke', width: 1.83333, round: true }, opacity: 1 },
      { d: "M3.0625 5.25L3.9375 6.125L5.25 4.375M3.0625 10.5L3.9375 11.375L5.25 9.625M3.0625 15.75L3.9375 16.625L5.25 14.875", paint: { kind: 'stroke', width: 1.83333, round: true }, opacity: 1 },
    ],
  },
} as const satisfies Readonly<Record<string, SmileIcon>>;

/** A mark's name, so a caller cannot ask for one the record does not hold. */
export type SmileIconName = keyof typeof smileIcons;
