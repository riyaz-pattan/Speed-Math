import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/app_segmented_control.dart';
import '../../core/widgets/app_toast.dart';
import 'package:speed_math_with_ai/core/widgets/empty_state_view.dart';
import '../../core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/repositories/mistake_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/adaptive/mistake_entry.dart';
import '../../domain/questions/session_random.dart';
import '../practice_session/models/practice_models.dart';

/// Screen displaying all questions currently stored in the spaced repetition mistake system.
class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  List<MistakeEntry>? _mistakes;
  Topic? _selectedTopicFilter; // null means 'All'
  int _selectedCountChoice = 10; // 10, 20, or 50 (for All)
  bool _similarMistakes = false; // Option A (false): Same questions; Option B (true): Similar questions
  bool _loading = true;
  bool _isLaunching = false;

  @override
  void activate() {
    super.activate();
    _isLaunching = false;
    _loadMistakes();
  }

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    setState(() => _loading = true);
    final repo = ref.read(mistakeRepositoryProvider);
    final list = await repo.getAllMistakes();
    if (mounted) {
      setState(() {
        _mistakes = list;
        _loading = false;
      });
    }
  }

  Future<void> _removeMistake(MistakeEntry entry) async {
    if (entry.id == null) return;
    final repo = ref.read(mistakeRepositoryProvider);
    await repo.removeMistake(entry.id!);
    setState(() {
      _mistakes?.removeWhere((m) => m.id == entry.id);
    });

    if (mounted) {
      AppToast.show(
        context,
        message: 'Removed "${entry.questionText}"',
        type: AppToastType.info,
        actionLabel: 'Undo',
        onAction: () async {
          await repo.reinsertMistake(entry);
          await _loadMistakes();
        },
      );
    }
  }

  Future<void> _startMistakePractice(List<MistakeEntry> candidateList) async {
    if (_isLaunching || candidateList.isEmpty) return;
    setState(() => _isLaunching = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLaunching) {
        setState(() => _isLaunching = false);
      }
    });

    try {
      final settings = ref.read(settingsRepositoryProvider);
      final int count;
      if (candidateList.length <= 10) {
        count = candidateList.length;
      } else if (_selectedCountChoice == 50) {
        count = min(candidateList.length, 50);
      } else {
        count = min(candidateList.length, _selectedCountChoice);
      }
      final practiceList = candidateList.take(count).toList();

      final config = PracticeConfig(
        topic: _selectedTopicFilter ?? Topic.mixed,
        selectedTopics: _selectedTopicFilter != null
            ? [_selectedTopicFilter!]
            : Topic.standardTopics,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.mistakes,
        kind: SessionKind.mistakes,
        modeValue: practiceList.length,
        sessionSeed: SessionRandom.newSessionSeed(),
        autoSubmit: settings.autoSubmit,
        hapticsEnabled: settings.hapticsEnabled,
        correctSoundEnabled: settings.correctSoundEnabled,
        wrongSoundEnabled: settings.wrongSoundEnabled,
        soundVolume: settings.soundVolume,
        correctSoundVolume: settings.correctSoundVolume,
        wrongSoundVolume: settings.wrongSoundVolume,
        keypadStyle: settings.keypadStyle,
        initialMistakes: practiceList,
        similarMistakes: _similarMistakes,
      );

      if (mounted) {
        await context.push('/practice/session', extra: config);
        // Refresh list after returning from practice session
        await _loadMistakes();
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  List<MistakeEntry> get _filteredMistakes {
    if (_mistakes == null) return [];
    if (_selectedTopicFilter == null) return _mistakes!;
    return _mistakes!.where((m) => m.topic == _selectedTopicFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMistakes;
    final allMistakes = _mistakes ?? [];

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: AppStrings.myMistakes,
            subtitle: 'Spaced repetition mistake drills',
            leading: HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : allMistakes.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildTopicFilterBar(allMistakes),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildEmptyFilteredState()
                                : _buildMistakesList(filtered),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: (!_loading && filtered.isNotEmpty)
          ? _buildBottomBar(filtered)
          : null,
    );
  }

  Widget _buildTopicFilterBar(List<MistakeEntry> allMistakes) {
    final topicsWithMistakes = <Topic>{
      for (final m in allMistakes) m.topic,
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.canvasBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(
                  'All (${allMistakes.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedTopicFilter == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _selectedTopicFilter == null
                        ? Colors.white
                        : AppTheme.textPrimary,
                  ),
                ),
                selected: _selectedTopicFilter == null,
                backgroundColor: AppTheme.surfaceCard,
                selectedColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: _selectedTopicFilter == null
                      ? AppTheme.primaryColor
                      : AppTheme.borderLight,
                ),
                onSelected: (_) => setState(() => _selectedTopicFilter = null),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ...topicsWithMistakes.map((t) {
              final isSelected = _selectedTopicFilter == t;
              final count = allMistakes.where((m) => m.topic == t).length;
              final topicColor = AppTheme.getTopicColor(t);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: Text(
                    t.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : topicColor,
                    ),
                  ),
                  label: Text(
                    '${t.displayName} ($count)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: AppTheme.surfaceCard,
                  selectedColor: topicColor,
                  side: BorderSide(
                    color: isSelected
                        ? topicColor
                        : AppTheme.borderLight,
                  ),
                  onSelected: (_) => setState(() => _selectedTopicFilter = t),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: Icons.task_alt_rounded,
      title: 'No mistakes to revise!',
      message: 'You are all caught up. Keep practicing to build speed.',
      actionLabel: 'Practice Now',
      onAction: () => context.go('/practice'),
    );
  }

  Widget _buildEmptyFilteredState() {
    return EmptyStateView(
      icon: Icons.check_circle_outline_rounded,
      title: 'No mistakes found',
      message: 'No mistakes recorded for ${_selectedTopicFilter?.displayName ?? "this topic"}.',
      actionLabel: 'Show All',
      onAction: () => setState(() => _selectedTopicFilter = null),
    );
  }

  Widget _buildMistakesList(List<MistakeEntry> list) {
    final Map<Topic, List<MistakeEntry>> grouped = {};
    for (final m in list) {
      grouped.putIfAbsent(m.topic, () => []).add(m);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final topic = grouped.keys.elementAt(index);
        final topicMistakes = grouped[topic]!;
        final topicColor = AppTheme.getTopicColor(topic);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic Header
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      topic.symbol,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: topicColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topic.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${topicMistakes.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mistake Cards
              ...topicMistakes.map((m) => _buildMistakeCard(m, topicColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMistakeCard(
    MistakeEntry mistake,
    Color topicColor,
  ) {
    final sourceColor = switch (mistake.source) {
      MistakeSource.wrong => AppTheme.errorColor,
      MistakeSource.skipped => AppTheme.warningColor,
      MistakeSource.slow => const Color(0xFFEA580C),
    };

    return Dismissible(
      key: ValueKey('mistake_${mistake.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _removeMistake(mistake),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TactileCard(
          padding: const EdgeInsets.all(14),
          borderRadius: AppTheme.radiusMd,
          child: Row(
            children: [
              // Expression using shared QuestionTextWidget
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionTextWidget(
                      text: mistake.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ${mistake.correctAnswer}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: topicColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Badges: Times wrong & Source
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sourceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sourceColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      mistake.source.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sourceColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mistake.wrongCount}x wrong',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<MistakeEntry> filtered) {
    final available = filtered.length;
    final allLimit = min(available, 50);

    final int effectiveCount;
    if (available <= 10) {
      effectiveCount = available;
    } else if (_selectedCountChoice == 50) {
      effectiveCount = allLimit;
    } else {
      effectiveCount = min(available, _selectedCountChoice);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderLight,
          ),
        ),
        boxShadow: AppTheme.stickyShadow,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Same questions" vs "Similar questions" switch
            AppSegmentedControl<bool>(
              selectedValue: _similarMistakes,
              onValueChanged: (val) => setState(() => _similarMistakes = val),
              items: const [
                AppSegmentedItem<bool>(
                  value: false,
                  label: 'Same questions',
                  icon: Icons.replay_rounded,
                ),
                AppSegmentedItem<bool>(
                  value: true,
                  label: 'Similar questions',
                  icon: Icons.shuffle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question count selector
            Row(
              children: [
                const Text(
                  'Questions:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                if (available <= 10) ...[
                  _buildCountChip(available, '$available questions', true, isSelected: true),
                ] else ...[
                  _buildCountChip(10, '10', true),
                  if (available >= 20) ...[
                    const SizedBox(width: 8),
                    _buildCountChip(20, '20', true),
                  ],
                  const SizedBox(width: 8),
                  _buildCountChip(50, 'All ($allLimit)', true),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // "Practice these" button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _startMistakePractice(filtered),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Practice $effectiveCount question${effectiveCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(
    int value,
    String label,
    bool enabled, {
    bool? isSelected,
  }) {
    final selected = isSelected ?? (_selectedCountChoice == value);

    return InkWell(
      key: ValueKey('count_chip_$value'),
      onTap: enabled
          ? () {
              setState(() => _selectedCountChoice = value);
            }
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (enabled
                  ? AppTheme.surfaceSecondary
                  : AppTheme.surfaceSecondary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected
                ? Colors.white
                : (enabled ? AppTheme.textPrimary : AppTheme.textTertiary),
          ),
        ),
      ),
    );
  }
}
