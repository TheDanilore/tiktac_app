import 'package:injectable/injectable.dart';
import 'package:tiktac_app/features/stopwatch/data/datasources/stopwatch_local_data_source.dart';
import 'package:tiktac_app/features/stopwatch/domain/models/stopwatch_entry.dart';
import 'package:tiktac_app/features/stopwatch/domain/repositories/stopwatch_repository.dart';

@LazySingleton(as: StopwatchRepository)
class StopwatchRepositoryImpl implements StopwatchRepository {
  final StopwatchLocalDataSource _localDataSource;

  StopwatchRepositoryImpl(this._localDataSource);

  @override
  Future<void> init() => _localDataSource.init();

  @override
  List<StopwatchEntry> getAll({int limit = 20, int offset = 0}) {
    return _localDataSource.getAll(limit: limit, offset: offset);
  }

  @override
  Future<StopwatchEntry> saveEntry({
    required String title,
    required int duration,
    required String category,
    required String notes,
  }) {
    return _localDataSource.saveEntry(
      title: title,
      duration: duration,
      category: category,
      notes: notes,
    );
  }

  @override
  Future<void> restoreEntry(StopwatchEntry entry) =>
      _localDataSource.restoreEntry(entry);

  @override
  Future<void> updateEntry(StopwatchEntry entry) =>
      _localDataSource.updateEntry(entry);

  @override
  Future<void> deleteEntry(dynamic key) => _localDataSource.deleteEntry(key);

  @override
  Future<void> deleteEntries(List<dynamic> keys) =>
      _localDataSource.deleteEntries(keys);

  @override
  Future<void> clearAll() => _localDataSource.clearAll();

  @override
  Map<String, dynamic> getStats() => _localDataSource.getStats();

  @override
  List<StopwatchEntry> searchByTitle(
    String query, {
    int limit = 20,
    int offset = 0,
  }) {
    return _localDataSource.searchByTitle(query, limit: limit, offset: offset);
  }

  @override
  List<StopwatchEntry> getByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) {
    return _localDataSource.getByCategory(
      category,
      limit: limit,
      offset: offset,
    );
  }

  @override
  List<String> getCategories() => _localDataSource.getCategories();

  @override
  String exportAsCSV() => _localDataSource.exportAsCSV();

  @override
  Future<int> importFromCSV(String csvData) =>
      _localDataSource.importFromCSV(csvData);
}
