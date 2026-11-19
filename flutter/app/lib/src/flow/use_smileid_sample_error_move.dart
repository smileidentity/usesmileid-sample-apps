import 'package:sample_ui/sample_ui.dart';

/// Where a failure's one action takes the user.
sealed class UseSmileIDSampleErrorMove {
  const UseSmileIDSampleErrorMove();
}

/// The product's flow again, past the forms, as a new job.
final class UseSmileIDSampleRunAgain extends UseSmileIDSampleErrorMove {
  /// Runs [product] again.
  const UseSmileIDSampleRunAgain(this.product);

  /// The product to run.
  final UseSmileIDSampleProduct product;
}

/// The ID form, whose Continue starts the flow.
final class UseSmileIDSampleEditIdDetails extends UseSmileIDSampleErrorMove {
  /// Opens [product]'s ID form.
  const UseSmileIDSampleEditIdDetails(this.product);

  /// The product whose form opens.
  final UseSmileIDSampleProduct product;
}

/// The scanner for a new token, then the flow.
final class UseSmileIDSampleNewToken extends UseSmileIDSampleErrorMove {
  /// Rescans, then runs [product].
  const UseSmileIDSampleNewToken(this.product);

  /// The product to run after the scan.
  final UseSmileIDSampleProduct product;
}

/// Out of the run, to the products tab.
final class UseSmileIDSampleLeave extends UseSmileIDSampleErrorMove {
  /// The one way out.
  const UseSmileIDSampleLeave();
}

/// The move [action] makes for the run of [product]; without a product there is nothing to run again.
UseSmileIDSampleErrorMove useSmileIDSampleErrorMove(
  UseSmileIDSampleErrorAction action,
  UseSmileIDSampleProduct? product,
) {
  if (product == null) return const UseSmileIDSampleLeave();
  return switch (action) {
    UseSmileIDSampleErrorAction.retry ||
    UseSmileIDSampleErrorAction.retryLater ||
    UseSmileIDSampleErrorAction.recapture => UseSmileIDSampleRunAgain(product),
    UseSmileIDSampleErrorAction.fixInput => UseSmileIDSampleEditIdDetails(
      product,
    ),
    UseSmileIDSampleErrorAction.newSession => UseSmileIDSampleNewToken(product),
    UseSmileIDSampleErrorAction.exit => const UseSmileIDSampleLeave(),
  };
}
