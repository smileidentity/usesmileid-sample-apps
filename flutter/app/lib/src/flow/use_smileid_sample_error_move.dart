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

/// The product's first step under the live session, whose partner may not take the details the run had.
final class UseSmileIDSampleRunFromStart extends UseSmileIDSampleErrorMove {
  /// Starts [product] from its first step.
  const UseSmileIDSampleRunFromStart(this.product);

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

/// The scanner for a new token, then the run from [resumeAt].
final class UseSmileIDSampleNewToken extends UseSmileIDSampleErrorMove {
  /// Rescans, then runs [product] from [resumeAt].
  const UseSmileIDSampleNewToken(this.product, this.resumeAt);

  /// The product to run after the scan.
  final UseSmileIDSampleProduct product;

  /// Where the run resumes once a token links.
  final UseSmileIDSampleResumePoint resumeAt;
}

/// Out of the run, to the products tab.
final class UseSmileIDSampleLeave extends UseSmileIDSampleErrorMove {
  /// The one way out.
  const UseSmileIDSampleLeave();
}

/// The move [action] makes for the run of [product], gated as a product tap is: a live session, on the run's own partner.
UseSmileIDSampleErrorMove useSmileIDSampleErrorMove(
  UseSmileIDSampleErrorAction action,
  UseSmileIDSampleProduct? product, {
  required bool sessionLive,
  required String? livePartnerId,
  required String? runPartnerId,
}) {
  if (product == null) return const UseSmileIDSampleLeave();
  final bool ownPartner = runPartnerId != null && runPartnerId == livePartnerId;
  return switch (action) {
    UseSmileIDSampleErrorAction.retry ||
    UseSmileIDSampleErrorAction.retryLater ||
    UseSmileIDSampleErrorAction.recapture =>
      !sessionLive
          ? UseSmileIDSampleNewToken(product, UseSmileIDSampleResumePoint.flow)
          : ownPartner
          ? UseSmileIDSampleRunAgain(product)
          : UseSmileIDSampleRunFromStart(product),
    UseSmileIDSampleErrorAction.fixInput =>
      !sessionLive
          ? UseSmileIDSampleNewToken(
              product,
              UseSmileIDSampleResumePoint.firstStep,
            )
          : ownPartner
          ? UseSmileIDSampleEditIdDetails(product)
          : UseSmileIDSampleRunFromStart(product),
    UseSmileIDSampleErrorAction.newSession => UseSmileIDSampleNewToken(
      product,
      UseSmileIDSampleResumePoint.flow,
    ),
    UseSmileIDSampleErrorAction.exit => const UseSmileIDSampleLeave(),
  };
}
