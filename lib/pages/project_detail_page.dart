import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../models/record.dart';
import '../providers/records_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/date_filter_provider.dart';
import '../widgets/counter_buttons.dart';
import '../widgets/record_list_tile.dart';

final todayTotalProvider = FutureProvider.family<int, int>((ref, projectId) async {
  final repository = ref.watch(recordRepositoryProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final records = await repository.getByProjectIdAndDateRange(projectId, startOfDay, endOfDay);
  return records.fold<int>(0, (sum, r) => sum + r.delta);
});

class ProjectDetailPage extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  int _sessionUndoCount = 0;

  static final _projectNameProvider = FutureProvider.family<String, int>((ref, projectId) async {
    final repository = ref.watch(projectRepositoryProvider);
    final project = await repository.getById(projectId);
    return project?.name ?? '计数详情';
  });

  static final _projectProvider = FutureProvider.family<CounterProject?, int>((ref, projectId) async {
    final repository = ref.watch(projectRepositoryProvider);
    return await repository.getById(projectId);
  });

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider(widget.projectId));
    final totalAsync = ref.watch(totalProvider(widget.projectId));
    final dateFilter = ref.watch(dateFilterProvider);
    final projectAsync = ref.watch(_projectProvider(widget.projectId));
    final projectNameAsync = ref.watch(_projectNameProvider(widget.projectId));
    final todayTotalAsync = ref.watch(todayTotalProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: projectNameAsync.when(
          data: (name) => Text(name),
          loading: () => const Text('加载中...'),
          error: (_, _) => const Text('计数详情'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/project/${widget.projectId}/stats'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total display with animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: projectAsync.when(
              data: (project) {
                final isDaily = project?.countMode == CountMode.daily;
                final displayTotalAsync = isDaily ? todayTotalAsync : totalAsync;
                return Column(
                  children: [
                    Text(
                      isDaily ? '今日计数' : '累计总数',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    displayTotalAsync.when(
                      data: (total) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                        child: FittedBox(
                          key: ValueKey(total),
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$total',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Error'),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('累计总数'),
            ),
          ),

          // Counter buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: projectAsync.when(
              data: (project) {
                final isDaily = project?.countMode == CountMode.daily;
                final currentTotalAsync = isDaily ? todayTotalAsync : totalAsync;
                return currentTotalAsync.when(
                  data: (total) {
                    final records = recordsAsync.valueOrNull ?? [];
                    final canUndo = records.isNotEmpty || _sessionUndoCount > 0;
                    return CounterButtons(
                      currentTotal: total,
                      canUndo: canUndo,
                      onDelta: (delta) {
                        final newTotal = total + delta;
                        ref.read(recordsProvider(widget.projectId).notifier).addRecord(delta, newTotal);
                        ref.invalidate(totalProvider(widget.projectId));
                        ref.invalidate(todayTotalProvider(widget.projectId));
                        setState(() => _sessionUndoCount++);
                        // SnackBar 提示
                        final isPositive = delta > 0;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${isPositive ? '增加' : '减少'} $delta'),
                            duration: const Duration(milliseconds: 800),
                            behavior: SnackBarBehavior.floating,
                            width: 160,
                          ),
                        );
                      },
                      onUndo: canUndo
                          ? () {
                              if (_sessionUndoCount > 0) {
                                // 撤销本次会话的操作
                                final undoCount = _sessionUndoCount;
                                for (var i = 0; i < undoCount; i++) {
                                  if (records.isNotEmpty) {
                                    final lastRecord = records[i];
                                    ref.read(recordsProvider(widget.projectId).notifier).deleteRecord(lastRecord.id!);
                                  }
                                }
                                ref.invalidate(totalProvider(widget.projectId));
                                ref.invalidate(todayTotalProvider(widget.projectId));
                                setState(() => _sessionUndoCount = 0);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已撤销 $undoCount 步操作'),
                                    duration: const Duration(milliseconds: 800),
                                    behavior: SnackBarBehavior.floating,
                                    width: 200,
                                  ),
                                );
                              } else {
                                // 撤销最近一条历史记录
                                final lastRecord = records.first;
                                ref.read(recordsProvider(widget.projectId).notifier).deleteRecord(lastRecord.id!);
                                ref.invalidate(totalProvider(widget.projectId));
                                ref.invalidate(todayTotalProvider(widget.projectId));
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已撤销'),
                                    duration: Duration(milliseconds: 800),
                                    behavior: SnackBarBehavior.floating,
                                    width: 120,
                                  ),
                                );
                              }
                            }
                          : null,
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (e, s) => const SizedBox(),
                );
              },
              loading: () => const SizedBox(),
              error: (e, s) => const SizedBox(),
            ),
          ),

          // Date filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('筛选: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ...DateFilter.values.map((filter) {
                  final isSelected = dateFilter.filter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getFilterLabel(filter, dateFilter)),
                      selected: isSelected,
                      onSelected: (_) {
                        if (filter == DateFilter.custom) {
                          _showDateRangePicker(context, dateFilter);
                        } else {
                          ref.read(dateFilterProvider.notifier).setFilter(filter);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(),

          // Records list
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          '暂无记录',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方按钮开始计数',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // Filter records by date range
                final (start, end) = dateFilter.getDateRange();
                final filteredRecords = records.where((r) {
                  return r.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                      r.createdAt.isBefore(end.add(const Duration(seconds: 1)));
                }).toList();

                if (filteredRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          '筛选范围内无记录',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.read(dateFilterProvider.notifier).setToday(),
                          child: const Text('查看今日'),
                        ),
                      ],
                    ),
                  );
                }

                // Group records by day
                final groupedRecords = <DateTime, List<CounterRecord>>{};
                for (final r in filteredRecords) {
                  final dayKey = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
                  groupedRecords.putIfAbsent(dayKey, () => []).add(r);
                }
                final sortedDays = groupedRecords.keys.toList()
                  ..sort((a, b) => b.compareTo(a)); // newest first

                return ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final dayKey = sortedDays[index];
                    final dayRecords = groupedRecords[dayKey]!;
                    final dayTotal = dayRecords.fold<int>(0, (sum, r) => sum + r.delta);
                    return _DayGroup(
                      dateKey: dayKey,
                      records: dayRecords,
                      dayTotal: dayTotal,
                      isDailyMode: projectAsync.valueOrNull?.countMode == CountMode.daily,
                      onDelete: (record) {
                        ref.read(recordsProvider(widget.projectId).notifier).deleteRecord(record.id!);
                        ref.invalidate(totalProvider(widget.projectId));
                        ref.invalidate(todayTotalProvider(widget.projectId));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(DateFilter filter, DateFilterState state) {
    switch (filter) {
      case DateFilter.day:
        return '今日';
      case DateFilter.week:
        return '本周';
      case DateFilter.month:
        return '本月';
      case DateFilter.custom:
        if (state.filter == DateFilter.custom && state.customStart != null && state.customEnd != null) {
          final startStr = '${state.customStart!.month}/${state.customStart!.day}';
          final endStr = '${state.customEnd!.month}/${state.customEnd!.day}';
          return '$startStr-$endStr';
        }
        return '自定义';
    }
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    DateFilterState currentState,
  ) async {
    final now = DateTime.now();
    final initialStart = currentState.customStart ?? DateTime(now.year, now.month, 1);
    final initialEnd = currentState.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dateFilterProvider.notifier).setCustomRange(picked.start, picked.end);
    }
  }
}

/// A collapsible day group showing date header + list of records
class _DayGroup extends StatefulWidget {
  final DateTime dateKey;
  final List<CounterRecord> records;
  final int dayTotal;
  final bool isDailyMode;
  final void Function(CounterRecord) onDelete;

  const _DayGroup({
    required this.dateKey,
    required this.records,
    required this.dayTotal,
    required this.isDailyMode,
    required this.onDelete,
  });

  @override
  State<_DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends State<_DayGroup> {
  bool _isExpanded = false;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return '今天';
    if (date == yesterday) return '昨天';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _formatDate(widget.dateKey);
    final isPositive = widget.dayTotal > 0;
    final deltaColor = isPositive ? Colors.green : Colors.red;
    final deltaText = isPositive ? '+${widget.dayTotal}' : '${widget.dayTotal}';

    return Column(
      children: [
        // Day header (tappable)
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  dayLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deltaText,
                    style: TextStyle(
                      color: deltaColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.records.length} 条记录',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Expanded record list
        if (_isExpanded)
          ...widget.records.map((record) => RecordListTile(
                record: record,
                onDelete: () => widget.onDelete(record),
              )),
        const Divider(height: 1),
      ],
    );
  }
}
