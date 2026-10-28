import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/features/learn/engine/lesson_registry.dart';

void main() {
  group('LessonRegistry.findLessonForQuestion tests', () {
    test('36² matches squares_base_50 with operand 36, NOT squares_ending_5 with 35', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [36],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_base_50');
      expect(match.operands, [36]);
    });

    test('35² matches squares_ending_5 with operand 35', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [35],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_ending_5');
      expect(match.operands, [35]);
    });

    test('65² matches squares_ending_5 with operand 65', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [65],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_ending_5');
      expect(match.operands, [65]);
    });

    test('96² matches squares_base_100 with operand 96', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [96],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_base_100');
      expect(match.operands, [96]);
    });

    test('148² matches squares_base_150 with operand 148', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [148],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_base_150');
      expect(match.operands, [148]);
    });

    test('196² matches squares_base_200 with operand 196', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [196],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_base_200');
      expect(match.operands, [196]);
    });

    test('23² matches squares_base_25 with operand 23', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [23],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'squares_base_25');
      expect(match.operands, [23]);
    });

    test('17² matches multiply_2x2 (criss-cross multiplication) with operands [17, 17]', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.squares,
        operands: [17],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'multiply_2x2');
      expect(match.operands, [17, 17]);
    });

    test('48 × 11 matches multiply_by_11 with operands [48, 11]', () {
      final match = LessonRegistry.findLessonForQuestion(
        topic: Topic.multiplication,
        operands: [48, 11],
      );

      expect(match, isNotNull);
      expect(match!.lesson.id, 'multiply_by_11');
      expect(match.operands, [48, 11]);
    });
  });
}
