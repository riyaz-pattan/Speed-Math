import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/ads/ad_service.dart';
import '../../core/ads/interstitial_ad_manager.dart';
import '../../core/ads/widgets/banner_ad_container.dart';
import '../../core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/double_back_exit_scope.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/models/session.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/scoring/xp_calculator.dart';
import 'widgets/home_report_card.dart';
import 'widgets/today_habit_card.dart';
import 'widgets/upgrade_goal_dialog.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdService.instance.initialize());
      unawaited(InterstitialAdManager.instance.init());
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        _checkOnboardingOrUpgrade(recent.isNotEmpty);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lastSession = null;
          _isLoading = false;
        });
        _checkOnboardingOrUpgrade(false);
      }
    }
  }

  void _checkOnboardingOrUpgrade(bool hasSessions) {
    final settings = ref.read(settingsRepositoryProvider);
    if (settings.isOnboardingDone) return;

    if (hasSessions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) UpgradeGoalDialog.show(context);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/onboarding');
      });
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

    return DoubleBackExitScope(
      child: Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLastSession,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Sliver
                    SliverToBoxAdapter(
                      child: _buildHeaderArea(),
                    ),

                    // Content List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
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

                          const SizedBox(height: 18),

                          // Home Performance Report Summary Card
                          const HomeReportCard(),

                          const SizedBox(height: 16),

                          // Learn Shortcuts card
                          _LearnShortcutsCard(),

                          const SizedBox(height: 24),

                          // Practice Topics Section Title
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Practice Topics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Topic Practice Cards grouped by Arithmetic, Powers & Roots, Applied Maths
                          _buildTopicGrid(colorScheme),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const BannerAdContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderArea() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3730A3), // Indigo 800
            Color(0xFF4F46E5), // Indigo 600
            Color(0xFF6366F1), // Indigo 500
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.amberAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Master mental calculations with speed and precision',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCompactLevelChip(),
                const SizedBox(height: 14),
                const TodayHabitCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLevelChip() {
    final totalXpAsync = ref.watch(totalXpProvider);
    final totalXp = totalXpAsync.valueOrNull ?? 0;
    final level = XpCalculator.levelFromXp(totalXp);
    final title = XpCalculator.titleForLevel(level);
    final progress = XpCalculator.progressToNextLevel(totalXp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Level $level • $title',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$totalXp XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
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
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Last Session',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TactileCard(
          onTap: () => context.push('/history/details', extra: session),
          padding: const EdgeInsets.all(14),
          borderColor: topicColor.withValues(alpha: 0.28),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: topicColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      session.topic.symbol,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: topicColor,
                      ),
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
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modeSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.score.toStringAsFixed(0)} pts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: topicColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$accuracyPercent% acc',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(ColorScheme colorScheme) {
    return TactileCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Speed Math!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Select any topic below to start your mental calculation practice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
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
    const arithmeticTopics = [
      (Topic.addition, '2 & 3-digit speed addition'),
      (Topic.subtraction, 'Mental subtraction drills'),
      (Topic.multiplication, 'Fast multiplication tables'),
      (Topic.division, 'Exact mental division'),
    ];

    const powersRootsTopics = [
      (Topic.squares, 'Squares from 1 to 99'),
      (Topic.cubes, 'Cubes from 2 to 35'),
      (Topic.squareRoots, 'Perfect square roots up to 99²'),
      (Topic.cubeRoots, 'Perfect cube roots up to 35³'),
      (Topic.exponents, 'Powers & exponent calculations'),
    ];

    const appliedMathsTopics = [
      (Topic.percentages, 'Fast percentage of numbers'),
      (Topic.fractions, 'Fractions & mixed fraction parts'),
      (Topic.simplification, 'Order of operations (BODMAS)'),
      (Topic.approximation, 'Fast rounding & estimation'),
      (Topic.averages, 'Group & series averages'),
      (Topic.missingNumber, 'Solve for the missing ?'),
      (Topic.numberSeries, 'Find the missing sequence term'),
    ];

    const mentalShortcutsTopics = [
      (Topic.fractionReciprocals, 'Convert % to unit fractions quickly'),
      (Topic.derivedFractions, 'Convert % to any fraction quickly'),
      (Topic.fractionPercentages, 'Apply fraction % shortcuts'),
      (Topic.basePercentages, 'Calculate 100%+ percentages fast'),
      (Topic.splitPercentages, 'Decompose % into easy parts'),
      (Topic.powerOfFive, 'Multiply & divide by 5, 25, 125'),
      (Topic.patternMultiplication, 'Fast multiplication by 11, 99'),
    ];

    const algebraTopics = [
      (Topic.linearEquations, '1, 2 & 3-variable linear systems'),
      (Topic.quadraticEquations, 'Roots & competitive equation comparison'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopicGroupHeader('Arithmetic', arithmeticTopics.length),
        const SizedBox(height: 10),
        ...arithmeticTopics.map((item) => _buildTopicCard(item.$1, item.$2)),
        const SizedBox(height: 16),
        _buildTopicGroupHeader('Powers & Roots', powersRootsTopics.length),
        const SizedBox(height: 10),
        ...powersRootsTopics.map((item) => _buildTopicCard(item.$1, item.$2)),
        const SizedBox(height: 16),
        _buildTopicGroupHeader('Applied Maths', appliedMathsTopics.length),
        const SizedBox(height: 10),
        ...appliedMathsTopics.map((item) => _buildTopicCard(item.$1, item.$2)),
        const SizedBox(height: 16),
        _buildTopicGroupHeader('Algebra & Equations', algebraTopics.length),
        const SizedBox(height: 10),
        ...algebraTopics.map((item) => _buildTopicCard(item.$1, item.$2)),
        const SizedBox(height: 16),
        _buildTopicGroupHeader('Mental Shortcuts', mentalShortcutsTopics.length),
        const SizedBox(height: 10),
        ...mentalShortcutsTopics.map((item) => _buildTopicCard(item.$1, item.$2)),
      ],
    );
  }

  Widget _buildTopicGroupHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Topic topic, String description) {
    final topicColor = AppTheme.getTopicColor(topic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TactileCard(
        onTap: () => _onTopicTapped(topic),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: topicColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    topic.symbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: topicColor,
                    ),
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
                    topic.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: topicColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: topicColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Learn Shortcuts" card shown on the Home screen.
class _LearnShortcutsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/learn'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn Shortcuts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '8 animated lessons · mental math tricks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
