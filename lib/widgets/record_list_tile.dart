import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';

class RecordListTile extends StatelessWidget {
  final CounterRecord record;
  final VoidCallback? onDelete;

  const RecordListTile({
    super.key,
    required this.record,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM-dd HH:mm');
    final isPositive = record.delta > 0;
    final deltaColor = isPositive ? Colors.green : Colors.red;
    final deltaText = isPositive ? '+${record.delta}' : '${record.delta}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: deltaColor.withValues(alpha: 0.2),
        child: Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: deltaColor,
        ),
      ),
      title: Text(
        deltaText,
        style: TextStyle(
          color: deltaColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        dateFormat.format(record.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '累计: ${record.totalAfter}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '删除记录',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '确定要删除这条记录吗？',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '此操作不可撤销。',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认删除'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
