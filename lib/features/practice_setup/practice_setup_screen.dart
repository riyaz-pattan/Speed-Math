import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/app_segmented_control.dart';
import '../../core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/repositories/mistake_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/skill_repository.dart';
import '../../domain/adaptive/skill_rating.dart';
import '../learn/engine/lesson_registry.dart';
import '../../domain/questions/session_random.dart';
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
  void activate() {
    super.activate();
    _isLaunching = false;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLaunching = false;
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
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _toggleAllTopics() {
    setState(() {
      if (_selectedTopics.length == Topic.standardTopics.length) {
        _selectedTopics.clear();
      } else {
        _selectedTopics = List.from(Topic.standardTopics);
      }
    });
  }

  Future<void> _startPractice() async {
    if (_selectedTopics.isEmpty || _isLaunching) return;
    setState(() => _isLaunching = true);

    // Safety fallback: ensure lock is released after 1.5s even if navigation futures are aborted
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLaunching) {
        setState(() => _isLaunching = false);
      }
    });

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
      _isLaunching = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _startMistakePractice() async {
    if (_mistakeCount == 0 || _isLaunching) return;
    setState(() => _isLaunching = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLaunching) {
        setState(() => _isLaunching = false);
      }
    });

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
      _isLaunching = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  String _buildSummaryLine() {
    if (_selectedTopics.isEmpty) {
      return 'Choose at least one topic';
    }

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
      backgroundColor: AppTheme.canvasBackground,
      body: Column(
        children: [
          const ScreenHeader(
            title: AppStrings.practice,
            subtitle: 'Customize your calculation drill',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                if (_mistakeCount > 0) ...[
                  _buildMistakesCard(colorScheme),
                  const SizedBox(height: 16),
                ],

                // 7. Shortcut Tricks
                _buildShortcutTricksRow(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Sticky Bottom Section: Summary line + Start Practice Button
          _buildStickyBottom(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Select all topics" / "All topics selected" toggle button
        Row(
          children: [
            FilterChip(
              showCheckmark: false,
              avatar: isAllSelected
                  ? const Icon(Icons.done_all_rounded, size: 16, color: Colors.white)
                  : const Icon(Icons.done_all_rounded, size: 16),
              label: Text(isAllSelected ? 'All topics selected' : 'Select all topics'),
              selected: isAllSelected,
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
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
              onSelected: (_) => _toggleAllTopics(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Subgroups
        ...TopicGroup.values.map((group) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    group.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final int columns;
                    if (width >= 480) {
                      columns = 4;
                    } else if (width >= 280) {
                      columns = 3;
                    } else {
                      columns = 2;
                    }
                    const spacing = 8.0;
                    final itemWidth = ((width - (spacing * (columns - 1)) - 0.5) / columns).floorToDouble();

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: group.topics.map((topic) {
                        final isSelected = _selectedTopics.contains(topic);
                        final topicColor = AppTheme.getTopicColor(topic);

                        return SizedBox(
                          width: itemWidth,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggleTopic(topic),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                constraints: const BoxConstraints(minHeight: 74),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? topicColor.withValues(alpha: 0.10)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? topicColor
                                        : colorScheme.outline.withValues(alpha: 0.22),
                                    width: isSelected ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? topicColor : topicColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          topic.symbol,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : topicColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      topic.displayName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.focusWeakAreas,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.focusWeakAreasExplanation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _focusOnWeakAreas,
            activeTrackColor: AppTheme.primaryColor,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.cardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTimerDuration = seconds),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '${mins}m',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.cardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _selectedQuestionCount = count),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '${count}Q',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
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
    if (_mistakeCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Soft warm amber-50 background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFED7AA), // Amber-200 border
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5), // Amber-100 round icon
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: Color(0xFFEA580C), // Orange-600 icon
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Revise your mistakes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_mistakeCount questions waiting',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push('/mistakes'),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEA580C),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _startMistakePractice,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 38),
              shape: const StadiumBorder(),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Practice ${min(10, _mistakeCount)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottom(ColorScheme colorScheme) {
    final summary = _buildSummaryLine();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderLight,
            width: 1.2,
          ),
        ),
        boxShadow: AppTheme.stickyShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live summary line
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Primary Sticky Start button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedTopics.isEmpty ? null : AppTheme.primaryGlow,
              ),
              child: FilledButton.icon(
                onPressed: _selectedTopics.isEmpty ? null : _startPractice,
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
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutTricksRow() {
    // Gather lessons relevant to selected topics (up to 3)
    final relevant = _selectedTopics
        .expand((t) => LessonRegistry.forTopic(t))
        .toSet()
        .take(3)
        .toList();

    // Fallback: first 3 lessons if no relevant ones
    final lessons = relevant.isEmpty ? LessonRegistry.all.take(3).toList() : relevant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16,
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Shortcut Tricks',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/learn'),
              child: const Text('See all →',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lessons.map((meta) {
            return GestureDetector(
              onTap: () => context.push('/learn/${meta.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meta.icon, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(meta.title,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
