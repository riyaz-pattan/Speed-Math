import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../data/repositories/mistake_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/skill_repository.dart';
import '../../domain/adaptive/skill_rating.dart';
import '../../domain/questions/session_random.dart';
import '../../core/widgets/app_segmented_control.dart';
import '../practice_session/models/practice_models.dart';

/// Single unified Practice Screen for configuring and launching drills,
/// mixed practice, and revising mistakes.
class PracticeSetupScreen extends ConsumerStatefulWidget {
  final Topic? initialTopic;

  const PracticeSetupScreen({
    super.key,
    this.initialTopic,
  });

  @override
  ConsumerState<PracticeSetupScreen> createState() =>
      _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  late List<Topic> _selectedTopics;
  late Difficulty? _selectedDifficulty; // null = Auto
  late bool _focusOnWeakAreas;
  late PracticeMode _selectedMode;
  late int _selectedTimerDuration;
  late int _selectedQuestionCount;

  List<SkillRating> _weakSpots = [];
  int _mistakeCount = 0;
  bool _initialized = false;
  bool _isLaunching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = ref.read(settingsRepositoryProvider);

      if (widget.initialTopic != null) {
        _selectedTopics = [widget.initialTopic!];
        _selectedDifficulty = settings.practiceDifficulty ?? Difficulty.easy;
      } else {
        _selectedTopics = List.from(settings.practiceTopics);
        if (_selectedTopics.isEmpty) {
          _selectedTopics = List.from(Topic.standardTopics);
        }
        _selectedDifficulty = settings.practiceDifficulty;
      }

      _focusOnWeakAreas = settings.practiceFocusWeakAreas;
      _selectedMode = settings.lastMode == PracticeMode.timer
          ? PracticeMode.timer
          : PracticeMode.questions;
      _selectedTimerDuration = settings.lastTimerDuration;
      _selectedQuestionCount = settings.lastQuestionCount;

      _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMistakeCount(),
      _loadWeakSpots(),
    ]);
  }

  Future<void> _loadMistakeCount() async {
    try {
      final repo = ref.read(mistakeRepositoryProvider);
      final count = await repo.getMistakeCount();
      if (mounted) {
        setState(() => _mistakeCount = count);
      }
    } catch (_) {}
  }

  Future<void> _loadWeakSpots() async {
    try {
      final skillRepo = ref.read(skillRepositoryProvider);
      final ratings = await skillRepo.getAllRatings();
      final weak = ratings
          .where((r) => r.attemptsCount >= 5 && r.mastery < 0.65)
          .toList()
        ..sort((a, b) => a.mastery.compareTo(b.mastery));

      if (mounted) {
        setState(() {
          _weakSpots = weak.take(4).toList();
        });
      }
    } catch (_) {}
  }

  void _onWeakSpotTapped(SkillRating rating) {
    setState(() {
      _selectedTopics = [rating.topic];
      _selectedDifficulty = rating.difficulty;
      _focusOnWeakAreas = true;
    });
  }

  void _toggleTopic(Topic topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        if (_selectedTopics.length > 1) {
          _selectedTopics.remove(topic);
        }
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _selectAllTopics() {
    setState(() {
      _selectedTopics = List.from(Topic.standardTopics);
    });
  }

  Future<void> _startPractice() async {
    if (_isLaunching) return;
    _isLaunching = true;

    try {
      final settings = ref.read(settingsRepositoryProvider);

      await settings.saveUnifiedPracticeSetup(
        topics: _selectedTopics,
        difficulty: _selectedDifficulty,
        focusWeakAreas: _focusOnWeakAreas,
        mode: _selectedMode,
        timerDuration: _selectedTimerDuration,
        questionCount: _selectedQuestionCount,
      );

      final sessionConfig = SessionConfig(
        selectedTopics: List.from(_selectedTopics),
        difficulty: _selectedDifficulty,
        focusOnWeakAreas: _focusOnWeakAreas,
        mode: _selectedMode,
        targetValue: _selectedMode == PracticeMode.timer
            ? _selectedTimerDuration
            : _selectedQuestionCount,
      );

      final config = PracticeConfig.fromSessionConfig(
        sessionConfig: sessionConfig,
        sessionSeed: SessionRandom.newSessionSeed(),
        autoSubmit: settings.autoSubmit,
        hapticsEnabled: settings.hapticsEnabled,
        correctSoundEnabled: settings.correctSoundEnabled,
        wrongSoundEnabled: settings.wrongSoundEnabled,
        soundVolume: settings.soundVolume,
        correctSoundVolume: settings.correctSoundVolume,
        wrongSoundVolume: settings.wrongSoundVolume,
        keypadStyle: settings.keypadStyle,
      );

      if (mounted) {
        await context.push('/practice/session', extra: config);
        // Reload data after returning from session
        await _loadData();
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  Future<void> _startMistakePractice() async {
    if (_mistakeCount == 0 || _isLaunching) return;
    _isLaunching = true;

    try {
      final repo = ref.read(mistakeRepositoryProvider);
      final count = min(10, _mistakeCount);
      final mistakes = await repo.getMistakesForPractice(limit: count);
      if (mistakes.isEmpty) return;

      final settings = ref.read(settingsRepositoryProvider);

      final config = PracticeConfig(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.mistakes,
        kind: SessionKind.mistakes,
        modeValue: mistakes.length,
        sessionSeed: SessionRandom.newSessionSeed(),
        autoSubmit: settings.autoSubmit,
        hapticsEnabled: settings.hapticsEnabled,
        correctSoundEnabled: settings.correctSoundEnabled,
        wrongSoundEnabled: settings.wrongSoundEnabled,
        soundVolume: settings.soundVolume,
        correctSoundVolume: settings.correctSoundVolume,
        wrongSoundVolume: settings.wrongSoundVolume,
        keypadStyle: settings.keypadStyle,
        initialMistakes: mistakes,
      );

      if (mounted) {
        await context.push('/practice/session', extra: config);
        await _loadData();
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  String _buildSummaryLine() {
    final String topicPart;
    if (_selectedTopics.length == 1) {
      topicPart = _selectedTopics.first.displayName;
    } else if (_selectedTopics.length == Topic.standardTopics.length) {
      topicPart = 'Mixed practice (All topics)';
    } else {
      topicPart = 'Mixed practice (${_selectedTopics.length} topics)';
    }

    final String diffPart;
    if (_selectedDifficulty == null) {
      diffPart = 'Auto difficulty';
    } else {
      diffPart = _selectedDifficulty!.displayName;
    }

    final String targetPart;
    if (_selectedMode == PracticeMode.timer) {
      final mins = _selectedTimerDuration ~/ 60;
      targetPart = '$mins min timer';
    } else {
      targetPart = '$_selectedQuestionCount questions';
    }

    return '$topicPart • $diffPart • $targetPart';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Listen for data resets
    ref.listen(dataRevisionProvider, (_, __) {
      _loadData();
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.practice,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // 1. Weak Spots quick chips (if available)
                  if (_weakSpots.isNotEmpty) ...[
                    _buildWeakSpotsRow(colorScheme),
                    const SizedBox(height: 20),
                  ],

                  // 2. Topics Selector
                  _buildSectionHeader(
                    'Topics',
                    subtitle: '${_selectedTopics.length} of ${Topic.standardTopics.length} selected',
                  ),
                  const SizedBox(height: 10),
                  _buildTopicsChips(colorScheme),
                  const SizedBox(height: 24),

                  // 3. Difficulty Selector
                  _buildSectionHeader('Difficulty'),
                  const SizedBox(height: 10),
                  _buildDifficultySegmented(colorScheme),
                  const SizedBox(height: 20),

                  // 4. "Focus on my weak areas" Switch (shown in every case)
                  _buildWeakAreasSwitch(colorScheme),
                  const SizedBox(height: 20),

                  // 5. Practice Mode & Target
                  _buildSectionHeader('Practice Mode'),
                  const SizedBox(height: 10),
                  _buildModeSelector(colorScheme),
                  const SizedBox(height: 14),
                  _buildTargetPills(colorScheme),
                  const SizedBox(height: 28),

                  // 6. Practice My Mistakes Card
                  _buildMistakesCard(colorScheme),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Sticky Bottom Section: Summary line + Start Practice Button
            _buildStickyBottom(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildWeakSpotsRow(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 16, color: Colors.amber[800]),
            const SizedBox(width: 6),
            Text(
              AppStrings.yourWeakSpots,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weakSpots.map((rating) {
            final topicColor = AppTheme.getTopicColor(rating.topic);
            final label = '${rating.topic.displayName} - ${rating.difficulty.displayName}';

            return ActionChip(
              avatar: Text(
                rating.topic.symbol,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: topicColor,
                ),
              ),
              label: Text(label),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              backgroundColor: topicColor.withValues(alpha: 0.1),
              side: BorderSide(color: topicColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () => _onWeakSpotTapped(rating),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopicsChips(ColorScheme colorScheme) {
    final isAllSelected = _selectedTopics.length == Topic.standardTopics.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All topics" chip
        FilterChip(
          showCheckmark: false,
          label: const Text('All topics'),
          selected: isAllSelected,
          backgroundColor: colorScheme.surface,
          selectedColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w500,
            color: isAllSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          side: BorderSide(
            color: isAllSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (_) => _selectAllTopics(),
        ),

        // 9 standard topics
        ...Topic.standardTopics.map((topic) {
          final isSelected = _selectedTopics.contains(topic);
          final topicColor = AppTheme.getTopicColor(topic);

          return FilterChip(
            showCheckmark: false,
            avatar: Text(
              topic.symbol,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : topicColor,
              ),
            ),
            label: Text(topic.displayName),
            selected: isSelected,
            backgroundColor: colorScheme.surface,
            selectedColor: topicColor,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
            side: BorderSide(
              color: isSelected
                  ? topicColor
                  : colorScheme.outline.withValues(alpha: 0.25),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (_) => _toggleTopic(topic),
          );
        }),
      ],
    );
  }

  Widget _buildDifficultySegmented(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSegmentedControl<Difficulty?>(
          selectedValue: _selectedDifficulty,
          items: const [
            AppSegmentedItem<Difficulty?>(
              value: null,
              label: 'Auto',
            ),
            AppSegmentedItem<Difficulty?>(
              value: Difficulty.easy,
              label: 'Easy',
            ),
            AppSegmentedItem<Difficulty?>(
              value: Difficulty.medium,
              label: 'Medium',
            ),
            AppSegmentedItem<Difficulty?>(
              value: Difficulty.hard,
              label: 'Hard',
            ),
          ],
          onValueChanged: (val) {
            setState(() {
              _selectedDifficulty = val;
            });
          },
        ),
        if (_selectedDifficulty == null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              AppStrings.autoDifficultyExplanation,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeakAreasSwitch(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.focusWeakAreas,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.focusWeakAreasExplanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _focusOnWeakAreas,
            onChanged: (val) => setState(() => _focusOnWeakAreas = val),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme) {
    return AppSegmentedControl<PracticeMode>(
      selectedValue: _selectedMode,
      items: const [
        AppSegmentedItem<PracticeMode>(
          value: PracticeMode.questions,
          icon: Icons.format_list_numbered_rounded,
          label: 'Questions',
        ),
        AppSegmentedItem<PracticeMode>(
          value: PracticeMode.timer,
          icon: Icons.timer_outlined,
          label: 'Timer',
        ),
      ],
      onValueChanged: (mode) {
        setState(() {
          _selectedMode = mode;
        });
      },
    );
  }

  Widget _buildTargetPills(ColorScheme colorScheme) {
    if (_selectedMode == PracticeMode.timer) {
      // 1, 2, 3, 5, 10 min
      return Row(
        children: AppConstants.timerModeOptions.map((seconds) {
          final isSelected = _selectedTimerDuration == seconds;
          final mins = seconds ~/ 60;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => setState(() => _selectedTimerDuration = seconds),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${mins}m',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // 10, 20, 30, 50 questions
      return Row(
        children: AppConstants.questionModeOptions.map((count) {
          final isSelected = _selectedQuestionCount == count;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => setState(() => _selectedQuestionCount = count),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${count}Q',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildMistakesCard(ColorScheme colorScheme) {
    final hasMistakes = _mistakeCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.mixedColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: AppTheme.mixedColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.practiceMyMistakes,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasMistakes
                      ? '$_mistakeCount ${AppStrings.mistakesToRevise}'
                      : AppStrings.noMistakesToRevise,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasMistakes)
            FilledButton(
              onPressed: _startMistakePractice,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.mixedColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Practice ${min(10, _mistakeCount)}'),
            )
          else
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start'),
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.push('/mistakes'),
            child: const Text(
              AppStrings.seeAll,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottom(ColorScheme colorScheme) {
    final summary = _buildSummaryLine();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live summary line
          Text(
            summary,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Primary Sticky Start button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _startPractice,
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                AppStrings.startPractice,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
