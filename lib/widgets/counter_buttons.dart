import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CounterButtons extends StatefulWidget {
  final Function(int) onDelta;
  final int currentTotal;
  final VoidCallback? onUndo;
  final bool canUndo;

  const CounterButtons({
    super.key,
    required this.onDelta,
    required this.currentTotal,
    this.onUndo,
    this.canUndo = false,
  });

  @override
  State<CounterButtons> createState() => _CounterButtonsState();
}

class _CounterButtonsState extends State<CounterButtons> {
  String _lastTapped = '';

  void _handleTap(String button) {
    final now = DateTime.now();
    if (_lastTapped == button && now.millisecondsSinceEpoch % 10000 < 500) {
      // 双击：快速再次点击同按钮
      HapticFeedback.heavyImpact();
      widget.onDelta(button == 'plus' ? 5 : -5);
      _lastTapped = '';
    } else {
      HapticFeedback.mediumImpact();
      widget.onDelta(button == 'plus' ? 1 : -1);
      _lastTapped = button;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountButton(
              label: '-1',
              color: Colors.red,
              backgroundColor: Colors.red.shade100,
              onPressed: () => _handleTap('minus'),
            ),
            const SizedBox(width: 32),
            _CountButton(
              label: '+1',
              color: Colors.green,
              backgroundColor: Colors.green.shade100,
              onPressed: () => _handleTap('plus'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showCustomDeltaDialog(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('自定义'),
            ),
            if (widget.canUndo) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: widget.onUndo,
                icon: const Icon(Icons.undo),
                label: const Text('撤销'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showCustomDeltaDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '自定义增减',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: '数值（正数增加，负数减少）',
                  hintText: '例如: 5 或 -3',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入数值';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return '请输入有效的整数';
                  }
                  return null;
                },
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
                        if (formKey.currentState!.validate()) {
                          final value = int.parse(controller.text.trim());
                          HapticFeedback.mediumImpact();
                          widget.onDelta(value);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _CountButton({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 72,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
