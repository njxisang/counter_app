import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(filteredProjectsProvider);
    final currentSort = ref.watch(projectSortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索项目...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(projectSearchQueryProvider.notifier).state = value;
                },
              )
            : const Text('计数统计'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(projectSearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          PopupMenuButton<ProjectSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onSelected: (value) {
              ref.read(projectSortOrderProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ProjectSortOrder.createdAt,
                child: Row(
                  children: [
                    if (currentSort == ProjectSortOrder.createdAt)
                      const Icon(Icons.check, size: 18, color: Colors.green)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Text('按创建时间'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ProjectSortOrder.name,
                child: Row(
                  children: [
                    if (currentSort == ProjectSortOrder.name)
                      const Icon(Icons.check, size: 18, color: Colors.green)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Text('按名称'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            final hasSearchQuery = ref.read(projectSearchQueryProvider).isNotEmpty;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSearchQuery ? Icons.search_off : Icons.add_chart,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasSearchQuery ? '未找到匹配的项目' : '暂无计数项目',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasSearchQuery ? '尝试其他关键词' : '点击下方按钮创建第一个项目',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  if (hasSearchQuery) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        ref.read(projectSearchQueryProvider.notifier).state = '';
                        setState(() => _isSearching = false);
                      },
                      child: const Text('清除搜索'),
                    ),
                  ],
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return ProjectCard(project: projects[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(projectsProvider.notifier).loadProjects(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/project/new'),
        icon: const Icon(Icons.add),
        label: const Text('新建项目'),
      ),
    );
  }
}
