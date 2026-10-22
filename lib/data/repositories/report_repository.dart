import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/report/report_analyzer.dart';
import '../../domain/report/report_data.dart';
import '../../domain/report/report_writer.dart';
import '../../domain/report/todays_plan.dart';
import '../../domain/report/todays_plan_generator.dart';
import 'settings_repository.dart';

/// Riverpod provider for [ReportAnalyzer].
final reportAnalyzerProvider = Provider<ReportAnalyzer>((ref) {
  return ReportAnalyzer();
});

/// Riverpod provider for [TodaysPlanGenerator].
final todaysPlanGeneratorProvider = Provider<TodaysPlanGenerator>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TodaysPlanGenerator(prefs: prefs);
});

/// Riverpod provider for [ReportWriter].
final reportWriterProvider = FutureProvider<ReportWriter>((ref) async {
  return await ReportWriter.loadFromBundle();
});

/// Riverpod provider that loads fresh [ReportData], auto-refreshing on data revision changes.
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  ref.watch(dataRevisionProvider);
  final analyzer = ref.watch(reportAnalyzerProvider);
  return await analyzer.generateReport();
});

/// Riverpod provider that loads [TodayPlan] for today.
final todaysPlanProvider = FutureProvider<TodayPlan>((ref) async {
  final reportData = await ref.watch(reportDataProvider.future);
  final planGenerator = ref.watch(todaysPlanGeneratorProvider);
  return await planGenerator.getTodayPlan(reportData);
});

/// Riverpod composite view model for the Report Screen and Home card.
final reportViewModelProvider =
    FutureProvider<({ReportData data, TodayPlan plan, ReportText text})>((ref) async {
  final data = await ref.watch(reportDataProvider.future);
  final plan = await ref.watch(todaysPlanProvider.future);
  final writerAsync = await ref.watch(reportWriterProvider.future);
  final text = writerAsync.writeReport(data, plan: plan);
  return (data: data, plan: plan, text: text);
});
