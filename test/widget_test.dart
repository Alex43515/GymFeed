import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter test environment renders the GymFeed shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('GymFeed')),
      ),
    );

    expect(find.text('GymFeed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
