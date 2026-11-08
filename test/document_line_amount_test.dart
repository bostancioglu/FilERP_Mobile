import 'dart:ui' as ui;
import 'package:FilERP/widgets/document_line_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Amount and currency stay on one line at $width / $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: const [
                  SizedBox(width: 28),
                  SizedBox(width: 10),
                  Expanded(child: Text('Uzun stok adı ve ürün açıklaması')),
                  SizedBox(width: 8),
                  DocumentLineAmount(
                    amount: '123.456.789.012,34',
                    currency: 'USD',
                    color: Colors.black,
                    currencyColor: Colors.grey,
                  ),
                ]),
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
        final finder = find.descendant(
            of: find.byType(DocumentLineAmount),
            matching: find.byType(RichText));
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.text.toPlainText(), '123.456.789.012,34 USD');
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 21),
          boxHeightStyle: ui.BoxHeightStyle.max,
        );
        expect(boxes, isNotEmpty);
        expect(boxes.map((box) => box.top).toSet().length, 1);
        final fitted = find.descendant(
            of: find.byType(DocumentLineAmount),
            matching: find.byType(FittedBox));
        expect(tester.getSize(fitted).width, lessThanOrEqualTo(width * .4));
      });
    }
  }
}
