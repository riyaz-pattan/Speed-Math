import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_service.dart';
import '../../core/ads/interstitial_ad_manager.dart';
import '../../data/db/database_helper.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/widgets/app_toast.dart';
import '../coach/controllers/coach_controller.dart';
import 'package:speed_math_with_ai/features/settings/question_gallery_screen.dart';

/// Hidden diagnostic screen accessible by long-pressing the version number in Settings > About.
/// Displays raw SQLite table counts and compares them with derived cache values across
/// Report, Home card, and Coach.
class DataCheckScreen extends ConsumerStatefulWidget {
  const DataCheckScreen({super.key});

  @override
  ConsumerState<DataCheckScreen> createState() => _DataCheckScreenState();
}

class _DataCheckScreenState extends ConsumerState<DataCheckScreen> {
  bool _isLoading = true;

  // Raw Database Metrics
  int _totalSessions = 0;
  Map<String, int> _sessionsByKind = {};
  int _completedSessions = 0;
  int _incompleteSessions = 0;

  int _totalAttempts = 0;
  int _answeredAttempts = 0;
  int _skippedAttempts = 0;
  int _correctAttempts = 0;
  int _wrongAttempts = 0;

  int _mistakeBankCount = 0;
  int _skillRatingsCount = 0;
  int _patternSkillsCount = 0;

  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _fetchRawDbData();
  }

  Future<void> _fetchRawDbData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    // 1. Sessions
    final sessTotalRes = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableSessions}');
    final totalSessions = (sessTotalRes.first['c'] as num?)?.toInt() ?? 0;

    final sessKindRes = await db.rawQuery(
      'SELECT kind, COUNT(*) as c FROM ${DatabaseHelper.tableSessions} GROUP BY kind',
    );
    final byKind = <String, int>{};
    for (final row in sessKindRes) {
      byKind[row['kind']?.toString() ?? 'unknown'] = (row['c'] as num?)?.toInt() ?? 0;
    }

    final sessCompletedRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableSessions} WHERE completed = 1',
    );
    final completedSessions = (sessCompletedRes.first['c'] as num?)?.toInt() ?? 0;

    final sessIncompleteRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableSessions} WHERE completed = 0',
    );
    final incompleteSessions = (sessIncompleteRes.first['c'] as num?)?.toInt() ?? 0;

    // 2. Attempts
    final attTotalRes = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableAttempts}');
    final totalAttempts = (attTotalRes.first['c'] as num?)?.toInt() ?? 0;

    final attAnsweredRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableAttempts} WHERE COALESCE(is_skipped, 0) = 0',
    );
    final answeredAttempts = (attAnsweredRes.first['c'] as num?)?.toInt() ?? 0;

    final attSkippedRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableAttempts} WHERE is_skipped = 1',
    );
    final skippedAttempts = (attSkippedRes.first['c'] as num?)?.toInt() ?? 0;

    final attCorrectRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableAttempts} WHERE is_correct = 1',
    );
    final correctAttempts = (attCorrectRes.first['c'] as num?)?.toInt() ?? 0;

    final attWrongRes = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableAttempts} WHERE is_correct = 0 AND COALESCE(is_skipped, 0) = 0',
    );
    final wrongAttempts = (attWrongRes.first['c'] as num?)?.toInt() ?? 0;

    // 3. Mistakes
    final mistRes = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableMistakeBank}');
    final mistakeCount = (mistRes.first['c'] as num?)?.toInt() ?? 0;

    // 4. Skills
    final skillRes = await db.rawQuery('SELECT COUNT(*) as c FROM skill_ratings');
    final skillCount = (skillRes.first['c'] as num?)?.toInt() ?? 0;

    // 5. Pattern Skills (if table exists)
    int patternCount = 0;
    try {
      final patRes = await db.rawQuery('SELECT COUNT(*) as c FROM pattern_skills');
      patternCount = (patRes.first['c'] as num?)?.toInt() ?? 0;
    } catch (_) {
      patternCount = 0;
    }

    if (mounted) {
      setState(() {
        _totalSessions = totalSessions;
        _sessionsByKind = byKind;
        _completedSessions = completedSessions;
        _incompleteSessions = incompleteSessions;

        _totalAttempts = totalAttempts;
        _answeredAttempts = answeredAttempts;
        _skippedAttempts = skippedAttempts;
        _correctAttempts = correctAttempts;
        _wrongAttempts = wrongAttempts;

        _mistakeBankCount = mistakeCount;
        _skillRatingsCount = skillCount;
        _patternSkillsCount = patternCount;

        _lastFetchTime = DateTime.now();
        _isLoading = false;
      });
    }
  }

  Future<void> _recomputeNow() async {
    setState(() => _isLoading = true);

    // Bump revision signal
    ref.read(dataRevisionProvider.notifier).state++;

    // Invalidate report providers
    ref.invalidate(reportDataProvider);
    ref.invalidate(todaysPlanProvider);
    ref.invalidate(reportViewModelProvider);

    // Refresh coach context
    await ref.read(coachControllerProvider.notifier).refreshContext();

    // Re-fetch raw DB counts
    await _fetchRawDbData();

    if (mounted) {
      AppToast.show(
        context,
        message: 'Recomputed! Caches invalidated and DB re-queried.',
        type: AppToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final revision = ref.watch(dataRevisionProvider);
    final reportAsync = ref.watch(reportViewModelProvider);
    final coachState = ref.watch(coachControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Check (Diagnostics)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchRawDbData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top Action Banner
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _recomputeNow,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Recompute Now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QuestionGalleryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.collections_bookmark_rounded),
                        label: const Text('Question Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Data Revision Card
                _buildCard(
                  colorScheme,
                  title: 'Data Revision Signal',
                  icon: Icons.tag_rounded,
                  children: [
                    _buildRow('dataRevisionProvider.state', revision.toString(), highlight: true),
                    if (_lastFetchTime != null)
                      _buildRow('Last queried', _formatTime(_lastFetchTime!)),
                  ],
                ),
                const SizedBox(height: 12),

                // AdMob Ads & Privacy Diagnostics Card
                Consumer(
                  builder: (context, ref, _) {
                    final adService = ref.watch(adServiceProvider);
                    final interstitialManager = InterstitialAdManager.instance;
                    return _buildCard(
                      colorScheme,
                      title: 'Ads & Privacy Diagnostics',
                      icon: Icons.ads_click_rounded,
                      children: [
                        _buildRow(
                          'AdConfig enabled',
                          AdConfig.isEnabled ? 'Yes (Active)' : 'No (REPLACE in ID)',
                          highlight: true,
                        ),
                        _buildRow('AdService initialized', adService.isInitialized ? 'Yes' : 'No'),
                        _buildRow(
                          'Connectivity status',
                          adService.isOnline ? 'Online' : 'Offline',
                          highlight: true,
                        ),
                        _buildRow('Consent status', adService.consentStatus),
                        _buildRow('Privacy choices required', adService.isPrivacyOptionsRequired ? 'Yes' : 'No'),
                        _buildRow('Last banner result', adService.lastBannerResult),
                        _buildRow('Last interstitial result', adService.lastInterstitialResult),
                        const Divider(height: 12),
                        _buildRow(
                          'Interstitial ready in cache',
                          interstitialManager.isLoaded ? 'Yes' : 'No',
                          highlight: true,
                        ),
                        _buildRow(
                          'Total completed sessions',
                          interstitialManager.totalCompletedSessions.toString(),
                        ),
                        _buildRow(
                          'Sessions since last interstitial',
                          '${interstitialManager.sessionsSinceLastInterstitial} / 4',
                        ),
                        _buildRow(
                          'Last interstitial shown',
                          interstitialManager.lastInterstitialShownTime == 0
                              ? 'Never'
                              : _formatTime(DateTime.fromMillisecondsSinceEpoch(
                                  interstitialManager.lastInterstitialShownTime)),
                        ),
                        _buildRow(
                          'Interstitials shown today',
                          '${interstitialManager.shownTodayCount} / 3',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Derived Component Counts (The Suspects)
                _buildCard(
                  colorScheme,
                  title: 'Derived Counts (In-Memory / Providers)',
                  icon: Icons.memory_rounded,
                  children: [
                    reportAsync.when(
                      loading: () => const Text('Loading ReportData...'),
                      error: (err, _) => Text('Error loading report: $err'),
                      data: (vm) => Column(
                        children: [
                          _buildRow(
                            'Report answered Qs',
                            '${vm.data.totalQuestionsAllTime} Q (enoughData: ${vm.data.hasEnoughData})',
                            highlight: true,
                          ),
                          _buildRow('Report generated at', _formatTime(vm.data.generatedAt)),
                          _buildRow('Home Card reads', '${vm.data.totalQuestionsAllTime} Q'),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                    _buildRow(
                      'Coach totalAnswered',
                      '${coachState.context?.totalAnswered ?? 'null'} Q',
                      highlight: true,
                    ),
                    _buildRow(
                      'Coach context exists',
                      coachState.context != null ? 'Yes' : 'No',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Raw SQLite Attempts
                _buildCard(
                  colorScheme,
                  title: 'Raw Database: Attempts (attempts table)',
                  icon: Icons.checklist_rounded,
                  children: [
                    _buildRow('Total rows', _totalAttempts.toString()),
                    _buildRow(
                      'Answered (COALESCE(is_skipped,0)=0)',
                      _answeredAttempts.toString(),
                      highlight: true,
                    ),
                    _buildRow('Skipped (is_skipped=1)', _skippedAttempts.toString()),
                    _buildRow('Correct (is_correct=1)', _correctAttempts.toString()),
                    _buildRow('Wrong', _wrongAttempts.toString()),
                  ],
                ),
                const SizedBox(height: 12),

                // Raw SQLite Sessions
                _buildCard(
                  colorScheme,
                  title: 'Raw Database: Sessions (sessions table)',
                  icon: Icons.history_rounded,
                  children: [
                    _buildRow('Total sessions', _totalSessions.toString()),
                    _buildRow('Completed (completed=1)', _completedSessions.toString()),
                    _buildRow('Incomplete (completed=0)', _incompleteSessions.toString()),
                    const Divider(height: 12),
                    const Text('By Kind:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ..._sessionsByKind.entries.map((e) => _buildRow('  • ${e.key}', e.value.toString())),
                  ],
                ),
                const SizedBox(height: 12),

                // Other Tables
                _buildCard(
                  colorScheme,
                  title: 'Raw Database: Other Tables',
                  icon: Icons.storage_rounded,
                  children: [
                    _buildRow('Mistake rows (mistake_bank)', _mistakeBankCount.toString()),
                    _buildRow('Skill rows (skill_ratings)', _skillRatingsCount.toString()),
                    _buildRow('Pattern rows (pattern_skills)', _patternSkillsCount.toString()),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildCard(
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? null : Colors.grey.shade600,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Colors.blue.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
