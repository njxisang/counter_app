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
        backgroundColor: deltaColor.withOpacity(0.2),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
