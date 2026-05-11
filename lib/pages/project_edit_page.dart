import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';

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
        );
        await ref.read(projectsProvider.notifier).updateProject(updated);
      } else {
        final project = CounterProject(
          name: _nameController.text.trim(),
          createdAt: DateTime.now(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
        await ref.read(projectsProvider.notifier).addProject(project);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '删除项目',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '确定要删除此项目吗？',
              style: TextStyle(fontSize: 16),
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
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true && mounted) {
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
