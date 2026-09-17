import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

Future<TextStyle> pumpAndReadStyle(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppColor.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
  return tester.widget<Text>(find.byType(Text)).style!;
}

void main() {
  testWidgets('applies the size, line height and weight it is given', (
    tester,
  ) async {
    final style = await pumpAndReadStyle(
      tester,
      const AppText(
        '₦248,350.75',
        fontSize: 32,
        lineHeight: 40,
        fontWeight: FontWeight.w800,
        tabular: true,
      ),
    );

    expect(find.text('₦248,350.75'), findsOneWidget);
    expect(style.fontSize, 32);
    expect(style.fontWeight, FontWeight.w800);
    expect(style.height, 40 / 32);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('defaults to 14/20 regular in the primary text colour', (
    tester,
  ) async {
    final style = await pumpAndReadStyle(
      tester,
      const AppText('Available balance'),
    );

    expect(style.fontSize, 14);
    expect(style.height, 20 / 14);
    expect(style.fontWeight, FontWeight.w400);
    expect(style.color, AppColors.textPrimary);
    expect(style.fontFeatures, isNull);
  });

  testWidgets('an explicit colour wins over the default', (tester) async {
    final style = await pumpAndReadStyle(
      tester,
      const AppText('Pending', color: AppColors.pending),
    );

    expect(style.color, AppColors.pending);
  });

  testWidgets(
    'line height is a multiple, so text grows with the font setting',
    (tester) async {
      // The style itself is unscaled; Flutter applies the scaler at paint time.
      // What matters is that height is a ratio, so the line grows with the text
      // instead of clipping inside a fixed pixel height.
      final style = await pumpAndReadStyle(
        tester,
        const AppText('Available balance: ₦248,350.75'),
        textScale: 2.0,
      );

      expect(style.height, 20 / 14);

      final painted = tester.renderObject<RenderParagraph>(find.byType(Text));
      expect(painted.textScaler.scale(14), 28);
    },
  );

  testWidgets('long text wraps at 200% instead of overflowing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppColor.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SizedBox(
              width: 200,
              child: AppText(
                'Transfers and savings will go out once you reconnect.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
