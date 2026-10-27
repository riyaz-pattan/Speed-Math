import 'dart:math';

import '../../../core/enums/enums.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Linear Equations.
///
/// Difficulty progression:
/// - Easy: Single-variable equations (e.g. x + 5 = 5, 3x - 7 = 14) with positive/negative integer roots.
/// - Medium: 2-variable linear systems (e.g. 2x + y = 11, x - y = 1) asking for x, y, or comparing x vs y.
/// - Hard: 3-variable symmetric systems (e.g. x + y + z = 12, 2x + y + z = 15) or cross-swapped symmetric systems.
class LinearEquationsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.linearEquations;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  }) {
    switch (difficulty) {
      case Difficulty.easy:
        return _generateEasy(random);
      case Difficulty.medium:
        return _generateMedium(random);
      case Difficulty.hard:
        return _generateHard(random);
      case Difficulty.expert:
        return _generateExpert(random);
      case Difficulty.genius:
        return _generateGenius(random);
      case Difficulty.mixed:
        final r = random.nextInt(5);
        if (r == 0) return _generateEasy(random);
        if (r == 1) return _generateMedium(random);
        if (r == 2) return _generateHard(random);
        if (r == 3) return _generateExpert(random);
        return _generateGenius(random);
    }
  }

  @override
  String patternOf(Difficulty difficulty, List<int> operands) {
    return 'linear_${difficulty.name}';
  }

  /// Easy: Single-variable linear equations
  Question _generateEasy(Random random) {
    final type = random.nextInt(3);

    if (type == 0) {
      // x + b = c
      final x = random.nextInt(25) - 10; // -10 to 14
      final b = (random.nextInt(20) + 1) * (random.nextBool() ? 1 : -1);
      final c = x + b;
      final sign = b >= 0 ? '+ $b' : '- ${b.abs()}';

      return Question(
        topic: topic,
        difficulty: Difficulty.easy,
        displayText: 'x $sign = $c',
        subtitleText: 'Find the value of x',
        operands: [b, c],
        correctAnswer: x,
        pattern: 'linear_1var_add',
      );
    } else if (type == 1) {
      // ax = c
      final a = (random.nextInt(8) + 2) * (random.nextBool() ? 1 : -1); // 2..9 or -9..-2
      final x = random.nextInt(19) - 9; // -9 to 9
      final c = a * x;

      return Question(
        topic: topic,
        difficulty: Difficulty.easy,
        displayText: '${a}x = $c',
        subtitleText: 'Find the value of x',
        operands: [a, c],
        correctAnswer: x,
        pattern: 'linear_1var_mult',
      );
    } else {
      // ax + b = c
      final a = random.nextInt(6) + 2; // 2..7
      final x = random.nextInt(21) - 10; // -10 to 10
      final b = (random.nextInt(15) + 1) * (random.nextBool() ? 1 : -1);
      final c = a * x + b;
      final sign = b >= 0 ? '+ $b' : '- ${b.abs()}';

      return Question(
        topic: topic,
        difficulty: Difficulty.easy,
        displayText: '${a}x $sign = $c',
        subtitleText: 'Find the value of x',
        operands: [a, b, c],
        correctAnswer: x,
        pattern: 'linear_1var_step',
      );
    }
  }

  /// Medium: 2-variable linear systems (solve for a variable or compare)
  Question _generateMedium(Random random) {
    final isComparison = random.nextBool();

    // Integer solutions
    final x = random.nextInt(17) - 8; // -8 to 8
    final y = random.nextInt(17) - 8; // -8 to 8

    // Generate small coefficients with non-zero determinant
    int a1 = random.nextInt(4) + 1;
    int b1 = (random.nextInt(3) + 1) * (random.nextBool() ? 1 : -1);
    int a2 = random.nextInt(3) + 1;
    int b2 = (random.nextInt(3) + 1) * (random.nextBool() ? 1 : -1);

    if (a1 * b2 - a2 * b1 == 0) {
      b2 = b2 > 0 ? b2 + 1 : b2 - 1;
    }

    final c1 = a1 * x + b1 * y;
    final c2 = a2 * x + b2 * y;

    final eq1 = '${_formatTerm(a1, 'x')} ${_formatSignedTerm(b1, 'y')} = $c1';
    final eq2 = '${_formatTerm(a2, 'x')} ${_formatSignedTerm(b2, 'y')} = $c2';

    if (isComparison) {
      // Compare x vs y
      final String relation;
      if (x > y) {
        relation = 'x > y';
      } else if (x < y) {
        relation = 'x < y';
      } else {
        relation = 'x = y or CND';
      }

      const options = [
        'x > y',
        'x < y',
        'x ≥ y',
        'x ≤ y',
        'x = y or CND',
      ];
      final correctIndex = options.indexOf(relation);

      return Question(
        topic: topic,
        difficulty: Difficulty.medium,
        displayText: '$eq1\n$eq2',
        subtitleText: 'Compare Quantity x and Quantity y',
        operands: [c1, c2],
        correctAnswer: correctIndex,
        stringAnswer: relation,
        options: options,
        pattern: 'linear_2var_compare',
      );
    } else {
      // Solve for x or y
      final solveForX = random.nextBool();
      final targetVar = solveForX ? 'x' : 'y';
      final answer = solveForX ? x : y;

      return Question(
        topic: topic,
        difficulty: Difficulty.medium,
        displayText: '$eq1\n$eq2',
        subtitleText: 'Find the value of $targetVar',
        operands: [c1, c2],
        correctAnswer: answer,
        pattern: 'linear_2var_solve',
      );
    }
  }

  /// Hard: 3-variable systems or symmetric addition trick
  Question _generateHard(Random random) {
    final type = random.nextInt(2);

    if (type == 0) {
      // Symmetric addition trick:
      // a x + b y = c1
      // b x + a y = c2
      // Find x + y (simply (c1 + c2) / (a + b))
      final a = random.nextInt(15) + 10; // 10..24
      final b = random.nextInt(15) + 25; // 25..39
      final x = random.nextInt(9) + 1; // 1..9
      final y = random.nextInt(9) + 1; // 1..9
      final c1 = a * x + b * y;
      final c2 = b * x + a * y;

      return Question(
        topic: topic,
        difficulty: Difficulty.hard,
        displayText: '${a}x + ${b}y = $c1\n${b}x + ${a}y = $c2',
        subtitleText: 'Find the value of x + y',
        operands: [a, b, c1, c2],
        correctAnswer: x + y,
        pattern: 'linear_symmetric_sum',
      );
    } else {
      // 3-variable system with rapid elimination
      final x = random.nextInt(9) + 1; // 1..9
      final y = random.nextInt(9) + 1; // 1..9
      final z = random.nextInt(9) + 1; // 1..9

      // Eq 1: x + y + z = S
      final s = x + y + z;
      // Eq 2: 2x + y + z = s + x
      final s2 = 2 * x + y + z;
      // Eq 3: x + 2y + z = s + y
      final s3 = x + 2 * y + z;

      return Question(
        topic: topic,
        difficulty: Difficulty.hard,
        displayText: 'x + y + z = $s\n2x + y + z = $s2\nx + 2y + z = $s3',
        subtitleText: 'Find the value of x',
        operands: [s, s2, s3],
        correctAnswer: x,
        pattern: 'linear_3var_elimination',
      );
    }
  }

  /// Expert: 3-variable systems with negative/fractional components or larger coefficients (e.g. 5x + 3y + 2z = 45), or find (x + y + z)
  Question _generateExpert(Random random) {
    final type = random.nextInt(3);

    if (type == 0) {
      // Find x + y + z from cyclic symmetric system with larger coefficients
      // a x + b y + c z = c1
      // b x + c y + a z = c2
      // c x + a y + b z = c3
      // Sum = (a + b + c)(x + y + z) = c1 + c2 + c3
      const coeffTriples = [
        [5, 3, 2], // sum = 10
        [6, 3, 1], // sum = 10
        [5, 4, 1], // sum = 10
        [7, 2, 1], // sum = 10
        [4, 3, 2], // sum = 9
        [6, 5, 4], // sum = 15
      ];
      final triple = coeffTriples[random.nextInt(coeffTriples.length)];
      final a = triple[0];
      final b = triple[1];
      final c = triple[2];

      final x = random.nextInt(15) - 5; // -5..9
      final y = random.nextInt(15) - 5;
      final z = random.nextInt(15) - 5;

      final c1 = a * x + b * y + c * z;
      final c2 = b * x + c * y + a * z;
      final c3 = c * x + a * y + b * z;

      final eq1 = '${_formatTerm(a, 'x')} ${_formatSignedTerm(b, 'y')} ${_formatSignedTerm(c, 'z')} = $c1';
      final eq2 = '${_formatTerm(b, 'x')} ${_formatSignedTerm(c, 'y')} ${_formatSignedTerm(a, 'z')} = $c2';
      final eq3 = '${_formatTerm(c, 'x')} ${_formatSignedTerm(a, 'y')} ${_formatSignedTerm(b, 'z')} = $c3';

      return Question(
        topic: topic,
        difficulty: Difficulty.expert,
        displayText: '$eq1\n$eq2\n$eq3',
        subtitleText: 'Find the value of x + y + z',
        operands: [c1, c2, c3],
        correctAnswer: x + y + z,
        pattern: 'linear_3var_sum',
      );
    } else if (type == 1) {
      // 3-variable pairwise sum with negative roots:
      // x + y = a
      // y + z = b
      // x + z = c
      // (a + b + c) / 2 = x + y + z
      final x = random.nextInt(21) - 10; // -10..10
      final y = random.nextInt(21) - 10;
      final z = random.nextInt(21) - 10;

      final a = x + y;
      final b = y + z;
      final c = x + z;

      final targetVarChoice = random.nextInt(3);
      final String targetVar;
      final int targetVal;
      if (targetVarChoice == 0) {
        targetVar = 'x';
        targetVal = x;
      } else if (targetVarChoice == 1) {
        targetVar = 'y';
        targetVal = y;
      } else {
        targetVar = 'z';
        targetVal = z;
      }

      return Question(
        topic: topic,
        difficulty: Difficulty.expert,
        displayText: 'x + y = $a\ny + z = $b\nx + z = $c',
        subtitleText: 'Find the value of $targetVar',
        operands: [a, b, c],
        correctAnswer: targetVal,
        pattern: 'linear_3var_pairwise',
      );
    } else {
      // 3-variable system with fractional components / elimination:
      // x + y + z = S
      // x/2 + y + z = c1   => x/2 = S - c1 => x = 2*(S - c1)
      // x + y + z/2 = c2   => z/2 = S - c2 => z = 2*(S - c2)
      final x = (random.nextInt(10) + 1) * 2; // 2, 4, 6..20
      final y = random.nextInt(15) + 1; // 1..15
      final z = (random.nextInt(10) + 1) * 2; // 2, 4, 6..20

      final s = x + y + z;
      final c1 = (x ~/ 2) + y + z;
      final c2 = x + y + (z ~/ 2);

      final solveForX = random.nextBool();
      final targetVar = solveForX ? 'x' : 'z';
      final targetVal = solveForX ? x : z;

      return Question(
        topic: topic,
        difficulty: Difficulty.expert,
        displayText: 'x + y + z = $s\nx/2 + y + z = $c1\nx + y + z/2 = $c2',
        subtitleText: 'Find the value of $targetVar',
        operands: [s, c1, c2],
        correctAnswer: targetVal,
        pattern: 'linear_3var_fractional',
      );
    }
  }

  /// Genius: 3-variable systems with tricky elimination, or 4-variable symmetric systems (x+y+z=a, y+z+w=b, etc.), or competitive exam ratio comparison of variables
  Question _generateGenius(Random random) {
    final type = random.nextInt(3);

    if (type == 0) {
      // 4-variable symmetric system:
      // x + y + z = a
      // y + z + w = b
      // z + w + x = c
      // w + x + y = d
      // Sum = 3(x + y + z + w) = a + b + c + d
      // Total = (a + b + c + d) / 3
      // w = Total - a, x = Total - b, y = Total - c, z = Total - d
      final x = random.nextInt(15) + 1; // 1..15
      final y = random.nextInt(15) + 1;
      final z = random.nextInt(15) + 1;
      final w = random.nextInt(15) + 1;

      final a = x + y + z;
      final b = y + z + w;
      final c = z + w + x;
      final d = w + x + y;

      final targetChoice = random.nextInt(5);
      final String targetVar;
      final int targetVal;

      if (targetChoice == 0) {
        targetVar = 'x';
        targetVal = x;
      } else if (targetChoice == 1) {
        targetVar = 'y';
        targetVal = y;
      } else if (targetChoice == 2) {
        targetVar = 'z';
        targetVal = z;
      } else if (targetChoice == 3) {
        targetVar = 'w';
        targetVal = w;
      } else {
        targetVar = 'x + y + z + w';
        targetVal = x + y + z + w;
      }

      return Question(
        topic: topic,
        difficulty: Difficulty.genius,
        displayText: 'x + y + z = $a\ny + z + w = $b\nz + w + x = $c\nw + x + y = $d',
        subtitleText: 'Find the value of $targetVar',
        operands: [a, b, c, d],
        correctAnswer: targetVal,
        pattern: 'linear_4var_symmetric',
      );
    } else if (type == 1) {
      // 3-variable system with tricky elimination:
      // Eq 1: 3x + 2y + z = c1
      // Eq 2: 2x + 2y + z = c2  (Eq 1 - Eq 2 => x = c1 - c2)
      // Eq 3: x + 3y + z = c3   (Eq 3 - Eq 2 => y - x = c3 - c2 => y = c3 - c2 + x)
      final x = random.nextInt(17) - 8; // -8..8
      final y = random.nextInt(17) - 8;
      final z = random.nextInt(17) - 8;

      final c1 = 3 * x + 2 * y + z;
      final c2 = 2 * x + 2 * y + z;
      final c3 = x + 3 * y + z;

      final targetChoice = random.nextInt(3);
      final String targetVar;
      final int targetVal;
      if (targetChoice == 0) {
        targetVar = 'x';
        targetVal = x;
      } else if (targetChoice == 1) {
        targetVar = 'y';
        targetVal = y;
      } else {
        targetVar = 'z';
        targetVal = z;
      }

      final eq1 = '${_formatTerm(3, 'x')} ${_formatSignedTerm(2, 'y')} + z = $c1';
      final eq2 = '${_formatTerm(2, 'x')} ${_formatSignedTerm(2, 'y')} + z = $c2';
      final eq3 = 'x ${_formatSignedTerm(3, 'y')} + z = $c3';

      return Question(
        topic: topic,
        difficulty: Difficulty.genius,
        displayText: '$eq1\n$eq2\n$eq3',
        subtitleText: 'Find the value of $targetVar',
        operands: [c1, c2, c3],
        correctAnswer: targetVal,
        pattern: 'linear_3var_tricky_elim',
      );
    } else {
      // Competitive exam ratio comparison of variables
      final x = random.nextInt(25) - 12; // -12..12
      final y = random.nextInt(25) - 12; // -12..12

      int a1 = random.nextInt(5) + 3; // 3..7
      int b1 = (random.nextInt(4) + 2) * (random.nextBool() ? 1 : -1);
      int a2 = random.nextInt(4) + 2; // 2..5
      int b2 = (random.nextInt(4) + 2) * (random.nextBool() ? 1 : -1);

      if (a1 * b2 - a2 * b1 == 0) {
        b2 = b2 > 0 ? b2 + 1 : b2 - 1;
      }

      final c1 = a1 * x + b1 * y;
      final c2 = a2 * x + b2 * y;

      final eq1 = '${_formatTerm(a1, 'x')} ${_formatSignedTerm(b1, 'y')} = $c1';
      final eq2 = '${_formatTerm(a2, 'x')} ${_formatSignedTerm(b2, 'y')} = $c2';

      final String relation;
      if (x > y) {
        relation = 'x > y';
      } else if (x < y) {
        relation = 'x < y';
      } else {
        relation = 'x = y or CND';
      }

      const options = [
        'x > y',
        'x < y',
        'x ≥ y',
        'x ≤ y',
        'x = y or CND',
      ];
      final correctIndex = options.indexOf(relation);

      return Question(
        topic: topic,
        difficulty: Difficulty.genius,
        displayText: '$eq1\n$eq2',
        subtitleText: 'Compare Quantity x and Quantity y',
        operands: [c1, c2],
        correctAnswer: correctIndex,
        stringAnswer: relation,
        options: options,
        pattern: 'linear_ratio_compare',
      );
    }
  }

  String _formatTerm(int coeff, String variable) {
    if (coeff == 1) return variable;
    if (coeff == -1) return '-$variable';
    return '$coeff$variable';
  }

  String _formatSignedTerm(int coeff, String variable) {
    final absCoeff = coeff.abs();
    final sign = coeff >= 0 ? '+' : '-';
    final term = absCoeff == 1 ? variable : '$absCoeff$variable';
    return '$sign $term';
  }
}
