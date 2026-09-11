public import UseSmileID
import SwiftUI

/// What a theme scenario hands the SDK's theme builder, field for field.
///
/// Typed in the SDK's own `AdaptiveColor` rather than a parallel colour type, so the shell assigns
/// these straight across and a rename on either side is a compile error rather than a silent drift.
public struct UseSmileIDSampleThemeOverride: Equatable, Sendable {
  public var primaryColor: AdaptiveColor
  public var primaryForeground: AdaptiveColor
  public var secondaryColor: AdaptiveColor
  public var accentColor: AdaptiveColor
  public var buttonShape: CGFloat
  /// A family the app can actually resolve, or the SDK keeps its own.
  public var fontFamily: String?

  public init(
    primaryColor: AdaptiveColor,
    primaryForeground: AdaptiveColor,
    secondaryColor: AdaptiveColor,
    accentColor: AdaptiveColor,
    buttonShape: CGFloat,
    fontFamily: String? = nil
  ) {
    self.primaryColor = primaryColor
    self.primaryForeground = primaryForeground
    self.secondaryColor = secondaryColor
    self.accentColor = accentColor
    self.buttonShape = buttonShape
    self.fontFamily = fontFamily
  }
}

public extension UseSmileIDSampleThemeScenario {
  /// What this scenario overrides, or nil for the shipped branding.
  var override: UseSmileIDSampleThemeOverride? {
    switch self {
    case .brandDefault:
      nil
    case .partnerOverride:
      UseSmileIDSampleThemeOverride(
        primaryColor: AdaptiveColor(light: .indigo, dark: .indigo),
        primaryForeground: AdaptiveColor(light: .white, dark: .white),
        secondaryColor: AdaptiveColor(light: .teal, dark: .teal),
        accentColor: AdaptiveColor(light: .orange, dark: .orange),
        buttonShape: 4
      )
    // Far from the defaults on every axis the override reaches; Courier is a system face, so it always resolves.
    case .clashingHost:
      UseSmileIDSampleThemeOverride(
        primaryColor: AdaptiveColor(light: Color(red: 0.85, green: 0, blue: 0.5), dark: Color(red: 0.85, green: 0, blue: 0.5)),
        primaryForeground: AdaptiveColor(light: .yellow, dark: .yellow),
        secondaryColor: AdaptiveColor(light: Color(red: 0.4, green: 0.8, blue: 0), dark: Color(red: 0.4, green: 0.8, blue: 0)),
        accentColor: AdaptiveColor(light: Color(red: 0.9, green: 0.3, blue: 0), dark: Color(red: 0.9, green: 0.3, blue: 0)),
        buttonShape: 24,
        fontFamily: "Courier New"
      )
    }
  }
}
