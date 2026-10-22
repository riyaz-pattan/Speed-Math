import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/question_text_widget.dart';
import '../../data/repositories/mistake_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/adaptive/mistake_entry.dart';
import '../../domain/questions/session_random.dart';
import '../practice_session/models/practice_models.dart';

/// Screen displaying all questions currently stored in the spaced repetition mistake system.
///
/// Features:
/// - Topic filter chips (All + individual topics)
/// - Grouped by topic with signature topic colors
/// - Details: question text (via QuestionTextWidget), correct answer, times wrong, label (Wrong/Skipped/Too slow)
/// - Swipe-to-dismiss with Undo SnackBar
/// - Choice of 10, 20, or All (up to 50) questions for "Practice these", respecting topic filter
/// - Friendly empty state
class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  List<MistakeEntry>? _mistakes;
  Topic? _selectedTopicFilter; // null means 'All'
  int _selectedCountChoice = 10; // 10, 20, or 50 (for All)
  bool _loading = true;
  bool _isLaunching = false;

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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${entry.questionText}"'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.reinsertMistake(entry);
              await _loadMistakes();
            },
          ),
        ),
      );
    }
  }

  Future<void> _startMistakePractice(List<MistakeEntry> candidateList) async {
    if (_isLaunching || candidateList.isEmpty) return;
    _isLaunching = true;

    try {
      final settings = ref.read(settingsRepositoryProvider);
      final count = _selectedCountChoice == 50
          ? min(candidateList.length, 50)
          : min(candidateList.length, _selectedCountChoice);
      final practiceList = candidateList.take(count).toList();

      final config = PracticeConfig(
        topic: _selectedTopicFilter ?? Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.mistakes,
        kind: SessionKind.mistakes,
        modeValue: count,
        sessionSeed: SessionRandom.newSessionSeed(),
        autoSubmit: settings.autoSubmit,
        hapticsEnabled: settings.hapticsEnabled,
        correctSoundEnabled: settings.correctSoundEnabled,
        wrongSoundEnabled: settings.wrongSoundEnabled,
        soundVolume: settings.soundVolume,
        keypadStyle: settings.keypadStyle,
        initialMistakes: practiceList,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredMistakes;
    final allMistakes = _mistakes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.myMistakes,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : allMistakes.isEmpty
              ? _buildEmptyState(colorScheme)
              : Column(
                  children: [
                    _buildTopicFilterBar(colorScheme, allMistakes),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyFilteredState(colorScheme)
                          : _buildMistakesList(colorScheme, filtered),
                    ),
                  ],
                ),
      bottomNavigationBar: (!_loading && filtered.isNotEmpty)
          ? _buildBottomBar(colorScheme, filtered)
          : null,
    );
  }

  Widget _buildTopicFilterBar(ColorScheme colorScheme, List<MistakeEntry> allMistakes) {
    final topicsWithMistakes = <Topic>{
      for (final m in allMistakes) m.topic,
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
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
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedTopicFilter == null
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                selected: _selectedTopicFilter == null,
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primary,
                side: BorderSide(
                  color: _selectedTopicFilter == null
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.25),
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
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.noMistakesInBank,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noMistakesInBankSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No mistakes in ${_selectedTopicFilter?.displayName ?? "this topic"}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakesList(ColorScheme colorScheme, List<MistakeEntry> list) {
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.14),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${topicMistakes.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mistake Cards
              ...topicMistakes.map((m) => _buildMistakeCard(m, topicColor, colorScheme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMistakeCard(
    MistakeEntry mistake,
    Color topicColor,
    ColorScheme colorScheme,
  ) {
    final sourceColor = switch (mistake.source) {
      MistakeSource.wrong => Colors.red,
      MistakeSource.skipped => Colors.amber[800] ?? Colors.amber,
      MistakeSource.slow => Colors.orange,
    };

    return Dismissible(
      key: ValueKey('mistake_${mistake.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _removeMistake(mistake),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ${mistake.correctAnswer}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.bold,
                        color: sourceColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mistake.wrongCount}x wrong',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildBottomBar(ColorScheme colorScheme, List<MistakeEntry> filtered) {
    final available = filtered.length;
    final allLimit = min(available, 50);

    return Container(
      padding: const EdgeInsets.all(16),
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
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question count selector: 10, 20, or All (up to 50)
            Row(
              children: [
                Text(
                  'Questions:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                _buildCountChip(10, '10', available >= 10),
                const SizedBox(width: 8),
                _buildCountChip(20, '20', available >= 20),
                const SizedBox(width: 8),
                _buildCountChip(50, 'All ($allLimit)', true),
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
                  '${AppStrings.practiceThese} (${_selectedCountChoice == 50 ? allLimit : min(available, _selectedCountChoice)})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildCountChip(int value, String label, bool enabled) {
    final isSelected = _selectedCountChoice == value;
    final colorScheme = Theme.of(context).colorScheme;

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
          color: isSelected
              ? colorScheme.primary
              : (enabled
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? colorScheme.onPrimary
                : (enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
