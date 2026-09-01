import SampleUI
import SwiftUI

/// Binds a route to its screen; the mapping is the shell's because only it knows the route table.
struct UseSmileIDSampleDestination: View {
  let route: Route

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var inAppLink: UseSmileIDSampleInAppLink?

  var body: some View {
    switch route {
    case .products:
      ProductsScreen(
        state: .init(
          initials: app.initials,
          avatarColor: app.avatarColor,
          sessionId: app.sessionId,
          sessionRemaining: app.sessionRemaining,
          sessionEnded: app.sessionEnded
        ),
        onProduct: { product in router.open(.consentDetailsForm(productId: product.id)) },
        onProfile: { router.sheet = .profileSwitch },
        onScan: { router.open(.scanToken) }
      )
    case .verifications:
      VerificationsScreen()
    case .consentDetailsForm(let productId):
      UserDetailsScreen(
        state: .init(
          productLabel: Self.product(productId)?.label ?? productId,
          details: app.userDetails,
          rememberDetails: app.rememberDetails,
          requirement: app.userDetailsRequirement
        ),
        onFieldChange: { field, value in app.setUserField(field, to: value) },
        onRememberChange: { app.rememberDetails = $0 },
        onBack: { router.pop() },
        onContinue: { router.push(Self.stepAfterUserDetails(productId)) }
      )
      .navigationBarHidden(true)
    case .idDetailsForm(let productId):
      KycIdFormScreen(
        state: .init(productLabel: Self.product(productId)?.label ?? productId, details: app.idDetails),
        onCountryTap: { app.countryQuery = ""
          router.sheet = .countryPicker },
        onIdTypeTap: { app.idTypeQuery = ""
          router.sheet = .idTypePicker },
        onIdNumberChange: { app.idDetails.idNumber = $0 },
        onBack: { router.pop() },
        onContinue: { router.push(.sdkFlow(productId: productId, presentation: .fullscreen)) },
        onToken: { router.open(.scanToken) }
      )
      .navigationBarHidden(true)
    case .verificationDetails(let jobId):
      VerificationDetailsScreen(
        state: .init(jobId: jobId, job: app.jobs?.first { $0.id == jobId }),
        onBack: { router.pop() },
        // The row's removal lands with the store that holds it.
        onDelete: { router.pop() },
        onCopy: { label, value in copy(label, value) }
      )
      .navigationBarHidden(true)
    case .settings:
      browser(SettingsScreen(
        state: .init(
          settings: app.settings,
          organisation: app.organisation,
          initials: app.initials,
          versionLabel: app.versionLabel,
          avatarColor: app.avatarColor
        ),
        onSettingChange: { setting, enabled in app.change(setting, to: enabled) },
        onProfile: { router.open(.profiles) },
        onNavRow: { row in open(row) },
        onOpenScenarioDrawer: { router.sheet = .scenarioDrawer },
        onSignOut: {}
      ))
    default:
      UseSmileIDSampleSeat(name: String(describing: route))
    }
  }

  /// Only document and KYC products collect ID details; the rest go straight to the flow.
  private static func stepAfterUserDetails(_ productId: String) -> Route {
    let needsIdDetails = product(productId)?.needsIdDetails ?? false
    return needsIdDetails ? .idDetailsForm(productId: productId) : .sdkFlow(productId: productId, presentation: .fullscreen)
  }

  private static func product(_ id: String) -> UseSmileIDSampleProduct? {
    UseSmileIDSampleProduct(rawValue: id)
  }

  /// `UIPasteboard` has no clip label, so only the value crosses.
  private func copy(_: String, _ value: String) {
    UIPasteboard.general.string = value
  }

  /// A layer over the screen that opened it, never a destination.
  private func browser(_ content: some View) -> some View {
    content.sheet(item: $inAppLink) { UseSmileIDSampleBrowser(url: $0.url) }
  }

  /// Three destinations, per `spec/screens.json` → linkPresentation: no url is the app's own
  /// screen; `opensInApp` stays in an in-app browser; the two legal pages eject, because both serve
  /// their document as an embedded PDF a mobile browser shows as a stub.
  private func open(_ row: UseSmileIDSampleNavRow) {
    guard let url = row.url else {
      router.open(.licenses)
      return
    }
    if row.opensInApp {
      inAppLink = UseSmileIDSampleInAppLink(url: url)
    } else {
      UIApplication.shared.open(url)
    }
  }
}

/// A named seat for a screen U3 has not built yet.
struct UseSmileIDSampleSeat: View {
  let name: String

  var body: some View {
    Text(name)
  }
}
