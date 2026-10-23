import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/models/attempt.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/data/repositories/attempt_repository.dart';
import 'package:speed_math_with_ai/data/repositories/session_repository.dart';
import 'package:speed_math_with_ai/data/repositories/stats_repository.dart';
import 'package:speed_math_with_ai/domain/questions/difficulty_ranges.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/features/practice_session/controllers/practice_session_controller.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

class _NoOpSessionRepo extends SessionRepository {
  @override
  Future<int> insertSession(Session session) async => 1;
}

class _NoOpAttemptRepo extends AttemptRepository {
  @override
  Future<List<int>> insertAttempts(List<Attempt> attempts) async => [];
}

class _NoOpStatsRepo extends StatsRepository {}

void main() {
  group('Session-Level Difficulty Range Verification (9 topics x 3 diffs x 2 modes)', () {
    final sessionRepo = _NoOpSessionRepo();
    final attemptRepo = _NoOpAttemptRepo();
    final statsRepo = _NoOpStatsRepo();

    void assertQuestionInRange(Topic topic, Difficulty difficulty, Question q) {
      expect(q.topic, topic);
      expect(q.difficulty, difficulty);

      switch (topic) {
        case Topic.addition:
          if (difficulty == Difficulty.easy) {
            expect(q.operands.length, 2);
            expect(q.operands[0], inInclusiveRange(DifficultyRanges.additionEasyMin, DifficultyRanges.additionEasyMax));
            expect(q.operands[1], inInclusiveRange(DifficultyRanges.additionEasyMin, DifficultyRanges.additionEasyMax));
            expect(q.correctAnswer, q.operands[0] + q.operands[1]);
          } else if (difficulty == Difficulty.medium) {
            expect(q.operands.length, 2);
            expect(q.operands[0], inInclusiveRange(DifficultyRanges.additionMediumMin, DifficultyRanges.additionMediumMax));
            expect(q.operands[1], inInclusiveRange(DifficultyRanges.additionMediumMin, DifficultyRanges.additionMediumMax));
            expect(q.correctAnswer, q.operands[0] + q.operands[1]);
          } else if (difficulty == Difficulty.hard) {
            expect(q.operands.length, DifficultyRanges.additionHardAddendCount);
            for (final op in q.operands) {
              expect(op, inInclusiveRange(DifficultyRanges.additionHardMin, DifficultyRanges.additionHardMax));
            }
            expect(q.correctAnswer, q.operands.reduce((a, b) => a + b));
          }
          break;

        case Topic.subtraction:
          expect(q.operands.length, 2);
          final a = q.operands[0];
          final b = q.operands[1];
          expect(a >= b, isTrue, reason: 'Subtraction result must be non-negative');
          expect(q.correctAnswer, a - b);
          expect(q.correctAnswer >= 0, isTrue);

          if (difficulty == Difficulty.easy) {
            expect(a, inInclusiveRange(DifficultyRanges.subtractionEasyMin, DifficultyRanges.subtractionEasyMax));
            expect(b, inInclusiveRange(DifficultyRanges.subtractionEasyMin, DifficultyRanges.subtractionEasyMax));
          } else if (difficulty == Difficulty.medium) {
            expect(a, inInclusiveRange(DifficultyRanges.subtractionMediumMin, DifficultyRanges.subtractionMediumMax));
            expect(b, inInclusiveRange(DifficultyRanges.subtractionMediumMin, DifficultyRanges.subtractionMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(a, inInclusiveRange(DifficultyRanges.subtractionHardMin, DifficultyRanges.subtractionHardMax));
            expect(b, inInclusiveRange(DifficultyRanges.subtractionHardMin, DifficultyRanges.subtractionHardMax));
          }
          break;

        case Topic.multiplication:
          expect(q.operands.length, 2);
          final a = q.operands[0];
          final b = q.operands[1];
          expect(q.correctAnswer, a * b);

          if (difficulty == Difficulty.easy) {
            expect(a, inInclusiveRange(DifficultyRanges.multiplicationEasyAMin, DifficultyRanges.multiplicationEasyAMax));
            expect(b, inInclusiveRange(DifficultyRanges.multiplicationEasyBMin, DifficultyRanges.multiplicationEasyBMax));
          } else if (difficulty == Difficulty.medium) {
            expect(a, inInclusiveRange(DifficultyRanges.multiplicationMediumMin, DifficultyRanges.multiplicationMediumMax));
            expect(b, inInclusiveRange(DifficultyRanges.multiplicationMediumMin, DifficultyRanges.multiplicationMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(a, inInclusiveRange(DifficultyRanges.multiplicationHardAMin, DifficultyRanges.multiplicationHardAMax));
            expect(b, inInclusiveRange(DifficultyRanges.multiplicationHardBMin, DifficultyRanges.multiplicationHardBMax));
          }
          break;

        case Topic.division:
          expect(q.operands.length, 2);
          final dividend = q.operands[0];
          final divisor = q.operands[1];
          final quotient = q.correctAnswer;
          expect(dividend, quotient * divisor, reason: 'Division must be exact');

          if (difficulty == Difficulty.easy) {
            expect(dividend, inInclusiveRange(DifficultyRanges.divisionEasyDividendMin, DifficultyRanges.divisionEasyDividendMax));
            expect(divisor, inInclusiveRange(DifficultyRanges.divisionEasyDivisorMin, DifficultyRanges.divisionEasyDivisorMax));
          } else if (difficulty == Difficulty.medium) {
            final is3by1 = dividend >= 100 && dividend <= 999;
            if (is3by1) {
              expect(quotient, inInclusiveRange(DifficultyRanges.divisionMedium3by1QuotientMin, DifficultyRanges.divisionMedium3by1QuotientMax));
              expect(divisor, inInclusiveRange(DifficultyRanges.divisionMedium3by1DivisorMin, DifficultyRanges.divisionMedium3by1DivisorMax));
            } else {
              expect(dividend, inInclusiveRange(DifficultyRanges.divisionMedium2by2DividendMin, DifficultyRanges.divisionMedium2by2DividendMax));
              expect(divisor, inInclusiveRange(DifficultyRanges.divisionMedium2by2DivisorMin, DifficultyRanges.divisionMedium2by2DivisorMax));
              expect(quotient, inInclusiveRange(DifficultyRanges.divisionMedium2by2QuotientMin, DifficultyRanges.divisionMedium2by2QuotientMax));
            }
          } else if (difficulty == Difficulty.hard) {
            expect(dividend, inInclusiveRange(DifficultyRanges.divisionHardDividendMin, DifficultyRanges.divisionHardDividendMax));
            expect(divisor, inInclusiveRange(DifficultyRanges.divisionHardDivisorMin, DifficultyRanges.divisionHardDivisorMax));
          }
          break;

        case Topic.squares:
          final n = q.operands[0];
          expect(q.operands[1], n);
          expect(q.correctAnswer, n * n);

          if (difficulty == Difficulty.easy) {
            expect(n, inInclusiveRange(DifficultyRanges.squaresEasyMin, DifficultyRanges.squaresEasyMax));
          } else if (difficulty == Difficulty.medium) {
            expect(n, inInclusiveRange(DifficultyRanges.squaresMediumMin, DifficultyRanges.squaresMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(n, inInclusiveRange(DifficultyRanges.squaresHardMin, DifficultyRanges.squaresHardMax));
            expect(n % 10 != 0, isTrue, reason: 'Squares hard excludes multiples of 10');
          }
          break;

        case Topic.cubes:
          final n = q.operands[0];
          expect(q.operands[1], 3);
          expect(q.correctAnswer, n * n * n);

          if (difficulty == Difficulty.easy) {
            expect(n, inInclusiveRange(DifficultyRanges.cubesEasyMin, DifficultyRanges.cubesEasyMax));
          } else if (difficulty == Difficulty.medium) {
            expect(n, inInclusiveRange(DifficultyRanges.cubesMediumMin, DifficultyRanges.cubesMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(n, inInclusiveRange(DifficultyRanges.cubesHardMin, DifficultyRanges.cubesHardMax));
            expect(n % 10 != 0, isTrue, reason: 'Cubes hard excludes multiples of 10');
          }
          break;

        case Topic.squareRoots:
          final radicand = q.operands[0];
          final root = q.operands[1];
          expect(radicand, root * root);
          expect(q.correctAnswer, root);

          if (difficulty == Difficulty.easy) {
            expect(root, inInclusiveRange(DifficultyRanges.squareRootsEasyMin, DifficultyRanges.squareRootsEasyMax));
          } else if (difficulty == Difficulty.medium) {
            expect(root, inInclusiveRange(DifficultyRanges.squareRootsMediumMin, DifficultyRanges.squareRootsMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(root, inInclusiveRange(DifficultyRanges.squareRootsHardMin, DifficultyRanges.squareRootsHardMax));
            expect(root % 10 != 0, isTrue, reason: 'Square roots hard excludes multiples of 10');
          }
          break;

        case Topic.cubeRoots:
          final radicand = q.operands[0];
          final root = q.operands[1];
          expect(radicand, root * root * root);
          expect(q.correctAnswer, root);

          if (difficulty == Difficulty.easy) {
            expect(root, inInclusiveRange(DifficultyRanges.cubeRootsEasyMin, DifficultyRanges.cubeRootsEasyMax));
          } else if (difficulty == Difficulty.medium) {
            expect(root, inInclusiveRange(DifficultyRanges.cubeRootsMediumMin, DifficultyRanges.cubeRootsMediumMax));
          } else if (difficulty == Difficulty.hard) {
            expect(root, inInclusiveRange(DifficultyRanges.cubeRootsHardMin, DifficultyRanges.cubeRootsHardMax));
            expect(root % 10 != 0, isTrue, reason: 'Cube roots hard excludes multiples of 10');
          }
          break;

        case Topic.exponents:
          final base = q.operands[0];
          final power = q.operands[1];
          expect(base != 1 && base != 10, isTrue, reason: 'Exponents never base 1 or 10');
          expect(q.correctAnswer <= DifficultyRanges.exponentsHardMaxResult, isTrue);

          int expectedResult = 1;
          for (var i = 0; i < power; i++) {
            expectedResult *= base;
          }
          expect(q.correctAnswer, expectedResult);

          if (difficulty == Difficulty.easy) {
            expect(base, inInclusiveRange(DifficultyRanges.exponentsEasyBaseMin, DifficultyRanges.exponentsEasyBaseMax));
            expect(power, inInclusiveRange(DifficultyRanges.exponentsEasyPowMin, DifficultyRanges.exponentsEasyPowMax));
          } else if (difficulty == Difficulty.medium) {
            expect(base, inInclusiveRange(DifficultyRanges.exponentsMediumBaseMin, DifficultyRanges.exponentsMediumBaseMax));
            expect(power, inInclusiveRange(DifficultyRanges.exponentsMediumPowMin, DifficultyRanges.exponentsMediumPowMax));
          } else if (difficulty == Difficulty.hard) {
            expect(base, inInclusiveRange(DifficultyRanges.exponentsHardBaseMin, DifficultyRanges.exponentsHardBaseMax));
            expect(power, inInclusiveRange(DifficultyRanges.exponentsHardPowMin, DifficultyRanges.exponentsHardPowMax));
          }
          break;

        case Topic.percentages:
        case Topic.fractions:
        case Topic.simplification:
        case Topic.averages:
        case Topic.missingNumber:
        case Topic.numberSeries:
        case Topic.approximation:
          expect(q.correctAnswer > 0, isTrue);
          break;

        case Topic.mixed:
          break;
      }
    }

    for (final topic in Topic.standardTopics) {
      for (final difficulty in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        for (final mode in [PracticeMode.questions, PracticeMode.timer]) {
          test('Session 500 questions stay strictly inside range table for ${topic.name} • ${difficulty.name} (${mode.name})', () {
            final config = PracticeConfig(
              topic: topic,
              difficulty: difficulty,
              mode: mode,
              modeValue: mode == PracticeMode.questions ? 1000 : 300,
              sessionSeed: 12345 + topic.index * 100 + difficulty.index * 10 + mode.index,
            );

            final controller = PracticeSessionController(
              config: config,
              sessionRepository: sessionRepo,
              attemptRepository: attemptRepo,
              statsRepository: statsRepo,
            );

            controller.start();

            // Check initial question
            assertQuestionInRange(topic, difficulty, controller.state.currentQuestion);

            // Answer 500 questions sequentially through real controller path
            for (var i = 1; i < 500; i++) {
              final q = controller.state.currentQuestion;
              assertQuestionInRange(topic, difficulty, q);

              // Answer correctly to advance
              final digits = q.correctAnswer.abs().toString().split('');
              if (q.correctAnswer < 0) {
                controller.inputMinus();
              }
              for (final digit in digits) {
                controller.inputDigit(digit);
              }
              if (!controller.state.config.autoSubmit) {
                controller.submit();
              }
            }
          });
        }
      }
    }
  });
}
