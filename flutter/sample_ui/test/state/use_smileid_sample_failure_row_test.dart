import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

/// How a failure the SDK hands `onResult` picks its row of `spec/error-handling.json`.
void main() {
  test('a refused submission resolves by its status', () {
    expect(
      const NetworkServerException(statusCode: 429).errorResolution?.id,
      'rateLimited',
    );
    expect(
      const NetworkServerException(statusCode: 503).errorResolution?.id,
      'serverError',
    );
    expect(
      const NetworkServerException(statusCode: 403).errorResolution?.id,
      'notEnabled',
    );
  });

  test("the server's message tells rows of one status apart", () {
    expect(
      const NetworkServerException(
        statusCode: 400,
        message:
            'Invalid ID number format for the specified country and ID type.',
      ).errorResolution?.id,
      'idNumberInvalid',
    );
    expect(
      const NetworkServerException(
        statusCode: 403,
        message: 'SDK version not allowed.',
      ).errorResolution?.id,
      'sdkVersionNotAllowed',
    );
    expect(
      const NetworkServerException(statusCode: 400).errorResolution?.id,
      'requestInvalid',
    );
  });

  test('a timeout and a lost connection resolve as transport failures', () {
    expect(const NetworkTimeoutException().errorResolution?.id, 'timeout');
    expect(
      const NetworkTransportException(
        cause: SocketException('offline'),
      ).errorResolution?.id,
      'noConnection',
    );
  });

  test('a failure no submission returned has no row', () {
    expect(Exception('the camera could not start').errorResolution, isNull);
    expect(
      const NetworkResponseParseException(
        cause: FormatException('not JSON'),
      ).errorResolution,
      isNull,
    );
  });
}
