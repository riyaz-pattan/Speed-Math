import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/ads/widgets/banner_ad_container.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import 'package:speed_math_with_ai/core/widgets/empty_state_view.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/models/session.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/skill_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../domain/adaptive/skill_engine.dart';
import '../../domain/adaptive/skill_rating.dart';
import 'widgets/history_line_graph.dart';

/// Screen presenting per-topic performance metrics, high scores, top-3 best times,
/// and interactive history line charts.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late Topic _selectedTopic;
  late Difficulty _selectedDifficulty;
  late PracticeMode _selectedMode;
  late int _selectedModeValue;
  bool _initialized = false;

  Session? _bestScoreSession;
  double? _recentBestScore;
  List<Session> _topBestTimes = [];
  List<Session> _historySessions = [];
  Map<Difficulty, SkillRating> _topicSkillRatings = {};
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = ref.read(settingsRepositoryProvider);
      var topic = settings.lastTopic;
      if (topic == Topic.mixed) topic = Topic.addition;
      var diff = settings.lastDifficulty;
      if (diff == Difficulty.mixed) diff = Difficulty.easy;
      var mode = settings.lastMode;
      if (mode == PracticeMode.smart || mode == PracticeMode.mistakes) {
        mode = PracticeMode.questions;
      }
      _selectedTopic = topic;
      _selectedDifficulty = diff;
      _selectedMode = mode;
      _selectedModeValue = _selectedMode == PracticeMode.timer
          ? settings.lastTimerDuration
          : settings.lastQuestionCount;
      _initialized = true;
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final statsRepo = ref.read(statsRepositoryProvider);
      final skillRepo = ref.read(skillRepositoryProvider);

      final bestSessionFuture = statsRepo.getBestScoreSession(
        _selectedTopic,
        _selectedDifficulty,
        _selectedMode,
        _selectedModeValue,
      );

      final recentBestFuture = statsRepo.getRecentBestScore(
        _selectedTopic,
        _selectedDifficulty,
        _selectedMode,
        _selectedModeValue,
        limit: 10,
      );

      final topTimesFuture = statsRepo.getTopBestTimes(
        _selectedTopic,
        _selectedDifficulty,
        _selectedMode,
        _selectedModeValue,
        limit: 3,
      );

      final historyFuture = statsRepo.getSessionHistory(
        _selectedTopic,
        _selectedDifficulty,
        _selectedMode,
        _selectedModeValue,
      );

      final skillsFuture = skillRepo.getRatingsForTopic(_selectedTopic);

      final results = await Future.wait([
        bestSessionFuture,
        recentBestFuture,
        topTimesFuture,
        historyFuture,
        skillsFuture,
      ]);

      if (!mounted) return;

      final skillsList = results[4] as List<SkillRating>;
      final skillsMap = <Difficulty, SkillRating>{};
      for (final s in skillsList) {
        skillsMap[s.difficulty] = s;
      }

      setState(() {
        _bestScoreSession = results[0] as Session?;
        _recentBestScore = results[1] as double?;
        _topBestTimes = results[2] as List<Session>;
        _historySessions = results[3] as List<Session>;
        _topicSkillRatings = skillsMap;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bestScoreSession = null;
        _recentBestScore = null;
        _topBestTimes = const [];
        _historySessions = const [];
        _topicSkillRatings = const {};
        _isLoading = false;
      });
    }
  }

  void _onTopicChanged(Topic topic) {
    setState(() => _selectedTopic = topic);
    ref.read(settingsRepositoryProvider).setLastTopic(topic);
    _loadStats();
  }

  void _onDifficultyChanged(Difficulty difficulty) {
    setState(() => _selectedDifficulty = difficulty);
    ref.read(settingsRepositoryProvider).setLastDifficulty(difficulty);
    _loadStats();
  }

  void _onModeChanged(PracticeMode mode) {
    final settings = ref.read(settingsRepositoryProvider);
    final newModeValue = mode == PracticeMode.timer
        ? settings.lastTimerDuration
        : settings.lastQuestionCount;

    setState(() {
      _selectedMode = mode;
      _selectedModeValue = newModeValue;
    });
    settings.setLastMode(mode);
    _loadStats();
  }

  void _onModeValueChanged(int value) {
    final settings = ref.read(settingsRepositoryProvider);
    setState(() => _selectedModeValue = value);
    if (_selectedMode == PracticeMode.timer) {
      settings.setLastTimerDuration(value);
    } else {
      settings.setLastQuestionCount(value);
    }
    _loadStats();
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dataRevisionProvider, (_, __) {
      _loadStats();
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: AppStrings.stats,
            subtitle: 'Performance metrics & growth',
            actions: [
              HeaderIconButton(
                icon: Icons.history_rounded,
                tooltip: 'History',
                onPressed: () => context.push('/history'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Top filter controls
                  _buildFilterSelectors(colorScheme),
                  const SizedBox(height: 16),

                  // Skill Level Card for selected topic
                  _buildSkillLevelCard(colorScheme),
                  const SizedBox(height: 16),

              if (_isLoading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // High Scores & Best Times Cards
                _buildSummaryCards(colorScheme),
                const SizedBox(height: 20),

                // History Line Graph
                Text(
                  'Progress Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                HistoryLineGraph(completedSessions: _historySessions),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Showing single-topic drills. Mixed practice is tracked in your Performance Report.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // "View all sessions" button
                OutlinedButton.icon(
                  onPressed: () => context.push('/history'),
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View All Sessions'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
      if (!_isLoading) const BannerAdContainer(),
    ],
  ),
);
  }

  Widget _buildFilterSelectors(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic chips (Standard topics only for single-topic drills)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: Topic.standardTopics.map((t) {
              final isSelected = _selectedTopic == t;
              final topicColor = AppTheme.getTopicColor(t);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: Text(
                    t.symbol,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : topicColor,
                    ),
                  ),
                  label: Text(
                    t.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: colorScheme.surface,
                  selectedColor: topicColor,
                  side: BorderSide(
                    color: isSelected
                        ? topicColor
                        : colorScheme.outline.withValues(alpha: 0.25),
                  ),
                  onSelected: (_) => _onTopicChanged(t),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Difficulty & Mode & Value row
        Row(
          children: [
            // Difficulty dropdown (Easy, Medium, Hard only)
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Difficulty>(
                    value: _selectedDifficulty,
                    isDense: true,
                    isExpanded: true,
                    items: const [
                      Difficulty.easy,
                      Difficulty.medium,
                      Difficulty.hard,
                    ].map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d.displayName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onDifficultyChanged(val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mode dropdown (Questions or Timer)
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PracticeMode>(
                    value: _selectedMode,
                    isDense: true,
                    isExpanded: true,
                    items: const [
                      PracticeMode.questions,
                      PracticeMode.timer,
                    ].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.displayName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onModeChanged(val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mode Value dropdown
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedModeValue,
                    isDense: true,
                    isExpanded: true,
                    items: (_selectedMode == PracticeMode.timer
                            ? AppConstants.timerModeOptions
                            : AppConstants.questionModeOptions)
                        .map((val) {
                      final label = _selectedMode == PracticeMode.timer
                          ? '${val ~/ 60}m'
                          : '$val Qs';
                      return DropdownMenuItem(
                        value: val,
                        child: Text(label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onModeValueChanged(val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillLevelCard(ColorScheme colorScheme) {
    final topicColor = AppTheme.getTopicColor(_selectedTopic);
    const engine = SkillEngine();
    final hasAnyData = _topicSkillRatings.values.any((r) => r.attemptsCount >= 5);

    return TactileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: topicColor),
              const SizedBox(width: 8),
              Text(
                '${_selectedTopic.displayName} Skill Level',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: topicColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedTopic.symbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: topicColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bars for concrete difficulties (Easy, Medium, Hard, Expert, Genius)
          ...Difficulty.concreteDifficulties.map((diff) {
            final rating = _topicSkillRatings[diff];
            final bucket = rating != null
                ? engine.classifyBucket(rating)
                : SkillBucketLevel.notEnoughData;
            final hasData = (rating?.attemptsCount ?? 0) >= 5;
            final mastery = rating?.mastery ?? 0.5;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        diff.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hasData
                            ? '${(mastery * 100).round()}% • ${bucket.displayName}'
                            : bucket.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: hasData ? topicColor : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hasData ? mastery : 0.0,
                      minHeight: 6,
                      backgroundColor: colorScheme.outline.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(topicColor),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (!hasAnyData)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Complete at least 5 questions per difficulty to reveal your skill rating.',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ColorScheme colorScheme) {
    if (_historySessions.isEmpty) {
      return EmptyStateView(
        icon: Icons.emoji_events_outlined,
        title: 'No practice data yet',
        message:
            'Practice with ${_selectedTopic.displayName} (${_selectedDifficulty.displayName}) to unlock high scores and progress trends.',
        actionLabel: 'Practice Now',
        onAction: () => context.go('/practice', extra: _selectedTopic),
      );
    }

    return Column(
      children: [
        // High Score Row
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                title: AppStrings.bestScore,
                value: _bestScoreSession != null
                    ? _bestScoreSession!.score.toStringAsFixed(0)
                    : '—',
                subtitle: _bestScoreSession != null
                    ? _formatDate(_bestScoreSession!.startedAt)
                    : null,
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber.shade700,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                title: AppStrings.recentBestScore,
                value: _recentBestScore != null
                    ? _recentBestScore!.toStringAsFixed(0)
                    : '—',
                subtitle: 'Last 10 sessions',
                icon: Icons.history_toggle_off_rounded,
                iconColor: AppTheme.primaryColor,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Top 3 Best Times Card
        _buildTopTimesCard(colorScheme),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required ColorScheme colorScheme,
  }) {
    return TactileCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopTimesCard(ColorScheme colorScheme) {
    final isQuestionMode = _selectedMode == PracticeMode.questions;

    return TactileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 20, color: Colors.cyan.shade700),
              const SizedBox(width: 8),
              const Text(
                AppStrings.bestTimes,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isQuestionMode
                      ? 'Total time (≥80% acc)'
                      : 'Avg / correct (≥80% acc)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_topBestTimes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No qualifying sessions (≥80% accuracy) recorded yet.',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ...List.generate(_topBestTimes.length, (index) {
              final s = _topBestTimes[index];
              final rankIcon = switch (index) {
                0 => '🥇',
                1 => '🥈',
                _ => '🥉',
              };

              final metricText = isQuestionMode
                  ? _formatDuration(s.durationMs)
                  : '${(s.avgTimeMs / 1000).toStringAsFixed(2)}s / correct';

              final accuracyText = '${(s.accuracy <= 1.0 ? s.accuracy * 100 : s.accuracy).toStringAsFixed(0)}%';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(rankIcon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      metricText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($accuracyText acc)',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(s.startedAt),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
