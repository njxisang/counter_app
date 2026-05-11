import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../providers/records_provider.dart';

const _projectColors = [
  Color(0xFF6366F1), // 靛蓝
  Color(0xFF10B981), // 翠绿
  Color(0xFFF59E0B), // 琥珀
  Color(0xFFEF4444), // 玫红
  Color(0xFF8B5CF6), // 紫罗兰
  Color(0xFF06B6D4), // 青色
  Color(0xFFF97316), // 橙色
  Color(0xFF84CC16), // 青柠
];

class ProjectCard extends ConsumerWidget {
  final CounterProject project;

  const ProjectCard({super.key, required this.project});

  Color get _accentColor => _projectColors[project.colorIndex % _projectColors.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalProvider(project.id!));
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/project/${project.id}'),
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.push('/project/${project.id}/edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '总计: ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        totalAsync.when(
                          data: (total) => Text(
                            '$total',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          loading: () => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (e, s) => const Text('Error'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '创建于: ${dateFormat.format(project.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (project.note != null && project.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑项目'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/project/${project.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('查看统计'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/project/${project.id}/stats');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
