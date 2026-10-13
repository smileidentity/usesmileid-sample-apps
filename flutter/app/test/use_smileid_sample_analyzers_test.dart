import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_huawei_document/usesmileid_huawei_document.dart';
import 'package:usesmileid_huawei_face/usesmileid_huawei_face.dart';
import 'package:usesmileid_mlkit_document/usesmileid_mlkit_document.dart';
import 'package:usesmileid_mlkit_face/usesmileid_mlkit_face.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_vision_document/usesmileid_vision_document.dart';
import 'package:usesmileid_vision_face/usesmileid_vision_face.dart';

void main() {
  group('the analyzers follow the phone', () {
    test('a Huawei without Google Play services runs HMS', () {
      const UseSmileIDMobileServicesProvider huawei =
          UseSmileIDMobileServicesProvider.huawei;
      expect(
        useSmileIDSampleFaceAnalyzerFactory(huawei, isAndroid: true),
        isA<HuaweiFaceAnalyzerFactory>(),
      );
      expect(
        useSmileIDSampleDocumentAnalyzerFactory(huawei, isAndroid: true),
        isA<HuaweiDocumentAnalyzerFactory>(),
      );
    });

    test('Google Play services, and a phone reporting neither, run ML Kit', () {
      for (final UseSmileIDMobileServicesProvider services
          in <UseSmileIDMobileServicesProvider>[
            UseSmileIDMobileServicesProvider.google,
            UseSmileIDMobileServicesProvider.none,
          ]) {
        expect(
          useSmileIDSampleFaceAnalyzerFactory(services, isAndroid: true),
          isA<MlKitFaceAnalyzerFactory>(),
        );
        expect(
          useSmileIDSampleDocumentAnalyzerFactory(services, isAndroid: true),
          isA<MlKitDocumentAnalyzerFactory>(),
        );
      }
    });

    test('iOS runs Vision whatever the probe says', () {
      for (final UseSmileIDMobileServicesProvider services
          in UseSmileIDMobileServicesProvider.values) {
        expect(
          useSmileIDSampleFaceAnalyzerFactory(services, isAndroid: false),
          isA<VisionFaceAnalyzerFactory>(),
        );
        expect(
          useSmileIDSampleDocumentAnalyzerFactory(services, isAndroid: false),
          isA<VisionDocumentAnalyzerFactory>(),
        );
      }
    });
  });
}
