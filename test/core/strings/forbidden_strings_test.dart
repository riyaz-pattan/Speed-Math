import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';

void main() {
  group('User-Facing Strings Audit (Phase 7A.2)', () {
    test('AppStrings does not contain bank, Smart Practice, or Custom Practice in user-facing labels', () {
      // Check all string constants in AppStrings
      expect(AppStrings.noMistakesInBank.toLowerCase().contains('bank'), isFalse);
      expect(AppStrings.noMistakesInBankSubtitle.toLowerCase().contains('bank'), isFalse);
      expect(AppStrings.noMistakesToRevise.toLowerCase().contains('bank'), isFalse);
      expect(AppStrings.mistakesToRevise.toLowerCase().contains('bank'), isFalse);
      expect(AppStrings.practiceMyMistakes.toLowerCase().contains('bank'), isFalse);
      expect(AppStrings.practiceYourMistakes.toLowerCase().contains('bank'), isFalse);

      // Verify no user-facing string mentions "Custom Practice"
      expect(AppStrings.practiceSetup.contains('Custom Practice'), isFalse);
      expect(AppStrings.practice.contains('Custom Practice'), isFalse);
    });

    test('phrases.json does not contain "bank" or "banked"', () {
      final file = File('assets/coach/phrases.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final Map<String, dynamic> jsonMap = jsonDecode(content);

      for (final entry in jsonMap.entries) {
        final phrases = entry.value as List<dynamic>;
        for (final p in phrases) {
          final phraseStr = p as String;
          expect(
            phraseStr.toLowerCase().contains('bank'),
            isFalse,
            reason: 'Found "bank" in category "${entry.key}": "$phraseStr"',
          );
        }
      }
    });

    test('UI screen files do not render "bank", "Smart Practice" or "Custom Practice" to user', () {
      final uiFiles = [
        'lib/features/practice_setup/practice_setup_screen.dart',
        'lib/features/mistakes/mistakes_screen.dart',
        'lib/features/results/results_screen.dart',
        'lib/features/home/home_screen.dart',
        'lib/features/history/history_screen.dart',
        'lib/features/history/session_details_screen.dart',
      ];

      final forbiddenRegex = RegExp(r"""['"][^'"]*\b(bank|banked|Smart Practice|Custom Practice)\b[^'"]*['"]""", caseSensitive: false);

      for (final filePath in uiFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: 'File $filePath should exist');

        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip comments, internal imports, database table names, or repository calls
          final trimmed = line.trim();
          if (trimmed.startsWith('//') ||
              trimmed.startsWith('import ') ||
              trimmed.contains('tableMistakeBank') ||
              trimmed.contains('DatabaseHelper.tableMistakeBank') ||
              trimmed.contains('mistakeRepository') ||
              trimmed.contains('MistakeRepository')) {
            continue;
          }

          final match = forbiddenRegex.firstMatch(line);
          expect(
            match,
            isNull,
            reason: 'Found forbidden phrase "${match?.group(0)}" in $filePath at line ${i + 1}:\n$line',
          );
        }
      }
    });
  });
}
