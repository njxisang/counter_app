import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/repositories/record_repository.dart';
import '../models/record.dart';

final recordRepositoryProvider = Provider((ref) => RecordRepository());

final recordsProvider =
    StateNotifierProvider.family<RecordNotifier, AsyncValue<List<CounterRecord>>, int>(
  (ref, projectId) => RecordNotifier(ref.watch(recordRepositoryProvider), projectId),
);

class RecordNotifier extends StateNotifier<AsyncValue<List<CounterRecord>>> {
  final RecordRepository _repository;
  final int projectId;

  RecordNotifier(this._repository, this.projectId) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByProjectId(projectId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(int delta, int totalAfter) async {
    try {
      final record = CounterRecord(
        projectId: projectId,
        delta: delta,
        totalAfter: totalAfter,
        createdAt: DateTime.now(),
      );
      await _repository.create(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.delete(id);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final totalProvider = FutureProvider.family<int, int>((ref, projectId) async {
  final repository = ref.watch(recordRepositoryProvider);
  return await repository.getTotalByProjectId(projectId);
});
