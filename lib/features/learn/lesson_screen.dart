// lib/features/learn/lesson_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import '../results/widgets/confetti_burst.dart';
import 'engine/lesson_block.dart';
import 'engine/lesson_registry.dart';
import 'widgets/addition_custom_number_sheet.dart';
import 'widgets/addition_static_diagram.dart';
import 'widgets/applied_math_custom_number_sheet.dart';
import 'widgets/applied_math_static_diagram.dart';
import 'widgets/division_custom_number_sheet.dart';
import 'widgets/division_static_diagram.dart';
import 'widgets/lesson_stars.dart';
import 'widgets/mental_multiplication_custom_number_sheet.dart';
import 'widgets/mental_multiplication_static_diagram.dart';
import 'widgets/multiplication_custom_number_sheet.dart';
import 'widgets/multiplication_static_diagram.dart';
import 'widgets/squares_custom_number_sheet.dart';
import 'widgets/squares_static_diagram.dart';
import 'widgets/subtraction_custom_number_sheet.dart';
import 'widgets/subtraction_static_diagram.dart';
import 'widgets/variant_chooser.dart';

enum _Phase { variantChooser, active, done }

enum LessonDifficulty {
  beginner,
  easy,
  medium,
  hard,
  expert,
  genius,
}

enum LessonExamMode {
  questions,
  timer,
}

class _PracticeQ {
  const _PracticeQ({
    required this.ops,
    required this.answer,
    required this.questionText,
  });

  final List<int> ops;
  final int answer;
  final String questionText;
}

/// Comprehensive lesson screen supporting static diagrams (Addition & Subtraction)
/// and block player lessons with difficulty levels, exam modes, and conflict-free tabbed UI.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    this.initialOperands,
    this.initialVariantId,
  });

  final String lessonId;
  final List<int>? initialOperands;
  final String? initialVariantId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  _Phase _phase = _Phase.active;
  LessonMeta? _meta;
  String? _variantId;
  LessonVariant? _variant;
  late List<int> _operands;
  // ignore: unused_field
  late LessonScript _script;
  num? _customDivisor;

  num get _currentDivisor {
    if (_customDivisor != null) return _customDivisor!;
    if (_meta?.id == 'reciprocal_division') return 2.5;
    if (_operands.length > 1) return _operands[1];
    return 5;
  }

  // Active Tab: 0 = Shortcut Board / Lesson, 1 = Step Breakdown (FAQs), 2 = Practice Shortcut
  int _selectedTab = 0;

  // Practice Configuration State
  LessonDifficulty _difficulty = LessonDifficulty.easy;
  LessonExamMode _examMode = LessonExamMode.questions;
  int _selectedQuestionsCount = 5;
  int _selectedTimerSeconds = 60;

  // Active Practice State
  bool _isPracticing = false;
  int _practiceIndex = 0;
  int _practiceCorrect = 0;
  List<_PracticeQ> _questions = [];
  final TextEditingController _ansCtrl = TextEditingController();
  final FocusNode _ansFocusNode = FocusNode();
  bool _answered = false;
  bool _wasCorrect = false;

  // Timer Mode State
  Timer? _countdownTimer;
  int _remainingSeconds = 60;

  // Done State
  int _stars = 0;
  bool _xpAwarded = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _initLesson();
  }

  void _initLesson() {
    final meta = LessonRegistry.findById(widget.lessonId);
    if (meta == null) return;
    _meta = meta;

    if (meta.hasVariants && !_isMentalMultiplicationLesson()) {
      if (widget.initialVariantId != null) {
        _variantId = widget.initialVariantId;
      } else if (widget.initialOperands != null &&
          widget.initialOperands!.length >= 2) {
        final mult = widget.initialOperands![1];
        for (final v in meta.variants) {
          if (v.variantId == 'x$mult') {
            _variantId = v.variantId;
            break;
          }
        }
      }

      if (_variantId == null) {
        if (meta.variants.isNotEmpty) {
          _variant = meta.variants.first;
          _variantId = _variant!.variantId;
          _operands = widget.initialOperands ?? _variant!.featuredOperands;
          _script = _variant!.builder(_operands);
          _phase = _Phase.active;
          _selectedTab = 0;
        } else {
          _phase = _Phase.variantChooser;
          return;
        }
      } else {
        _variant = meta.variant(_variantId!) ?? meta.variants.first;
        _operands = widget.initialOperands ?? _variant!.featuredOperands;
        _script = _variant!.builder(_operands);
        _phase = _Phase.active;
        _selectedTab = 0;
      }
    } else {
      _operands = widget.initialOperands ?? meta.featuredOperands;
      if (meta.id == 'multiply_by_11' && _operands.length == 1) {
        _operands = [_operands[0], 11];
      }
      if (meta.id == 'multiply_by_5_25' && _operands.length < 2) {
        _operands = [_operands.isNotEmpty ? _operands[0] : 48, 5];
      }
      if (meta.id == 'multiply_by_99' && _operands.length < 2) {
        _operands = [_operands.isNotEmpty ? _operands[0] : 47, 99];
      }
      if (meta.id == 'near_100_mult' && _operands.length < 2) {
        _operands = const [97, 94];
      }
      if (meta.id == 'split_percentages' && _operands.length < 2) {
        _operands = const [15, 240];
      }
      if (meta.id == 'fraction_pct_friends' && _operands.length < 2) {
        _operands = const [3, 8];
      }
      if (meta.id == 'percentage_to_fraction' && _operands.length < 2) {
        _operands = const [3750, 640];
      }
      _script = _buildScript(_operands);
      _phase = _Phase.active;
    }

    if (_meta?.id == 'reciprocal_division') {
      _customDivisor = 2.5;
    } else if (_operands.length > 1) {
      _customDivisor = _operands[1];
    }
  }

  void _onVariantSelected(String variantId) {
    if (_meta == null) return;
    final v = _meta!.variant(variantId);
    if (v == null) return;
    setState(() {
      _variantId = variantId;
      _variant = v;
      _operands = v.featuredOperands;
      _script = v.builder(_operands);
      _phase = _Phase.active;
      _selectedTab = 0;
    });
  }

  LessonScript _buildScript(List<int> ops) {
    if (_meta!.hasVariants && _variant != null) {
      return _variant!.builder(ops);
    }
    if (_meta!.hasVariants && _meta!.variants.isNotEmpty) {
      if (ops.length > 1) {
        final mult = ops[1];
        final v = _meta!.variant('x$mult');
        if (v != null) return v.builder(ops);
      }
      return _meta!.variants.first.builder(ops);
    }
    return _meta!.buildScript(ops);
  }

  List<int> _generateOperands(Random rng) {
    if (_meta!.hasVariants && _variant != null) {
      return _variant!.generateOperands(rng);
    }
    return _meta!.generateOperands(rng);
  }

  bool _isStaticLesson() {
    return _meta?.id == 'add_in_parts' ||
        _meta?.id == 'subtract_in_parts' ||
        _isMultiplicationLesson() ||
        _isMentalMultiplicationLesson() ||
        _isDivisionLesson() ||
        _isSquaresLesson() ||
        _isAppliedMathLesson();
  }

  bool _isMultiplicationLesson() {
    return _meta?.id == 'multiply_2x2' ||
        _meta?.id == 'multiply_3x2' ||
        _meta?.id == 'multiply_3x3';
  }

  bool _isMentalMultiplicationLesson() {
    return _meta?.id == 'multiply_by_5_25' ||
        _meta?.id == 'multiply_by_11' ||
        _meta?.id == 'multiply_by_99' ||
        _meta?.id == 'near_100_mult';
  }

  bool _isDivisionLesson() {
    return _meta?.id == 'divide_by_5_25' ||
        _meta?.id == 'divide_by_9_99' ||
        _meta?.id == 'factor_division' ||
        _meta?.id == 'reciprocal_division' ||
        _meta?.id == 'flag_division';
  }

  bool _isSquaresLesson() {
    return _meta?.id == 'squares_ending_5' ||
        _meta?.id == 'squares_base_25' ||
        _meta?.id == 'squares_base_50' ||
        _meta?.id == 'squares_base_100' ||
        _meta?.id == 'squares_base_150' ||
        _meta?.id == 'squares_base_200';
  }

  bool _isAppliedMathLesson() {
    return _meta?.id == 'split_percentages' ||
        _meta?.id == 'fraction_pct_friends' ||
        _meta?.id == 'percentage_to_fraction';
  }

  // ── Practice Generation by Difficulty ─────────────────────────────────────

  List<int> _generateOperandsForDifficulty(Random rng, LessonDifficulty diff) {
    final metaId = _meta!.id;

    if (metaId == 'add_in_parts') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final a1 = 1 + rng.nextInt(5);
          final a0 = 1 + rng.nextInt(5);
          final b1 = 1 + rng.nextInt(9 - a1);
          final b0 = 1 + rng.nextInt(9 - a0);
          return [a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.easy:
          return [20 + rng.nextInt(45), 15 + rng.nextInt(35)];
        case LessonDifficulty.medium:
          final a0 = 5 + rng.nextInt(5);
          final b0 = (10 - a0) + rng.nextInt(a0);
          final a1 = 3 + rng.nextInt(6);
          final b1 = 2 + rng.nextInt(6);
          return [a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.hard:
          return [150 + rng.nextInt(600), 45 + rng.nextInt(350)];
        case LessonDifficulty.expert:
          return [800 + rng.nextInt(3700), 250 + rng.nextInt(2250)];
        case LessonDifficulty.genius:
          return [5000 + rng.nextInt(40000), 2500 + rng.nextInt(32500)];
      }
    }

    if (metaId == 'subtract_in_parts') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final a1 = 3 + rng.nextInt(6);
          final a0 = 3 + rng.nextInt(7);
          final b1 = 1 + rng.nextInt(a1);
          final b0 = 1 + rng.nextInt(a0 + 1);
          return [a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.easy:
          final a = 35 + rng.nextInt(55);
          final b = 12 + rng.nextInt(a - 15);
          return [a, b];
        case LessonDifficulty.medium:
          final a1 = 4 + rng.nextInt(5);
          final a0 = 1 + rng.nextInt(5);
          final b1 = 1 + rng.nextInt(a1 - 1);
          final b0 = (a0 + 1) + rng.nextInt(9 - a0);
          return [a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.hard:
          final a = 180 + rng.nextInt(670);
          final b = 45 + rng.nextInt(a - 60);
          return [a, b];
        case LessonDifficulty.expert:
          final a = 900 + rng.nextInt(3900);
          final b = 350 + rng.nextInt(a - 400);
          return [a, b];
        case LessonDifficulty.genius:
          final a = 6000 + rng.nextInt(44000);
          final b = 2500 + rng.nextInt(a - 3000);
          return [a, b];
      }
    }

    if (metaId == 'multiply_2x2') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final a1 = 1 + rng.nextInt(3);
          final a0 = 1 + rng.nextInt(3);
          final b1 = 1 + rng.nextInt(3);
          final b0 = 1 + rng.nextInt(3);
          return [a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.easy:
          return [15 + rng.nextInt(35), 12 + rng.nextInt(35)];
        case LessonDifficulty.medium:
          return [35 + rng.nextInt(45), 25 + rng.nextInt(45)];
        case LessonDifficulty.hard:
          return [55 + rng.nextInt(40), 45 + rng.nextInt(50)];
        case LessonDifficulty.expert:
          return [75 + rng.nextInt(24), 65 + rng.nextInt(34)];
        case LessonDifficulty.genius:
          return [85 + rng.nextInt(14), 85 + rng.nextInt(14)];
      }
    }

    if (metaId == 'multiply_3x2') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final a2 = 1 + rng.nextInt(3);
          final a1 = 1 + rng.nextInt(3);
          final a0 = 1 + rng.nextInt(3);
          final b1 = 1 + rng.nextInt(3);
          final b0 = 1 + rng.nextInt(3);
          return [a2 * 100 + a1 * 10 + a0, b1 * 10 + b0];
        case LessonDifficulty.easy:
          return [120 + rng.nextInt(180), 15 + rng.nextInt(30)];
        case LessonDifficulty.medium:
          return [250 + rng.nextInt(350), 25 + rng.nextInt(45)];
        case LessonDifficulty.hard:
          return [450 + rng.nextInt(400), 45 + rng.nextInt(50)];
        case LessonDifficulty.expert:
          return [700 + rng.nextInt(280), 65 + rng.nextInt(34)];
        case LessonDifficulty.genius:
          return [850 + rng.nextInt(148), 75 + rng.nextInt(24)];
      }
    }

    if (metaId == 'multiply_3x3') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final a2 = 1 + rng.nextInt(3);
          final a1 = 1 + rng.nextInt(3);
          final a0 = 1 + rng.nextInt(3);
          final b2 = 1 + rng.nextInt(3);
          final b1 = 1 + rng.nextInt(3);
          final b0 = 1 + rng.nextInt(3);
          return [a2 * 100 + a1 * 10 + a0, b2 * 100 + b1 * 10 + b0];
        case LessonDifficulty.easy:
          return [120 + rng.nextInt(200), 120 + rng.nextInt(200)];
        case LessonDifficulty.medium:
          return [250 + rng.nextInt(350), 200 + rng.nextInt(350)];
        case LessonDifficulty.hard:
          return [450 + rng.nextInt(350), 350 + rng.nextInt(450)];
        case LessonDifficulty.expert:
          return [650 + rng.nextInt(300), 550 + rng.nextInt(400)];
        case LessonDifficulty.genius:
          return [750 + rng.nextInt(248), 750 + rng.nextInt(248)];
      }
    }

    if (metaId == 'multiply_by_11') {
      switch (diff) {
        case LessonDifficulty.beginner:
          final tens = 1 + rng.nextInt(5);
          final ones = 1 + rng.nextInt(9 - tens);
          return [tens * 10 + ones];
        case LessonDifficulty.easy:
          return [11 + rng.nextInt(45)];
        case LessonDifficulty.medium:
          final tens = 4 + rng.nextInt(6);
          final ones = (10 - tens) + rng.nextInt(tens);
          return [tens * 10 + ones];
        case LessonDifficulty.hard:
          return [100 + rng.nextInt(400)];
        case LessonDifficulty.expert:
          return [1000 + rng.nextInt(5000)];
        case LessonDifficulty.genius:
          return [10000 + rng.nextInt(89000)];
      }
    }

    if (metaId == 'multiply_by_5_25') {
      final currentMult = _operands.length > 1 ? _operands[1] : 5;
      final mult = _variantId == 'x25'
          ? 25
          : _variantId == 'x75'
              ? 75
              : _variantId == 'x125'
                  ? 125
                  : (_variantId == 'x5' ? 5 : currentMult);
      final factor = mult == 5 ? 2 : mult == 25 || mult == 75 ? 4 : 8;
      int base;
      switch (diff) {
        case LessonDifficulty.beginner:
          base = factor * (2 + rng.nextInt(8));
        case LessonDifficulty.easy:
          base = factor * (5 + rng.nextInt(15));
        case LessonDifficulty.medium:
          base = factor * (15 + rng.nextInt(25));
        case LessonDifficulty.hard:
          base = factor * (30 + rng.nextInt(40));
        case LessonDifficulty.expert:
          base = factor * (80 + rng.nextInt(70));
        case LessonDifficulty.genius:
          base = factor * (200 + rng.nextInt(300));
      }
      return [base, mult];
    }

    if (metaId == 'multiply_by_99') {
      final currentMult = _operands.length > 1 ? _operands[1] : 99;
      final mult = _variantId == 'x9'
          ? 9
          : _variantId == 'x999'
              ? 999
              : (_variantId == 'x99' ? 99 : currentMult);
      int n;
      switch (diff) {
        case LessonDifficulty.beginner:
          n = 11 + rng.nextInt(18);
        case LessonDifficulty.easy:
          n = 20 + rng.nextInt(40);
        case LessonDifficulty.medium:
          n = 45 + rng.nextInt(50);
        case LessonDifficulty.hard:
          n = 100 + rng.nextInt(250);
        case LessonDifficulty.expert:
          n = 500 + rng.nextInt(1500);
        case LessonDifficulty.genius:
          n = 2000 + rng.nextInt(8000);
      }
      return [n, mult];
    }

    if (metaId == 'near_100_mult') {
      switch (diff) {
        case LessonDifficulty.beginner:
          return [96 + rng.nextInt(4), 96 + rng.nextInt(4)];
        case LessonDifficulty.easy:
          return [91 + rng.nextInt(9), 91 + rng.nextInt(9)];
        case LessonDifficulty.medium:
          final a = 91 + rng.nextInt(15);
          final b = 91 + rng.nextInt(15);
          return [a, b];
        case LessonDifficulty.hard:
          final a = 85 + rng.nextInt(25);
          final b = 85 + rng.nextInt(25);
          return [a, b];
        case LessonDifficulty.expert:
          final a = 75 + rng.nextInt(45);
          final b = 75 + rng.nextInt(45);
          return [a, b];
        case LessonDifficulty.genius:
          final a = 65 + rng.nextInt(65);
          final b = 65 + rng.nextInt(65);
          return [a, b];
      }
    }

    if (metaId == 'squares_ending_5') {
      switch (diff) {
        case LessonDifficulty.beginner:
          return [const [15, 25, 35][rng.nextInt(3)]];
        case LessonDifficulty.easy:
          return [const [35, 45, 55][rng.nextInt(3)]];
        case LessonDifficulty.medium:
          return [const [65, 75, 85, 95][rng.nextInt(4)]];
        case LessonDifficulty.hard:
          return [const [45, 65, 85, 95][rng.nextInt(4)]];
        case LessonDifficulty.expert:
          return [const [75, 85, 95][rng.nextInt(3)]];
        case LessonDifficulty.genius:
          return [const [85, 95][rng.nextInt(2)]];
      }
    }

    if (metaId == 'squares_base_25') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const p = [24, 25, 26];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.easy:
          const p = [23, 27, 28];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.medium:
          const p = [21, 22, 29, 30];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.hard:
          const p = [19, 20, 31, 32];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.expert:
          const p = [17, 18, 33, 34];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.genius:
          const p = [15, 16, 35, 36];
          return [p[rng.nextInt(p.length)]];
      }
    }

    if (metaId == 'squares_base_50') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const p = [47, 48, 49, 51, 52, 53];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.easy:
          const p = [44, 45, 46, 54, 55, 56];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.medium:
          const p = [41, 42, 43, 57, 58, 59];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.hard:
          const p = [37, 38, 39, 40, 60, 61, 62, 63];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.expert:
          const p = [32, 33, 34, 35, 36, 64, 65, 66, 67, 68];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.genius:
          const p = [26, 27, 28, 29, 30, 31, 69, 70, 71, 72, 73, 74];
          return [p[rng.nextInt(p.length)]];
      }
    }

    if (metaId == 'squares_base_100') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const p = [96, 97, 98, 99, 101, 102, 103, 104];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.easy:
          const p = [92, 93, 94, 95, 105, 106, 107, 108];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.medium:
          const p = [86, 87, 88, 89, 90, 91, 109, 110, 111, 112, 113, 114];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.hard:
          const p = [80, 81, 82, 83, 84, 85, 115, 116, 117, 118, 119, 120];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.expert:
          const p = [72, 73, 74, 75, 76, 77, 78, 79, 121, 122, 123, 124, 125, 126, 127, 128];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.genius:
          const p = [64, 65, 66, 67, 68, 69, 70, 71, 129, 130, 131, 132, 133, 134, 135, 136];
          return [p[rng.nextInt(p.length)]];
      }
    }

    if (metaId == 'squares_base_150') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const p = [147, 148, 149, 151, 152, 153];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.easy:
          const p = [144, 145, 146, 154, 155, 156];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.medium:
          const p = [140, 141, 142, 143, 157, 158, 159, 160];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.hard:
          const p = [135, 136, 137, 138, 139, 161, 162, 163, 164, 165];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.expert:
          const p = [128, 129, 130, 131, 132, 168, 169, 170, 171, 172];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.genius:
          const p = [120, 121, 122, 123, 124, 176, 177, 178, 179, 180];
          return [p[rng.nextInt(p.length)]];
      }
    }

    if (metaId == 'squares_base_200') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const p = [197, 198, 199, 201, 202, 203];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.easy:
          const p = [194, 195, 196, 204, 205, 206];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.medium:
          const p = [190, 191, 192, 193, 207, 208, 209, 210];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.hard:
          const p = [184, 185, 186, 187, 188, 212, 213, 214, 215, 216];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.expert:
          const p = [175, 176, 177, 178, 179, 221, 222, 223, 224, 225];
          return [p[rng.nextInt(p.length)]];
        case LessonDifficulty.genius:
          const p = [165, 166, 167, 168, 169, 231, 232, 233, 234, 235];
          return [p[rng.nextInt(p.length)]];
      }
    }

    if (metaId == 'divide_by_5_25') {
      final mult = diff.index < 2 ? 5 : (diff.index < 4 ? 25 : 125);
      final k = (diff.index + 1) * 8 + rng.nextInt(15);
      return [k * mult, mult];
    }

    if (metaId == 'divide_by_9_99') {
      final isDiv99 = _variantId == 'div99' || (_operands.length > 1 && _operands[1] == 99);
      final divisor = isDiv99 ? 99 : 9;
      final k = (diff.index + 1) * (isDiv99 ? 5 : 12) + rng.nextInt(isDiv99 ? 15 : 30);
      return [k * divisor, divisor];
    }

    if (metaId == 'factor_division') {
      const divisors = [14, 15, 18, 24, 36, 45];
      final d = divisors[diff.index % divisors.length];
      final k = 5 + rng.nextInt(25);
      return [k * d, d];
    }

    if (metaId == 'reciprocal_division') {
      switch (diff) {
        case LessonDifficulty.beginner:
          _customDivisor = 0.5;
          final n = 20 + rng.nextInt(60);
          return [n, 1];
        case LessonDifficulty.easy:
          _customDivisor = 0.25;
          final n = 15 + rng.nextInt(50);
          return [n, 1];
        case LessonDifficulty.medium:
          _customDivisor = 0.2;
          final n = 12 + rng.nextInt(40);
          return [n, 1];
        case LessonDifficulty.hard:
          _customDivisor = 2.5;
          final n = 140 + rng.nextInt(120);
          return [n, 2];
        case LessonDifficulty.expert:
          _customDivisor = 0.125;
          final n = 12 + rng.nextInt(35);
          return [n, 1];
        case LessonDifficulty.genius:
          _customDivisor = 2.5;
          final n = 450 + rng.nextInt(450);
          return [n, 2];
      }
    }

    if (metaId == 'flag_division') {
      const divisors = [32, 43, 54, 62, 73];
      final d = divisors[diff.index % divisors.length];
      final k = 15 + rng.nextInt(40);
      return [k * d, d];
    }

    if (metaId == 'split_percentages') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const pcts = [10, 20, 50];
          const ns = [120, 240, 300, 400, 500, 600, 800];
          return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
        case LessonDifficulty.easy:
          const pcts = [15, 25, 30, 40];
          const ns = [160, 240, 320, 400, 480, 600];
          return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
        case LessonDifficulty.medium:
          const pcts = [35, 45, 55, 65];
          const ns = [240, 360, 420, 560, 640, 720];
          return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
        case LessonDifficulty.hard:
          const pcts = [48, 52, 85, 95];
          const ns = [250, 350, 450, 650, 850, 950];
          return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
        case LessonDifficulty.expert:
          const pcts = [65, 75, 85, 95, 120, 150];
          const ns = [400, 600, 800, 1200, 1600];
          final p = pcts[rng.nextInt(pcts.length)];
          return [p, ns[rng.nextInt(ns.length)]];
        case LessonDifficulty.genius:
          const pcts = [45, 99, 175, 250, 750];
          const ns = [640, 880, 960, 1440, 2400];
          return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
      }
    }

    if (metaId == 'fraction_pct_friends') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const pool = [[1, 2], [1, 4], [3, 4], [1, 5], [2, 5]];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.easy:
          const pool = [[1, 3], [2, 3], [3, 5], [4, 5], [1, 10]];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.medium:
          const pool = [[1, 8], [3, 8], [5, 8], [7, 8]];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.hard:
          const pool = [[1, 6], [5, 6], [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.expert:
          const pool = [[1, 9], [2, 9], [4, 9], [5, 9], [7, 9], [8, 9], [1, 11], [2, 11], [3, 11]];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.genius:
          const pool = [[1, 12], [5, 12], [7, 12], [11, 12], [1, 16], [3, 16], [5, 16], [7, 16], [9, 16], [15, 16]];
          return pool[rng.nextInt(pool.length)];
      }
    }

    if (metaId == 'percentage_to_fraction') {
      switch (diff) {
        case LessonDifficulty.beginner:
          const pool = [
            [25, 240], [50, 360], [75, 480], [20, 600], [25, 440],
          ];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.easy:
          const pool = [
            [3333, 180], [6667, 270], [40, 350], [60, 450], [80, 550],
          ];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.medium:
          const pool = [
            [3750, 640], [6250, 480], [8750, 560], [1250, 720], [3750, 320], [6250, 800],
          ];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.hard:
          const pool = [
            [1667, 726], [8333, 360], [1428, 490], [2857, 350], [4286, 420], [5714, 560],
          ];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.expert:
          const pool = [
            [1111, 630], [2222, 540], [4444, 270], [5556, 450], [7778, 360],
            [909, 330], [1818, 550], [2727, 440],
          ];
          return pool[rng.nextInt(pool.length)];
        case LessonDifficulty.genius:
          const pool = [
            [833, 288], [4167, 360], [625, 640], [1875, 480], [3125, 640], [4375, 480],
          ];
          return pool[rng.nextInt(pool.length)];
      }
    }

    return _generateOperands(rng);
  }

  (int, String) _calcAnswerAndText(List<int> ops) {
    final metaId = _meta!.id;
    if (metaId == 'multiply_by_5_25') {
      final mult = ops.length >= 2 ? ops[1] : 5;
      return (ops[0] * mult, '${ops[0]} × $mult = ?');
    }
    if (metaId == 'multiply_by_99') {
      final mult = ops.length >= 2 ? ops[1] : 99;
      return (ops[0] * mult, '${ops[0]} × $mult = ?');
    }
    if (_meta!.hasVariants && _variant != null) {
      final mult = ops.length >= 2 ? ops[1] : 1;
      return (ops[0] * mult, '${ops[0]} × $mult = ?');
    }

    if (metaId == 'add_in_parts') {
      return (ops[0] + ops[1], '${ops[0]} + ${ops[1]} = ?');
    }
    if (metaId == 'subtract_in_parts') {
      return (ops[0] - ops[1], '${ops[0]} − ${ops[1]} = ?');
    }
    if (_isMultiplicationLesson()) {
      return (ops[0] * ops[1], '${ops[0]} × ${ops[1]} = ?');
    }
    if (metaId == 'divide_by_5_25' || metaId == 'factor_division' || metaId == 'flag_division') {
      final d = ops.length > 1 ? ops[1] : 5;
      return (ops[0] ~/ d, '${ops[0]} ÷ $d = ?');
    }
    if (metaId == 'divide_by_9_99') {
      return (ops[0] ~/ 9, '${ops[0]} ÷ 9 = ? (Quotient)');
    }
    if (metaId == 'reciprocal_division') {
      return ((ops[0] / 2.5).round(), '${ops[0]} ÷ 2.5 = ?');
    }
    if (metaId == 'multiply_by_11') {
      return (ops[0] * 11, '${ops[0]} × 11 = ?');
    }
    if (metaId == 'near_100_mult') {
      return (ops[0] * ops[1], '${ops[0]} × ${ops[1]} = ?');
    }
    if (_isSquaresLesson()) {
      return (ops[0] * ops[0], '${ops[0]}² = ?');
    }
    if (metaId == 'split_percentages') {
      final pct = ops.isNotEmpty ? ops[0] : 15;
      final n = ops.length > 1 ? ops[1] : 240;
      final pctVal = pct > 500 ? (pct / 100.0) : pct.toDouble();
      final ans = ((n * pctVal) / 100.0).round();
      final pctStr = (pctVal == pctVal.truncate())
          ? '${pctVal.truncate()}%'
          : '${pctVal.toStringAsFixed(1)}%';
      return (ans, '$pctStr of $n = ?');
    }
    if (metaId == 'fraction_pct_friends') {
      final num = ops.isNotEmpty ? ops[0] : 3;
      final den = ops.length > 1 ? ops[1] : 8;
      final pct = (num * 100.0) / den;
      return (pct.round(), '$num/$den = ? % (rounded)');
    }
    if (metaId == 'percentage_to_fraction') {
      final rawPct = ops.isNotEmpty ? ops[0] : 3750;
      final pct = rawPct > 500 ? (rawPct / 100.0) : rawPct.toDouble();
      final pctStr = (pct == pct.truncate())
          ? '${pct.truncate()}%'
          : '${pct.toStringAsFixed(2)}%';
      final examBase = ops.length > 1 ? ops[1] : 640;
      final ans = ((examBase * pct) / 100.0).round();
      return (ans, '$pctStr of $examBase = ?');
    }

    return (ops[0] * ops[1], '${ops[0]} × ${ops[1]} = ?');
  }

  void _buildQuestions() {
    final rng = Random();
    final count = _examMode == LessonExamMode.questions
        ? _selectedQuestionsCount
        : 60; // large pool for timer mode
    _questions = List.generate(count, (_) {
      final ops = _generateOperandsForDifficulty(rng, _difficulty);
      final (ans, qText) = _calcAnswerAndText(ops);
      return _PracticeQ(ops: ops, answer: ans, questionText: qText);
    });
  }

  // ── Practice Flow ──────────────────────────────────────────────────────────

  void _startPracticeSession() {
    _buildQuestions();
    setState(() {
      _isPracticing = true;
      _practiceIndex = 0;
      _practiceCorrect = 0;
      _answered = false;
      _wasCorrect = false;
      _ansCtrl.clear();
      _selectedTab = 2;
    });

    if (_examMode == LessonExamMode.timer) {
      _remainingSeconds = _selectedTimerSeconds;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingSeconds > 1) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
          _finishPractice();
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ansFocusNode.requestFocus();
    });
  }

  void _submitAnswer() {
    if (_questions.isEmpty || _practiceIndex >= _questions.length) return;
    final q = _questions[_practiceIndex];
    final entered = int.tryParse(_ansCtrl.text.trim());
    final correct = entered != null && entered == q.answer;

    HapticFeedback.selectionClick();

    if (_examMode == LessonExamMode.timer) {
      // Fast paced timer mode
      if (correct) {
        _practiceCorrect++;
        _ansCtrl.clear();
        if (_practiceIndex < _questions.length - 1) {
          setState(() => _practiceIndex++);
        } else {
          _buildQuestions();
          setState(() => _practiceIndex = 0);
        }
      } else {
        // Soft feedback without freezing
        HapticFeedback.heavyImpact();
      }
    } else {
      // Questions mode with review
      setState(() {
        _answered = true;
        _wasCorrect = correct;
        if (correct) _practiceCorrect++;
      });
    }
  }

  void _nextQuestion() {
    _ansCtrl.clear();
    final total = _selectedQuestionsCount;
    if (_practiceIndex < total - 1) {
      setState(() {
        _practiceIndex++;
        _answered = false;
        _wasCorrect = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _ansFocusNode.requestFocus();
      });
    } else {
      _finishPractice();
    }
  }

  Future<void> _finishPractice() async {
    _countdownTimer?.cancel();

    final repo = ref.read(lessonRepositoryProvider);
    final progId = _meta!.progressId(_variantId);
    final p = await repo.getProgress(progId);

    int newStars;
    if (_examMode == LessonExamMode.questions) {
      final ratio = _practiceCorrect / _selectedQuestionsCount;
      if (ratio >= 1.0) {
        newStars = 3;
      } else if (ratio >= 0.6) {
        newStars = 2;
      } else if (ratio >= 0.2) {
        newStars = 1;
      } else {
        newStars = 0;
      }
    } else {
      // Timer mode stars based on speed & accuracy
      final threshold3 = _selectedTimerSeconds == 30 ? 8 : (_selectedTimerSeconds == 60 ? 15 : 25);
      final threshold2 = _selectedTimerSeconds == 30 ? 5 : (_selectedTimerSeconds == 60 ? 9 : 16);
      final threshold1 = _selectedTimerSeconds == 30 ? 2 : (_selectedTimerSeconds == 60 ? 4 : 7);

      if (_practiceCorrect >= threshold3) {
        newStars = 3;
      } else if (_practiceCorrect >= threshold2) {
        newStars = 2;
      } else if (_practiceCorrect >= threshold1) {
        newStars = 1;
      } else {
        newStars = 0;
      }
    }

    final bestStars = max(newStars, p.stars);
    final isFirst = p.xpAwarded == 0;
    final xp = isFirst ? 30 : 0;

    await repo.saveProgress(p.copyWith(
      lessonId: progId,
      status: newStars == 3 ? LessonStatus.mastered : LessonStatus.learned,
      stars: bestStars,
      practiceCorrect: p.practiceCorrect + _practiceCorrect,
      practiceTotal: p.practiceTotal + (_examMode == LessonExamMode.questions ? _selectedQuestionsCount : _practiceIndex + 1),
      lastCompletedAt: DateTime.now(),
      xpAwarded: p.xpAwarded + xp,
    ));
    ref.invalidate(allLessonProgressProvider);
    ref.invalidate(lessonProgressProvider(progId));

    setState(() {
      _stars = bestStars;
      _xpAwarded = isFirst;
      _isPracticing = false;
      _phase = _Phase.done;
      _showConfetti = bestStars == 3;
    });

    if (bestStars == 3) HapticFeedback.heavyImpact();
  }

  void _onBack() {
    _countdownTimer?.cancel();
    if (_phase == _Phase.done) {
      setState(() {
        _phase = _Phase.active;
        _selectedTab = 0;
      });
    } else if (_isPracticing) {
      setState(() => _isPracticing = false);
    } else if (_phase == _Phase.active &&
        _meta != null &&
        _meta!.hasVariants &&
        widget.initialVariantId == null) {
      setState(() => _phase = _Phase.variantChooser);
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/learn');
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ansCtrl.dispose();
    _ansFocusNode.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_meta == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/learn');
            }
          }
        },
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Lesson not found.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/learn');
                    }
                  },
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_phase == _Phase.variantChooser) {
      final allProgressAsync = ref.watch(allLessonProgressProvider);
      final map = allProgressAsync.maybeWhen(
        data: (list) => {for (final p in list) p.lessonId: p},
        orElse: () => <String, LessonProgress>{},
      );
      return VariantChooser(
        meta: _meta!,
        progressMap: map,
        onSelect: _onVariantSelected,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/learn');
          }
        },
      );
    }

    if (_phase == _Phase.done) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: AppTheme.canvasBackground,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: _buildDone(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isStatic = _isStaticLesson();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppTheme.canvasBackground,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  // Conflict-Free Segmented Tab Navigation
                  _buildSegmentedTabs(),
                  Expanded(
                    child: _buildTabBody(isStatic),
                  ),
                  // Bottom Quick Action Bar on Tab 0
                  if (_selectedTab == 0 && isStatic) _buildStaticBottomBar(),
                ],
              ),
            ),
          ),
          if (_showConfetti) const ConfettiBurst(),
        ],
      ),
    );
  }

  // ── Top Bar & Navigation ───────────────────────────────────────────────────

  Widget _buildTopBar() {
    final title = _variant != null
        ? '${_meta!.title} (${_variant!.displayName})'
        : _meta!.title;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_meta!.category} • ${_meta!.durationLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showDifficultyPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _difficulty.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 14, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDifficultyPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Difficulty Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Adjust problem complexity and speed practice questions',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...LessonDifficulty.values.map((diff) {
                final isSelected = _difficulty == diff;
                final (desc, icon) = switch (diff) {
                  LessonDifficulty.beginner => (
                      'Gentle start with minimal carries',
                      Icons.sentiment_satisfied_rounded
                    ),
                  LessonDifficulty.easy => (
                      'Standard introductory speed calculation',
                      Icons.filter_1_rounded
                    ),
                  LessonDifficulty.medium => (
                      'Moderate multi-digit numbers & carries',
                      Icons.filter_2_rounded
                    ),
                  LessonDifficulty.hard => (
                      'Challenging calculations with heavy mental carries',
                      Icons.filter_3_rounded
                    ),
                  LessonDifficulty.expert => (
                      'Rapid mental calculation speed challenge',
                      Icons.bolt_rounded
                    ),
                  LessonDifficulty.genius => (
                      'Ultimate high-speed calculation mastery',
                      Icons.military_tech_rounded
                    ),
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryTint
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderLight,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    title: Text(
                      diff.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primaryColor, size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(sheetContext);
                      setState(() {
                        _difficulty = diff;
                        _operands = _generateOperandsForDifficulty(Random(), diff);
                        _script = _buildScript(_operands);
                        if (_isPracticing) {
                          _buildQuestions();
                          _practiceIndex = 0;
                          _practiceCorrect = 0;
                          _answered = false;
                          _ansCtrl.clear();
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentedTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _PillTabItem(
            icon: Icons.architecture_rounded,
            label: 'Shortcut Board',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 8),
          _PillTabItem(
            icon: Icons.menu_book_rounded,
            label: 'Breakdown & FAQ',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          const SizedBox(width: 8),
          _PillTabItem(
            icon: Icons.fitness_center_rounded,
            label: 'Practice Shortcut',
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(bool isStatic) {
    switch (_selectedTab) {
      case 0:
        return _buildStaticBoardTab();
      case 1:
        return _buildBreakdownTab();
      case 2:
        return _buildPracticeTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Tab 0: Static Board (Zero Scroll Conflict) ─────────────────────────────

  Widget _buildStaticBoardTab() {
    final a = _operands.isNotEmpty
        ? _operands[0]
        : (_meta!.id == 'multiply_by_5_25'
            ? 48
            : (_meta!.id == 'multiply_by_99'
                ? 47
                : (_meta!.id == 'near_100_mult' ? 97 : 42)));
    final b = switch (_meta!.id) {
      'multiply_by_11' => 11,
      'multiply_by_5_25' => (_operands.length > 1 ? _operands[1] : 5),
      'multiply_by_99' => (_operands.length > 1 ? _operands[1] : 99),
      'near_100_mult' => (_operands.length > 1 ? _operands[1] : 94),
      _ => (_operands.length > 1 ? _operands[1] : 45),
    };
    final isAdd = _meta!.id == 'add_in_parts';
    final isSub = _meta!.id == 'subtract_in_parts';
    final isMult = _isMultiplicationLesson();
    final isMentalMult = _isMentalMultiplicationLesson();
    final isDiv = _isDivisionLesson();
    final isSquares = _isSquaresLesson();
    final isApplied = _isAppliedMathLesson();

    final String badgeLabel;
    if (isAdd) {
      badgeLabel = 'Addition Shortcut';
    } else if (isSub) {
      badgeLabel = 'Subtraction Shortcut';
    } else if (isMult) {
      badgeLabel = 'Multiplication Shortcut (Criss-Cross)';
    } else if (isMentalMult) {
      badgeLabel = switch (_meta!.id) {
        'multiply_by_5_25' => 'Multiplication Shortcut (× 5, 25, 75, 125)',
        'multiply_by_11' => 'Multiplication Shortcut (× 11)',
        'multiply_by_99' => 'Multiplication Shortcut (× 9, 99, 999)',
        'near_100_mult' => 'Near-100 Multiplication Shortcut',
        _ => 'Multiplication Shortcut',
      };
    } else if (isSquares) {
      badgeLabel = switch (_meta!.id) {
        'squares_ending_5' => 'Squares Shortcut (Ending in 5)',
        'squares_base_25' => 'Base 25 Squares (21–29)',
        'squares_base_50' => 'Base 50 Squares (35–65)',
        'squares_base_100' => 'Base 100 Squares (75–125)',
        'squares_base_150' => 'Base 150 Squares (130–170)',
        'squares_base_200' => 'Base 200 Squares (175–225)',
        _ => 'Squaring Shortcut',
      };
    } else if (isApplied) {
      badgeLabel = switch (_meta!.id) {
        'split_percentages' => 'Split Percentages Shortcut',
        'percentage_to_fraction' => 'Percentage to Fraction Shortcut',
        _ => 'Fraction to Percentage Shortcut',
      };
    } else {
      badgeLabel = switch (_meta!.id) {
        'divide_by_5_25' => 'Division Shortcut (÷ 5, 25, 125)',
        'divide_by_9_99' => 'Division Shortcut (Vedic 9 & 99)',
        'factor_division' => 'Composite Factor Division',
        'reciprocal_division' => 'Reciprocal & Decimal Division',
        'flag_division' => 'Straight Flag Division',
        _ => 'Division Shortcut',
      };
    }

    final String equationText;
    if (isAdd) {
      equationText = '$a + $b = ${a + b}';
    } else if (isSub) {
      equationText = '$a − $b = ${a - b}';
    } else if (isMult || isMentalMult) {
      equationText = '$a × $b = ${a * b}';
    } else if (isSquares) {
      equationText = '$a² = ${a * a}';
    } else if (_meta!.id == 'split_percentages') {
      final pctVal = a > 500 ? (a / 100.0) : a.toDouble();
      final pctStr = (pctVal == pctVal.truncate()) ? '${pctVal.truncate()}%' : '${pctVal.toStringAsFixed(1)}%';
      final res = (b * pctVal) / 100.0;
      final resStr = (res == res.truncate()) ? '${res.truncate()}' : res.toStringAsFixed(2);
      equationText = '$pctStr of $b = $resStr';
    } else if (_meta!.id == 'percentage_to_fraction') {
      final pctVal = a > 500 ? (a / 100.0) : a.toDouble();
      final pctStr = (pctVal == pctVal.truncate()) ? '${pctVal.truncate()}%' : '${pctVal.toStringAsFixed(2)}%';
      final res = (b * pctVal) / 100.0;
      final resStr = (res == res.truncate()) ? '${res.truncate()}' : res.toStringAsFixed(2);
      equationText = '$pctStr of $b = $resStr';
    } else if (_meta!.id == 'fraction_pct_friends') {
      final pct = (a * 100.0) / b;
      final pctStr = (pct == pct.truncate()) ? '${pct.truncate()}%' : '${pct.toStringAsFixed(2)}%';
      equationText = '$a/$b = $pctStr';
    } else if (_meta!.id == 'divide_by_5_25') {
      final div = _currentDivisor;
      final res = a / div;
      final resStr = res == res.truncate() ? '${res.truncate()}' : res.toStringAsFixed(2);
      equationText = '$a ÷ $div = $resStr';
    } else if (_meta!.id == 'divide_by_9_99') {
      final div = _currentDivisor.toInt();
      final q = a ~/ div;
      final r = a % div;
      equationText = '$a ÷ $div = $q ${r > 0 ? "R $r" : ""}';
    } else if (_meta!.id == 'factor_division') {
      final div = _currentDivisor.toInt();
      final q = a ~/ div;
      final r = a % div;
      equationText = '$a ÷ $div = $q ${r > 0 ? "R $r" : ""}';
    } else if (_meta!.id == 'reciprocal_division') {
      final div = _currentDivisor;
      final res = a / div;
      final resStr = res == res.truncate() ? '${res.truncate()}' : res.toStringAsFixed(2);
      equationText = '$a ÷ $div = $resStr';
    } else if (_meta!.id == 'flag_division') {
      final div = _currentDivisor.toInt();
      final q = a ~/ div;
      final r = a % div;
      equationText = '$a ÷ $div = $q ${r > 0 ? "R $r" : ""}';
    } else {
      equationText = '$a ÷ $_currentDivisor = ${a ~/ _currentDivisor}';
    }

    return Column(
      children: [
        // 1. Active Problem Banner & Custom Number trigger
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _operands = _generateOperandsForDifficulty(Random(), _difficulty);
                            _script = _buildScript(_operands);
                          });
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 13),
                        label: const Text('New'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (isAdd) {
                            AdditionCustomNumberSheet.show(
                              context: context,
                              currentA: a,
                              currentB: b,
                              onApply: (newA, newB) {
                                setState(() {
                                  _operands = [newA, newB];
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isSub) {
                            SubtractionCustomNumberSheet.show(
                              context: context,
                              currentA: a,
                              currentB: b,
                              onApply: (newA, newB) {
                                setState(() {
                                  _operands = [newA, newB];
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isMult) {
                            MultiplicationCustomNumberSheet.show(
                              context: context,
                              currentA: a,
                              currentB: b,
                              onApply: (newA, newB) {
                                setState(() {
                                  _operands = [newA, newB];
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isMentalMult) {
                            MentalMultiplicationCustomNumberSheet.show(
                              context: context,
                              lessonId: _meta!.id,
                              currentOperands: [a, b],
                              onApply: (newOps) {
                                setState(() {
                                  _operands = newOps;
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isSquares) {
                            SquaresCustomNumberSheet.show(
                              context: context,
                              lessonId: _meta!.id,
                              currentNumber: a,
                              onApply: (newNum) {
                                setState(() {
                                  _operands = [newNum];
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isDiv) {
                            DivisionCustomNumberSheet.show(
                              context: context,
                              lessonId: _meta!.id,
                              currentDividend: a,
                              currentDivisor: _currentDivisor,
                              onApply: (newDividend, newDivisor) {
                                setState(() {
                                  _operands = [newDividend, newDivisor.toInt()];
                                  _customDivisor = newDivisor;
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          } else if (isApplied) {
                            AppliedMathCustomNumberSheet.show(
                              context: context,
                              lessonId: _meta!.id,
                              currentOperands: _operands,
                              onApply: (newOps) {
                                setState(() {
                                  _operands = newOps;
                                  _script = _buildScript(_operands);
                                });
                              },
                            );
                          }
                        },
                        icon: const Icon(Icons.edit_rounded, size: 13),
                        label: const Text('Custom Numbers'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  equationText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Preset selector chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildPresetChips(a, b, isAdd, isSub),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. The Static Ruled Notebook Canvas (Expanded = 100% Free Pan & Pinch Zoom)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: isAdd
                ? AdditionStaticDiagram(a: a, b: b)
                : (isSub
                    ? SubtractionStaticDiagram(a: a, b: b)
                    : (isMult
                        ? MultiplicationStaticDiagram(a: a, b: b)
                        : (isMentalMult
                            ? MentalMultiplicationStaticDiagram(
                                lessonId: _meta!.id,
                                first: a,
                                second: b,
                              )
                            : (isSquares
                                ? SquaresStaticDiagram(
                                    lessonId: _meta!.id,
                                    number: a,
                                  )
                                : (isDiv
                                    ? DivisionStaticDiagram(
                                        lessonId: _meta!.id,
                                        dividend: a,
                                        divisor: _currentDivisor,
                                      )
                                    : AppliedMathStaticDiagram(
                                        lessonId: _meta!.id,
                                        operands: _operands,
                                      )))))),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPresetChips(int a, int b, bool isAdd, bool isSub) {
    if (isAdd) {
      return [
        _PresetChip(
          label: '42 + 45 (2-digit)',
          isActive: a == 42 && b == 45,
          onTap: () => setState(() {
            _operands = [42, 45];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '342 + 156 (3-digit)',
          isActive: a == 342 && b == 156,
          onTap: () => setState(() {
            _operands = [342, 156];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '485 + 67 (3 + 2 digit)',
          isActive: a == 485 && b == 67,
          onTap: () => setState(() {
            _operands = [485, 67];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1250 + 480 (4-digit)',
          isActive: a == 1250 && b == 480,
          onTap: () => setState(() {
            _operands = [1250, 480];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (isSub) {
      return [
        _PresetChip(
          label: '85 − 42 (2-digit)',
          isActive: a == 85 && b == 42,
          onTap: () => setState(() {
            _operands = [85, 42];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '83 − 47 (with deficit)',
          isActive: a == 83 && b == 47,
          onTap: () => setState(() {
            _operands = [83, 47];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '342 − 156 (3-digit)',
          isActive: a == 342 && b == 156,
          onTap: () => setState(() {
            _operands = [342, 156];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '624 − 278 (3-digit deficit)',
          isActive: a == 624 && b == 278,
          onTap: () => setState(() {
            _operands = [624, 278];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1250 − 480 (4-digit)',
          isActive: a == 1250 && b == 480,
          onTap: () => setState(() {
            _operands = [1250, 480];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    final metaId = _meta!.id;
    if (metaId == 'multiply_3x2') {
      return [
        _PresetChip(
          label: '312 × 42 (3×2 standard)',
          isActive: a == 312 && b == 42,
          onTap: () => setState(() {
            _operands = [312, 42];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '214 × 32 (3×2 standard)',
          isActive: a == 214 && b == 32,
          onTap: () => setState(() {
            _operands = [214, 32];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '425 × 38 (with carry)',
          isActive: a == 425 && b == 38,
          onTap: () => setState(() {
            _operands = [425, 38];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '624 × 57 (large)',
          isActive: a == 624 && b == 57,
          onTap: () => setState(() {
            _operands = [624, 57];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'multiply_3x3') {
      return [
        _PresetChip(
          label: '123 × 321 (3×3 standard)',
          isActive: a == 123 && b == 321,
          onTap: () => setState(() {
            _operands = [123, 321];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '231 × 214 (3×3 standard)',
          isActive: a == 231 && b == 214,
          onTap: () => setState(() {
            _operands = [231, 214];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '342 × 256 (with carry)',
          isActive: a == 342 && b == 256,
          onTap: () => setState(() {
            _operands = [342, 256];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '512 × 438 (large)',
          isActive: a == 512 && b == 438,
          onTap: () => setState(() {
            _operands = [512, 438];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (_isMultiplicationLesson()) {
      return [
        _PresetChip(
          label: '23 × 42 (2×2 standard)',
          isActive: a == 23 && b == 42,
          onTap: () => setState(() {
            _operands = [23, 42];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '31 × 24 (2×2 standard)',
          isActive: a == 31 && b == 24,
          onTap: () => setState(() {
            _operands = [31, 24];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '47 × 36 (with carry)',
          isActive: a == 47 && b == 36,
          onTap: () => setState(() {
            _operands = [47, 36];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '84 × 23 (large)',
          isActive: a == 84 && b == 23,
          onTap: () => setState(() {
            _operands = [84, 23];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'multiply_by_5_25') {
      return [
        _PresetChip(
          label: '48 × 5 (halve & shift)',
          isActive: a == 48 && b == 5,
          onTap: () => setState(() {
            _operands = [48, 5];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '48 × 25 (halve twice)',
          isActive: a == 48 && b == 25,
          onTap: () => setState(() {
            _operands = [48, 25];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '32 × 75 (quarter & triple)',
          isActive: a == 32 && b == 75,
          onTap: () => setState(() {
            _operands = [32, 75];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '24 × 125 (halve 3 times)',
          isActive: a == 24 && b == 125,
          onTap: () => setState(() {
            _operands = [24, 125];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '84 × 5 (fast halve)',
          isActive: a == 84 && b == 5,
          onTap: () => setState(() {
            _operands = [84, 5];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '64 × 25 (double halve)',
          isActive: a == 64 && b == 25,
          onTap: () => setState(() {
            _operands = [64, 25];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'multiply_by_11') {
      return [
        _PresetChip(
          label: '35 × 11 (no carry: 3_8_5)',
          isActive: a == 35,
          onTap: () => setState(() {
            _operands = [35, 11];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '42 × 11 (no carry: 4_6_2)',
          isActive: a == 42,
          onTap: () => setState(() {
            _operands = [42, 11];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '67 × 11 (with carry: 7_3_7)',
          isActive: a == 67,
          onTap: () => setState(() {
            _operands = [67, 11];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '85 × 11 (with carry: 9_3_5)',
          isActive: a == 85,
          onTap: () => setState(() {
            _operands = [85, 11];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '123 × 11 (3-digit: 1_3_5_3)',
          isActive: a == 123,
          onTap: () => setState(() {
            _operands = [123, 11];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '342 × 11 (3-digit: 3_7_6_2)',
          isActive: a == 342,
          onTap: () => setState(() {
            _operands = [342, 11];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'multiply_by_99') {
      return [
        _PresetChip(
          label: '47 × 9 (round-up: 470 − 47)',
          isActive: a == 47 && b == 9,
          onTap: () => setState(() {
            _operands = [47, 9];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '47 × 99 (round-up: 4700 − 47)',
          isActive: a == 47 && b == 99,
          onTap: () => setState(() {
            _operands = [47, 99];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '47 × 999 (round-up: 47000 − 47)',
          isActive: a == 47 && b == 999,
          onTap: () => setState(() {
            _operands = [47, 999];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '63 × 99 (Vedic: 62 | 37)',
          isActive: a == 63 && b == 99,
          onTap: () => setState(() {
            _operands = [63, 99];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '85 × 99 (Vedic: 84 | 15)',
          isActive: a == 85 && b == 99,
          onTap: () => setState(() {
            _operands = [85, 99];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'near_100_mult') {
      return [
        _PresetChip(
          label: '97 × 94 (both below: −3, −6)',
          isActive: a == 97 && b == 94,
          onTap: () => setState(() {
            _operands = [97, 94];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '98 × 97 (pad zero: −2, −3)',
          isActive: a == 98 && b == 97,
          onTap: () => setState(() {
            _operands = [98, 97];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '96 × 95 (both below: −4, −5)',
          isActive: a == 96 && b == 95,
          onTap: () => setState(() {
            _operands = [96, 95];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '104 × 107 (both above: +4, +7)',
          isActive: a == 104 && b == 107,
          onTap: () => setState(() {
            _operands = [104, 107];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '108 × 103 (both above: +8, +3)',
          isActive: a == 108 && b == 103,
          onTap: () => setState(() {
            _operands = [108, 103];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '105 × 96 (mixed: +5, −4)',
          isActive: a == 105 && b == 96,
          onTap: () => setState(() {
            _operands = [105, 96];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'divide_by_5_25') {
      return [
        _PresetChip(
          label: '340 ÷ 5 (divide by 5)',
          isActive: a == 340 && _currentDivisor == 5,
          onTap: () => setState(() {
            _operands = [340, 5];
            _customDivisor = 5;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '612 ÷ 25 (divide by 25)',
          isActive: a == 612 && _currentDivisor == 25,
          onTap: () => setState(() {
            _operands = [612, 25];
            _customDivisor = 25;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '750 ÷ 125 (divide by 125)',
          isActive: a == 750 && _currentDivisor == 125,
          onTap: () => setState(() {
            _operands = [750, 125];
            _customDivisor = 125;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '840 ÷ 5 (fast halve)',
          isActive: a == 840 && _currentDivisor == 5,
          onTap: () => setState(() {
            _operands = [840, 5];
            _customDivisor = 5;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1450 ÷ 25 (double-double)',
          isActive: a == 1450 && _currentDivisor == 25,
          onTap: () => setState(() {
            _operands = [1450, 25];
            _customDivisor = 25;
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'divide_by_9_99') {
      return [
        _PresetChip(
          label: '1214 ÷ 9 (running sum)',
          isActive: a == 1214 && _currentDivisor == 9,
          onTap: () => setState(() {
            _operands = [1214, 9];
            _customDivisor = 9;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '2345 ÷ 99 (2-digit blocks)',
          isActive: a == 2345 && _currentDivisor == 99,
          onTap: () => setState(() {
            _operands = [2345, 99];
            _customDivisor = 99;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '4121 ÷ 9 (running sum)',
          isActive: a == 4121 && _currentDivisor == 9,
          onTap: () => setState(() {
            _operands = [4121, 9];
            _customDivisor = 9;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1321 ÷ 99 (2-digit blocks)',
          isActive: a == 1321 && _currentDivisor == 99,
          onTap: () => setState(() {
            _operands = [1321, 99];
            _customDivisor = 99;
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'factor_division') {
      return [
        _PresetChip(
          label: '1620 ÷ 45 (split 9 × 5)',
          isActive: a == 1620 && _currentDivisor == 45,
          onTap: () => setState(() {
            _operands = [1620, 45];
            _customDivisor = 45;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1728 ÷ 24 (split 8 × 3)',
          isActive: a == 1728 && _currentDivisor == 24,
          onTap: () => setState(() {
            _operands = [1728, 24];
            _customDivisor = 24;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1296 ÷ 36 (split 9 × 4)',
          isActive: a == 1296 && _currentDivisor == 36,
          onTap: () => setState(() {
            _operands = [1296, 36];
            _customDivisor = 36;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '882 ÷ 14 (split 7 × 2)',
          isActive: a == 882 && _currentDivisor == 14,
          onTap: () => setState(() {
            _operands = [882, 14];
            _customDivisor = 14;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '1125 ÷ 15 (split 5 × 3)',
          isActive: a == 1125 && _currentDivisor == 15,
          onTap: () => setState(() {
            _operands = [1125, 15];
            _customDivisor = 15;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '972 ÷ 18 (split 9 × 2)',
          isActive: a == 972 && _currentDivisor == 18,
          onTap: () => setState(() {
            _operands = [972, 18];
            _customDivisor = 18;
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'reciprocal_division') {
      return [
        _PresetChip(
          label: '140 ÷ 2.5 (× 4 ÷ 10)',
          isActive: a == 140 && (_currentDivisor - 2.5).abs() < 0.01,
          onTap: () => setState(() {
            _operands = [140, 2];
            _customDivisor = 2.5;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '320 ÷ 0.5 (× 2)',
          isActive: a == 320 && (_currentDivisor - 0.5).abs() < 0.01,
          onTap: () => setState(() {
            _operands = [320, 1];
            _customDivisor = 0.5;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '240 ÷ 0.25 (× 4)',
          isActive: a == 240 && (_currentDivisor - 0.25).abs() < 0.01,
          onTap: () => setState(() {
            _operands = [240, 1];
            _customDivisor = 0.25;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '450 ÷ 0.2 (× 5)',
          isActive: a == 450 && (_currentDivisor - 0.2).abs() < 0.01,
          onTap: () => setState(() {
            _operands = [450, 1];
            _customDivisor = 0.2;
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '180 ÷ 0.125 (× 8)',
          isActive: a == 180 && (_currentDivisor - 0.125).abs() < 0.01,
          onTap: () => setState(() {
            _operands = [180, 1];
            _customDivisor = 0.125;
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_ending_5') {
      return [
        _PresetChip(
          label: '35² (3 × 4 | 25)',
          isActive: a == 35,
          onTap: () => setState(() {
            _operands = [35];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '65² (6 × 7 | 25)',
          isActive: a == 65,
          onTap: () => setState(() {
            _operands = [65];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '85² (8 × 9 | 25)',
          isActive: a == 85,
          onTap: () => setState(() {
            _operands = [85];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '95² (9 × 10 | 25)',
          isActive: a == 95,
          onTap: () => setState(() {
            _operands = [95];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '45² (4 × 5 | 25)',
          isActive: a == 45,
          onTap: () => setState(() {
            _operands = [45];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '75² (7 × 8 | 25)',
          isActive: a == 75,
          onTap: () => setState(() {
            _operands = [75];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_base_25') {
      return [
        _PresetChip(
          label: '26² (d = +1)',
          isActive: a == 26,
          onTap: () => setState(() {
            _operands = [26];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '24² (d = −1)',
          isActive: a == 24,
          onTap: () => setState(() {
            _operands = [24];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '28² (d = +3)',
          isActive: a == 28,
          onTap: () => setState(() {
            _operands = [28];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '22² (d = −3)',
          isActive: a == 22,
          onTap: () => setState(() {
            _operands = [22];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '27² (d = +2)',
          isActive: a == 27,
          onTap: () => setState(() {
            _operands = [27];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '29² (d = +4)',
          isActive: a == 29,
          onTap: () => setState(() {
            _operands = [29];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_base_50') {
      return [
        _PresetChip(
          label: '46² (d = −4, 21 | 16)',
          isActive: a == 46,
          onTap: () => setState(() {
            _operands = [46];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '54² (d = +4, 29 | 16)',
          isActive: a == 54,
          onTap: () => setState(() {
            _operands = [54];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '42² (d = −8, 17 | 64)',
          isActive: a == 42,
          onTap: () => setState(() {
            _operands = [42];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '56² (d = +6, 31 | 36)',
          isActive: a == 56,
          onTap: () => setState(() {
            _operands = [56];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '38² (d = −12, carry 1)',
          isActive: a == 38,
          onTap: () => setState(() {
            _operands = [38];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '62² (d = +12, carry 1)',
          isActive: a == 62,
          onTap: () => setState(() {
            _operands = [62];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_base_100') {
      return [
        _PresetChip(
          label: '96² (d = −4, 92 | 16)',
          isActive: a == 96,
          onTap: () => setState(() {
            _operands = [96];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '104² (d = +4, 108 | 16)',
          isActive: a == 104,
          onTap: () => setState(() {
            _operands = [104];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '93² (d = −7, 86 | 49)',
          isActive: a == 93,
          onTap: () => setState(() {
            _operands = [93];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '107² (d = +7, 114 | 49)',
          isActive: a == 107,
          onTap: () => setState(() {
            _operands = [107];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '88² (d = −12, carry 1)',
          isActive: a == 88,
          onTap: () => setState(() {
            _operands = [88];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '112² (d = +12, carry 1)',
          isActive: a == 112,
          onTap: () => setState(() {
            _operands = [112];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_base_150') {
      return [
        _PresetChip(
          label: '146² (d = −4, 1.5×)',
          isActive: a == 146,
          onTap: () => setState(() {
            _operands = [146];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '154² (d = +4, 1.5×)',
          isActive: a == 154,
          onTap: () => setState(() {
            _operands = [154];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '142² (d = −8, 1.5×)',
          isActive: a == 142,
          onTap: () => setState(() {
            _operands = [142];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '158² (d = +8, 1.5×)',
          isActive: a == 158,
          onTap: () => setState(() {
            _operands = [158];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '138² (d = −12, carry 1)',
          isActive: a == 138,
          onTap: () => setState(() {
            _operands = [138];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '162² (d = +12, carry 1)',
          isActive: a == 162,
          onTap: () => setState(() {
            _operands = [162];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'squares_base_200') {
      return [
        _PresetChip(
          label: '196² (d = −4, 2×)',
          isActive: a == 196,
          onTap: () => setState(() {
            _operands = [196];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '204² (d = +4, 2×)',
          isActive: a == 204,
          onTap: () => setState(() {
            _operands = [204];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '192² (d = −8, 2×)',
          isActive: a == 192,
          onTap: () => setState(() {
            _operands = [192];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '208² (d = +8, 2×)',
          isActive: a == 208,
          onTap: () => setState(() {
            _operands = [208];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '188² (d = −12, carry 1)',
          isActive: a == 188,
          onTap: () => setState(() {
            _operands = [188];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '212² (d = +12, carry 1)',
          isActive: a == 212,
          onTap: () => setState(() {
            _operands = [212];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'split_percentages') {
      return [
        _PresetChip(
          label: '15% of 240 (10% + 5%)',
          isActive: a == 15 && b == 240,
          onTap: () => setState(() {
            _operands = [15, 240];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '35% of 420 (25% + 10%)',
          isActive: a == 35 && b == 420,
          onTap: () => setState(() {
            _operands = [35, 420];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '45% of 360 (50% − 5%)',
          isActive: a == 45 && b == 360,
          onTap: () => setState(() {
            _operands = [45, 360];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '48% of 250 (50% − 2%)',
          isActive: a == 48 && b == 250,
          onTap: () => setState(() {
            _operands = [48, 250];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '65% of 800 (50% + 15%)',
          isActive: a == 65 && b == 800,
          onTap: () => setState(() {
            _operands = [65, 800];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '95% of 640 (100% − 5%)',
          isActive: a == 95 && b == 640,
          onTap: () => setState(() {
            _operands = [95, 640];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '17.5% of 400 (compound)',
          isActive: (a == 1750 || a == 17) && b == 400,
          onTap: () => setState(() {
            _operands = [1750, 400];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '99% of 750 (100% − 1%)',
          isActive: a == 99 && b == 750,
          onTap: () => setState(() {
            _operands = [99, 750];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'fraction_pct_friends') {
      return [
        _PresetChip(
          label: '1/3 (33.33%)',
          isActive: a == 1 && b == 3,
          onTap: () => setState(() {
            _operands = [1, 3];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '3/8 (37.5%)',
          isActive: a == 3 && b == 8,
          onTap: () => setState(() {
            _operands = [3, 8];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '5/6 (83.33%)',
          isActive: a == 5 && b == 6,
          onTap: () => setState(() {
            _operands = [5, 6];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '4/7 (57.14%)',
          isActive: a == 4 && b == 7,
          onTap: () => setState(() {
            _operands = [4, 7];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '5/9 (55.56%)',
          isActive: a == 5 && b == 9,
          onTap: () => setState(() {
            _operands = [5, 9];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '5/12 (41.67%)',
          isActive: a == 5 && b == 12,
          onTap: () => setState(() {
            _operands = [5, 12];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '7/16 (43.75%)',
          isActive: a == 7 && b == 16,
          onTap: () => setState(() {
            _operands = [7, 16];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '7/8 (87.5%)',
          isActive: a == 7 && b == 8,
          onTap: () => setState(() {
            _operands = [7, 8];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    if (metaId == 'percentage_to_fraction') {
      return [
        _PresetChip(
          label: '37.5% of 640 (3/8)',
          isActive: a == 3750 && b == 640,
          onTap: () => setState(() {
            _operands = [3750, 640];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '62.5% of 480 (5/8)',
          isActive: a == 6250 && b == 480,
          onTap: () => setState(() {
            _operands = [6250, 480];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '83.33% of 360 (5/6)',
          isActive: a == 8333 && b == 360,
          onTap: () => setState(() {
            _operands = [8333, 360];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '16.67% of 726 (1/6)',
          isActive: a == 1667 && b == 726,
          onTap: () => setState(() {
            _operands = [1667, 726];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '14.28% of 490 (1/7)',
          isActive: a == 1428 && b == 490,
          onTap: () => setState(() {
            _operands = [1428, 490];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '44.44% of 270 (4/9)',
          isActive: a == 4444 && b == 270,
          onTap: () => setState(() {
            _operands = [4444, 270];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '9.09% of 330 (1/11)',
          isActive: a == 909 && b == 330,
          onTap: () => setState(() {
            _operands = [909, 330];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '8.33% of 288 (1/12)',
          isActive: a == 833 && b == 288,
          onTap: () => setState(() {
            _operands = [833, 288];
            _script = _buildScript(_operands);
          }),
        ),
        const SizedBox(width: 6),
        _PresetChip(
          label: '6.25% of 640 (1/16)',
          isActive: a == 625 && b == 640,
          onTap: () => setState(() {
            _operands = [625, 640];
            _script = _buildScript(_operands);
          }),
        ),
      ];
    }

    return [
      _PresetChip(
        label: '4536 ÷ 54 (flag 4, base 5)',
        isActive: a == 4536 && _currentDivisor == 54,
        onTap: () => setState(() {
          _operands = [4536, 54];
          _customDivisor = 54;
          _script = _buildScript(_operands);
        }),
      ),
      const SizedBox(width: 6),
      _PresetChip(
        label: '2368 ÷ 32 (flag 2, base 3)',
        isActive: a == 2368 && _currentDivisor == 32,
        onTap: () => setState(() {
          _operands = [2368, 32];
          _customDivisor = 32;
          _script = _buildScript(_operands);
        }),
      ),
      const SizedBox(width: 6),
      _PresetChip(
        label: '3698 ÷ 43 (flag 3, base 4)',
        isActive: a == 3698 && _currentDivisor == 43,
        onTap: () => setState(() {
          _operands = [3698, 43];
          _customDivisor = 43;
          _script = _buildScript(_operands);
        }),
      ),
      const SizedBox(width: 6),
      _PresetChip(
        label: '5146 ÷ 62 (flag 2, base 6)',
        isActive: a == 5146 && _currentDivisor == 62,
        onTap: () => setState(() {
          _operands = [5146, 62];
          _customDivisor = 62;
          _script = _buildScript(_operands);
        }),
      ),
      const SizedBox(width: 6),
      _PresetChip(
        label: '6424 ÷ 73 (flag 3, base 7)',
        isActive: a == 6424 && _currentDivisor == 73,
        onTap: () => setState(() {
          _operands = [6424, 73];
          _customDivisor = 73;
          _script = _buildScript(_operands);
        }),
      ),
    ];
  }

  Widget _buildStaticBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _selectedTab = 1),
              icon: const Icon(Icons.menu_book_rounded, size: 16),
              label: const Text('Step Breakdown'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => setState(() => _selectedTab = 2),
              icon: const Icon(Icons.fitness_center_rounded, size: 16),
              label: const Text('Practice Shortcut'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Step Breakdown & FAQs ───────────────────────────────────────────

  Widget _buildBreakdownTab() {
    final isAdd = _meta!.id == 'add_in_parts';
    final isSub = _meta!.id == 'subtract_in_parts';
    final isMult = _isMultiplicationLesson();
    final isMentalMult = _isMentalMultiplicationLesson();
    final isDiv = _isDivisionLesson();
    final isSquares = _isSquaresLesson();
    final isApplied = _isAppliedMathLesson();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdd) ...[
            _ExpandCard(
              Icons.account_tree_outlined,
              const Color(0xFF2563EB),
              'Step 1: Place-Value Decomposition',
              'Break both numbers into their place values (hundreds, tens, units). For example, 42 becomes 40 and 2; 45 becomes 40 and 5. This eliminates mental carrying entirely.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.add_circle_outline_rounded,
              const Color(0xFFF97316),
              'Step 2: Add Place Values Mentally (Cone Arrows)',
              'Add the matching place values: 40 + 40 = 80, and 2 + 5 = 7. Because there are no cross-column carries at this stage, the human brain computes these in milliseconds.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.speed_rounded,
              const Color(0xFF16A34A),
              'Step 3: Combine Left-to-Right (The Speed Trick)',
              'Combine your subtotals from left to right: 80 + 7 = 87! Traditional school math goes right-to-left with pencil carrying; mental speed math always moves left-to-right holding round numbers.',
            ),
          ] else if (isSub) ...[
            _ExpandCard(
              Icons.account_tree_outlined,
              const Color(0xFF2563EB),
              'Step 1: Place-Value Decomposition',
              'Split both numbers into place values: 83 becomes 80 and 3; 47 becomes 40 and 7. You never have to cross-borrow on scratch paper.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.remove_circle_outline_rounded,
              const Color(0xFFDC2626),
              'Step 2: Mental Differences & Deficits (Cone Arrows)',
              'Subtract matching place values: Tens: 80 − 40 = 40. Units: 3 − 7 = −4 (a deficit of 4). Holding a deficit mentally is far faster than scratchpad borrowing.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.speed_rounded,
              const Color(0xFF16A34A),
              'Step 3: Adjust Left-to-Right (The Speed Trick)',
              'Take your round tens result and adjust by the deficit: 40 − 4 = 36! If there is no deficit (e.g. 85 − 42), simply combine: 40 + 3 = 43.',
            ),
          ] else if (isMult) ...[
            _ExpandCard(
              Icons.vertical_align_center_rounded,
              const Color(0xFF2563EB),
              'Step 1: Vertical Units Column (|)',
              'Multiply the last two digits vertically (a₀ × b₀). Write down the units digit of the result, and hold any tens digit in your mind as the carry.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.close_rounded,
              const Color(0xFFF97316),
              'Step 2: Crosswise Diagonals (X)',
              'Cross-multiply adjacent digits and add their products: (a₁ × b₀) + (a₀ × b₁). Add any carry from Step 1. Write the units digit and carry the rest forward.',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.auto_awesome_rounded,
              const Color(0xFF7C3AED),
              'Step 3: Expanded Columns & Stars (*)',
              'For 2-digit numbers: multiply the tens column vertically (a₁ × b₁), add the carry, and write the complete final value!\n\nFor 3-digit numbers: expand to the full 3-way star (a₂ × b₀ + a₀ × b₂ + a₁ × b₁), then step down to the left cross and leftmost column (the universal 1 → 2 → 3 → 2 → 1 pattern).',
            ),
            const SizedBox(height: 10),
            _ExpandCard(
              Icons.speed_rounded,
              const Color(0xFF16A34A),
              'The Single-Line Advantage (Why it is faster)',
              'Traditional school multiplication forces you to write 2 or 3 lines of partial products with zeros, then add them up. Criss-Cross computes each place value directly from right to left, producing the answer in a single line with zero scratchpad clutter!',
            ),
          ] else if (isMentalMult) ...[
            ..._buildMentalMultiplicationBreakdownCards(),
          ] else if (isDiv) ...[
            ..._buildDivisionBreakdownCards(),
          ] else if (isSquares) ...[
            ..._buildSquaresBreakdownCards(),
          ] else if (isApplied) ...[
            ..._buildAppliedMathBreakdownCards(),
          ],
          const SizedBox(height: 12),
          _ExpandCard(
            Icons.lightbulb_outline_rounded,
            const Color(0xFF16A34A),
            'Why this shortcut works',
            _meta!.whyItWorks,
          ),
          const SizedBox(height: 10),
          _ExpandCard(
            Icons.warning_amber_rounded,
            const Color(0xFFDC2626),
            'Common mistake to avoid',
            _meta!.commonMistake,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: () => setState(() => _selectedTab = 2),
              icon: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Practice this Shortcut',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildMentalMultiplicationBreakdownCards() {
    final metaId = _meta!.id;
    if (metaId == 'multiply_by_5_25') {
      return const [
        _ExpandCard(
          Icons.swap_horiz_rounded,
          Color(0xFF2563EB),
          'Step 1: The Inversion Principle',
          'Multiplying by powers of 5 is converted into rapid mental halving and decimal shifts:\n• × 5   ≡  (÷ 2) × 10\n• × 25  ≡  (÷ 4) × 100\n• × 75  ≡  (÷ 4 × 3) × 100\n• × 125 ≡  (÷ 8) × 1,000\nHuman brains halve numbers far faster than performing multi-digit multiplication.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.call_split_rounded,
          Color(0xFFF97316),
          'Step 2: Mental Halving Cascade',
          '• For × 5: Halve once (e.g. 48 ÷ 2 = 24).\n• For × 25: Halve twice (e.g. 48 → 24 → 12).\n• For × 75: Halve twice then triple (48 → 12 → 36).\n• For × 125: Halve three times (48 → 24 → 12 → 6).',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Shift the Decimal Point Right',
          'Append zeros or shift the decimal point to the right:\n• × 5: shift 1 place right (24 → 240)\n• × 25: shift 2 places right (12 → 1,200)\n• × 75: shift 2 places right (36 → 3,600)\n• × 125: shift 3 places right (6 → 6,000)',
        ),
      ];
    }

    if (metaId == 'multiply_by_11') {
      return const [
        _ExpandCard(
          Icons.view_array_rounded,
          Color(0xFF2563EB),
          'Step 1: Outer Frame Setup',
          'Keep the outer digits intact! For any 2-digit number (e.g. 35), write the tens digit (3) on the left and the units digit (5) on the right, leaving an open slot in the center: 3 [ _ ] 5.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.add_link_rounded,
          Color(0xFFF97316),
          'Step 2: Adjacent Digit Sum',
          'Add the two outer digits: 3 + 5 = 8. If the sum is less than 10, simply drop it into the middle blank: 385! That is the complete product in 2 seconds.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Carrying When Sum ≥ 10',
          'If the digit sum is 10 or greater (e.g. 67 × 11: 6 + 7 = 13), write down the units digit (3) in the middle slot and carry the 1 over to the leftmost digit: 6 + 1 = 7. The result is 737 ✓.',
        ),
      ];
    }

    if (metaId == 'multiply_by_99') {
      return const [
        _ExpandCard(
          Icons.all_inclusive_rounded,
          Color(0xFF2563EB),
          'Step 1: The Round-Up Identity',
          '9 = 10 − 1, 99 = 100 − 1, and 999 = 1,000 − 1. Multiplying by 9, 99, or 999 is equivalent to multiplying by a round power of 10 and subtracting the number itself once.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.exposure_minus_1_rounded,
          Color(0xFFF97316),
          'Step 2: Base Multiply & Left-to-Right Subtraction',
          'Multiply by the base by appending zeros, then subtract the original number from left to right:\nE.g. 47 × 99 = 4,700 − 47.\n4,700 − 40 = 4,660;\n4,660 − 7 = 4,653.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: The Vedic Complement Shortcut',
          'Vedic Ekanyunena shortcut calculates this in one glance:\n• Left part: subtract 1 from the number (47 − 1 = 46)\n• Right part: complement to 100 (100 − 47 = 53)\nJoin them side-by-side: 46 | 53 = 4,653 ✓',
        ),
      ];
    }

    if (metaId == 'near_100_mult') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Base-100 Deviations',
          'Find how far each number deviates from base 100:\n• E.g. for 97 × 94: 97 is −3, 94 is −6.\n• For 104 × 107: 104 is +4, 107 is +7.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.swap_calls_rounded,
          Color(0xFFF97316),
          'Step 2: Cross Operation (Left Part)',
          'Add either number to the other number’s deviation. Both cross operations always give the exact same left part:\n97 + (−6) = 91  (and 94 + (−3) = 91).\nLeft part = 91.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Deviation Product & 2-Digit Zero-Padding',
          'Multiply the two deviations together:\n(−3) × (−6) = +18.\nIMPORTANT: Base 100 has 2 zeros, so the right part MUST take exactly 2 digits. (If product is 6, pad with zero to 06).\nAssemble: 91 | 18 = 9,118 ✓',
        ),
      ];
    }

    return const [];
  }

  List<Widget> _buildDivisionBreakdownCards() {
    final metaId = _meta!.id;
    if (metaId == 'divide_by_5_25') {
      return const [
        _ExpandCard(
          Icons.swap_horiz_rounded,
          Color(0xFF2563EB),
          'Step 1: The Inversion Principle',
          'Division by powers of 5 is converted into simple doubling and decimal shifts:\n• ÷ 5  ≡  (× 2) ÷ 10\n• ÷ 25 ≡  (× 4) ÷ 100\n• ÷ 125 ≡ (× 8) ÷ 1,000\nHuman brains double numbers up to 5 times faster than performing manual division.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.double_arrow_rounded,
          Color(0xFFF97316),
          'Step 2: Mental Doubling Cascade',
          '• For ÷ 5: Double once (e.g. 340 × 2 = 680).\n• For ÷ 25: Double twice (e.g. 612 → 1,224 → 2,448).\n• For ÷ 125: Double three times (e.g. 750 → 1,500 → 3,000 → 6,000).',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Shift the Decimal Point',
          'Shift the decimal left by the power of 10:\n• ÷ 5: shift 1 place left (680 → 68)\n• ÷ 25: shift 2 places left (2,448 → 24.48)\n• ÷ 125: shift 3 places left (6,000 → 6.00)',
        ),
      ];
    }
    if (metaId == 'divide_by_9_99') {
      return const [
        _ExpandCard(
          Icons.alt_route_rounded,
          Color(0xFF2563EB),
          'Step 1: The Vedic Digit Sum Principle',
          'Because 1/9 = 0.1111... and 1/99 = 0.010101..., division by 9 and 99 does NOT require traditional long division. Every digit in the quotient is produced simply by keeping a running cascade sum of the dividend digits!',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.trending_down_rounded,
          Color(0xFFF97316),
          'Step 2: Running Sum Cascade',
          'Bring down the first digit as the leading digit of the quotient. Then add each successive digit of the dividend to your running total:\n• 1st digit: 1\n• 2nd: 1 + 2 = 3\n• 3rd: 3 + 1 = 4\n• 4th (last): 4 + 4 = 8 (Remainder)',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Final Quotient & Remainder',
          'Read the running sum digits: Quotient = 134, Remainder = 8. If the remainder reaches 9 or above, carry 1 to the quotient and subtract 9.',
        ),
      ];
    }
    if (metaId == 'factor_division') {
      return const [
        _ExpandCard(
          Icons.call_split_rounded,
          Color(0xFF2563EB),
          'Step 1: Decompose the Divisor into 1-Digit Factors',
          'Never divide by a 2-digit composite number in one step. Break the divisor into two single-digit factors:\n• 45 = 9 × 5\n• 24 = 8 × 3 (or 6 × 4)\n• 36 = 9 × 4\n• 18 = 9 × 2\n• 14 = 7 × 2\n• 15 = 5 × 3',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.filter_1_rounded,
          Color(0xFFF97316),
          'Step 2: First Single-Digit Division',
          'Divide the dividend by the first factor. For example: 1,620 ÷ 9 = 180. Dividing by a single digit can be done entirely mentally in seconds.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.filter_2_rounded,
          Color(0xFF16A34A),
          'Step 3: Second Single-Digit Division',
          'Divide that intermediate answer by the second factor: 180 ÷ 5 = 36. You arrive at the exact answer with zero multi-digit scratchpad work!',
        ),
      ];
    }
    if (metaId == 'reciprocal_division') {
      return const [
        _ExpandCard(
          Icons.swap_horiz_rounded,
          Color(0xFF2563EB),
          'Step 1: Reciprocal Fraction Replacement',
          'Instead of dividing by decimals, replace them with their reciprocal multipliers:\n• ÷ 0.5  ≡  × 2\n• ÷ 0.25 ≡  × 4\n• ÷ 0.2  ≡  × 5\n• ÷ 0.125 ≡ × 8\n• ÷ 2.5  ≡  × 4 ÷ 10\n• ÷ 7.5  ≡  × 4 ÷ 30',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.bolt_rounded,
          Color(0xFFF97316),
          'Step 2: Mental Whole Multiplication',
          'Multiply the dividend by the integer multiplier. For 140 ÷ 2.5: compute 140 × 4 = 560.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Decimal Normalization',
          'Adjust by the power of 10 if necessary: 560 ÷ 10 = 56! Clean, fast, and completely exact.',
        ),
      ];
    }
    if (metaId == 'flag_division') {
      return const [
        _ExpandCard(
          Icons.flag_rounded,
          Color(0xFF2563EB),
          'Step 1: Base Divisor & Flag Digit Setup',
          'Split any 2-digit divisor into a base digit and a flag digit:\nFor 54: Base = 5, Flag = 4.\nThe single-digit base (5) handles the main division; the flag (4) adjusts remainders.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.tune_rounded,
          Color(0xFFF97316),
          'Step 2: Single-Digit Base Division',
          'Divide the leading digits of the dividend by the base divisor (5). Write down quotient digit q, and pass the remainder to the next column.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Crosswise Flag Adjustment',
          'Subtract (quotient digit × flag) from the combined next column value before dividing again. This single line eliminates scratchpad long division entirely.',
        ),
      ];
    }
    return const [];
  }

  List<Widget> _buildSquaresBreakdownCards() {
    final metaId = _meta!.id;
    if (metaId == 'squares_ending_5') {
      return const [
        _ExpandCard(
          Icons.pin_end_rounded,
          Color(0xFF2563EB),
          'Step 1: Tens Digit Multiplied by (n + 1)',
          'Isolate the part before the final 5 (the tens digit t). Multiply it by the next consecutive integer (t + 1).\n\nFor example, in 35²: tens digit is 3. Compute 3 × (3 + 1) = 3 × 4 = 12.\nThis becomes the entire left block of your answer.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.looks_5_rounded,
          Color(0xFFF97316),
          'Step 2: Units Digit Square (5² = 25)',
          'Square the units digit: 5² = 25.\n\nEvery single square of an integer ending in 5 ALWAYS ends in 25. You never have to calculate this part—it is fixed and guaranteed!',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Combine Left and Right Blocks',
          'Place the left product and right block side-by-side:\n12 | 25 = 1,225 ✓\n\nMore examples:\n• 65² → (6 × 7) | 25 = 4,225\n• 85² → (8 × 9) | 25 = 7,225\n• 95² → (9 × 10) | 25 = 9,025\nDone mentally in under 2 seconds!',
        ),
      ];
    }

    if (metaId == 'squares_base_25') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Distance from Reference Base 25',
          'Determine the difference d = N − 25.\n• For 26: d = +1\n• For 24: d = −1\n• For 28: d = +3\n• For 22: d = −3',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.call_split_rounded,
          Color(0xFFF97316),
          'Step 2: Mental 50-Cascade Addition',
          'Use the speed identity: (25 ± d)² = 625 ± 50d + d².\nBecause multiplying by 50 always produces a round number ending in 50 or 00, mental addition to 625 is instantaneous:\nFor 26²: 625 + (50 × 1) = 675.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Add Difference Squared (d²)',
          'Add the difference squared: d².\n675 + 1² = 676 ✓\n\nFor 24²: 625 − 50 + 1 = 576 ✓\nFor 28²: 625 + 150 + 9 = 784 ✓',
        ),
      ];
    }

    if (metaId == 'squares_base_50') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Deviation from Base 50',
          'Find the deviation d = N − 50:\n• For 46: d = −4\n• For 54: d = +4\n• For 42: d = −8\n• For 56: d = +6',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.exposure_rounded,
          Color(0xFFF97316),
          'Step 2: Left Part (25 ± d)',
          'Add the deviation directly to 25 (since 50² = 2500, the base multiplier is 25):\n• For 46: 25 + (−4) = 21\n• For 54: 25 + 4 = 29\n• For 42: 25 + (−8) = 17\n• For 56: 25 + 6 = 31',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Right Part (d²) & 2-Digit Width',
          'Square the deviation: d². Base 50 reserves exactly 2 digits for the right part:\n(−4)² = 16 → 21 | 16 = 2,116 ✓\n(+4)² = 16 → 29 | 16 = 2,916 ✓\n\nIf d² has 3 digits (e.g. 38² where d = 12, 12² = 144): keep 44 on right and carry 1 to left (25 − 12 + 1 = 14 → 1,444 ✓).',
        ),
      ];
    }

    if (metaId == 'squares_base_100') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Deviation from Base 100',
          'Find the deviation d = N − 100:\n• For 96: d = −4\n• For 104: d = +4\n• For 93: d = −7\n• For 107: d = +7',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.exposure_rounded,
          Color(0xFFF97316),
          'Step 2: Left Part (N ± d)',
          'Apply the deviation to the number itself: N + d:\n• For 96: 96 + (−4) = 92\n• For 104: 104 + 4 = 108\n• For 93: 93 + (−7) = 86\n• For 107: 107 + 7 = 114',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Right Part (d²) & 2-Digit Width',
          'Square the deviation: d². It occupies exactly 2 digits:\n(−4)² = 16 → 92 | 16 = 9,216 ✓\n(+4)² = 16 → 108 | 16 = 10,816 ✓\n\nIf d² < 10, pad with leading zero (e.g. 98²: d = −2, d² = 04 → 9,604 ✓).\nIf d² ≥ 100 (e.g. 88²: d = −12, 12² = 144), write 44 and carry 1 to left (88 − 12 + 1 = 77 → 7,744 ✓).',
        ),
      ];
    }

    if (metaId == 'squares_base_150') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Deviation from Base 150',
          'Find how far the number deviates from 150: d = N − 150:\n• For 146: d = −4\n• For 154: d = +4',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.swap_calls_rounded,
          Color(0xFFF97316),
          'Step 2: Left Part (N ± d) × 1.5',
          'Adjust the number: (N + d). Then scale by 1.5 (since 150 / 100 = 1.5).\nMultiplying by 1.5 is effortless: simply add half the number!\n• For 146: 146 − 4 = 142. Add half of 142 (71): 142 + 71 = 213.\n• For 154: 154 + 4 = 158. Add half of 158 (79): 158 + 79 = 237.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Right Part (d²) & 2-Digit Width',
          'Square the deviation: d² (2 digits):\n(−4)² = 16 → 213 | 16 = 21,316 ✓\n(+4)² = 16 → 237 | 16 = 23,716 ✓',
        ),
      ];
    }

    if (metaId == 'squares_base_200') {
      return const [
        _ExpandCard(
          Icons.radar_rounded,
          Color(0xFF2563EB),
          'Step 1: Deviation from Base 200',
          'Find the deviation from 200: d = N − 200:\n• For 196: d = −4\n• For 204: d = +4',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.double_arrow_rounded,
          Color(0xFFF97316),
          'Step 2: Left Part (N ± d) × 2',
          'Adjust the number: (N + d). Then scale by 2 (since 200 / 100 = 2):\n• For 196: (196 − 4) × 2 = 192 × 2 = 384.\n• For 204: (204 + 4) × 2 = 208 × 2 = 416.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Right Part (d²) & 2-Digit Width',
          'Square the deviation: d² (2 digits):\n(−4)² = 16 → 384 | 16 = 38,416 ✓\n(+4)² = 16 → 416 | 16 = 41,616 ✓',
        ),
      ];
    }

    return const [];
  }

  List<Widget> _buildAppliedMathBreakdownCards() {
    final metaId = _meta!.id;
    if (metaId == 'split_percentages') {
      return const [
        _ExpandCard(
          Icons.pie_chart_outline_rounded,
          Color(0xFF2563EB),
          'Step 1: Benchmark Decomposition',
          'Break any percentage into friendly anchors: 50%, 25%, 10%, 5%, and 1% chunks.\n• For 45%: think (50% − 5%)\n• For 95%: think (100% − 5%)\n• For 35%: think (25% + 10%)\n• For 17.5%: think (10% + 5% + 2.5%)\nThis eliminates pencil long-multiplication completely.',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.psychology_rounded,
          Color(0xFFF97316),
          'Step 2: Rapid Mental Derivations',
          'Calculate each anchor chunk instantaneously in memory:\n• 50%: Halve the number (N ÷ 2)\n• 25%: Halve twice (N ÷ 4)\n• 10%: Shift the decimal left by 1 place (N ÷ 10)\n• 5%: Halve the 10% subtotal\n• 1%: Shift the decimal left by 2 places (N ÷ 100)',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Add or Subtract in Memory',
          'Combine the derived benchmark values:\n• For 45% of 360: 50% (180) − 5% (18) = 162 ✓\n• For 15% of 240: 10% (24) + 5% (12) = 36 ✓\nAll calculations are done strictly left-to-right without scratchpad carrying!',
        ),
      ];
    }

    if (metaId == 'fraction_pct_friends') {
      return const [
        _ExpandCard(
          Icons.swap_horiz_rounded,
          Color(0xFF2563EB),
          'Step 1: The Unit Reciprocal Anchor (1/d)',
          'Every fraction n/d is anchored to its unit reciprocal 1/d:\n• 1/2 = 50%\n• 1/3 ≈ 33.33%\n• 1/4 = 25%\n• 1/5 = 20%\n• 1/6 ≈ 16.67%\n• 1/7 ≈ 14.28%\n• 1/8 = 12.5%\n• 1/9 ≈ 11.11%\n• 1/11 ≈ 9.09%\n• 1/12 ≈ 8.33%\n• 1/16 = 6.25%',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.trending_up_rounded,
          Color(0xFFF97316),
          'Step 2: Numerator Scaling or Complement Subtraction',
          'Scale up by the numerator:\n• 3/8 = 3 × 12.5% = 37.5%\n• 4/7 = 4 × 14.28% = 57.14%\nFor fractions near 1, use complement subtraction (100% − 1/d):\n• 5/6 = 100% − 1/6 = 100% − 16.67% = 83.33%\n• 7/8 = 100% − 1/8 = 100% − 12.5% = 87.5%',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: Instant Recall for Competitive Speed',
          'Standard questions frequently hide fractions inside decimals. Recognizing 37.5% as 3/8 or 83.33% as 5/6 instantly turns 2-minute decimal struggles into 2-second mental division!',
        ),
      ];
    }

    if (metaId == 'percentage_to_fraction') {
      return const [
        _ExpandCard(
          Icons.sync_alt_rounded,
          Color(0xFF2563EB),
          'Step 1: The Decimal-to-Fraction Paradigm',
          'Multiplying by decimal percentages like 37.5% or 83.33% with long multiplication takes over 60 seconds and invites careless arithmetic errors.\nBy memorizing reciprocal families, you replace decimal percentages with exact irreducible fractions (37.5% → 3/8, 83.33% → 5/6).',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.category_rounded,
          Color(0xFFF97316),
          'Step 2: The Core Percentage Families',
          '• Eighths (/8): 12.5% (1/8), 37.5% (3/8), 62.5% (5/8), 87.5% (7/8)\n• Sixths (/6): 16.67% (1/6), 83.33% (5/6)\n• Sevenths (/7): 14.28% (1/7), 28.57% (2/7), 42.86% (3/7), 57.14% (4/7)\n• Ninths (/9): 11.11% (1/9), 22.22% (2/9), 44.44% (4/9)\n• Elevenths (/11): 9.09% (1/11), 18.18% (2/11), 27.27% (3/11)\n• Sixteenths (/16): 6.25% (1/16), 18.75% (3/16)',
        ),
        SizedBox(height: 10),
        _ExpandCard(
          Icons.speed_rounded,
          Color(0xFF16A34A),
          'Step 3: 2-Second Division Shortcut',
          'Convert the question into integer division:\nP% of N = (n / d) × N = n × (N ÷ d)\nExample: 37.5% of 640:\n1. 640 ÷ 8 = 80\n2. 80 × 3 = 240 ✓\nFinished in under 2 seconds without writing a single line of working!',
        ),
      ];
    }

    return const [];
  }

  // ── Tab 2: Practice Shortcut (Config + Active Session) ──────────────────────

  Widget _buildPracticeTab() {
    if (!_isPracticing) {
      return _buildPracticeConfig();
    }
    return _buildActivePracticeSession();
  }

  Widget _buildPracticeConfig() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Difficulty Level Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Difficulty Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Difficulty Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: LessonDifficulty.values.map((d) {
                      final isSelected = _difficulty == d;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            d.name[0].toUpperCase() + d.name.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.surfaceCard,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                          ),
                          onSelected: (_) => setState(() => _difficulty = d),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _difficultyDescription(_difficulty),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Examination Mode Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.speed_rounded, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Examination Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mode Selector Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _examMode = LessonExamMode.questions),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _examMode == LessonExamMode.questions
                                ? AppTheme.primaryColor
                                : AppTheme.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Questions Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _examMode == LessonExamMode.questions
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _examMode = LessonExamMode.timer),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _examMode == LessonExamMode.timer
                                ? AppTheme.primaryColor
                                : AppTheme.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Timer Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _examMode == LessonExamMode.timer
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Secondary mode options
                if (_examMode == LessonExamMode.questions) ...[
                  const Text(
                    'Number of Questions:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [5, 10, 15, 20].map((qCount) {
                      final active = _selectedQuestionsCount == qCount;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$qCount'),
                          selected: active,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.surfaceCard,
                          labelStyle: TextStyle(
                            color: active ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(color: active ? AppTheme.primaryColor : AppTheme.borderLight),
                          onSelected: (_) => setState(() => _selectedQuestionsCount = qCount),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Text(
                    'Timer Duration:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [30, 60, 120].map((sec) {
                      final active = _selectedTimerSeconds == sec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${sec}s'),
                          selected: active,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.surfaceCard,
                          labelStyle: TextStyle(
                            color: active ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(color: active ? AppTheme.primaryColor : AppTheme.borderLight),
                          onSelected: (_) => setState(() => _selectedTimerSeconds = sec),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start Practice Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: _startPracticeSession,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              label: Text(
                _examMode == LessonExamMode.questions
                    ? 'Start Practice ($_selectedQuestionsCount Questions)'
                    : 'Start Practice (${_selectedTimerSeconds}s Timer)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyDescription(LessonDifficulty diff) {
    switch (diff) {
      case LessonDifficulty.beginner:
        return 'Beginner: 2-digit numbers without carrying or deficits.';
      case LessonDifficulty.easy:
        return 'Easy: Standard 2-digit numbers for foundational speed.';
      case LessonDifficulty.medium:
        return 'Medium: 2-digit numbers with carrying and column deficits.';
      case LessonDifficulty.hard:
        return 'Hard: 3-digit and mixed 3+2 digit numbers.';
      case LessonDifficulty.expert:
        return 'Expert: 3-digit and 4-digit speed math calculations.';
      case LessonDifficulty.genius:
        return 'Genius: 4-digit and 5-digit high-speed mental arithmetic.';
    }
  }

  Widget _buildActivePracticeSession() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final q = _questions[_practiceIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          if (_examMode == LessonExamMode.questions) ...[
            Row(
              children: [
                Text(
                  'Question ${_practiceIndex + 1} of $_selectedQuestionsCount',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_practiceCorrect correct',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _practiceCorrect > 0 ? const Color(0xFF16A34A) : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_practiceIndex) / _selectedQuestionsCount,
                minHeight: 5,
                backgroundColor: AppTheme.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Text(
                  '⏱️ $_remainingSeconds s remaining',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _remainingSeconds <= 10 ? Colors.red : AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_practiceCorrect correct',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _remainingSeconds / _selectedTimerSeconds,
                minHeight: 6,
                backgroundColor: AppTheme.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds <= 10 ? Colors.red : AppTheme.primaryColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Question display card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              q.questionText,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),

          // Input field and Check button
          if (!_answered) ...[
            TextField(
              controller: _ansCtrl,
              focusNode: _ansFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: 'Enter answer',
                hintStyle: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onSubmitted: (_) => _submitAnswer(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onPressed: _submitAnswer,
                child: Text(
                  _examMode == LessonExamMode.timer ? 'Submit' : 'Check Answer',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _wasCorrect
                    ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: _wasCorrect
                      ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _wasCorrect ? const Color(0xFF16A34A) : Colors.red,
                    size: 30,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _wasCorrect ? 'Correct! 🎉' : 'Answer: ${q.answer}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _wasCorrect ? const Color(0xFF16A34A) : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Show the trick for THIS question's operands!
            _buildQuestionTrickCard(q),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onPressed: _nextQuestion,
                child: Text(
                  _practiceIndex < _selectedQuestionsCount - 1
                      ? 'Next question →'
                      : 'See results',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionTrickCard(_PracticeQ q) {
    if (_meta!.id == 'add_in_parts' && q.ops.length >= 2) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive decomposition (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: AdditionStaticDiagram(a: q.ops[0], b: q.ops[1]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_meta!.id == 'subtract_in_parts' && q.ops.length >= 2) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive decomposition & deficits (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: SubtractionStaticDiagram(a: q.ops[0], b: q.ops[1]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isMultiplicationLesson() && q.ops.length >= 2) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Criss-Cross single-line steps (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child:
                        MultiplicationStaticDiagram(a: q.ops[0], b: q.ops[1]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isMentalMultiplicationLesson() && q.ops.isNotEmpty) {
      final first = q.ops[0];
      final second = _meta!.id == 'multiply_by_11'
          ? 11
          : (q.ops.length > 1 ? q.ops[1] : 5);
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive shortcut breakdown (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: MentalMultiplicationStaticDiagram(
                      lessonId: _meta!.id,
                      first: first,
                      second: second,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isDivisionLesson() && q.ops.isNotEmpty) {
      final dividend = q.ops[0];
      final divisor = q.ops.length > 1 ? q.ops[1] : _currentDivisor;
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive division shortcut (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: DivisionStaticDiagram(
                      lessonId: _meta!.id,
                      dividend: dividend,
                      divisor: divisor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isSquaresLesson() && q.ops.isNotEmpty) {
      final number = q.ops[0];
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive squaring shortcut (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: SquaresStaticDiagram(
                      lessonId: _meta!.id,
                      number: number,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isAppliedMathLesson() && q.ops.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text(
            'Show the trick for this problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive notebook diagram (pinch to zoom / pan):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 380,
                    child: AppliedMathStaticDiagram(
                      lessonId: _meta!.id,
                      operands: q.ops,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final script = _buildScript(q.ops);
    final trickText = script.blocks
        .map((b) => '${b.stepTitle}: ${b.caption}')
        .join('\n\n');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(
          Icons.lightbulb_outline_rounded,
          color: AppTheme.primaryColor,
        ),
        title: const Text(
          'Show the trick for this problem',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trickText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Done Phase ─────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final msg = switch (_stars) {
      3 => 'Perfect! You\'ve mastered this shortcut!',
      2 => 'Great work! Almost perfect speed math.',
      1 => 'Good start! Practice more to build reflex.',
      _ => 'Keep practicing — you will master it!',
    };

    final totalCount = _examMode == LessonExamMode.questions
        ? _selectedQuestionsCount
        : (_practiceIndex + 1);

    return Column(
      children: [
        const SizedBox(height: 20),
        LessonStars(stars: _stars, size: 42),
        const SizedBox(height: 14),
        Text(
          msg,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$_practiceCorrect / $totalCount correct (${_difficulty.name.toUpperCase()})',
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_xpAwarded) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '+30 XP — first mastery bonus!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            onPressed: () {
              setState(() {
                _phase = _Phase.active;
                _selectedTab = 2;
                _isPracticing = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Practice Again',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            onPressed: () {
              setState(() {
                _phase = _Phase.active;
                _selectedTab = 0;
              });
            },
            icon: const Icon(Icons.architecture_rounded, size: 18),
            label: const Text(
              'Review Shortcut Board',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Back to lessons',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pill Tab Item ────────────────────────────────────────────────────────────

class _PillTabItem extends StatelessWidget {
  const _PillTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting Preset & Expand Widgets ───────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.primaryTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _ExpandCard extends StatefulWidget {
  const _ExpandCard(this.icon, this.iconColor, this.title, this.content);
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  @override
  State<_ExpandCard> createState() => _ExpandCardState();
}

class _ExpandCardState extends State<_ExpandCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
