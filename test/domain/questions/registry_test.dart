import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/addition_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/cube_roots_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/cubes_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/division_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/exponents_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/multiplication_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/square_roots_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/squares_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/subtraction_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator_registry.dart';

void main() {
  group('QuestionGeneratorRegistry', () {
    test('returns correct generator for each topic', () {
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.addition),
        isA<AdditionGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.subtraction),
        isA<SubtractionGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.multiplication),
        isA<MultiplicationGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.division),
        isA<DivisionGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.squares),
        isA<SquaresGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.cubes),
        isA<CubesGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.squareRoots),
        isA<SquareRootsGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.cubeRoots),
        isA<CubeRootsGenerator>(),
      );
      expect(
        QuestionGeneratorRegistry.getGenerator(Topic.exponents),
        isA<ExponentsGenerator>(),
      );
    });

    test('all non-mixed topics are registered', () {
      final registered = QuestionGeneratorRegistry.registeredTopics;
      for (final topic in Topic.standardTopics) {
        expect(registered, contains(topic));
      }
      for (final topic in Topic.values.where((t) => t != Topic.mixed)) {
        expect(registered, contains(topic));
      }
      expect(registered.length, Topic.values.length - 1);
      expect(registered, isNot(contains(Topic.mixed)));
    });
  });
}
