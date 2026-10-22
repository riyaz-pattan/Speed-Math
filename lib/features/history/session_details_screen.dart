import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/question_text_widget.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Session Overview Header
            _buildOverviewCard(session, colorScheme),
            const SizedBox(height: 16),

            // Performance Metrics Grid
            _buildMetricsGrid(session, colorScheme),
            const SizedBox(height: 24),

            // Questions List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (${_attempts.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (!session.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'Ended early',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No question records available for this session.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                    colorScheme,
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Session session, ColorScheme colorScheme) {
    final isMixed = session.kind == SessionKind.mixed || session.mode == PracticeMode.smart;
    final isMistakes = session.kind == SessionKind.mistakes || session.mode == PracticeMode.mistakes;
    final modeLabel = session.mode == PracticeMode.timer
        ? '${session.modeValue ~/ 60} Min Timer'
        : '${session.modeValue} Questions';
    final topicColor = isMixed || isMistakes
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(session.topic);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: topicColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: topicColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                modeLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                _formatDate(session.startedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.score.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    session.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.accuracy.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(session.accuracy <= 1.0 ? session.accuracy * 100 : session.accuracy).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
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

  Widget _buildMetricsGrid(Session session, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            'Duration',
            _formatDuration(session.durationMs),
            Icons.timer_outlined,
            colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            'Avg. Time',
            '${(session.avgTimeMs / 1000).toStringAsFixed(1)}s',
            Icons.speed_rounded,
            colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            'Correct',
            '${session.correctCount} / ${session.totalQuestions}',
            Icons.check_circle_outline_rounded,
            colorScheme,
            valueColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
    ColorScheme colorScheme, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? colorScheme.onSurface,
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
    ColorScheme colorScheme,
  ) {
    final isCorrect = attempt.isCorrect;
    final isSkipped = attempt.isSkipped;

    final Color statusColor;
    final IconData statusIcon;

    if (isSkipped) {
      statusColor = Colors.orange;
      statusIcon = Icons.skip_next_rounded;
    } else if (isCorrect) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSlowest
            ? Colors.orange.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSlowest
              ? Colors.orange.withValues(alpha: 0.6)
              : colorScheme.outline.withValues(alpha: 0.12),
          width: isSlowest ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Index number
          SizedBox(
            width: 26,
            child: Text(
              '$number.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
                if (!isCorrect && !isSkipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Answered: ${attempt.userAnswer ?? "—"} (Correct: ${attempt.correctAnswer})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (isSkipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Skipped (Correct: ${attempt.correctAnswer})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
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
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Slowest',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),

          // Time taken
          Text(
            '${(attempt.timeMs / 1000).toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSlowest ? Colors.orange : colorScheme.onSurfaceVariant,
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
