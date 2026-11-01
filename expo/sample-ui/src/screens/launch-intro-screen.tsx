import { useCallback, useEffect, useRef, useState } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Circle, G, Path, Rect } from 'react-native-svg';

import { UseSmileIDSampleLogo } from '../components/use-smile-id-sample-logo';
import { smileDarkColors } from '../theme/smile-colors';
import { darkColors, tokens } from '../tokens';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// Where every part of the logo is at one instant; `shackleLock` runs from 0, the logo's own open shackle, to 1, seated on the body.
export type LaunchIntroPose = {
  readonly markAlpha: number;
  readonly markScale: number;
  readonly shackleLock: number;
  readonly shackleLift: number;
  readonly clickSquash: number;
  readonly ringProgress: number;
  readonly wordmarkReveal: number;
};

/// The logo as the brand draws it, which is where every intro ends.
export const launchIntroRest: LaunchIntroPose = {
  markAlpha: 1,
  markScale: 1,
  shackleLock: 0,
  shackleLift: 0,
  clickSquash: 0,
  ringProgress: 1,
  wordmarkReveal: 1,
};

/// A CSS cubic-bezier's height where its x reaches `fraction`; x rises monotonically, so bisection always converges.
const cubicBezier =
  (x1: number, y1: number, x2: number, y2: number) =>
  (fraction: number): number => {
    if (fraction <= 0) return 0;
    if (fraction >= 1) return 1;
    const bezier = (first: number, second: number, t: number) =>
      3 * first * (1 - t) * (1 - t) * t + 3 * second * (1 - t) * t * t + t * t * t;
    let low = 0;
    let high = 1;
    let t = fraction;
    for (let step = 0; step < 40; step += 1) {
      if (bezier(x1, x2, t) < fraction) low = t;
      else high = t;
      t = (low + high) / 2;
    }
    return bezier(y1, y2, t);
  };

const fastOutSlowIn = cubicBezier(0.4, 0, 0.2, 1);
const linearOutSlowIn = cubicBezier(0, 0, 0.2, 1);
const linear = (fraction: number) => fraction;

const lerp = (start: number, stop: number, fraction: number) => start + (stop - start) * fraction;

/// A hop's height along its flight: zero on the ground at both ends, never below it.
const arc = (flight: number) => (flight > 0 && flight < 1 ? Math.sin(flight * Math.PI) : 0);

/// A landing's squash, decaying to nothing so the body settles back to its own shape.
const bump = (time: number) => (1 - time) * arc(time);

const DURATION_MILLIS = 2800;

/// How long the intro takes to fade into the app, from the design system's slow duration.
export const SMILE_ID_SAMPLE_LAUNCH_INTRO_FADE_MS = Number.parseFloat(tokens.duration.slow);

const phase = (ms: number, start: number, end: number, easing: (fraction: number) => number) =>
  easing(Math.min(Math.max((ms - start) / (end - start), 0), 1));

/// The intro's choreography in milliseconds, as a pure function of progress so goldens can stop it on any frame.
export const LaunchIntroTimeline = {
  DURATION_MILLIS,

  /// The logo drawn in full size, its shackle still in the brand's open position.
  APPEARED: 500 / DURATION_MILLIS,

  /// The shackle seated on the body, with the name part-way out.
  LOCKED: 1150 / DURATION_MILLIS,

  pose(progress: number): LaunchIntroPose {
    const ms = Math.min(Math.max(progress, 0), 1) * DURATION_MILLIS;
    const lock = phase(ms, 600, 1000, fastOutSlowIn);
    const unlock = phase(ms, 1300, 1700, fastOutSlowIn);
    return {
      markAlpha: phase(ms, 0, 350, linearOutSlowIn),
      markScale: lerp(MARK_START_SCALE, 1, phase(ms, 0, 450, fastOutSlowIn)),
      shackleLock: lock * (1 - unlock),
      shackleLift: HOP_HEIGHT * (arc(lock) + arc(unlock)),
      clickSquash: bump(phase(ms, 1000, 1250, linear)) + UNLOCK_CLICK_STRENGTH * bump(phase(ms, 1700, 1950, linear)),
      ringProgress: phase(ms, 1000, 1500, linearOutSlowIn),
      wordmarkReveal: phase(ms, 350, 1600, linearOutSlowIn),
    };
  },
} as const;

const MARK_START_SCALE = 0.85;
const HOP_HEIGHT = 1.6;
const UNLOCK_CLICK_STRENGTH = 0.6;
const LOGO_WIDTH_FRACTION = 0.62;
const SQUASH_Y = 0.14;
const SQUASH_X = 0.07;
const RING_START_RADIUS = 4;
const RING_END_RADIUS = 9;
const RING_STROKE = 0.16;
const RING_ALPHA = 0.45;
const WORDMARK_SLIDE = 2;
const CLIP_BLEED = 0.5;

/// A scale about `pivot` rather than the origin, as an SVG transform list.
const scaleAbout = (x: number, y: number, pivot: { x: number; y: number }) =>
  `translate(${pivot.x} ${pivot.y}) scale(${x} ${y}) translate(${-pivot.x} ${-pivot.y})`;

type FrameProps = {
  /// From 0, an empty screen, to 1, the logo at rest.
  progress: number;
  /// The screen the logo is centred in.
  size: { readonly width: number; readonly height: number };
  style?: StyleProp<ViewStyle>;
};

/// One frame of the intro, always on the dark scheme whatever the app's.
export const LaunchIntroFrame = ({ progress, size, style }: FrameProps) => {
  const strings = useSmileIDSampleStrings();
  const ink = smileDarkColors.textTitle;
  const accent = darkColors.color.decorative.orange;
  const pose = LaunchIntroTimeline.pose(progress);
  const logo = UseSmileIDSampleLogo;
  const logoWidth = logo.bounds.right - logo.bounds.left;
  const logoScale = (size.width * LOGO_WIDTH_FRACTION) / logoWidth;
  // Centres what is visible so far, so the name pushes the lock aside as it unrolls.
  const visibleRight = lerp(logo.markBounds.right, logo.bounds.right, pose.wordmarkReveal);
  const focusX = (logo.markBounds.left + visibleRight) / 2;
  const focusY = (logo.bounds.top + logo.bounds.bottom) / 2;
  const markCenter = {
    x: (logo.markBounds.left + logo.markBounds.right) / 2,
    y: (logo.markBounds.top + logo.markBounds.bottom) / 2,
  };
  const bodyScaleY = 1 - SQUASH_Y * pose.clickSquash;
  const bodyScaleX = 1 + SQUASH_X * pose.clickSquash;
  // The shackle rides the body's top edge, so it sinks with the squash instead of floating above it.
  const seatDrop = (logo.bodyBase.y - logo.BODY_TOP) * (1 - bodyScaleY);
  const ringRadius = lerp(RING_START_RADIUS, RING_END_RADIUS, pose.ringProgress);
  const revealStart = logo.wordmarkBounds.left - CLIP_BLEED;
  const revealEdge = lerp(revealStart, logo.wordmarkBounds.right + CLIP_BLEED, pose.wordmarkReveal);

  return (
    <View
      style={[styles.frame, { backgroundColor: smileDarkColors.background }, style]}
      accessible
      accessibilityRole="image"
      accessibilityLabel={strings.launchIntroLabel}
    >
      {size.width > 0 && (
        <Svg width={size.width} height={size.height}>
          <G
            transform={`translate(${size.width / 2 - focusX * logoScale} ${size.height / 2 - focusY * logoScale}) scale(${logoScale})`}
          >
            {pose.wordmarkReveal > 0 && (
              <G transform={`translate(${-WORDMARK_SLIDE * (1 - pose.wordmarkReveal)} 0)`}>
                <Path d={logo.WORDMARK} fill={ink} />
              </G>
            )}
            {pose.wordmarkReveal < 1 && (
              // The name is covered either side of what has unrolled, in the backdrop's own colour, which reads as a clip on a solid screen.
              <G>
                <Rect
                  x={revealStart - WORDMARK_SLIDE}
                  y={logo.bounds.top - CLIP_BLEED}
                  width={WORDMARK_SLIDE}
                  height={logo.bounds.bottom - logo.bounds.top + CLIP_BLEED * 2}
                  fill={smileDarkColors.background}
                />
                <Rect
                  x={revealEdge}
                  y={logo.bounds.top - CLIP_BLEED}
                  width={logo.wordmarkBounds.right + CLIP_BLEED - revealEdge + WORDMARK_SLIDE}
                  height={logo.bounds.bottom - logo.bounds.top + CLIP_BLEED * 2}
                  fill={smileDarkColors.background}
                />
              </G>
            )}
            <G transform={scaleAbout(pose.markScale, pose.markScale, markCenter)}>
              {pose.ringProgress > 0 && pose.ringProgress < 1 && (
                <Circle
                  cx={logo.bodyBase.x}
                  cy={markCenter.y}
                  r={ringRadius}
                  stroke={accent}
                  strokeOpacity={(1 - pose.ringProgress) * RING_ALPHA}
                  strokeWidth={RING_STROKE}
                  fill="none"
                />
              )}
              <G transform={scaleAbout(bodyScaleX, bodyScaleY, logo.bodyBase)}>
                <Path d={logo.BODY} fill={ink} fillOpacity={pose.markAlpha} />
              </G>
              <G transform={`translate(${logo.LOCKED_SHACKLE_SHIFT * pose.shackleLock} ${seatDrop - pose.shackleLift})`}>
                <Path d={logo.SHACKLE} fill={accent} fillOpacity={pose.markAlpha} />
              </G>
            </G>
          </G>
        </Svg>
      )}
    </View>
  );
};

type ScreenProps = {
  /// Runs once, when the intro ends or is tapped away.
  onFinished: () => void;
  style?: StyleProp<ViewStyle>;
};

/// The cold-start intro: "SmileID" unrolls out of the logo's lock, which shuts and opens again on the way; a tap skips to `onFinished`.
export const LaunchIntroScreen = ({ onFinished, style }: ScreenProps) => {
  const [progress, setProgress] = useState(0);
  const size = useWindowDimensions();
  const finished = useRef(false);
  const onFinishedRef = useRef(onFinished);
  useEffect(() => {
    onFinishedRef.current = onFinished;
  }, [onFinished]);

  const finish = useCallback(() => {
    if (finished.current) return;
    finished.current = true;
    onFinishedRef.current();
  }, []);

  useEffect(() => {
    let frame = 0;
    let start: number | null = null;
    const tick = (now: number) => {
      start ??= now;
      const next = Math.min((now - start) / DURATION_MILLIS, 1);
      setProgress(next);
      if (next < 1) {
        frame = requestAnimationFrame(tick);
      } else {
        finish();
      }
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [finish]);

  return (
    <Pressable style={[StyleSheet.absoluteFill, style]} onPress={finish}>
      <LaunchIntroFrame progress={progress} size={size} style={StyleSheet.absoluteFill} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  frame: { flex: 1 },
});
