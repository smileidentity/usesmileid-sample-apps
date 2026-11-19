import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The product a run keeps for its failure actions, which the card never shows.
void main() {
  UseSmileIDSampleResult started(UseSmileIDSampleProduct product) =>
      UseSmileIDSampleResult.idle.started(
        scenario: UseSmileIDSampleScenario.normal,
        theme: UseSmileIDSampleThemeScenario.brandDefault,
        route: UseSmileIDSampleFlowRoute.fullscreen,
        environment: UseSmileIDSampleEnvironment.sandbox,
        product: product,
      );

  test('a run keeps its product through its result and a token refresh', () {
    final UseSmileIDSampleResult result =
        started(UseSmileIDSampleProduct.enhancedKyc).refreshed().recorded(
          UseSmileIDSampleFlowStatus.failed,
          error: 'HTTP 503',
        );

    expect(result.product, UseSmileIDSampleProduct.enhancedKyc);
    expect(result.toMap().containsKey('product'), isFalse);
  });

  test("a blocked run keeps its own product, not the previous run's", () {
    final UseSmileIDSampleResult result =
        started(UseSmileIDSampleProduct.smartSelfieEnrollment).blocked(
          'no token',
          scenario: UseSmileIDSampleScenario.normal,
          theme: UseSmileIDSampleThemeScenario.brandDefault,
          route: UseSmileIDSampleFlowRoute.fullscreen,
          environment: UseSmileIDSampleEnvironment.sandbox,
          product: UseSmileIDSampleProduct.enhancedKyc,
        );

    expect(result.product, UseSmileIDSampleProduct.enhancedKyc);
  });
}
