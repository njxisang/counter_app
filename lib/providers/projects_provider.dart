import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/repositories/project_repository.dart';
import '../models/project.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository());

final projectsProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<CounterProject>>>(
  (ref) => ProjectListNotifier(ref.watch(projectRepositoryProvider)),
);

class ProjectListNotifier extends StateNotifier<AsyncValue<List<CounterProject>>> {
  final ProjectRepository _repository;

  ProjectListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getAll();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject(CounterProject project) async {
    try {
      await _repository.create(project);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProject(CounterProject project) async {
    try {
      await _repository.update(project);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _repository.delete(id);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
