import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator_registry.dart';
import 'package:speed_math_with_ai/domain/questions/session_random.dart';

void main() {
  group('SessionRandom', () {
    test('newSessionSeed produces fresh values', () {
      final s1 = SessionRandom.newSessionSeed();
      final s2 = SessionRandom.newSessionSeed();
      expect(s1, isPositive);
      expect(s2, isPositive);
    });

    test('different topics with same session seed derive different random sequences', () {
      const sessionSeed = 123456789;
      final randAddition = SessionRandom.forTopic(sessionSeed, Topic.addition);
      final randSubtraction = SessionRandom.forTopic(sessionSeed, Topic.subtraction);

      final seqAdd = List.generate(10, (_) => randAddition.nextInt(1000));
      final seqSub = List.generate(10, (_) => randSubtraction.nextInt(1000));

      expect(seqAdd, isNot(equals(seqSub)));
    });

    test('two different topics with same session seed do not give same operand sequences', () {
      const sessionSeed = 987654321;
      final addGen = QuestionGeneratorRegistry.getGenerator(Topic.addition);
      final subGen = QuestionGeneratorRegistry.getGenerator(Topic.subtraction);

      final addRand = SessionRandom.forTopic(sessionSeed, Topic.addition);
      final subRand = SessionRandom.forTopic(sessionSeed, Topic.subtraction);

      final addOperands = <List<int>>[];
      final subOperands = <List<int>>[];

      for (var i = 0; i < 20; i++) {
        final qAdd = addGen.generate(
          difficulty: Difficulty.easy,
          random: addRand,
        );
        final qSub = subGen.generate(
          difficulty: Difficulty.easy,
          random: subRand,
        );
        addOperands.add(qAdd.operands);
        subOperands.add(qSub.operands);
      }

      // Check they are not identical
      expect(addOperands, isNot(equals(subOperands)));
    });
  });
}
