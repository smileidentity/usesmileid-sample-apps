import SwiftUI

/// A shipped affordance, not scaffolding. Theme scenarios apply on top of the flow scenario, so the
/// two are separate selections, and a row selects without closing the sheet.
public struct ScenarioDrawerSheet: View {
  private let activeScenario: UseSmileIDSampleScenario
  private let activeTheme: UseSmileIDSampleThemeScenario
  private let onScenarioSelect: (UseSmileIDSampleScenario) -> Void
  private let onThemeSelect: (UseSmileIDSampleThemeScenario) -> Void

  public init(
    activeScenario: UseSmileIDSampleScenario,
    activeTheme: UseSmileIDSampleThemeScenario,
    onScenarioSelect: @escaping (UseSmileIDSampleScenario) -> Void,
    onThemeSelect: @escaping (UseSmileIDSampleThemeScenario) -> Void
  ) {
    self.activeScenario = activeScenario
    self.activeTheme = activeTheme
    self.onScenarioSelect = onScenarioSelect
    self.onThemeSelect = onThemeSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Scenarios", testId: UseSmileIDSampleTestIds.scenarioDrawer) {
      UseSmileIDSampleSectionLabel("FLOW")
      VStack(spacing: 0) {
        ForEach(UseSmileIDSampleScenario.allCases, id: \.self) { scenario in
          UseSmileIDSampleOptionRow(
            label: scenario.label,
            selected: scenario == activeScenario,
            testId: UseSmileIDSampleTestIds.scenarioItem(scenario.id),
            onTap: { onScenarioSelect(scenario) }
          )
        }
      }
      UseSmileIDSampleSectionLabel("THEME")
      VStack(spacing: 0) {
        ForEach(UseSmileIDSampleThemeScenario.allCases, id: \.self) { theme in
          UseSmileIDSampleOptionRow(
            label: theme.label,
            selected: theme == activeTheme,
            testId: UseSmileIDSampleTestIds.themeItem(theme.id),
            onTap: { onThemeSelect(theme) }
          )
        }
      }
    }
  }
}
