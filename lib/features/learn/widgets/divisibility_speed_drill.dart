// lib/features/learn/widgets/divisibility_speed_drill.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../engine/divisibility_helper.dart';

/// Interactive rapid-fire Divisibility Speed Drill.
///
/// Features:
/// - Questions Mode (5, 10, 20 questions) vs Timer Mode (30s, 60s, 120s)
/// - 6 Difficulty Tiers (Beginner to Genius)
/// - Instant mental rule breakdown on every answer
/// - Accuracy, streak tracking, and celebration banner
class DivisibilitySpeedDrill extends StatefulWidget {
  const DivisibilitySpeedDrill({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<DivisibilitySpeedDrill> createState() => _DivisibilitySpeedDrillState();
}

class _DivisibilitySpeedDrillState extends State<DivisibilitySpeedDrill> {
  // Config
  int _difficulty = 2; // 1 to 6
  bool _isTimerMode = false;
  int _targetQuestions = 10;
  int _targetSeconds = 60;

  // Active Game State
  bool _isPlaying = false;
  bool _isFinished = false;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _bestStreak = 0;

  late DrillQuestion _currentQ;
  bool _answered = false;
  bool _wasCorrect = false;

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 60;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _currentQ = DivisibilityHelper.generateDrillQuestion(_rng, _difficulty);
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = true;
      _isFinished = false;
      _currentIndex = 0;
      _correctCount = 0;
      _streak = 0;
      _bestStreak = 0;
      _answered = false;
      _currentQ = DivisibilityHelper.generateDrillQuestion(_rng, _difficulty);
      _remainingSeconds = _targetSeconds;
    });

    if (_isTimerMode) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_remainingSeconds <= 1) {
          t.cancel();
          _finishGame();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  void _submitAnswer(bool userSaidYes) {
    if (_answered || !_isPlaying) return;
    HapticFeedback.selectionClick();

    final correct = userSaidYes == _currentQ.isDivisible;
    setState(() {
      _answered = true;
      _wasCorrect = correct;
      if (correct) {
        _correctCount++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });

    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _nextQuestion() {
    if (_isTimerMode) {
      setState(() {
        _answered = false;
        _currentIndex++;
        _currentQ = DivisibilityHelper.generateDrillQuestion(_rng, _difficulty);
      });
    } else {
      if (_currentIndex + 1 >= _targetQuestions) {
        _finishGame();
      } else {
        setState(() {
          _answered = false;
          _currentIndex++;
          _currentQ =
              DivisibilityHelper.generateDrillQuestion(_rng, _difficulty);
        });
      }
    }
  }

  void _finishGame() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = false;
      _isFinished = true;
    });
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _buildFinishedView();
    }

    if (!_isPlaying) {
      return _buildSetupView();
    }

    return _buildActiveGameView();
  }

  // ── Setup View ────────────────────────────────────────────────────────────

  Widget _buildSetupView() {
    final diffLabels = [
      'Beginner (2, 5, 10)',
      'Easy (3, 4, 9)',
      'Medium (6, 8, 11)',
      'Hard (7, 12, 15, 25)',
      'Expert (13, 14, 18)',
      'Genius (Mixed Complex)',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Divisibility Speed Drill',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Train your instant mental factor recognition!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Difficulty Tier Selector
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(diffLabels.length, (i) {
              final lvl = i + 1;
              final isSel = _difficulty == lvl;
              return ChoiceChip(
                label: Text(diffLabels[i]),
                selected: isSel,
                onSelected: (_) => setState(() => _difficulty = lvl),
                selectedColor: const Color(0xFFFEF3C7),
                backgroundColor: AppTheme.surfaceCard,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel
                      ? const Color(0xFFB45309)
                      : AppTheme.textSecondary,
                ),
                side: BorderSide(
                  color: isSel
                      ? const Color(0xFFF59E0B)
                      : AppTheme.borderLight,
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Mode Selector (Questions vs Timer)
          const Text(
            'Drill Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _ModeOptionCard(
                  icon: Icons.format_list_numbered_rounded,
                  title: 'Questions Mode',
                  subtitle: '$_targetQuestions questions',
                  isSelected: !_isTimerMode,
                  onTap: () => setState(() => _isTimerMode = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeOptionCard(
                  icon: Icons.timer_outlined,
                  title: 'Timer Mode',
                  subtitle: '${_targetSeconds}s rapid fire',
                  isSelected: _isTimerMode,
                  onTap: () => setState(() => _isTimerMode = true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sub-options
          if (!_isTimerMode) ...[
            Row(
              children: [const [5, 10, 20].map((count) {
                final isSel = _targetQuestions == count;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$count Questions'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _targetQuestions = count),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel
                          ? const Color(0xFFB45309)
                          : AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList().first],
            ),
          ] else ...[
            Row(
              children: [const [30, 60, 120].map((sec) {
                final isSel = _targetSeconds == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${sec}s Timer'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _targetSeconds = sec),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel
                          ? const Color(0xFFB45309)
                          : AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList().first],
            ),
          ],

          const SizedBox(height: 30),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Start Divisibility Drill',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Game View ──────────────────────────────────────────────────────

  Widget _buildActiveGameView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Top HUD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(
                  _isTimerMode
                      ? Icons.timer_outlined
                      : Icons.format_list_numbered_rounded,
                  size: 18,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  _isTimerMode
                      ? '$_remainingSeconds s'
                      : 'Q ${_currentIndex + 1} of $_targetQuestions',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Streak
                if (_streak > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 3),
                        Text(
                          '$_streak streak',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  'Score: $_correctCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Problem Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RULE: ${_currentQ.ruleTitle.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Is this number divisible?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(text: '${_currentQ.number}'),
                      const TextSpan(
                        text: '  ÷  ',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '${_currentQ.divisor}',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons: YES / NO
          if (!_answered) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _submitAnswer(true),
                    icon: const Icon(Icons.check_rounded, size: 24),
                    label: const Text(
                      'YES',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // green-600
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _submitAnswer(false),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    label: const Text(
                      'NO',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // red-600
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Feedback Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _wasCorrect
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _wasCorrect
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _wasCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _wasCorrect
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _wasCorrect ? 'CORRECT!' : 'INCORRECT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _wasCorrect
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _currentQ.isDivisible
                            ? 'It IS divisible by ${_currentQ.divisor}'
                            : 'It is NOT divisible by ${_currentQ.divisor}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _wasCorrect
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentQ.explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  _currentIndex + 1 >= _targetQuestions && !_isTimerMode
                      ? 'Finish Drill'
                      : 'Next Question',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Finished View ─────────────────────────────────────────────────────────

  Widget _buildFinishedView() {
    final total = _isTimerMode ? _currentIndex + 1 : _targetQuestions;
    final accuracy = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 3),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                size: 38, color: Color(0xFFD97706)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Drill Completed!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Great practice! Your divisibility recognition is getting faster.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),

          // Score Cards Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Score',
                  value: '$_correctCount / $total',
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Accuracy',
                  value: '$accuracy%',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Best Streak',
                  value: '$_bestStreak',
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _isPlaying = false;
                _isFinished = false;
              }),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppTheme.borderLight),
              ),
              child: const Text('Back to Setup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD97706)
                : AppTheme.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFFD97706)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFFB45309)
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
