import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:tiktac_app/models/stopwatch_entry.dart';

class StopwatchService {
  static const String boxName = 'stopwatch_entries';
  late Box<StopwatchEntry> _box;

  bool get isInitialized => _box.isOpen;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(StopwatchEntryAdapter());
    _box = await Hive.openBox<StopwatchEntry>(boxName);
  }

  // Obtener todos los registros ordenados por fecha (más recientes primero)
  List<StopwatchEntry> getAll() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // Guardar un nuevo registro
  Future<StopwatchEntry> saveEntry({
    required String title,
    required int duration,
    required String category,
    required String notes,
  }) async {
    final entry = StopwatchEntry(
      id: const Uuid().v4(),
      title: title.isEmpty ? 'Actividad sin título' : title,
      duration: duration,
      createdAt: DateTime.now(),
      category: category,
      notes: notes,
    );
    await _box.add(entry);
    return entry;
  }

  // Actualizar un registro existente
  Future<void> updateEntry(StopwatchEntry entry) async {
    await _box.put(entry.key, entry);
  }

  // Eliminar un registro
  Future<void> deleteEntry(dynamic key) async {
    await _box.delete(key);
  }

  // Eliminar múltiples registros
  Future<void> deleteEntries(List<dynamic> keys) async {
    await _box.deleteAll(keys);
  }

  // Eliminar todos los registros
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Obtener estadísticas
  Map<String, dynamic> getStats() {
    final entries = _box.values.toList();
    if (entries.isEmpty) {
      return {
        'totalTime': 0,
        'totalCount': 0,
        'averageTime': 0,
        'longestTime': 0,
        'shortestTime': 0,
      };
    }

    int totalTime = 0;
    int longestTime = 0;
    int shortestTime = entries.first.duration;

    for (final entry in entries) {
      totalTime += entry.duration;
      if (entry.duration > longestTime) longestTime = entry.duration;
      if (entry.duration < shortestTime) shortestTime = entry.duration;
    }

    return {
      'totalTime': totalTime,
      'totalCount': entries.length,
      'averageTime': totalTime ~/ entries.length,
      'longestTime': longestTime,
      'shortestTime': shortestTime,
    };
  }

  // Buscar registros por título
  List<StopwatchEntry> searchByTitle(String query) {
    final entries = _box.values
        .where((entry) =>
            entry.title.toLowerCase().contains(query.toLowerCase()) ||
            entry.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // Obtener registros por categoría
  List<StopwatchEntry> getByCategory(String category) {
    final entries = _box.values
        .where((entry) => entry.category == category)
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  // Obtener todas las categorías únicas
  List<String> getCategories() {
    final categories = <String>{};
    for (final entry in _box.values) {
      categories.add(entry.category);
    }
    return categories.toList()..sort();
  }

  // Exportar datos como texto
  String exportAsText() {
    final entries = getAll();
    final buffer = StringBuffer();
    buffer.writeln('=== HISTORIAL DE CRONÓMETRO ===\n');

    for (final entry in entries) {
      buffer.writeln('Título: ${entry.title}');
      buffer.writeln('Categoría: ${entry.category}');
      buffer.writeln('Duración: ${entry.formattedDuration}');
      buffer.writeln('Fecha: ${entry.createdAt}');
      if (entry.notes.isNotEmpty) {
        buffer.writeln('Notas: ${entry.notes}');
      }
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  // Cerrar la base de datos
  Future<void> close() async {
    await _box.close();
  }
}
