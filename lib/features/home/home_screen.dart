import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../data/models/session.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'widgets/home_report_card.dart';

/// Home screen displaying time-of-day greeting in a gradient header,
/// last session summary, and direct topic practice tiles with signature colors.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Session? _lastSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLastSession();
  }

  Future<void> _loadLastSession() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final recent = await repo.getRecentSessions(1);

      if (mounted) {
        setState(() {
          _lastSession = recent.isNotEmpty ? recent.first : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lastSession = null;
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _onTopicTapped(Topic topic) {
    final settings = ref.read(settingsRepositoryProvider);
    settings.setLastTopic(topic);
    context.go('/practice', extra: topic);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for data changes
    ref.listen(dataRevisionProvider, (_, __) {
      _loadLastSession();
      ref.invalidate(reportDataProvider);
      ref.invalidate(reportViewModelProvider);
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLastSession,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Gradient Header Area with Greeting
              _buildHeaderArea(theme, colorScheme),
              const SizedBox(height: 20),

              // "Last Session" or Welcome Card
              if (_isLoading)
                const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_lastSession != null)
                _buildLastSessionCard(_lastSession!, colorScheme)
              else
                _buildWelcomeCard(colorScheme),

              const SizedBox(height: 20),

              // Home Performance Report Summary Card
              const HomeReportCard(),

              const SizedBox(height: 28),

              // Practice Topics Grid Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Practice Topics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${Topic.standardTopics.length} Topics',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Topic Practice Cards
              _buildTopicGrid(colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Master speed and precision for competitive exams',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSessionCard(Session session, ColorScheme colorScheme) {
    final accuracyPercent = (session.accuracy * 100).round();
    final isMixed = session.kind == SessionKind.mixed || session.mode == PracticeMode.smart;
    final isMistakes = session.kind == SessionKind.mistakes || session.mode == PracticeMode.mistakes;
    final topicColor = isMixed || isMistakes
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(session.topic);

    final title = isMixed
        ? 'Mixed practice'
        : isMistakes
            ? 'Mistakes practice'
            : '${session.topic.displayName} - ${session.difficulty.displayName}';

    final modeSubtitle = isMixed || isMistakes
        ? (session.mode == PracticeMode.timer
            ? '${session.modeValue ~/ 60}m Timer • ${_formatDate(session.startedAt)}'
            : '${session.modeValue} Questions • ${_formatDate(session.startedAt)}')
        : '${session.mode.displayName} • ${_formatDate(session.startedAt)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Last Session',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => context.push('/history/details', extra: session),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: topicColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: topicColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        session.topic.symbol,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: topicColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          modeSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${session.score.toStringAsFixed(0)} pts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: topicColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$accuracyPercent% acc',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Speed Math!',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select any topic below to start your mental calculation practice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGrid(ColorScheme colorScheme) {
    const basicTopics = [
      (Topic.addition, '2 & 3-digit speed addition'),
      (Topic.subtraction, 'Mental subtraction drills'),
      (Topic.multiplication, 'Fast multiplication tables'),
      (Topic.division, 'Exact mental division'),
      (Topic.squares, 'Squares from 1 to 99'),
      (Topic.cubes, 'Cubes from 2 to 35'),
      (Topic.squareRoots, 'Perfect square roots up to 99²'),
      (Topic.cubeRoots, 'Perfect cube roots up to 35³'),
      (Topic.exponents, 'Powers & exponent calculations'),
    ];

    const moreTopics = [
      (Topic.percentages, 'Fast percentage of numbers'),
      (Topic.fractions, 'Fractions of numbers & parts'),
      (Topic.simplification, 'Order of operations (BODMAS)'),
      (Topic.averages, 'Fast mean & missing averages'),
      (Topic.missingNumber, 'Solve for the missing ?'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopicGroupHeader('Basics', colorScheme),
        const SizedBox(height: 10),
        ...basicTopics.map((item) => _buildTopicCard(item.$1, item.$2, colorScheme)),
        const SizedBox(height: 16),
        _buildTopicGroupHeader('More topics', colorScheme),
        const SizedBox(height: 10),
        ...moreTopics.map((item) => _buildTopicCard(item.$1, item.$2, colorScheme)),
      ],
    );
  }

  Widget _buildTopicGroupHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    Topic topic,
    String description,
    ColorScheme colorScheme,
  ) {
    final topicColor = AppTheme.getTopicColor(topic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _onTopicTapped(topic),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: topicColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: topicColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: topicColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      topic.symbol,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: topicColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: topicColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
