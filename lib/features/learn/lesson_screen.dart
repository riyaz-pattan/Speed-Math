// lib/features/learn/lesson_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import '../results/widgets/confetti_burst.dart';
import 'engine/lesson_data.dart';
import 'engine/lesson_registry.dart';
import 'engine/whiteboard_player.dart';
import 'widgets/lesson_stars.dart';

enum _Phase { intro, watch, yourTurn, practice, done }

/// Full lesson flow: Intro → Watch → Your Turn → Practice → Done.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId, this.initialOperands});
  final String lessonId;
  final List<int>? initialOperands;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  _Phase _phase = _Phase.intro;
  LessonMeta? _meta;
  late List<int> _operands;
  List<LessonStep> _steps = [];

  // Practice
  static const int _practiceTotal = 5;
  int _practiceIndex = 0;
  int _practiceCorrect = 0;
  List<_PracticeQ> _questions = [];
  final TextEditingController _ansCtrl = TextEditingController();
  bool _answered = false;
  bool _wasCorrect = false;

  // Done
  int _stars = 0;
  bool _xpAwarded = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    final meta = LessonRegistry.findById(widget.lessonId);
    if (meta != null) {
      _meta = meta;
      _operands = widget.initialOperands ?? meta.featuredOperands;
      _rebuildSteps();
    }
  }

  void _rebuildSteps() {
    try {
      _steps = _meta!.featuredBuilder(_operands);
    } catch (e) {
      debugPrint('LessonScreen: builder error: $e');
      _steps = [LessonStep(caption: 'Lesson unavailable. Please try again.', elements: const [])];
    }
  }

  // ── Navigation between phases ──────────────────────────────────────────────

  void _startWatch() => setState(() => _phase = _Phase.watch);

  void _watchFinished() {
    _incrementViewCount();
    setState(() => _phase = _Phase.yourTurn);
  }

  void _yourTurnFinished() {
    _buildQuestions();
    setState(() {
      _phase = _Phase.practice;
      _practiceIndex = 0;
      _practiceCorrect = 0;
      _answered = false;
    });
  }

  void _buildQuestions() {
    final rng = Random();
    _questions = List.generate(_practiceTotal, (_) {
      final ops = _meta!.generateOperands(rng);
      int answer = 0;
      try {
        final s = _meta!.featuredBuilder(ops);
        // Extract last number from last written-text element of last step
        final texts = s.last.elements
            .where((e) =>
                e.type == DrawElementType.writtenText ||
                e.type == DrawElementType.staticText)
            .map((e) => e.text ?? '')
            .toList();
        for (final t in texts.reversed) {
          final m = RegExp(r'(\d+)').allMatches(t).lastOrNull;
          if (m != null) {
            answer = int.tryParse(m.group(1) ?? '') ?? 0;
            if (answer > 0) break;
          }
        }
        if (answer == 0) answer = _fallback(ops);
      } catch (_) {
        answer = _fallback(ops);
      }
      return _PracticeQ(ops: ops, answer: answer);
    });
  }

  int _fallback(List<int> ops) {
    if (ops.isEmpty) return 0;
    if (ops.length == 1) return ops[0] * ops[0];
    return ops[0] * ops[1];
  }

  Future<void> _incrementViewCount() async {
    final repo = ref.read(lessonRepositoryProvider);
    final p = await repo.getProgress(widget.lessonId);
    await repo.saveProgress(p.copyWith(
      viewCount: p.viewCount + 1,
      status: p.status == LessonStatus.none ? LessonStatus.started : p.status,
    ));
    ref.invalidate(allLessonProgressProvider);
    ref.invalidate(lessonProgressProvider(widget.lessonId));
  }

  void _submit() {
    if (_answered) return;
    final q = _questions[_practiceIndex];
    final entered = int.tryParse(_ansCtrl.text.trim());
    final correct = entered != null && entered == q.answer;
    HapticFeedback.selectionClick();
    setState(() {
      _answered = true;
      _wasCorrect = correct;
      if (correct) _practiceCorrect++;
    });
  }

  void _nextQuestion() {
    _ansCtrl.clear();
    if (_practiceIndex < _practiceTotal - 1) {
      setState(() {
        _practiceIndex++;
        _answered = false;
        _wasCorrect = false;
      });
    } else {
      _finishPractice();
    }
  }

  Future<void> _finishPractice() async {
    final repo = ref.read(lessonRepositoryProvider);
    final p = await repo.getProgress(widget.lessonId);

    int newStars;
    if (_practiceCorrect == 5) {
      newStars = 3;
    } else if (_practiceCorrect >= 3) {
      newStars = 2;
    } else if (_practiceCorrect >= 1) {
      newStars = 1;
    } else {
      newStars = 0;
    }

    final bestStars = max(newStars, p.stars);
    final isFirst = p.xpAwarded == 0;
    final xp = isFirst ? 30 : 0;

    await repo.saveProgress(p.copyWith(
      status: newStars == 3 ? LessonStatus.mastered : LessonStatus.learned,
      stars: bestStars,
      practiceCorrect: p.practiceCorrect + _practiceCorrect,
      practiceTotal: p.practiceTotal + _practiceTotal,
      lastCompletedAt: DateTime.now(),
      xpAwarded: p.xpAwarded + xp,
    ));
    ref.invalidate(allLessonProgressProvider);
    ref.invalidate(lessonProgressProvider(widget.lessonId));

    setState(() {
      _stars = bestStars;
      _xpAwarded = isFirst;
      _phase = _Phase.done;
      _showConfetti = bestStars == 3;
    });
    if (bestStars == 3) HapticFeedback.heavyImpact();
  }

  void _tryAnother() {
    final ops = _meta!.generateOperands(Random());
    setState(() {
      _operands = ops;
      _rebuildSteps();
      _phase = _Phase.watch;
    });
  }

  @override
  void dispose() {
    _ansCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_meta == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Lesson not found.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go back')),
          ]),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.canvasBackground,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(meta: _meta!, phase: _phase, onBack: _onBack),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildPhase(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showConfetti) const ConfettiBurst(),
      ],
    );
  }

  void _onBack() {
    if (_phase == _Phase.intro) {
      context.pop();
    } else {
      setState(() => _phase = _Phase.intro);
    }
  }

  Widget _buildPhase() => switch (_phase) {
        _Phase.intro => _buildIntro(),
        _Phase.watch => _buildWatch(),
        _Phase.yourTurn => _buildYourTurn(),
        _Phase.practice => _buildPractice(),
        _Phase.done => _buildDone(),
      };

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntro() {
    final meta = _meta!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _Tag(meta.category),
          const SizedBox(width: 8),
          Text('• ${meta.durationLabel}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        const SizedBox(height: 14),
        Text(meta.title,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 22),
        _InfoCard(Icons.lightbulb_outline_rounded, const Color(0xFFF59E0B),
            'Why it works', meta.whyItWorks),
        const SizedBox(height: 12),
        _InfoCard(Icons.warning_amber_rounded, const Color(0xFFDC2626),
            'Common mistake', meta.commonMistake),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
            onPressed: _startWatch,
            icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.white),
            label: const Text('Watch the trick',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Watch ──────────────────────────────────────────────────────────────────

  Widget _buildWatch() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhiteboardPlayer(steps: _steps, canvasHeight: 200, onFinished: _watchFinished),
          const SizedBox(height: 18),
          _ExpandCard(Icons.lightbulb_outline_rounded, const Color(0xFFF59E0B),
              'Why it works', _meta!.whyItWorks),
          const SizedBox(height: 10),
          _ExpandCard(Icons.warning_amber_rounded, const Color(0xFFDC2626),
              'Common mistake', _meta!.commonMistake),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                onPressed: _tryAnother,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Another example', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                onPressed: _watchFinished,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                label: const Text('Your turn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ],
      );

  // ── Your Turn ──────────────────────────────────────────────────────────────

  Widget _buildYourTurn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Now watch again and try to follow the steps.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 18),
          WhiteboardPlayer(steps: _steps, canvasHeight: 200, onFinished: _yourTurnFinished),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
              onPressed: _yourTurnFinished,
              child: const Text("I've got it — start practice!",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      );

  // ── Practice ───────────────────────────────────────────────────────────────

  Widget _buildPractice() {
    if (_questions.isEmpty) return const Center(child: CircularProgressIndicator());
    final q = _questions[_practiceIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Question ${_practiceIndex + 1} of $_practiceTotal',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$_practiceCorrect correct',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _practiceCorrect > 0 ? const Color(0xFF16A34A) : AppTheme.textSecondary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _practiceIndex / _practiceTotal,
            minHeight: 5,
            backgroundColor: AppTheme.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 22),

        // Question card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Text(
            _questionText(q),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),

        if (!_answered) ...[
          TextField(
            controller: _ansCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter answer',
              hintStyle: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
              onPressed: _submit,
              child: const Text('Check',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                      : Colors.red.withValues(alpha: 0.4)),
            ),
            child: Column(children: [
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
                    color: _wasCorrect ? const Color(0xFF16A34A) : Colors.red),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _ExpandCard(Icons.lightbulb_outline_rounded, AppTheme.primaryColor,
              'Show the trick', _steps.map((s) => '• ${s.caption}').join('\n')),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _practiceIndex < _practiceTotal - 1 ? 'Next question →' : 'See results',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _questionText(_PracticeQ q) {
    final ops = q.ops;
    final metaId = _meta!.id;
    if (ops.length == 1) {
      if (metaId == 'squares_ending_5') return '${ops[0]}² = ?';
      if (metaId == 'multiply_by_11') return '${ops[0]} × 11 = ?';
      if (metaId == 'multiply_by_99') return '${ops[0]} × 99 = ?';
      return '${ops[0]}² = ?';
    }
    if (metaId == 'add_in_parts') return '${ops[0]} + ${ops[1]} = ?';
    if (metaId == 'split_percentages') return '${ops[0]}% of ${ops[1]} = ?';
    if (metaId == 'fraction_pct_friends') return '${ops[0]} = ?';
    return '${ops[0]} × ${ops[1]} = ?';
  }

  // ── Done ───────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final msg = switch (_stars) {
      3 => 'Perfect! You\'ve mastered this trick!',
      2 => 'Great work! Almost perfect.',
      1 => 'Good start! Practice more to improve.',
      _ => 'Keep going — try again!',
    };

    return Column(
      children: [
        const SizedBox(height: 20),
        LessonStars(stars: _stars, size: 40),
        const SizedBox(height: 12),
        Text(msg,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('$_practiceCorrect / $_practiceTotal correct',
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        if (_xpAwarded) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(20)),
            child: const Text('+30 XP — first completion bonus!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          ),
        ],
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
            onPressed: _tryAnother,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Try another example', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
            onPressed: () => context.go('/practice'),
            icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 17),
            label: const Text('Practice with timer',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to lessons',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.meta, required this.phase, required this.onBack});
  final LessonMeta meta;
  final _Phase phase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      _Phase.intro => 'Intro',
      _Phase.watch => 'Watch',
      _Phase.yourTurn => 'Your Turn',
      _Phase.practice => 'Practice',
      _Phase.done => 'Done',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meta.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ]),
        ),
        _PhaseDots(phase: phase),
      ]),
    );
  }
}

class _PhaseDots extends StatelessWidget {
  const _PhaseDots({required this.phase});
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _Phase.values.map((p) {
        final active = p == phase;
        final past = p.index < phase.index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: past
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : active
                    ? AppTheme.primaryColor
                    : AppTheme.borderLight,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 4),
              Text(body,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
            ]),
          ),
        ]),
      );
}

class _ExpandCard extends StatefulWidget {
  const _ExpandCard(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  State<_ExpandCard> createState() => _ExpandCardState();
}

class _ExpandCardState extends State<_ExpandCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Row(children: [
              Icon(widget.icon, color: widget.color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.color))),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: widget.color, size: 18),
            ]),
            if (_open) ...[
              const SizedBox(height: 8),
              Text(widget.body,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
            ],
          ]),
        ),
      );
}

// ── Internal model ────────────────────────────────────────────────────────────

class _PracticeQ {
  const _PracticeQ({required this.ops, required this.answer});
  final List<int> ops;
  final int answer;
}
