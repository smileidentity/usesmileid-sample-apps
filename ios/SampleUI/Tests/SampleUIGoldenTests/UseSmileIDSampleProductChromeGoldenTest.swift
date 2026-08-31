@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleProductChromeGoldenTest: UseSmileIDSampleGoldenTest {
  func testProductGrid() {
    goldens("product_grid") { Grid() }
  }

  func testProductGridSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { Grid() }
  }

  func testDisabledProductCard() {
    goldens("product_card_disabled") { DisabledCard() }
  }

  func testSectionHeaderAndEnvChip() {
    goldens("section_header_and_env_chip") { HeaderAndChip() }
  }

  func testNavBar() {
    goldens("nav_bar") { NavBars() }
  }
}

private struct Grid: View {
  var body: some View {
    UseSmileIDSampleProductGrid(itemCount: UseSmileIDSampleProduct.allCases.count) { index in
      let product = UseSmileIDSampleProduct.allCases[index]
      UseSmileIDSampleProductCard(
        title: product.cardTitle,
        family: product.cardFamily,
        hue: product.hue!,
        icon: product.icon,
        action: {}
      ) { ink in
        UseSmileIDSampleIcon(product.icon, tint: ink, size: 96)
      }
    }
  }
}

private struct DisabledCard: View {
  var body: some View {
    UseSmileIDSampleProductCard(
      title: UseSmileIDSampleProduct.enhancedKyc.cardTitle,
      family: UseSmileIDSampleProduct.enhancedKyc.cardFamily,
      hue: UseSmileIDSampleProduct.enhancedKyc.hue!,
      icon: UseSmileIDSampleProduct.enhancedKyc.icon,
      enabled: false,
      action: {}
    )
    .frame(width: 190)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct HeaderAndChip: View {
  var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleSectionHeader("Authentication")
      UseSmileIDSampleSectionHeader("Onboarding")
      HStack(spacing: SmileSpacing.spacingXs) {
        UseSmileIDSampleProfileEnvChip(environment: .sandbox)
        UseSmileIDSampleProfileEnvChip(environment: .production)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct NavBars: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleNavBar(selected: .products, onSelect: { _ in }, onToken: {})
      UseSmileIDSampleNavBar(selected: .verifications, sessionProgress: 0.62, onSelect: { _ in }, onToken: {})
    }
  }
}
