import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_filter_provider.dart';
import '../providers/records_provider.dart';
import '../widgets/stats_chart.dart';

class StatsPage extends ConsumerStatefulWidget {
  final int projectId;

  const StatsPage({super.key, required this.projectId});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  bool _isLineChart = true;
  bool _isLoading = true;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final repository = ref.read(recordRepositoryProvider);
    final dateFilter = ref.read(dateFilterProvider);
    final (start, end) = dateFilter.getDateRange();
    final records = await repository.getByProjectIdAndDateRange(
      widget.projectId,
      start,
      end,
    );
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计图表'),
        actions: [
          IconButton(
            icon: Icon(_isLineChart ? Icons.bar_chart : Icons.show_chart),
            onPressed: () {
              setState(() => _isLineChart = !_isLineChart);
            },
            tooltip: _isLineChart ? '切换柱状图' : '切换折线图',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('时间范围: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ...DateFilter.values.where((f) => f != DateFilter.custom).map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: ref.watch(dateFilterProvider).filter == filter,
                      onSelected: (_) {
                        ref.read(dateFilterProvider.notifier).setFilter(filter);
                        _loadRecords();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '暂无数据',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '在筛选范围内没有计数记录',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: StatsChart(
                          records: _records.cast(),
                          isLineChart: _isLineChart,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(DateFilter filter) {
    switch (filter) {
      case DateFilter.day:
        return '今日';
      case DateFilter.week:
        return '本周';
      case DateFilter.month:
        return '本月';
      case DateFilter.custom:
        return '自定义';
    }
  }
}
