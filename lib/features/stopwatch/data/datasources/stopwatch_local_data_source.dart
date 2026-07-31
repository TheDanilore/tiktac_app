import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tiktac_app/features/stopwatch/domain/models/stopwatch_entry.dart';
import 'package:injectable/injectable.dart';
import 'dart:developer' as developer;

@lazySingleton
class StopwatchLocalDataSource {
  static const String boxName = 'stopwatch_entries';
  late Box<StopwatchEntry> _box;

  StopwatchLocalDataSource();

  bool get isInitialized => _box.isOpen;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(StopwatchEntryAdapter());
    try {
      _box = await Hive.openBox<StopwatchEntry>(boxName);
    } catch (e, s) {
      developer.log(
        'Error abriendo Box de Stopwatch. Eliminando y reintentando...',
        error: e,
        stackTrace: s,
        name: 'StopwatchService',
      );
      await Hive.deleteBoxFromDisk(boxName);
      _box = await Hive.openBox<StopwatchEntry>(boxName);
    }
    if (_box.isEmpty) {
      await _autoRestoreFromPublicFolder();
    }
  }

  Future<void> _autoBackupToPublicFolder() async {
    try {
      final csvData = exportAsCSV();
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/TikTac');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final file = File('${directory.path}/Historial_Backup.csv');
      await file.writeAsString(csvData);
    } catch (e, s) {
      developer.log('Fallo al exportar backup automático a directorio público', error: e, stackTrace: s);
    }
  }

  Future<void> _autoRestoreFromPublicFolder() async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/TikTac');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final file = File('${directory.path}/Historial_Backup.csv');
      if (await file.exists()) {
        final content = await file.readAsString();
        await importFromCSV(content);
      }
    } catch (e, s) {
      developer.log('Fallo al restaurar backup automático desde directorio público', error: e, stackTrace: s);
    }
  }

  // Obtener registros con paginación simulando Range de Supabase
  List<StopwatchEntry> getAll({int limit = 20, int offset = 0}) {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (offset >= entries.length) return [];
    return entries.skip(offset).take(limit).toList();
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
    _autoBackupToPublicFolder();
    return entry;
  }

  // Restaurar un registro eliminado
  Future<void> restoreEntry(StopwatchEntry entry) async {
    await _box.put(entry.key ?? entry.id, entry);
    _autoBackupToPublicFolder();
  }

  // Actualizar un registro existente
  Future<void> updateEntry(StopwatchEntry entry) async {
    await _box.put(entry.key, entry);
    _autoBackupToPublicFolder();
  }

  // Eliminar un registro
  Future<void> deleteEntry(dynamic key) async {
    await _box.delete(key);
    _autoBackupToPublicFolder();
  }

  // Eliminar múltiples registros
  Future<void> deleteEntries(List<dynamic> keys) async {
    await _box.deleteAll(keys);
    _autoBackupToPublicFolder();
  }

  // Eliminar todos los registros
  Future<void> clearAll() async {
    await _box.clear();
    _autoBackupToPublicFolder();
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

  // Buscar registros por título con paginación (simulando .ilike y .range de Supabase)
  List<StopwatchEntry> searchByTitle(String query, {int limit = 20, int offset = 0}) {
    final entries = _box.values
        .where((entry) =>
            entry.title.toLowerCase().contains(query.toLowerCase()) ||
            entry.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (offset >= entries.length) return [];
    return entries.skip(offset).take(limit).toList();
  }

  // Obtener registros por categoría con paginación
  List<StopwatchEntry> getByCategory(String category, {int limit = 20, int offset = 0}) {
    final entries = _box.values
        .where((entry) => entry.category == category)
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (offset >= entries.length) return [];
    return entries.skip(offset).take(limit).toList();
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
    // Para exportar, cargamos todo sin límite
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  // Exportar datos como CSV
  String exportAsCSV() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final buffer = StringBuffer();
    buffer.writeln('Título,Categoría,Duración,Fecha,Notas');
    
    for (final entry in entries) {
      final title = entry.title.replaceAll(',', ' ');
      final category = entry.category.replaceAll(',', ' ');
      final duration = entry.formattedDuration;
      final date = entry.createdAt.toIso8601String();
      final notes = entry.notes.replaceAll(',', ' ').replaceAll('\n', ' ');
      buffer.writeln('$title,$category,$duration,$date,$notes');
    }
    
    return buffer.toString();
  }

  // Importar desde CSV
  Future<int> importFromCSV(String csvData) async {
    int importedCount = 0;
    final lines = csvData.split('\n');
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 4) {
        try {
          final title = parts[0].trim();
          final category = parts[1].trim();
          final durationStr = parts[2].trim();
          final dateStr = parts[3].trim();
          final notes = parts.length > 4 ? parts.sublist(4).join(',').trim() : '';

          int durationMillis = 0;
          final durationParts = durationStr.split(':');
          if (durationParts.length == 3) {
            final h = int.tryParse(durationParts[0]) ?? 0;
            final m = int.tryParse(durationParts[1]) ?? 0;
            final s = int.tryParse(durationParts[2]) ?? 0;
            durationMillis = (h * 3600000) + (m * 60000) + (s * 1000);
          } else if (durationParts.length == 2) {
            final m = int.tryParse(durationParts[0]) ?? 0;
            final s = int.tryParse(durationParts[1]) ?? 0;
            durationMillis = (m * 60000) + (s * 1000);
          }

          final createdAt = DateTime.tryParse(dateStr) ?? DateTime.now();

          if (durationMillis > 0) {
            final entry = StopwatchEntry(
              id: const Uuid().v4(),
              title: title.isEmpty ? 'Importado' : title,
              duration: durationMillis,
              createdAt: createdAt,
              category: category.isEmpty ? 'General' : category,
              notes: notes,
            );
            await _box.add(entry);
            importedCount++;
          }
        } catch (e, s) {
          developer.log('Error importando línea CSV: $line', error: e, stackTrace: s);
        }
      }
    }
    return importedCount;
  }

  // Cerrar la base de datos
  Future<void> close() async {
    await _box.close();
  }
}
