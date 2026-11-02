import { render } from "@testing-library/react-native";
import { readFileSync } from "fs";
import { join } from "path";
import { Dimensions, StyleSheet, View } from "react-native";

import {
  smileIDSampleFrameOn,
  smileIDSampleLargeScreen,
  smileIDSampleLargeScreenFrameSize,
  UseSmileIDSampleLargeScreenFrame,
} from "../src/navigation/use-smile-id-sample-large-screen-frame";

/// On a large screen the app draws its own screens in the largest phone's frame, centred; a phone, and the full-screen SDK run, fill the window.
describe("UseSmileIDSampleLargeScreenFrame", () => {
  it("the frames are the spec's", () => {
    const spec = JSON.parse(
      readFileSync(
        join(__dirname, "../../../spec/large-screen-frame.json"),
        "utf8",
      ),
    ) as {
      largeScreenMinSide: number;
      frames: Record<"ios" | "android", { width: number; height: number }>;
    };

    expect(smileIDSampleLargeScreen.minSide).toBe(spec.largeScreenMinSide);
    expect(smileIDSampleLargeScreen.iosFrame).toEqual({
      width: spec.frames.ios.width,
      height: spec.frames.ios.height,
    });
    expect(smileIDSampleLargeScreen.androidFrame).toEqual({
      width: spec.frames.android.width,
      height: spec.frames.android.height,
    });
  });

  for (const platform of ["android", "ios"]) {
    const frame = smileIDSampleFrameOn(platform);
    const frameIn = (width: number, height: number) =>
      smileIDSampleLargeScreenFrameSize(
        { width, height },
        { width, height },
        platform,
      );

    describe(`on ${platform}`, () => {
      it("a large screen draws the app in the largest phone's frame", () => {
        expect(frameIn(800, 1280)).toEqual(frame);
        expect(frameIn(600, 960)).toEqual(frame);
        expect(frameIn(1280, 800)).toEqual({ width: frame.width, height: 800 });
      });

      it("a phone draws the app across its whole window", () => {
        expect(frameIn(frame.width, frame.height)).toBeNull();
        expect(frameIn(frame.height, frame.width)).toBeNull();
        expect(frameIn(599, 1280)).toBeNull();
      });

      it("a side shorter than its frame keeps the safe area's length", () => {
        expect(
          smileIDSampleLargeScreenFrameSize(
            { width: 1280, height: 800 },
            { width: 1280, height: 728 },
            platform,
          ),
        ).toEqual({ width: frame.width, height: 728 });
      });
    });
  }

  /// The style of the view the frame draws the app in, in a window of `width` by `height`.
  const frameStyle = async (width: number, height: number, framed = true) => {
    Dimensions.set({
      window: { width, height, scale: 1, fontScale: 1 },
      screen: { width, height, scale: 1, fontScale: 1 },
    });
    const drawn = await render(
      <UseSmileIDSampleLargeScreenFrame framed={framed}>
        <View testID="screen" />
      </UseSmileIDSampleLargeScreenFrame>,
    );
    // The frame's view is the screen's nearest styled ancestor.
    let node = drawn.getByTestId("screen").parent;
    while (node !== null && StyleSheet.flatten(node.props.style) === undefined)
      node = node.parent;
    return StyleSheet.flatten(node?.props.style) as
      Record<string, unknown> | undefined;
  };

  const frame = smileIDSampleFrameOn("ios");

  it("a large screen centres the frame", async () => {
    expect(await frameStyle(800, 1280)).toMatchObject(frame);
  });

  it("the full-screen SDK run fills the window", async () => {
    expect(await frameStyle(800, 1280, false)).toEqual({
      flex: 1,
      alignSelf: "stretch",
    });
  });

  it("a phone fills its window", async () => {
    expect(await frameStyle(frame.width, frame.height)).toEqual({
      flex: 1,
      alignSelf: "stretch",
    });
  });
});
