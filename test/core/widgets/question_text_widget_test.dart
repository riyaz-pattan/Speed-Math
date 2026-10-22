import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator_registry.dart';

void main() {
  group('QuestionTextWidget Widget Tests', () {
    Widget buildTestWidget({
      required String text,
      double textScale = 1.0,
      double width = 360,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 600),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Center(
              child: SizedBox(
                width: width,
                child: QuestionTextWidget(
                  text: text,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders exponent base^power cleanly', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '3^4'));
      final richTextFinder = find.byType(RichText).first;
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      expect(richText.text.toPlainText(), contains('3'));
      expect(find.text('4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders square root with radical sign painter', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '√144'));
      expect(find.text('144'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cube root with ³√ notation and painter', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '³√125'));
      expect(find.text('125'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders legacy cube root with ∛ symbol gracefully', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '∛27'));
      expect(find.text('27'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders superscripts ² and ³', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '12²'));
      final richTextFinder = find.byType(RichText).first;
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      expect(richText.text.toPlainText(), contains('12'));
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(text: '7³'));
      final richTextFinder2 = find.byType(RichText).first;
      expect(richTextFinder2, findsOneWidget);
      final richText2 = tester.widget<RichText>(richTextFinder2);
      expect(richText2.text.toPlainText(), contains('7'));
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('verifies layout at 360px width and at 1.3x text scale without overflow', (tester) async {
      final sampleQuestions = [
        '123 + 456',
        '9876 − 5432',
        '87 × 65',
        '1234 ÷ 56',
        '89²',
        '34³',
        '√9801',
        '³√29791',
        '9^5',
      ];

      for (final q in sampleQuestions) {
        await tester.pumpWidget(buildTestWidget(
          text: q,
          textScale: 1.3,
          width: 360,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed for question: $q');
      }
    });

    testWidgets('renders all supported topic display text without throwing', (tester) async {
      for (final topic in Topic.values) {
        await tester.pumpWidget(buildTestWidget(text: topic.symbol));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Font Character Allowlist Test', () {
    // Characters known to be missing from bundled Poppins fonts
    const forbiddenChars = [
      '∛', // U+221B cube root
      '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '⁰', 'ⁿ', // U+2074..U+207F superscripts missing
      '✦', '★', '⚡', '✓', '⌫', // decorative and symbol glyphs
    ];

    test('Topic symbols do not contain forbidden/missing Poppins characters', () {
      for (final topic in Topic.values) {
        for (final forbidden in forbiddenChars) {
          expect(
            topic.symbol.contains(forbidden),
            isFalse,
            reason: 'Topic.${topic.name}.symbol contains missing glyph "$forbidden"',
          );
        }
      }
    });

    test('All generators produce question strings free of missing font characters', () {
      for (final topic in Topic.values) {
        if (topic == Topic.mixed) continue;
        for (final diff in Difficulty.values) {
          if (diff == Difficulty.mixed) continue;
          final gen = QuestionGeneratorRegistry.getGenerator(topic);
          for (var seed = 1; seed <= 50; seed++) {
            final q = gen.generate(difficulty: diff, random: Random(seed));
            for (final forbidden in forbiddenChars) {
              expect(
                q.displayText.contains(forbidden),
                isFalse,
                reason: 'Question "${q.displayText}" for ${topic.name}/${diff.name} contains forbidden glyph "$forbidden"',
              );
            }
          }
        }
      }
    });
  });
}
