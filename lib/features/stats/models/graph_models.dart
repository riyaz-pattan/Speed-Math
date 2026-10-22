/// Graph measure types available for selection.
enum GraphMeasure {
  avgTime,
  accuracy,
  score;

  String get displayName => switch (this) {
    GraphMeasure.avgTime => 'Avg. Time',
    GraphMeasure.accuracy => 'Accuracy',
    GraphMeasure.score => 'Score',
  };
}

/// Date range filter options for the stats history line graph.
enum GraphRange {
  days7,
  days30,
  allTime;

  String get displayName => switch (this) {
    GraphRange.days7 => '7 Days',
    GraphRange.days30 => '30 Days',
    GraphRange.allTime => 'All Time',
  };
}

/// A single data point plotted on the history line graph.
class GraphPoint {
  final DateTime date;
  final double value; // Display value for current measure
  final double score;
  final double accuracy; // 0.0 to 1.0 (or percentage)
  final double avgTimeSec;

  const GraphPoint({
    required this.date,
    required this.value,
    required this.score,
    required this.accuracy,
    required this.avgTimeSec,
  });

  @override
  String toString() =>
      'GraphPoint(date: $date, val: $value, score: $score, acc: $accuracy, time: ${avgTimeSec}s)';
}

/// Computed output ready for fl_chart rendering and trend display.
class ProcessedGraphData {
  final List<GraphPoint> points;
  final String? trendNote;
  final double minY;
  final double maxY;
  final bool hasEnoughData;

  const ProcessedGraphData({
    required this.points,
    required this.trendNote,
    required this.minY,
    required this.maxY,
    required this.hasEnoughData,
  });
}
