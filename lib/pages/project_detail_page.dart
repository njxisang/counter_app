import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/records_provider.dart';
import '../providers/date_filter_provider.dart';
import '../widgets/counter_buttons.dart';
import '../widgets/record_list_tile.dart';

class ProjectDetailPage extends ConsumerWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider(projectId));
    final totalAsync = ref.watch(totalProvider(projectId));
    final dateFilter = ref.watch(dateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计数详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/project/$projectId/stats'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              children: [
                const Text('累计总数', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                totalAsync.when(
                  data: (total) => Text(
                    '$total',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ),

          // Counter buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: totalAsync.when(
              data: (total) => CounterButtons(
                currentTotal: total,
                onDelta: (delta) {
                  final newTotal = total + delta;
                  ref.read(recordsProvider(projectId).notifier).addRecord(delta, newTotal);
                  ref.invalidate(totalProvider(projectId));
                },
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: dateFilter.filter == filter,
                      onSelected: (_) {
                        ref.read(dateFilterProvider.notifier).setFilter(filter);
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
                    child: Text(
                      '筛选范围内无记录',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return RecordListTile(
                      record: record,
                      onDelete: () {
                        ref.read(recordsProvider(projectId).notifier).deleteRecord(record.id!);
                        ref.invalidate(totalProvider(projectId));
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
