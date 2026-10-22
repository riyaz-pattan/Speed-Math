import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../data/models/session.dart';
import '../models/graph_models.dart';
import '../services/graph_data_processor.dart';

/// Interactive line chart widget visualizing user performance over time.
class HistoryLineGraph extends StatefulWidget {
  final List<Session> completedSessions;

  const HistoryLineGraph({
    super.key,
    required this.completedSessions,
  });

  @override
  State<HistoryLineGraph> createState() => _HistoryLineGraphState();
}

class _HistoryLineGraphState extends State<HistoryLineGraph> {
  GraphMeasure _selectedMeasure = GraphMeasure.avgTime;
  GraphRange _selectedRange = GraphRange.allTime;
  final GraphDataProcessor _processor = const GraphDataProcessor();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final processed = _processor.process(
      sessions: widget.completedSessions,
      measure: _selectedMeasure,
      range: _selectedRange,
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls: Measure Switch & Range Switch
            _buildControls(colorScheme),
            const SizedBox(height: 20),

            // Main Graph Body or Empty State
            SizedBox(
              height: 220,
              child: processed.hasEnoughData
                  ? _buildChart(processed, colorScheme)
                  : _buildEmptyState(colorScheme),
            ),

            // Trend Note
            if (processed.trendNote != null) ...[
              const SizedBox(height: 14),
              _buildTrendBanner(processed.trendNote!, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Measure chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: GraphMeasure.values.map((measure) {
              final isSelected = _selectedMeasure == measure;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(
                    measure.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.25),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMeasure = measure);
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Range selector
        AppSegmentedControl<GraphRange>(
          selectedValue: _selectedRange,
          items: GraphRange.values.map((r) {
            return AppSegmentedItem(
              value: r,
              label: r.displayName,
            );
          }).toList(),
          onValueChanged: (range) {
            setState(() => _selectedRange = range);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 40,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete at least 2 sessions to see your progress graph.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBanner(String trendNote, ColorScheme colorScheme) {
    final isImprovement = trendNote.contains('improved');
    final isDrop = trendNote.contains('dropped') || trendNote.contains('increased');

    final Color badgeColor;
    final IconData icon;

    if (isImprovement) {
      badgeColor = Colors.green;
      icon = Icons.trending_up_rounded;
    } else if (isDrop) {
      badgeColor = Colors.orange;
      icon = Icons.trending_down_rounded;
    } else {
      badgeColor = colorScheme.primary;
      icon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: badgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trendNote,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ProcessedGraphData data, ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), data.points[i].value));
    }

    return LineChart(
      LineChartData(
        minY: data.minY,
        maxY: data.maxY,
        minX: 0,
        maxX: (data.points.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (data.maxY - data.minY) / 4 > 0
              ? (data.maxY - data.minY) / 4
              : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                String text = val.toStringAsFixed(0);
                if (_selectedMeasure == GraphMeasure.avgTime) {
                  text = '${val.toStringAsFixed(1)}s';
                } else if (_selectedMeasure == GraphMeasure.accuracy) {
                  text = '${val.toInt()}%';
                }
                return Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: max(1.0, (data.points.length / 4).floorToDouble()),
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= data.points.length) {
                  return const SizedBox.shrink();
                }
                final date = data.points[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 3.2,
            isStrokeCapRound: true,
            color: colorScheme.primary,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: colorScheme.surface,
                strokeWidth: 2.2,
                strokeColor: colorScheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.28),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            tooltipRoundedRadius: 12,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final point = data.points[idx];
                final dateStr =
                    '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}-${point.date.day.toString().padLeft(2, '0')}';
                return LineTooltipItem(
                  '$dateStr\n'
                  '${_selectedMeasure.displayName}: ${spot.y.toStringAsFixed(1)}\n'
                  'Score: ${point.score.toStringAsFixed(0)} | Acc: ${point.accuracy.toStringAsFixed(0)}%',
                  TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
