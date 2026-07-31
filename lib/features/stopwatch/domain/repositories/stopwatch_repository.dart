import 'package:tiktac_app/features/stopwatch/domain/models/stopwatch_entry.dart';

abstract class StopwatchRepository {
  Future<void> init();
  List<StopwatchEntry> getAll({int limit = 20, int offset = 0});
  Future<StopwatchEntry> saveEntry({
    required String title,
    required int duration,
    required String category,
    required String notes,
  });
  Future<void> restoreEntry(StopwatchEntry entry);
  Future<void> updateEntry(StopwatchEntry entry);
  Future<void> deleteEntry(dynamic key);
  Future<void> deleteEntries(List<dynamic> keys);
  Future<void> clearAll();
  Map<String, dynamic> getStats();
  List<StopwatchEntry> searchByTitle(
    String query, {
    int limit = 20,
    int offset = 0,
  });
  List<StopwatchEntry> getByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  });
  List<String> getCategories();
  String exportAsCSV();
  Future<int> importFromCSV(String csvData);
}
