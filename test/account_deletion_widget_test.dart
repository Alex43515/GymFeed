import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gym_feed/components/delete_account_second_step/delete_account_second_step_widget.dart';
import 'package:gym_feed/flutter_flow/internationalization.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('delete action does not depend on a legacy administrative stream',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [FFLocalizationsDelegate()],
      supportedLocales: [Locale('en')],
      home: Scaffold(body: DeleteAccountSecondStepWidget()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
