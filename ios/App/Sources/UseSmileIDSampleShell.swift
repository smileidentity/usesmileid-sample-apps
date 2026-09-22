import SampleUI
import SwiftUI

/// The window's root. Everything identity-bound stays here — `SampleUI` runs under eight identities.
struct UseSmileIDSampleShell: View {
  @StateObject private var router = UseSmileIDSampleRouter()
  @StateObject private var app = UseSmileIDSampleAppState()

  /// One value, so the tab and its stacks cannot restore out of step.
  @SceneStorage("navigation") private var storedNavigation: String = ""

  /// Consumed on sight and never saved, so a confirmation already spent cannot come back with you.
  @State private var removalNotice: UseSmileIDSampleTransientNotice?

  /// Never in scene storage: a restored flag would swallow the run the launch asked for.
  @State private var autostarted = false

  var body: some View {
    // One tab mounted at a time: a hidden stack still answers id queries, and no modifier suppresses that.
    UseSmileIDSampleStack(tab: router.selectedTab) { bottomChrome }
      .environmentObject(router)
      .environmentObject(app)
      .modifier(UseSmileIDSampleShellEnvironment(app: app))
      // At the root, over whichever route is showing; a link opens the owner first, so it layers.
      .sheet(item: $router.sheet) { sheet in
        // A sheet is its own presentation and inherits none of the environment set above it.
        sheetContent(sheet).modifier(UseSmileIDSampleShellEnvironment(app: app))
      }
      .onOpenURL { url in
        guard let link = UseSmileIDSampleLinks.resolve(url) else { return }
        switch link {
        case .route(let route):
          router.open(route)
        case .sheet(let sheet, let owner):
          router.open(owner)
          router.sheet = sheet
        }
      }
      // On dismissal, not on open: the one point every path goes through, including a swipe.
      .onChange(of: router.sheet) { sheet in
        if sheet == nil {
          app.clearSheetState()
        }
      }
      .onAppear { router.restore(from: storedNavigation)
        autostart() }
      .onChange(of: app.lastJobRemoval) { count in showRemoval(count) }
      .onChange(of: router.selectedTab) { _ in
        storedNavigation = router.encodedState()
        // Select mode and its confirmation belong to the list, so neither follows you to another tab.
        app.verifications.changeSelectMode(false)
        removalNotice = nil
      }
      .onChange(of: router.paths) { _ in storedNavigation = router.encodedState() }
      // Debug only: shake to read the app's own traffic.
      .modifier(UseSmileIDSampleLoupeAccess())
  }

  @ViewBuilder
  private func sheetContent(_ sheet: Sheet) -> some View {
    switch sheet {
    case .countryPicker:
      CountryPickerSheet(
        selected: app.idDetails.country,
        query: $app.countryQuery,
        onSelect: { app.selectCountry($0)
          router.sheet = nil },
        onClose: { router.sheet = nil }
      )
    case .idTypePicker:
      IdTypePickerSheet(
        country: app.idDetails.country,
        selected: app.idDetails.idType,
        query: $app.idTypeQuery,
        onSelect: { app.idDetails.idType = $0
          router.sheet = nil },
        onClose: { router.sheet = nil }
      )
    case .profileSwitch:
      ProfileSwitchSheet(
        profiles: app.profiles.all,
        activeId: app.profiles.activeId,
        onSelect: { app.profiles.setActive($0.id)
          router.sheet = nil }
      )
    case .newProfile:
      NewProfileSheet(
        draft: $app.newProfile,
        onSave: { app.createProfile()
          router.sheet = nil }
      )
    case .scenarioDrawer:
      // App-level, not sheet-local: the result card reports the same selection.
      ScenarioDrawerSheet(
        activeScenario: app.flowResult.scenario,
        activeTheme: app.flowResult.theme,
        onScenarioSelect: { app.flowResult.selectScenario($0) },
        onThemeSelect: { app.flowResult.selectTheme($0) }
      )
    }
  }

  /// Select mode replaces the pill with the selection bar; the confirmation sits above whichever shows.
  private var bottomChrome: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleTransientNoticeHost(
        notice: router.selectedTab == .verifications ? removalNotice : nil,
        onAction: { app.undoJobRemoval() },
        onDismiss: { removalNotice = nil }
      )
      .padding(.horizontal, SmileSpacing.spacingMd)
      if app.verifications.selectMode {
        UseSmileIDSampleSelectionBar(
          selectedCount: app.verifications.selected.count,
          onRemove: { app.removeJobs(app.verifications.selected) }
        )
      } else {
        navBar
      }
    }
  }

  /// The same copy on every platform: the rows are hidden from this app's list, not deleted.
  private func showRemoval(_ count: Int?) {
    guard let count else { return }
    app.clearLastJobRemoval()
    removalNotice = UseSmileIDSampleTransientNotice(
      message: count == 1
        ? "1 verification hidden from App list"
        : "\(count) verifications hidden from App list",
      actionLabel: "Undo"
    )
  }

  /// The design's floating pill, ruled over `TabView`; it sits inside the host, so a push covers it.
  private var navBar: some View {
    UseSmileIDSampleNavBar(
      selected: router.selectedTab.navItem,
      sessionProgress: app.sessionProgress,
      onSelect: { select(UseSmileIDSampleTab($0)) },
      onToken: { router.pushOnce(.scanToken) }
    )
  }

  /// Lands on the flow route after the restore, so the argument wins over what the last scene left.
  private func autostart() {
    guard !autostarted, let product = app.launchArguments.autostart else { return }
    autostarted = true
    router.open(.sdkFlow(productId: product.id, presentation: app.launchArguments.route))
  }

  /// Re-selecting the showing tab pops it to its root, as the platform does.
  private func select(_ tab: UseSmileIDSampleTab) {
    if tab == router.selectedTab {
      router.openTabRoot(tab)
    } else {
      router.selectedTab = tab
    }
  }
}

/// The appearance, locale and notice window the shell imposes, on the stack and on every sheet it presents.
private struct UseSmileIDSampleShellEnvironment: ViewModifier {
  @ObservedObject var app: UseSmileIDSampleAppState

  func body(content: Content) -> some View {
    content
      // Pinned both ways, not nil: following the system leaves a dark device rendering dark while Settings reads off.
      .preferredColorScheme(app.settings.darkMode ? .dark : .light)
      // `preferredColorScheme` moves the system's controls; only this maps the scheme onto our tokens.
      .useSmileIDSampleTheme()
      // Reaches `\.locale` in the shell's own views only; the SDK's strings follow `-AppleLanguages`.
      .modifier(UseSmileIDSampleLocaleOverride(locale: app.launchArguments.locale))
      .modifier(UseSmileIDSampleNoticeWindowOverride(seconds: app.launchArguments.noticeWindow))
  }
}

/// `noticeWindow`, applied only when the launch named one, so an ordinary launch keeps the product's.
private struct UseSmileIDSampleNoticeWindowOverride: ViewModifier {
  let seconds: Int?

  func body(content: Content) -> some View {
    if let seconds {
      content.environment(\.useSmileIDSampleNoticeWindow, TimeInterval(seconds))
    } else {
      content
    }
  }
}

/// `appLocale`, applied only when the launch named one, so an ordinary launch keeps the device locale.
private struct UseSmileIDSampleLocaleOverride: ViewModifier {
  let locale: Locale?

  func body(content: Content) -> some View {
    if let locale {
      content.environment(\.locale, locale)
    } else {
      content
    }
  }
}
