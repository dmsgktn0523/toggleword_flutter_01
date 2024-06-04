import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggleworld_flutter_01/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyAppWrapper());

    // Navigate to the test word list screen
    await tester.tap(find.text('테스트 단어장'));
    await tester.pumpAndSettle();

    // Verify that the VocabularyList is displayed
    expect(find.text('단어장 목록'), findsOneWidget);

    // Additional testing logic can go here, for example:
    // Verify that the initial list is empty or has expected items

    // Tap the add button and verify the addition logic
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle();

    // Verify that the new word addition screen is shown
    expect(find.text('단어 추가'), findsOneWidget);

    // Enter a new word and its meaning
    await tester.enterText(find.byType(TextField).first, 'testWord');
    await tester.enterText(find.byType(TextField).last, 'testMeaning');

    // Tap the confirm button to add the new word
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    // Verify that the new word is now in the list
    expect(find.text('testWord'), findsOneWidget);
    expect(find.text('testMeaning'), findsOneWidget);
  });
}
