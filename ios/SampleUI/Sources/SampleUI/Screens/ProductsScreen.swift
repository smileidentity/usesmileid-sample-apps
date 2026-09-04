import SwiftUI

/// What the products header and session strip render, so the screen stays free of clock and store.
public struct UseSmileIDSampleProductsState: Equatable {
  public var initials: String
  /// The active profile's avatar hue, so every screen showing it agrees.
  public var avatarColor: Color
  public var sessionId: String?
  public var sessionRemaining: String?
  public var sessionEnded: Bool
  /// Shown as the compact line only while a run is in flight.
  public var result: UseSmileIDSampleResult?

  public init(
    initials: String,
    avatarColor: Color = smileProfileHues[0],
    sessionId: String? = nil,
    sessionRemaining: String? = nil,
    sessionEnded: Bool = false,
    result: UseSmileIDSampleResult? = nil
  ) {
    self.initials = initials
    self.avatarColor = avatarColor
    self.sessionId = sessionId
    self.sessionRemaining = sessionRemaining
    self.sessionEnded = sessionEnded
    self.result = result
  }
}

/// The products grid, the entry point every flow starts from.
public struct ProductsScreen: View {
  private let state: UseSmileIDSampleProductsState
  private let onProduct: (UseSmileIDSampleProduct) -> Void
  private let onProfile: () -> Void
  private let onScan: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleProductsState,
    onProduct: @escaping (UseSmileIDSampleProduct) -> Void,
    onProfile: @escaping () -> Void,
    onScan: @escaping () -> Void
  ) {
    self.state = state
    self.onProduct = onProduct
    self.onProfile = onProfile
    self.onScan = onScan
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
        header
        if let result = state.result, result.inFlight {
          UseSmileIDSampleResultLine(result: result)
        }
        sessionStrip
        ForEach(UseSmileIDSampleProductSection.allCases, id: \.self) { section in
          VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
            UseSmileIDSampleSectionHeader(section.label)
            grid(for: section)
          }
        }
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
      .padding(.vertical, SmileSpacing.spacingSm)
    }
    .background(colors.background)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.productsScreen)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      HStack(spacing: SmileSpacing.spacingXs) {
        UseSmileIDSampleText("Smile ID", style: pageTitle)
          .foregroundColor(colors.foreground)
          .frame(maxWidth: .infinity, alignment: .leading)
        // The environment chip is hidden here (node 5447:1705); the result card publishes it.
        Button(action: onProfile) {
          UseSmileIDSampleAvatar(initials: state.initials, containerColor: state.avatarColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch profile")
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.profileAvatarButton)
      }
      UseSmileIDSampleText(
        "Try our suite of products powered by our Anti-Fraud SDKs",
        style: UseSmileIDSampleTheme.type.textStyleCaption
      )
      .foregroundColor(colors.foreground)
    }
  }

  @ViewBuilder
  private var sessionStrip: some View {
    if state.sessionEnded {
      UseSmileIDSampleSessionEndedBanner(onScan: onScan)
    } else if let sessionId = state.sessionId, let remaining = state.sessionRemaining {
      UseSmileIDSampleSessionCard(sessionId: sessionId, remaining: remaining)
    }
  }

  private func grid(for section: UseSmileIDSampleProductSection) -> some View {
    let products = UseSmileIDSampleProduct.of(section)
    return UseSmileIDSampleProductGrid(itemCount: products.count) { index in
      let product = products[index]
      UseSmileIDSampleProductCard(
        title: product.cardTitle,
        family: product.cardFamily,
        hue: product.resolvedHue,
        icon: product.icon,
        testId: UseSmileIDSampleTestIds.productCard(product.id),
        action: { onProduct(product) }
      ) { ink in
        UseSmileIDSampleIcon(product.icon, tint: ink, size: Self.ghostSize)
      }
    }
  }

  private var pageTitle: SmileTextStyle {
    UseSmileIDSampleTheme.type.textStyleHeadingPage
      .with(
        size: smileHeadingPageSize,
        tracking: smileHeadingPageTracking,
        weight: smileHeadingPageWeight,
        lineHeight: smileHeadingPageLineHeight
      )
  }

  private static var ghostSize: CGFloat {
    SmileSpacing.space64 + SmileSpacing.space4
  }
}
