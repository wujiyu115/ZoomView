import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/database/database_helper.dart';
import '../models/history_model.dart';
import '../repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(DatabaseHelper.instance);
});

final historyProvider =
    NotifierProvider<HistoryNotifier, List<HistoryModel>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<HistoryModel>> {
  @override
  List<HistoryModel> build() => [];

  HistoryRepository get _repo => ref.read(historyRepositoryProvider);

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> addEntry(String title, String url) async {
    await _repo.addEntry(title, url);
  }

  Future<void> deleteEntry(int id) async {
    await _repo.deleteEntry(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await load();
      return;
    }
    state = await _repo.search(query);
  }
}
