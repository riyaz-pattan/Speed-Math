import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/strings/app_strings.dart';
import '../../data/models/session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Screen listing chronological practice history with topic filters and pagination.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Topic? _selectedTopicFilter; // null means 'All'
  bool _isMixedFilter = false;
  final List<Session> _sessions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 25;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadInitialSessions() async {
    setState(() {
      _isLoading = true;
      _sessions.clear();
      _hasMore = true;
    });

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final results = await repo.getSessionsFiltered(
        topic: _isMixedFilter ? null : _selectedTopicFilter,
        kinds: _isMixedFilter
            ? [SessionKind.mixed, SessionKind.mistakes]
            : (_selectedTopicFilter != null ? [SessionKind.drill] : null),
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _sessions.addAll(results);
          _hasMore = results.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessions.clear();
          _hasMore = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final results = await repo.getSessionsFiltered(
        topic: _isMixedFilter ? null : _selectedTopicFilter,
        kinds: _isMixedFilter
            ? [SessionKind.mixed, SessionKind.mistakes]
            : (_selectedTopicFilter != null ? [SessionKind.drill] : null),
        limit: _pageSize,
        offset: _sessions.length,
      );

      if (mounted) {
        setState(() {
          _sessions.addAll(results);
          _hasMore = results.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterSelected({Topic? topic, bool isMixed = false}) {
    if (_isMixedFilter == isMixed && _selectedTopicFilter == topic) return;
    setState(() {
      _isMixedFilter = isMixed;
      _selectedTopicFilter = isMixed ? null : topic;
    });
    _loadInitialSessions();
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dataRevisionProvider, (_, __) {
      _loadInitialSessions();
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.history,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                          'All Topics',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: (!_isMixedFilter && _selectedTopicFilter == null)
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: (!_isMixedFilter && _selectedTopicFilter == null)
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: !_isMixedFilter && _selectedTopicFilter == null,
                        backgroundColor: colorScheme.surface,
                        selectedColor: colorScheme.primary,
                        side: BorderSide(
                          color: (!_isMixedFilter && _selectedTopicFilter == null)
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                        onSelected: (_) => _onFilterSelected(topic: null, isMixed: false),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        showCheckmark: false,
                        avatar: Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: _isMixedFilter ? Colors.white : AppTheme.mixedColor,
                        ),
                        label: Text(
                          'Mixed',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isMixedFilter ? Colors.white : colorScheme.onSurface,
                            fontWeight: _isMixedFilter ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: _isMixedFilter,
                        backgroundColor: colorScheme.surface,
                        selectedColor: AppTheme.mixedColor,
                        side: BorderSide(
                          color: _isMixedFilter
                              ? AppTheme.mixedColor
                              : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                        onSelected: (_) => _onFilterSelected(isMixed: true),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ...Topic.standardTopics.map((t) {
                      final isSelected = !_isMixedFilter && _selectedTopicFilter == t;
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                          onSelected: (_) => _onFilterSelected(topic: t, isMixed: false),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Sessions List
            Expanded(
              child: _sessions.isEmpty && !_isLoading
                  ? _buildEmptyState(colorScheme)
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _sessions.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == _sessions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final session = _sessions[index];
                        return _buildSessionTile(session, colorScheme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No practice history found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _isMixedFilter
                  ? 'No mixed practice or mistakes practice sessions recorded yet.'
                  : _selectedTopicFilter != null
                      ? 'No practice sessions recorded for ${_selectedTopicFilter!.displayName} yet.'
                      : AppStrings.emptyHistoryMessage,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(Session session, ColorScheme colorScheme) {
    final isMixed = session.kind == SessionKind.mixed || session.mode == PracticeMode.smart;
    final isMistakes = session.kind == SessionKind.mistakes || session.mode == PracticeMode.mistakes;
    final sessionColor = isMixed || isMistakes
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(session.topic);

    final title = isMixed
        ? 'Mixed practice'
        : isMistakes
            ? 'Mistakes practice'
            : '${session.topic.displayName} - ${session.difficulty.displayName}';

    final modeLabel = session.mode == PracticeMode.timer
        ? '${session.modeValue ~/ 60}m Timer'
        : '${session.modeValue} Qs';

    final accuracyPercent =
        (session.accuracy <= 1.0 ? session.accuracy * 100 : session.accuracy)
            .toStringAsFixed(0);

    final difficultyText = session.difficulty == Difficulty.mixed
        ? 'Adaptive'
        : session.difficulty.displayName;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/history/details', extra: session),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // Topic Icon Container
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sessionColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  session.topic.symbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: sessionColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            difficultyText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (!session.completed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Ended early',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$modeLabel • ${_formatDate(session.startedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Score & Accuracy
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.score.toStringAsFixed(0)} pts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$accuracyPercent% acc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
