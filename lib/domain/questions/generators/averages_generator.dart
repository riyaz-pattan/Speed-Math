import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for practical Averages.
///
/// Features:
/// - Real-world practical question templates (groups, joining/leaving, weighted averages, series).
/// - Guarantees strictly whole positive answers.
class AveragesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.averages;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  }) {
    Question q;
    int tries = 0;
    do {
      final raw = switch (difficulty) {
        Difficulty.easy => _generateEasy(random, targetPattern: pattern),
        Difficulty.medium => _generateMedium(random, targetPattern: pattern),
        Difficulty.hard => _generateHard(random, targetPattern: pattern),
        Difficulty.expert => _generateExpert(random, targetPattern: pattern),
        Difficulty.genius => _generateGenius(random, targetPattern: pattern),
        Difficulty.mixed =>
          throw ArgumentError('Cannot generate Difficulty.mixed directly'),
      };

      final pat = patternOf(difficulty, raw.operands);
      q = Question(
        topic: raw.topic,
        difficulty: difficulty,
        displayText: raw.displayText,
        operands: raw.operands,
        correctAnswer: raw.correctAnswer,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }

  Question _generateEasy(Random random, {String? targetPattern}) {
    // 3 templates:
    // 1: Average of 4 or 5 given numbers
    // 2: "The average of 5 numbers is X, what is their sum?"
    // 3: Average of first N natural, even, or odd numbers
    final template = targetPattern == PatternConstants.avgEGroupSum
        ? 2
        : (targetPattern == PatternConstants.avgEConsec
            ? 3
            : (1 + random.nextInt(3)));

    if (template == 2) {
      // "The average of N numbers is X, what is their sum?"
      final count = 4 + random.nextInt(3); // 4..6
      final avg = 15 + random.nextInt(35); // 15..49
      final sum = count * avg;
      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.easy,
        displayText: 'The average of $count numbers is $avg. What is their sum?',
        operands: [count, avg, sum, 2],
        correctAnswer: sum,
      );
    } else if (template == 3) {
      // First N numbers
      final sub = random.nextInt(3);
      if (sub == 0) {
        // First N natural numbers (N must be odd so (N+1)/2 is integer)
        final n = (5 + random.nextInt(15)) * 2 + 1; // odd
        final ans = (n + 1) ~/ 2;
        return Question(
          topic: Topic.averages,
          difficulty: Difficulty.easy,
          displayText: 'Find the average of the first $n natural numbers.',
          operands: [n, ans, 3],
          correctAnswer: ans,
        );
      } else if (sub == 1) {
        // First N even numbers: avg is N + 1
        final n = 6 + random.nextInt(20);
        final ans = n + 1;
        return Question(
          topic: Topic.averages,
          difficulty: Difficulty.easy,
          displayText: 'Find the average of the first $n even numbers.',
          operands: [n, ans, 3],
          correctAnswer: ans,
        );
      } else {
        // First N odd numbers: avg is N
        final n = 7 + random.nextInt(20);
        final ans = n;
        return Question(
          topic: Topic.averages,
          difficulty: Difficulty.easy,
          displayText: 'Find the average of the first $n odd numbers.',
          operands: [n, ans, 3],
          correctAnswer: ans,
        );
      }
    } else {
      // 4 or 5 numbers
      final count = random.nextBool() ? 4 : 5;
      final avg = 20 + random.nextInt(50);
      final nums = <int>[];
      int sum = 0;
      for (int i = 0; i < count - 1; i++) {
        final d = (random.nextInt(12) + 1) * (random.nextBool() ? 1 : -1);
        final v = max(10, avg + d);
        nums.add(v);
        sum += v;
      }
      final last = (count * avg) - sum;
      nums.add(last > 0 ? last : avg);
      final realSum = nums.reduce((a, b) => a + b);
      // Adjust last if needed
      final rem = realSum % count;
      if (rem != 0) {
        nums[count - 1] += (count - rem);
      }
      final finalAvg = nums.reduce((a, b) => a + b) ~/ count;

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.easy,
        displayText: 'Average of ${nums.join(', ')} = ?',
        operands: [...nums, 1],
        correctAnswer: finalAvg,
      );
    }
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    // 3 templates:
    // 1: Person joins or leaves group and average changes
    // 2: One number removed or replaced from group
    // 3: 3 numbers avg is A, two given, find third
    final template = targetPattern == PatternConstants.avgMJoinLeave
        ? 1
        : (targetPattern == PatternConstants.avgMOneRemoved
            ? 2
            : (1 + random.nextInt(3)));

    if (template == 1) {
      // Member joins: e.g. 4 friends avg age 24. 5th aged 29 joins. What is new average?
      final count = 4 + random.nextInt(2); // 4 or 5
      final oldAvg = 20 + random.nextInt(25);
      final joinDiff = (count + 1) * (1 + random.nextInt(3)); // ensures new avg is whole!
      final newMemberAge = oldAvg + joinDiff;
      final newAvg = oldAvg + (joinDiff ~/ (count + 1));

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.medium,
        displayText:
            'The average age of $count friends is $oldAvg. A new friend aged $newMemberAge joins. What is the new average?',
        operands: [count, oldAvg, newMemberAge, newAvg, 2],
        correctAnswer: newAvg,
      );
    } else if (template == 2) {
      // One number removed: e.g. Average of 5 numbers is 20. One removed, average becomes 18. Find removed.
      final totalCount = 5;
      final oldAvg = 20 + random.nextInt(30);
      final newAvg = oldAvg - (1 + random.nextInt(3));
      final removed = (totalCount * oldAvg) - ((totalCount - 1) * newAvg);

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.medium,
        displayText:
            'The average of $totalCount numbers is $oldAvg. When one number is removed, the average becomes $newAvg. Find the removed number.',
        operands: [totalCount, oldAvg, newAvg, removed, 3],
        correctAnswer: removed,
      );
    } else {
      // Average of 3 numbers is A. Two of them are X and Y. Find third.
      final avg = 25 + random.nextInt(40);
      final total = avg * 3;
      final x = avg - (2 + random.nextInt(15));
      final y = avg + (1 + random.nextInt(12));
      final z = total - x - y;

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.medium,
        displayText:
            'The average of 3 numbers is $avg. Two of them are $x and $y. Find the third.',
        operands: [avg, x, y, z, 1],
        correctAnswer: z,
      );
    }
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    // 3 templates:
    // 1: Weighted average of two groups
    // 2: Member replaced causing average change
    // 3: Average of multiples or series
    final template = targetPattern == PatternConstants.avgHWeighted
        ? 1
        : (targetPattern == PatternConstants.avgHMemberReplaced
            ? 2
            : (1 + random.nextInt(3)));

    if (template == 1) {
      // Weighted average: e.g. 20 students avg 60, 30 students avg 70 -> all 50
      final count1 = 20;
      final count2 = 30;
      final avg1 = 50 + (random.nextInt(6) * 5); // 50, 55, 60, 65, 70, 75
      final avg2 = avg1 + 10;
      final totalScore = (count1 * avg1) + (count2 * avg2);
      final combinedAvg = totalScore ~/ (count1 + count2);

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.hard,
        displayText:
            'The average marks of $count1 students is $avg1 and of $count2 students is $avg2. Find the average of all ${count1 + count2} students.',
        operands: [count1, avg1, count2, avg2, combinedAvg, 2],
        correctAnswer: combinedAvg,
      );
    } else if (template == 2) {
      // Average weight increases/decreases when person replaced
      final count = 8;
      final change = 1 + random.nextInt(3); // increases by change
      final oldPersonWeight = 45 + random.nextInt(25);
      final newPersonWeight = oldPersonWeight + (count * change);

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.hard,
        displayText:
            'The average weight of $count people increases by $change kg when a person weighing $oldPersonWeight kg is replaced by a new person. Find the weight of the new person.',
        operands: [count, change, oldPersonWeight, newPersonWeight, 3],
        correctAnswer: newPersonWeight,
      );
    } else {
      // Average of multiples: e.g. Average of first 9 multiples of 7
      // multiples of K: K * 1, K * 2 ... K * M -> avg is K * (M + 1) / 2
      final k = 3 + random.nextInt(10);
      final m = (3 + random.nextInt(5)) * 2 + 1; // odd count (7, 9, 11)
      final ans = k * (m + 1) ~/ 2;

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.hard,
        displayText: 'Find the average of the first $m multiples of $k.',
        operands: [m, k, ans, 1],
        correctAnswer: ans,
      );
    }
  }

  Question _generateExpert(Random random, {String? targetPattern}) {
    final count = random.nextBool() ? 6 : 7;
    final targetAvg = 80 + random.nextInt(240); // 80..319
    final nums = <int>[];
    int sum = 0;
    for (int i = 0; i < count - 1; i++) {
      final d = -35 + random.nextInt(71);
      final v = (targetAvg + d).clamp(30, 400);
      nums.add(v);
      sum += v;
    }
    var last = (count * targetAvg) - sum;
    if (last < 30 || last > 400) {
      last = targetAvg;
      nums.add(last);
      final total = nums.reduce((a, b) => a + b);
      final rem = total % count;
      if (rem != 0) nums[count - 1] += (count - rem);
    } else {
      nums.add(last);
    }
    final finalAvg = nums.reduce((a, b) => a + b) ~/ count;

    final isMissing = random.nextBool();
    if (isMissing) {
      final hideIdx = random.nextInt(count);
      final ans = nums[hideIdx];
      final remaining = [...nums]..removeAt(hideIdx);
      final text =
          'The average of $count numbers is $finalAvg. ${count - 1} of them are ${remaining.join(', ')}. Find the missing number.';
      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [count, finalAvg, ...remaining, ans, 1],
        correctAnswer: ans,
      );
    } else {
      final text = 'Average of ${nums.join(', ')} = ?';
      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [...nums, finalAvg, 2],
        correctAnswer: finalAvg,
      );
    }
  }

  Question _generateGenius(Random random, {String? targetPattern}) {
    final useWeighted = random.nextBool();

    if (useWeighted) {
      const ratios = [
        (2, 3),
        (3, 2),
        (1, 3),
        (3, 1),
        (3, 4),
        (4, 3),
        (2, 5),
        (5, 2),
        (3, 5),
        (5, 3),
      ];
      final r = ratios[random.nextInt(ratios.length)];
      final rA = r.$1;
      final rB = r.$2;
      final m = 5 + random.nextInt(10);
      final countA = m * rA;
      final countB = m * rB;
      final totalCount = countA + countB;

      final combinedAvg = 45 + random.nextInt(45);
      final k = 1 + random.nextInt(3);
      final avgA = combinedAvg - (rB * k);
      final avgB = combinedAvg + (rA * k);

      final text =
          'Group A of $countA students has an average score of $avgA, and Group B of $countB students has an average score of $avgB. Find the combined average of all $totalCount students.';

      return Question(
        topic: Topic.averages,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [countA, avgA, countB, avgB, combinedAvg, 1],
        correctAnswer: combinedAvg,
      );
    } else {
      const count = 8;
      final targetAvg = 100 + random.nextInt(250);
      final nums = <int>[];
      int sum = 0;
      for (int i = 0; i < count - 1; i++) {
        final d = -40 + random.nextInt(81);
        final v = (targetAvg + d).clamp(30, 500);
        nums.add(v);
        sum += v;
      }
      var last = (count * targetAvg) - sum;
      if (last < 30 || last > 500) {
        last = targetAvg;
        nums.add(last);
        final total = nums.reduce((a, b) => a + b);
        final rem = total % count;
        if (rem != 0) nums[count - 1] += (count - rem);
      } else {
        nums.add(last);
      }
      final finalAvg = nums.reduce((a, b) => a + b) ~/ count;

      final isMissing = random.nextBool();
      if (isMissing) {
        final hideIdx = random.nextInt(count);
        final ans = nums[hideIdx];
        final remaining = [...nums]..removeAt(hideIdx);
        final text =
            'The average of $count numbers is $finalAvg. 7 of them are ${remaining.join(', ')}. Find the remaining number.';
        return Question(
          topic: Topic.averages,
          difficulty: Difficulty.genius,
          displayText: text,
          operands: [count, finalAvg, ...remaining, ans, 2],
          correctAnswer: ans,
        );
      } else {
        final text = 'Average of ${nums.join(', ')} = ?';
        return Question(
          topic: Topic.averages,
          difficulty: Difficulty.genius,
          displayText: text,
          operands: [...nums, finalAvg, 3],
          correctAnswer: finalAvg,
        );
      }
    }
  }
}
