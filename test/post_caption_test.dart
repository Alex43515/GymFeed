import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_feed/components/post_caption/post_caption.dart';

void main() {
  Widget caption(String text) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: SingleChildScrollView(
                child: PostCaption(
              caption: text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            )),
          ),
        ),
      );

  testWidgets('feed caption expands beyond two lines and collapses again',
      (tester) async {
    const text =
        'Today we trained together and completed every exercise in the plan. '
        'This longer description should stay readable after opening See more.';
    await tester.pumpWidget(caption(text));
    expect(tester.widget<Text>(find.text(text)).maxLines, 2);
    await tester.tap(find.text('See more'));
    await tester.pump();
    expect(tester.widget<Text>(find.text(text)).maxLines, isNull);
    await tester.tap(find.text('See less'));
    await tester.pump();
    expect(tester.widget<Text>(find.text(text)).maxLines, 2);
  });

  testWidgets('short captions need no expansion and edits reset expanded state',
      (tester) async {
    await tester.pumpWidget(caption('Short caption'));
    expect(find.text('See more'), findsNothing);
    final long = List.filled(30, 'Workout').join(' ');
    await tester.pumpWidget(caption(long));
    await tester.tap(find.text('See more'));
    await tester.pump();
    await tester.pumpWidget(caption('An edited caption'));
    expect(tester.widget<Text>(find.text('An edited caption')).maxLines, 2);
    expect(find.text('See less'), findsNothing);
  });
}
