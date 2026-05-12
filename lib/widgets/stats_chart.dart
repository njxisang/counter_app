import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';

class StatsChart extends StatelessWidget {
  final List<CounterRecord> records;
  final bool isLineChart;

  const StatsChart({
    super.key,
    required this.records,
    this.isLineChart = true,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isLineChart ? _buildLineChart(context) : _buildBarChart(context),
    );
  }

  /// Build grouped data: date key -> list of records on that day
  Map<DateTime, List<CounterRecord>> _groupByDate() {
    final grouped = <DateTime, List<CounterRecord>>{};
    for (final record in records) {
      final dateKey = DateTime(record.createdAt.year, record.createdAt.month, record.createdAt.day);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }
    return grouped;
  }

  /// Returns label text for a record at the given index.
  /// - Same-day records: show time (e.g. "13:05")
  /// - Cross-day records with multiple entries that day: show "5.9 10次"
  /// - Cross-day records with single entry that day: show "5.9"
  String _getBottomLabel(int index, Map<DateTime, List<CounterRecord>> grouped) {
    final record = records[index];
    final dateKey = DateTime(record.createdAt.year, record.createdAt.month, record.createdAt.day);
    final dayRecords = grouped[dateKey]!;
    final isSameDay = dayRecords.length > 1;

    if (isSameDay) {
      return DateFormat('M.d').format(record.createdAt) + ' ${dayRecords.length}次';
    } else {
      return DateFormat('H:mm').format(record.createdAt);
    }
  }

  Widget _buildLineChart(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), records[i].totalAfter.toDouble()));
    }
    final grouped = _groupByDate();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateInterval(records.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= records.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getBottomLabel(index, grouped),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final record = records[spot.spotIndex];
                final dateKey = DateTime(record.createdAt.year, record.createdAt.month, record.createdAt.day);
                final dayRecords = grouped[dateKey]!;
                final label = dayRecords.length > 1
                    ? '${DateFormat('MM-dd').format(record.createdAt)} ${dayRecords.length}次 ${DateFormat('HH:mm').format(record.createdAt)}'
                    : DateFormat('MM-dd HH:mm').format(record.createdAt);
                return LineTooltipItem(
                  '$label\n累计: ${record.totalAfter}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final grouped = _groupByDate();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= records.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getBottomLabel(index, grouped),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: records.asMap().entries.map((entry) {
          final isPositive = entry.value.delta > 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.delta.abs().toDouble(),
                color: isPositive ? Colors.green : Colors.red,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final record = records[groupIndex];
              final dateKey = DateTime(record.createdAt.year, record.createdAt.month, record.createdAt.day);
              final dayRecords = grouped[dateKey]!;
              final label = dayRecords.length > 1
                  ? '${DateFormat('MM-dd').format(record.createdAt)} ${dayRecords.length}次 ${DateFormat('HH:mm').format(record.createdAt)}'
                  : DateFormat('MM-dd HH:mm').format(record.createdAt);
              return BarTooltipItem(
                '$label\n变化: ${record.delta}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).ceilToDouble();
  }
}
