import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The grid measures each row by its cards' intrinsic height, so a card must be able to report one.
void main() {
  testWidgets('a row of cards lays out and steps a long label down', (
    WidgetTester tester,
  ) async {
    const List<UseSmileIDSampleProduct> products = <UseSmileIDSampleProduct>[
      UseSmileIDSampleProduct.documentVerification,
      UseSmileIDSampleProduct.enhancedDocumentVerification,
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Material(
          child: SizedBox(
            width: 393,
            child: UseSmileIDSampleProductGrid(
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) =>
                  UseSmileIDSampleProductCard(
                    title: products[index].cardTitle,
                    family: products[index].cardFamily,
                    hue: productHue(products[index]),
                    onTap: () {},
                  ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final Size first = tester.getSize(
      find.byType(UseSmileIDSampleProductCard).first,
    );
    expect(first.height, greaterThan(0));
    expect(
      tester.getSize(find.byType(UseSmileIDSampleProductCard).last).height,
      first.height,
    );
    expect(find.bySemanticsLabel(RegExp('Enhanced Doc')), findsOneWidget);
  });
}
