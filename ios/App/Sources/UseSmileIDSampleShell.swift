import Njia
import NjiaUI
import SampleUI
import SwiftUI

/// The window's root: njia draws the three tabs' stacks from `spec/njia-graph.json`, and the shell opens links. Everything identity-bound stays here — `SampleUI` runs under eight identities.
struct UseSmileIDSampleShell: View {
  @StateObject private var navigation = UseSmileIDSampleNavigationModel()
  @StateObject private var app = UseSmileIDSampleAppState()
  @StateObject private var chrome = UseSmileIDSampleChrome()

  /// The engine's state as njia's JSON, so a relaunch restores the stacks.
  @SceneStorage("navigation") private var storedNavigation: String = ""

  /// Never in scene storage: a restored flag would swallow the run the launch asked for.
  @State private var autostarted = false

  var body: some View {
    // No njia step ids: each screen names itself `sample_*`, and a second id on its element replaces the first.
    NjiaHost(engine: navigation.engine, steps: steps, stepIds: false)
      .environmentObject(navigation)
      .environmentObject(app)
      .environmentObject(chrome)
      .modifier(UseSmileIDSampleShellEnvironment(app: app))
      .modifier(UseSmileIDSampleDeviceScheme(app: app))
      .onOpenURL(perform: open)
      // On dismissal, not on open: the one point every path goes through, including a swipe.
      .onChange(of: topIsSheet) { isSheet in
        if !isSheet {
          app.clearSheetState()
        }
      }
      .onAppear {
        navigation.restore(from: storedNavigation)
        autostart()
      }
      .onChange(of: app.lastJobRemoval) { count in chrome.showRemoval(count, app: app) }
      .onChange(of: navigation.state.entries.first?.step) { _ in
        // Select mode and its confirmation belong to the list, so neither follows you to another tab.
        app.verifications.changeSelectMode(false)
        chrome.removalNotice = nil
      }
      .onChange(of: navigation.state) { _ in storedNavigation = navigation.encodedState() }
      // Debug only: shake to read the app's own traffic.
      .modifier(UseSmileIDSampleLoupeAccess())
  }

  /// Every step drawn by the one destination switch, with the shell's objects, the tab roots' bottom chrome and full-height sheets.
  private var steps: NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact> {
    let navigation = navigation
    let app = app
    let chrome = chrome
    return NjiaSteps { steps in
      // A sheet is its own presentation and inherits none of the environment set above it.
      steps.decorate { scope, content in
        UseSmileIDSampleStepEnvironment(scope: scope, app: app) { content }
          .environmentObject(navigation)
          .environmentObject(app)
          .environmentObject(chrome)
      }
      steps.decorate { scope, content in
        UseSmileIDSampleTabRoot(scope: scope) { content }
      }
      for kind in UseSmileIDSampleStep.allCases {
        steps.step(kind) { UseSmileIDSampleDestination(scope: $0) }
      }
    }
  }

  private var topIsSheet: Bool {
    navigation.state.top.map { navigation.engine.stepOf($0).presentation == .sheet } ?? false
  }

  /// A link opens as a new flow, under the facts its product runs with.
  private func open(_ url: URL) {
    guard let link = UseSmileIDSampleDeepLinks.linkOf(url) else { return }
    navigation.open(link.path, facts: facts(for: link))
  }

  /// The facts a link's run starts with: its product's, on the route it asked for, or the launch's.
  private func facts(for link: UseSmileIDSampleLink) -> Set<UseSmileIDSampleFact> {
    guard let product = UseSmileIDSampleProduct.allCases.first(where: { $0.id == UseSmileIDSampleDeepLinks.productId(of: link) }) else { return [] }
    return useSmileIDSampleFacts(product, bindsIdDetails: app.tokenBindsIdDetails(product), route: link.route ?? app.launchArguments.route)
  }

  /// Starts the run after the restore, so the argument wins over what the last scene left.
  private func autostart() {
    guard !autostarted else { return }
    autostarted = true
    // Ahead of autostart, which reads the session the moment the flow step opens.
    linkLaunchSession(useSmileIDSampleShellExtension, link: app.linkSession)
    guard let product = app.launchArguments.autostart else { return }
    navigation.restart()
    let engine = navigation.engine
    engine.top.map { engine.startRun(from: $0, product: product, run: app.runOnly(product, route: app.launchArguments.route)) }
  }
}

/// The confirmation a removal leaves, kept by the shell so it outlives the list's redraws but not a tab switch.
@MainActor
final class UseSmileIDSampleChrome: ObservableObject {
  /// Consumed on sight and never saved, so a confirmation already spent cannot come back with you.
  @Published var removalNotice: UseSmileIDSampleTransientNotice?

  /// The same copy on every platform: the rows are hidden from this app's list, not deleted.
  func showRemoval(_ count: Int?, app: UseSmileIDSampleAppState) {
    guard let count else { return }
    app.clearLastJobRemoval()
    removalNotice = UseSmileIDSampleTransientNotice(
      message: count == 1
        ? UseSmileIDSampleStrings.verificationsHiddenOne
        : UseSmileIDSampleStrings.verificationsHiddenMany(count: count),
      actionLabel: UseSmileIDSampleStrings.commonUndo
    )
  }
}

/// The shell's environment on every sheet at full height, as the shell's own sheets opened, and no system bar on a screen.
private struct UseSmileIDSampleStepEnvironment<Content: View>: View {
  let scope: UseSmileIDSampleStepScope
  let app: UseSmileIDSampleAppState
  @ViewBuilder let content: () -> Content

  var body: some View {
    if scope.step.presentation == .sheet {
      content().modifier(UseSmileIDSampleShellEnvironment(app: app)).presentationDetents([.large])
    } else {
      // Every screen draws its own header, and a stack shows an empty bar over a root it has pushed from.
      content().toolbar(.hidden, for: .navigationBar)
    }
  }
}

/// A tab's root, with the bottom chrome inset inside it, so a push covers the bar and a sheet over the root covers it too.
private struct UseSmileIDSampleTabRoot<Content: View>: View {
  let scope: UseSmileIDSampleStepScope
  @ViewBuilder let content: () -> Content

  var body: some View {
    if let tab = UseSmileIDSampleNavItem(step: scope.step.kind) {
      content().safeAreaInset(edge: .bottom) { UseSmileIDSampleBottomChrome(tab: tab, navigator: scope.navigator) }
    } else {
      content()
    }
  }
}

/// Select mode replaces the bar with the selection bar; the confirmation sits above whichever shows.
private struct UseSmileIDSampleBottomChrome: View {
  let tab: UseSmileIDSampleNavItem
  let navigator: NjiaNavigator

  @EnvironmentObject private var navigation: UseSmileIDSampleNavigationModel
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @EnvironmentObject private var chrome: UseSmileIDSampleChrome

  var body: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleTransientNoticeHost(
        notice: tab == .verifications ? chrome.removalNotice : nil,
        onAction: { app.undoJobRemoval() },
        onDismiss: { chrome.removalNotice = nil }
      )
      .padding(.horizontal, SmileSpacing.spacingMd)
      if app.verifications.selectMode {
        UseSmileIDSampleSelectionBar(
          selectedCount: app.verifications.selected.count,
          onRemove: { app.removeJobs(app.verifications.selected) }
        )
      } else {
        // The design's floating pill; re-selecting the showing tab pops it to its root, as the platform does.
        UseSmileIDSampleNavBar(
          selected: tab,
          sessionProgress: app.sessionProgress,
          onSelect: { navigation.engine.select($0.step.rawValue) },
          onToken: { navigator.go(.scanToken) }
        )
      }
    }
  }
}

extension UseSmileIDSampleNavItem {
  /// The tab root each nav bar item selects.
  var step: UseSmileIDSampleStep {
    switch self {
    case .products: .products
    case .verifications: .verifications
    case .settings: .settings
    }
  }

  /// The item whose root `step` is, or nil for a step above a root.
  init?(step: UseSmileIDSampleStep) {
    guard let item = Self.allCases.first(where: { $0.step == step }) else { return nil }
    self = item
  }
}

/// The appearance, locale and notice window the shell imposes, on the stack and on every sheet it presents.
private struct UseSmileIDSampleShellEnvironment: ViewModifier {
  @ObservedObject var app: UseSmileIDSampleAppState

  func body(content: Content) -> some View {
    content
      .preferredColorScheme(app.settings.appearance.colorScheme)
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
