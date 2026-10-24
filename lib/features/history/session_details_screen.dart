import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/models/attempt.dart';
import '../../data/models/session.dart';
import '../../data/repositories/attempt_repository.dart';

/// Screen displaying in-depth review of a single completed or partial session,
/// including all individual attempts and highlighting the slowest question.
class SessionDetailsScreen extends ConsumerStatefulWidget {
  final Session session;

  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<SessionDetailsScreen> createState() =>
      _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends ConsumerState<SessionDetailsScreen> {
  List<Attempt> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final sessionId = widget.session.id;
    if (sessionId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repo = ref.read(attemptRepositoryProvider);
    final attempts = await repo.getAttemptsBySessionId(sessionId);

    if (mounted) {
      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    // Identify the slowest attempt
    int maxTimeMs = 0;
    int? slowestAttemptId;
    for (final a in _attempts) {
      if (a.timeMs > maxTimeMs) {
        maxTimeMs = a.timeMs;
        slowestAttemptId = a.id;
      }
    }

    final isMixed = session.kind == SessionKind.mixed || session.mode == PracticeMode.smart;
    final isMistakes = session.kind == SessionKind.mistakes || session.mode == PracticeMode.mistakes;
    final screenTitle = isMixed
        ? 'Mixed practice'
        : isMistakes
            ? 'Mistakes practice'
            : '${session.topic.displayName} - ${session.difficulty.displayName}';

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: screenTitle,
            subtitle: _formatDate(session.startedAt),
            leading: HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Session Overview Header
                _buildOverviewCard(session),
                const SizedBox(height: 14),

                // Performance Metrics Grid
                _buildMetricsGrid(session),
                const SizedBox(height: 20),

                // Questions List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions (${_attempts.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (!session.completed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'Ended early',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_attempts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No question records available for this session.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ...List.generate(_attempts.length, (index) {
                    final attempt = _attempts[index];
                    final isSlowest =
                        attempt.id == slowestAttemptId && _attempts.length > 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildAttemptTile(
                        index + 1,
                        attempt,
                        isSlowest,
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Session session) {
    final isMixed = session.kind == SessionKind.mixed || session.mode == PracticeMode.smart;
    final isMistakes = session.kind == SessionKind.mistakes || session.mode == PracticeMode.mistakes;
    final modeLabel = session.mode == PracticeMode.timer
        ? '${session.modeValue ~/ 60} Min Timer'
        : '${session.modeValue} Questions';
    final topicColor = isMixed || isMistakes
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(session.topic);

    return TactileCard(
      padding: const EdgeInsets.all(18),
      borderColor: topicColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: topicColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: topicColor,
                  ),
                ),
              ),
              Text(
                'ID #${session.id ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.score.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ACCURACY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(session.accuracy <= 1.0 ? session.accuracy * 100 : session.accuracy).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: session.accuracy >= 0.8
                          ? AppTheme.successColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Session session) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            'Duration',
            _formatDuration(session.durationMs),
            Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            'Avg. Time',
            '${(session.avgTimeMs / 1000).toStringAsFixed(1)}s',
            Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            'Correct',
            '${session.correctCount} / ${session.totalQuestions}',
            Icons.check_circle_outline_rounded,
            valueColor: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return TactileCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: AppTheme.radiusMd,
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptTile(
    int number,
    Attempt attempt,
    bool isSlowest,
  ) {
    final isCorrect = attempt.isCorrect;
    final isSkipped = attempt.isSkipped;

    final Color statusColor;
    final IconData statusIcon;

    if (isSkipped) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.skip_next_rounded;
    } else if (isCorrect) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel_rounded;
    }

    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppTheme.radiusMd,
      borderColor: isSlowest
          ? AppTheme.warningColor.withValues(alpha: 0.5)
          : (!isCorrect && !isSkipped)
              ? AppTheme.errorColor.withValues(alpha: 0.2)
              : AppTheme.borderLight,
      backgroundColor: isSlowest
          ? AppTheme.warningColor.withValues(alpha: 0.05)
          : AppTheme.surfaceCard,
      child: Row(
        children: [
          // Index number
          SizedBox(
            width: 26,
            child: Text(
              '$number.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
              ),
            ),
          ),

          // Question expression
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuestionTextWidget(
                  text: attempt.questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.start,
                ),
                if (!isCorrect && !isSkipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      (attempt.topic == Topic.fractionReciprocals || attempt.topic == Topic.derivedFractions)
                          ? 'Incorrect (Correct: ${attempt.targetAnswerText})'
                          : 'Answered: ${attempt.userAnswer ?? "—"} (Correct: ${attempt.targetAnswerText})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (isSkipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Skipped (Correct: ${attempt.targetAnswerText})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Slowest badge if applicable
          if (isSlowest)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Slowest',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
              ),
            ),

          // Time taken
          Text(
            '${(attempt.timeMs / 1000).toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSlowest ? AppTheme.warningColor : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),

          // Right / Wrong / Skipped icon
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }
}
