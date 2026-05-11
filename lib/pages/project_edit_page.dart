import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';

const _projectColors = [
  Color(0xFF6366F1),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFF97316),
  Color(0xFF84CC16),
];

class ProjectEditPage extends ConsumerStatefulWidget {
  final int? projectId;

  const ProjectEditPage({super.key, this.projectId});

  @override
  ConsumerState<ProjectEditPage> createState() => _ProjectEditPageState();
}

class _ProjectEditPageState extends ConsumerState<ProjectEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  CounterProject? _existingProject;
  int _selectedColorIndex = 0;

  bool get isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadProject();
    }
  }

  Future<void> _loadProject() async {
    final repository = ref.read(projectRepositoryProvider);
    final project = await repository.getById(widget.projectId!);
    if (project != null && mounted) {
      setState(() {
        _existingProject = project;
        _nameController.text = project.name;
        _noteController.text = project.note ?? '';
        _selectedColorIndex = project.colorIndex;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing && _existingProject != null) {
        final updated = _existingProject!.copyWith(
          name: _nameController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          colorIndex: _selectedColorIndex,
        );
        await ref.read(projectsProvider.notifier).updateProject(updated);
      } else {
        final project = CounterProject(
          name: _nameController.text.trim(),
          createdAt: DateTime.now(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          colorIndex: _selectedColorIndex,
        );
        await ref.read(projectsProvider.notifier).addProject(project);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '已保存' : '项目已创建'),
            behavior: SnackBarBehavior.floating,
            width: 160,
            backgroundColor: Colors.green.shade700,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProject() async {
    if (_existingProject == null) return;

    // 第一步：确认删除
    final step1 = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              '删除项目',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '确定要删除「${_existingProject!.name}」吗？',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '所有相关记录也将被删除，此操作不可撤销。',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('继续'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (step1 != true || !mounted) return;

    // 第二步：输入项目名前两个字确认
    final confirmName = _existingProject!.name;
    final confirmPrefix = confirmName.length >= 2 ? confirmName.substring(0, 2) : confirmName;
    final controller = TextEditingController();

    final step2 = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '安全确认',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '请输入「$confirmPrefix」以确认删除',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '项目名前两个字',
                ),
                onChanged: (_) => setSheetState(() {}),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.text.trim() == confirmPrefix
                          ? () => Navigator.pop(ctx, true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确认删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (step2 == true && mounted) {
      await ref.read(projectsProvider.notifier).deleteProject(widget.projectId!);
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑项目' : '新建项目'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProject,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '项目名称',
                hintText: '请输入项目名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入项目名称';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '请输入备注信息',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('项目颜色', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setColorState) => Wrap(
                spacing: 12,
                children: List.generate(_projectColors.length, (i) {
                  final selected = _selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () => setColorState(() => _selectedColorIndex = i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _projectColors[i],
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: _projectColors[i], blurRadius: 8)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProject,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? '保存修改' : '创建项目'),
            ),
          ],
        ),
      ),
    );
  }
}
