import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_feed/components/privacy_plocy/privacy_plocy_widget.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('privacy and deletion links fit a ${size.width} wide screen',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PrivacyPlocyWidget()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GymFeed Privacy Policy'), findsOneWidget);
      expect(find.text('Read Privacy Policy'), findsOneWidget);
      expect(find.text('Request data deletion'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is TextButton),
          findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
