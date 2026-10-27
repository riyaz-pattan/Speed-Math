import 'dart:math';

import '../../../core/enums/enums.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Quadratic Equations.
///
/// Supports two primary competitive exam modes:
/// 1. Finding roots of a quadratic equation (Dual Root input boxes with ± support).
///    - Guaranteed real, rational integer roots (Discriminant Δ ≥ 0 is always a perfect square).
/// 2. Comparing two equations (Quantity I in x vs Quantity II in y) with 5 standard exam options:
///    - x > y
///    - x < y
///    - x ≥ y
///    - x ≤ y
///    - x = y or CND (Relationship cannot be established)
class QuadraticEquationsGenerator extends QuestionGenerator {
  static const List<String> standardComparisonOptions = [
    'x > y',
    'x < y',
    'x ≥ y',
    'x ≤ y',
    'x = y or CND',
  ];

  @override
  Topic get topic => Topic.quadraticEquations;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  }) {
    final bool isComparison;
    if (pattern != null) {
      if (pattern.contains('compare') ||
          pattern.contains('Compare') ||
          pattern.contains('comparison')) {
        isComparison = true;
      } else if (pattern.contains('roots') ||
          pattern.contains('Roots') ||
          pattern.contains('Finding')) {
        isComparison = false;
      } else {
        isComparison = random.nextBool();
      }
    } else {
      // 50% Root Finding, 50% Equation Comparison across difficulties
      isComparison = random.nextBool();
    }

    if (isComparison) {
      return _generateComparisonQuestion(difficulty, random);
    } else {
      return _generateRootFindingQuestion(difficulty, random);
    }
  }

  @override
  String patternOf(Difficulty difficulty, List<int> operands) {
    return 'quad_${difficulty.name}';
  }

  /// Generates a single quadratic equation with guaranteed real integer roots.
  Question _generateRootFindingQuestion(Difficulty difficulty, Random random) {
    int r1;
    int r2;
    int a = 1;

    switch (difficulty) {
      case Difficulty.easy:
        // Simple positive or mixed roots, a = 1
        r1 = random.nextInt(9) + 1; // 1..9
        r2 = random.nextInt(9) + 1; // 1..9
        if (random.nextBool()) r1 = -r1; // occasionally negative
        break;
      case Difficulty.medium:
        // Mixed signs roots, a = 1 or 2
        r1 = (random.nextInt(11) + 1) * (random.nextBool() ? 1 : -1); // -11..11
        r2 = (random.nextInt(11) + 1) * (random.nextBool() ? 1 : -1);
        if (random.nextBool()) a = 2;
        break;
      case Difficulty.hard:
        // Larger roots or leading coefficient a in {2, 3}
        r1 = (random.nextInt(14) + 1) * (random.nextBool() ? 1 : -1);
        r2 = (random.nextInt(14) + 1) * (random.nextBool() ? 1 : -1);
        a = random.nextBool() ? 2 : 3;
        break;
      case Difficulty.expert:
        // a in {3, 4, 5}, roots up to 18
        r1 = (random.nextInt(18) + 1) * (random.nextBool() ? 1 : -1);
        r2 = (random.nextInt(18) + 1) * (random.nextBool() ? 1 : -1);
        const expertAs = [3, 4, 5];
        a = expertAs[random.nextInt(expertAs.length)];
        break;
      case Difficulty.genius:
        // a in {4, 6, 8, 12}, large constant terms
        r1 = (random.nextInt(20) + 1) * (random.nextBool() ? 1 : -1);
        r2 = (random.nextInt(20) + 1) * (random.nextBool() ? 1 : -1);
        const geniusAs = [4, 6, 8, 12];
        a = geniusAs[random.nextInt(geniusAs.length)];
        break;
      case Difficulty.mixed:
        final r = random.nextInt(5);
        if (r == 0) {
          r1 = random.nextInt(9) + 1;
          r2 = random.nextInt(9) + 1;
          if (random.nextBool()) r1 = -r1;
        } else if (r == 1) {
          r1 = (random.nextInt(11) + 1) * (random.nextBool() ? 1 : -1);
          r2 = (random.nextInt(11) + 1) * (random.nextBool() ? 1 : -1);
          if (random.nextBool()) a = 2;
        } else if (r == 2) {
          r1 = (random.nextInt(14) + 1) * (random.nextBool() ? 1 : -1);
          r2 = (random.nextInt(14) + 1) * (random.nextBool() ? 1 : -1);
          a = random.nextBool() ? 2 : 3;
        } else if (r == 3) {
          r1 = (random.nextInt(18) + 1) * (random.nextBool() ? 1 : -1);
          r2 = (random.nextInt(18) + 1) * (random.nextBool() ? 1 : -1);
          const expertAs = [3, 4, 5];
          a = expertAs[random.nextInt(expertAs.length)];
        } else {
          r1 = (random.nextInt(20) + 1) * (random.nextBool() ? 1 : -1);
          r2 = (random.nextInt(20) + 1) * (random.nextBool() ? 1 : -1);
          const geniusAs = [4, 6, 8, 12];
          a = geniusAs[random.nextInt(geniusAs.length)];
        }
        break;
    }

    // Expand: a*(x - r1)*(x - r2) = a*x^2 - a*(r1 + r2)*x + a*(r1 * r2)
    final b = -a * (r1 + r2);
    final c = a * (r1 * r2);

    final eqString = _formatQuadratic(a, b, c, 'x');

    return Question(
      topic: topic,
      difficulty: difficulty,
      displayText: eqString,
      subtitleText: 'Enter both roots of the quadratic equation',
      operands: [a, b, c],
      correctAnswer: r1,
      rootAnswers: [r1, r2],
      pattern: 'quad_root_finding',
    );
  }

  /// Generates a two-equation comparison question (e.g. Quantity I in x vs Quantity II in y).
  Question _generateComparisonQuestion(Difficulty difficulty, Random random) {
    if (difficulty == Difficulty.genius) {
      return _generateGeniusComparisonQuestion(difficulty, random);
    }

    // Balanced distribution of desired outcome:
    // 0: x > y, 1: x < y, 2: x >= y, 3: x <= y, 4: CND (including -ve constant shortcut)
    final targetOutcome = random.nextInt(5);

    int x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    int ax = 1, ay = 1;

    switch (difficulty) {
      case Difficulty.easy:
        ax = 1;
        ay = 1;
        break;
      case Difficulty.medium:
        ax = random.nextBool() ? 1 : 2;
        ay = random.nextBool() ? 1 : 2;
        break;
      case Difficulty.hard:
        const hardAs = [2, 3];
        ax = hardAs[random.nextInt(hardAs.length)];
        ay = hardAs[random.nextInt(hardAs.length)];
        break;
      case Difficulty.expert:
        const expertAs = [3, 4, 5];
        ax = expertAs[random.nextInt(expertAs.length)];
        ay = expertAs[random.nextInt(expertAs.length)];
        break;
      case Difficulty.genius:
      case Difficulty.mixed:
        ax = 1;
        ay = 1;
        break;
    }

    final maxRoot = difficulty == Difficulty.expert ? 18 : 14;

    switch (targetOutcome) {
      case 0: // x > y (all x strictly greater than all y)
        if (difficulty == Difficulty.expert && random.nextBool()) {
          // Competitive Exam Signs Shortcut:
          // x roots both positive, y roots both negative => x > y instantly!
          x1 = random.nextInt(maxRoot ~/ 2) + 2; // +ve
          x2 = random.nextInt(maxRoot ~/ 2) + 2;
          y1 = -(random.nextInt(maxRoot ~/ 2) + 2); // -ve
          y2 = -(random.nextInt(maxRoot ~/ 2) + 2);
        } else {
          final baseY = random.nextInt(maxRoot ~/ 2) + 1;
          y1 = baseY;
          y2 = baseY + random.nextInt(3);
          final baseX = y2 + random.nextInt(4) + 1;
          x1 = baseX;
          x2 = baseX + random.nextInt(3);
        }
        break;

      case 1: // x < y (all x strictly less than all y)
        if (difficulty == Difficulty.expert && random.nextBool()) {
          // Competitive Exam Signs Shortcut:
          // x roots both negative, y roots both positive => x < y instantly!
          x1 = -(random.nextInt(maxRoot ~/ 2) + 2); // -ve
          x2 = -(random.nextInt(maxRoot ~/ 2) + 2);
          y1 = random.nextInt(maxRoot ~/ 2) + 2; // +ve
          y2 = random.nextInt(maxRoot ~/ 2) + 2;
        } else {
          final baseX = random.nextInt(maxRoot ~/ 2) + 1;
          x1 = baseX;
          x2 = baseX + random.nextInt(3);
          final baseY = x2 + random.nextInt(4) + 1;
          y1 = baseY;
          y2 = baseY + random.nextInt(3);
        }
        break;

      case 2: // x >= y (some x == y, none x < y)
        final shared = random.nextInt(maxRoot ~/ 2) + 3;
        y1 = shared - random.nextInt(3) - 1;
        y2 = shared;
        x1 = shared;
        x2 = shared + random.nextInt(3) + 1;
        break;

      case 3: // x <= y (some x == y, none x > y)
        final shared = random.nextInt(maxRoot ~/ 2) + 3;
        x1 = shared - random.nextInt(3) - 1;
        x2 = shared;
        y1 = shared;
        y2 = shared + random.nextInt(3) + 1;
        break;

      default: // 4: CND / Cannot be determined
        final isNegativeConstantTrick = random.nextBool();
        if (isNegativeConstantTrick) {
          // Golden Rule: Both constant terms negative => CND!
          x1 = random.nextInt(maxRoot ~/ 2) + 1;
          x2 = -(random.nextInt(maxRoot ~/ 2) + 1); // one +ve, one -ve => c < 0
          y1 = random.nextInt(maxRoot ~/ 2) + 1;
          y2 = -(random.nextInt(maxRoot ~/ 2) + 1); // one +ve, one -ve => c < 0
        } else {
          // Overlapping roots: x1 < y1 < x2 < y2
          final base = random.nextInt(maxRoot ~/ 2) + 2;
          x1 = base;
          y1 = base + 2;
          x2 = base + 4;
          y2 = base + 6;
        }
        break;
    }

    final bx = -ax * (x1 + x2);
    final cx = ax * (x1 * x2);

    final by = -ay * (y1 + y2);
    final cy = ay * (y1 * y2);

    final eqX = _formatQuadratic(ax, bx, cx, 'x');
    final eqY = _formatQuadratic(ay, by, cy, 'y');

    final expectedRelation = _computeRelation(x1, x2, y1, y2, cx, cy);
    final correctIndex = standardComparisonOptions.indexOf(expectedRelation);

    return Question(
      topic: topic,
      difficulty: difficulty,
      displayText: 'I: $eqX\nII: $eqY',
      subtitleText: 'Compare Quantity x and Quantity y',
      operands: [ax, bx, cx, ay, by, cy],
      correctAnswer: correctIndex,
      stringAnswer: expectedRelation,
      options: standardComparisonOptions,
      pattern: 'quad_comparison',
    );
  }

  /// Genius comparison: a in {4, 6, 8, 12}, large constant terms, fractional roots,
  /// 5-choice competitive exam comparison.
  Question _generateGeniusComparisonQuestion(Difficulty difficulty, Random random) {
    const geniusAs = [4, 6, 8, 12];
    final ax = geniusAs[random.nextInt(geniusAs.length)];
    final ay = geniusAs[random.nextInt(geniusAs.length)];

    // Factor pairs for ax and ay: (d1 * d2 = ax, d3 * d4 = ay)
    final (d1, d2) = _pickFactorPair(ax, random);
    final (d3, d4) = _pickFactorPair(ay, random);

    final targetOutcome = random.nextInt(5);
    int p1 = 0, p2 = 0, q1 = 0, q2 = 0;

    switch (targetOutcome) {
      case 0: // x > y: roots of x strictly > roots of y
        final baseY = random.nextInt(5) + 2; // 2..6
        q1 = baseY * d3;
        q2 = (baseY + random.nextInt(2) + 1) * d4;
        final maxRy = max(q1 / d3, q2 / d4);
        final baseX = (maxRy + random.nextInt(3) + 1).toInt();
        p1 = baseX * d1;
        p2 = (baseX + random.nextInt(3) + 1) * d2;
        break;

      case 1: // x < y: roots of x strictly < roots of y
        final baseX = random.nextInt(5) + 2;
        p1 = baseX * d1;
        p2 = (baseX + random.nextInt(2) + 1) * d2;
        final maxRx = max(p1 / d1, p2 / d2);
        final baseY = (maxRx + random.nextInt(3) + 1).toInt();
        q1 = baseY * d3;
        q2 = (baseY + random.nextInt(3) + 1) * d4;
        break;

      case 2: // x >= y: shared root and x has larger root
        final shared = random.nextInt(5) + 4;
        p1 = shared * d1; // shared root
        q1 = shared * d3; // shared root
        q2 = (shared - random.nextInt(2) - 1) * d4; // smaller root for y
        p2 = (shared + random.nextInt(3) + 1) * d2; // larger root for x
        break;

      case 3: // x <= y: shared root and y has larger root
        final shared = random.nextInt(5) + 4;
        p1 = shared * d1; // shared root
        q1 = shared * d3; // shared root
        p2 = (shared - random.nextInt(2) - 1) * d2; // smaller root for x
        q2 = (shared + random.nextInt(3) + 1) * d4; // larger root for y
        break;

      default: // 4: CND / Cannot be determined
        if (random.nextBool()) {
          // Double negative constant trick
          p1 = (random.nextInt(8) + 2) * d1;
          p2 = -(random.nextInt(8) + 2) * d2;
          q1 = (random.nextInt(8) + 2) * d3;
          q2 = -(random.nextInt(8) + 2) * d4;
        } else {
          // Overlapping fractional roots: rx1 < ry1 < rx2 < ry2
          final base = random.nextInt(4) + 2;
          p1 = base * d1;
          q1 = (base + 2) * d3;
          p2 = (base + 4) * d2;
          q2 = (base + 6) * d4;
        }
        break;
    }

    // Expand (d1*x - p1)*(d2*x - p2) = ax*x^2 - (d1*p2 + d2*p1)*x + p1*p2
    final bx = -(d1 * p2 + d2 * p1);
    final cx = p1 * p2;

    // Expand (d3*y - q1)*(d4*y - q2) = ay*y^2 - (d3*q2 + d4*q1)*y + q1*q2
    final by = -(d3 * q2 + d4 * q1);
    final cy = q1 * q2;

    final rx1 = p1 / d1;
    final rx2 = p2 / d2;
    final ry1 = q1 / d3;
    final ry2 = q2 / d4;

    final eqX = _formatQuadratic(ax, bx, cx, 'x');
    final eqY = _formatQuadratic(ay, by, cy, 'y');

    final expectedRelation = _computeRelation(rx1, rx2, ry1, ry2, cx, cy);
    final correctIndex = standardComparisonOptions.indexOf(expectedRelation);

    return Question(
      topic: topic,
      difficulty: difficulty,
      displayText: 'I: $eqX\nII: $eqY',
      subtitleText: 'Compare Quantity x and Quantity y',
      operands: [ax, bx, cx, ay, by, cy],
      correctAnswer: correctIndex,
      stringAnswer: expectedRelation,
      options: standardComparisonOptions,
      pattern: 'quad_comparison',
    );
  }

  (int, int) _pickFactorPair(int a, Random random) {
    switch (a) {
      case 4:
        return random.nextBool() ? (2, 2) : (4, 1);
      case 6:
        final r = random.nextInt(3);
        if (r == 0) return (2, 3);
        if (r == 1) return (3, 2);
        return (6, 1);
      case 8:
        final r = random.nextInt(3);
        if (r == 0) return (2, 4);
        if (r == 1) return (4, 2);
        return (8, 1);
      case 12:
        final r = random.nextInt(4);
        if (r == 0) return (3, 4);
        if (r == 1) return (4, 3);
        if (r == 2) return (2, 6);
        return (6, 2);
      default:
        return (a, 1);
    }
  }

  /// Computes the exact competitive exam relationship between roots of x and roots of y.
  String _computeRelation(num x1, num x2, num y1, num y2, int cx, int cy) {
    // 2-Second Shortcut: If both constant terms are negative, relation is CND
    if (cx < 0 && cy < 0) {
      return 'x = y or CND';
    }

    final rootsX = [x1.toDouble(), x2.toDouble()];
    final rootsY = [y1.toDouble(), y2.toDouble()];

    bool hasGreater = false;
    bool hasLess = false;
    bool hasEqual = false;
    const eps = 1e-9;

    for (final x in rootsX) {
      for (final y in rootsY) {
        if (x - y > eps) {
          hasGreater = true;
        } else if (y - x > eps) {
          hasLess = true;
        } else {
          hasEqual = true;
        }
      }
    }

    if (hasGreater && hasLess) {
      return 'x = y or CND';
    }
    if (hasGreater && hasEqual) {
      return 'x ≥ y';
    }
    if (hasLess && hasEqual) {
      return 'x ≤ y';
    }
    if (hasGreater && !hasLess && !hasEqual) {
      return 'x > y';
    }
    if (hasLess && !hasGreater && !hasEqual) {
      return 'x < y';
    }
    return 'x = y or CND';
  }

  String _formatQuadratic(int a, int b, int c, String varName) {
    final StringBuffer sb = StringBuffer();

    // a * x^2
    if (a == 1) {
      sb.write('$varName²');
    } else {
      sb.write('$a$varName²');
    }

    // b * x
    if (b > 0) {
      sb.write(' + ');
      if (b == 1) {
        sb.write(varName);
      } else {
        sb.write('$b$varName');
      }
    } else if (b < 0) {
      sb.write(' - ');
      final absB = b.abs();
      if (absB == 1) {
        sb.write(varName);
      } else {
        sb.write('$absB$varName');
      }
    }

    // c
    if (c > 0) {
      sb.write(' + $c');
    } else if (c < 0) {
      sb.write(' - ${c.abs()}');
    }

    sb.write(' = 0');
    return sb.toString();
  }
}
