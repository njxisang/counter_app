import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_filter_provider.dart';
import '../providers/records_provider.dart';
import '../providers/projects_provider.dart';
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
  String _projectName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load project name
    final repository = ref.read(projectRepositoryProvider);
    final project = await repository.getById(widget.projectId);
    if (project != null && mounted) {
      setState(() => _projectName = project.name);
    }

    // Load records
    await _loadRecords();
  }

  Future<void> _loadRecords() async {
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
    final dateFilter = ref.watch(dateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName.isEmpty ? '统计图表' : '统计 - $_projectName'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('时间范围: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ...DateFilter.values.where((f) => f != DateFilter.custom).map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: dateFilter.filter == filter,
                          onSelected: (_) {
                            ref.read(dateFilterProvider.notifier).setFilter(filter);
                            _loadRecords();
                          },
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(_getCustomLabel(dateFilter)),
                        onPressed: () => _showDateRangePicker(context, dateFilter),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chart type hint
          if (_records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _isLineChart ? Icons.show_chart : Icons.bar_chart,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLineChart
                        ? '累计值走势'
                        : '单次变化量',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

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

  String _getCustomLabel(DateFilterState state) {
    if (state.filter == DateFilter.custom && state.customStart != null && state.customEnd != null) {
      final startStr = '${state.customStart!.month}/${state.customStart!.day}';
      final endStr = '${state.customEnd!.month}/${state.customEnd!.day}';
      return '$startStr-$endStr';
    }
    return '自定义';
  }

  Future<void> _showDateRangePicker(BuildContext context, DateFilterState currentState) async {
    final now = DateTime.now();
    final initialStart = currentState.customStart ?? DateTime(now.year, now.month, 1);
    final initialEnd = currentState.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      ref.read(dateFilterProvider.notifier).setCustomRange(picked.start, picked.end);
      _loadRecords();
    }
  }
}
