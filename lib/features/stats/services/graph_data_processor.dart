import 'dart:math';

import '../../../data/models/session.dart';
import '../models/graph_models.dart';

/// Pure Dart service to filter, group, compute values, and calculate trends
/// for the stats history line graph.
class GraphDataProcessor {
  const GraphDataProcessor();

  /// Processes raw completed sessions into graph points and trend notes.
  ProcessedGraphData process({
    required List<Session> sessions,
    required GraphMeasure measure,
    required GraphRange range,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1. Filter completed sessions and range
    final filtered = sessions.where((s) {
      if (!s.completed) return false;
      return switch (range) {
        GraphRange.days7 =>
          s.startedAt.isAfter(currentTime.subtract(const Duration(days: 7))),
        GraphRange.days30 =>
          s.startedAt.isAfter(currentTime.subtract(const Duration(days: 30))),
        GraphRange.allTime => true,
      };
    }).toList();

    // Sort chronologically (oldest to newest)
    filtered.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (filtered.isEmpty) {
      return const ProcessedGraphData(
        points: [],
        trendNote: null,
        minY: 0,
        maxY: 10,
        hasEnoughData: false,
      );
    }

    // 2. Transform into individual points
    final individualPoints = filtered.map((s) {
      final timeSec = s.avgTimeMs / 1000.0;
      final accPct = s.accuracy <= 1.0 ? s.accuracy * 100.0 : s.accuracy;
      final scoreVal = s.score;

      final double value = switch (measure) {
        GraphMeasure.avgTime => timeSec,
        GraphMeasure.accuracy => accPct,
        GraphMeasure.score => scoreVal,
      };

      return GraphPoint(
        date: s.startedAt,
        value: value,
        score: scoreVal,
        accuracy: accPct,
        avgTimeSec: timeSec,
      );
    }).toList();

    // 3. Group by day if more than 30 points
    final List<GraphPoint> points;
    if (individualPoints.length > 30) {
      points = _groupByDay(individualPoints);
    } else {
      points = individualPoints;
    }

    if (points.length < 2) {
      final singleVal = points.first.value;
      return ProcessedGraphData(
        points: points,
        trendNote: null,
        minY: max(0.0, singleVal - 5),
        maxY: singleVal + 5,
        hasEnoughData: false,
      );
    }

    // 4. Calculate trend note
    final trendNote = _calculateTrend(points, measure);

    // 5. Calculate minY and maxY with comfortable padding
    final values = points.map((p) => p.value).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);

    double minY;
    double maxY;

    if (measure == GraphMeasure.accuracy) {
      minY = max(0.0, minVal - 5);
      maxY = min(100.0, maxVal + 5);
      if (minY == maxY) {
        minY = max(0.0, minY - 10);
        maxY = min(100.0, maxY + 10);
      }
    } else {
      final rangeSpan = maxVal - minVal;
      final padding = rangeSpan > 0 ? rangeSpan * 0.15 : (maxVal > 0 ? maxVal * 0.15 : 2.0);
      minY = max(0.0, minVal - padding);
      maxY = maxVal + padding;
    }

    return ProcessedGraphData(
      points: points,
      trendNote: trendNote,
      minY: minY,
      maxY: maxY,
      hasEnoughData: true,
    );
  }

  List<GraphPoint> _groupByDay(List<GraphPoint> points) {
    final Map<String, List<GraphPoint>> dayGroups = {};

    for (final p in points) {
      final key = '${p.date.year}-${p.date.month}-${p.date.day}';
      dayGroups.putIfAbsent(key, () => []).add(p);
    }

    final groupedList = <GraphPoint>[];

    for (final entry in dayGroups.entries) {
      final group = entry.value;
      final avgValue =
          group.map((e) => e.value).reduce((a, b) => a + b) / group.length;
      final avgScore =
          group.map((e) => e.score).reduce((a, b) => a + b) / group.length;
      final avgAcc =
          group.map((e) => e.accuracy).reduce((a, b) => a + b) / group.length;
      final avgTime =
          group.map((e) => e.avgTimeSec).reduce((a, b) => a + b) / group.length;

      final firstDate = group.first.date;
      final dayDate = DateTime(firstDate.year, firstDate.month, firstDate.day);

      groupedList.add(GraphPoint(
        date: dayDate,
        value: avgValue,
        score: avgScore,
        accuracy: avgAcc,
        avgTimeSec: avgTime,
      ));
    }

    groupedList.sort((a, b) => a.date.compareTo(b.date));
    return groupedList;
  }

  String? _calculateTrend(List<GraphPoint> points, GraphMeasure measure) {
    if (points.length < 2) return null;

    final mid = points.length ~/ 2;
    final olderHalf = points.sublist(0, mid);
    final newerHalf = points.sublist(mid);

    final olderAvg =
        olderHalf.map((p) => p.value).reduce((a, b) => a + b) / olderHalf.length;
    final newerAvg =
        newerHalf.map((p) => p.value).reduce((a, b) => a + b) / newerHalf.length;

    if (olderAvg == 0) {
      if (newerAvg == 0) return 'Steady, no big change';
      return null;
    }

    final diff = newerAvg - olderAvg;
    final changePct = (diff.abs() / olderAvg) * 100;

    if (changePct < 2.0) {
      return 'Steady, no big change';
    }

    final pctRounded = changePct.round();

    return switch (measure) {
      GraphMeasure.avgTime => diff < 0
          ? 'Your average time improved by $pctRounded% over this period'
          : 'Your average time increased by $pctRounded% over this period',
      GraphMeasure.accuracy => diff > 0
          ? 'Your accuracy improved by $pctRounded% over this period'
          : 'Your accuracy dropped by $pctRounded% over this period',
      GraphMeasure.score => diff > 0
          ? 'Your score improved by $pctRounded% over this period'
          : 'Your score dropped by $pctRounded% over this period',
    };
  }
}
