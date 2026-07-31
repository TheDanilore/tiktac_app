import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tiktac_app/models/stopwatch_entry.dart';
import 'package:tiktac_app/services/stopwatch_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:tiktac_app/services/foreground_task_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopwatchProvider with ChangeNotifier {
  final StopwatchService _service;

  StopwatchProvider(this._service);

  // Estado del cronómetro
  int _elapsedTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  List<StopwatchEntry> _entries = [];
  List<StopwatchEntry> _filteredEntries = [];
  String _filterQuery = '';


  // Getters
  int get elapsedTime => _elapsedTime;
  bool get isRunning => _isRunning;
  List<StopwatchEntry> get entries => _filteredEntries.isEmpty && _filterQuery.isEmpty ? _entries : _filteredEntries;
  List<StopwatchEntry> get allEntries => _entries;
  String get formattedTime {
    final hours = (_elapsedTime ~/ 3600000).toString().padLeft(2, '0');
    final minutes = ((_elapsedTime ~/ 60000) % 60).toString().padLeft(2, '0');
    final seconds = ((_elapsedTime ~/ 1000) % 60).toString().padLeft(2, '0');
    final milliseconds = ((_elapsedTime ~/ 10) % 100).toString().padLeft(2, '0');
    
    if (_elapsedTime >= 3600000) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds.$milliseconds';
  }

  String get formattedTimeShort {
    final minutes = (_elapsedTime ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((_elapsedTime ~/ 1000) % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Inicializar
  Future<void> init() async {
    loadEntries();
    await _checkPendingSessions();
  }

  Future<void> _checkPendingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_sessions') ?? [];
    if (pending.isNotEmpty) {
      for (final sessionStr in pending) {
        final data = jsonDecode(sessionStr);
        final elapsed = data['timeElapsed'] as int;
        if (data['isTimer'] == false) { // Es cronómetro
          await addEntry('Sesión de Cronómetro', 'General', elapsed);
        } else {
          await addEntry('Sesión de Temporizador', 'General', elapsed);
        }
      }
      await prefs.setStringList('pending_sessions', []);
    }
    
    // Y recuperamos el estado si el servicio sigue vivo
    if (await FlutterForegroundTask.isRunningService) {
      final mode = await FlutterForegroundTask.getData<String>(key: 'mode');
      if (mode == 'stopwatch') {
        _isRunning = true;
        _elapsedTime = await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ?? 0;
        final startMillis = await FlutterForegroundTask.getData<int>(key: 'startMillis') ?? DateTime.now().millisecondsSinceEpoch;
        _elapsedTime += (DateTime.now().millisecondsSinceEpoch - startMillis);
        
        _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          _elapsedTime += 10;
          notifyListeners();
        });
        notifyListeners();
      }
    }
  }

  // Cargar historial
  void loadEntries() {
    _entries = _service.getAll();
    _filterQuery = '';

    _filteredEntries = [];
    notifyListeners();
  }

  // Iniciar/pausar cronómetro
  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  Future<void> startTimer() async {
    if (_isRunning) return;
    _isRunning = true;
    
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _elapsedTime += 10;
      notifyListeners();
    });
    
    notifyListeners();

    try {
      await FlutterForegroundTask.saveData(key: 'mode', value: 'stopwatch');
      await FlutterForegroundTask.saveData(key: 'startMillis', value: DateTime.now().millisecondsSinceEpoch);
      await FlutterForegroundTask.saveData(key: 'accumulatedMillis', value: _elapsedTime);

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Cronómetro activo',
          notificationText: 'Tiempo corriendo...',
          callback: startCallback,
        );
      }
      SimplePip().setAutoPipMode(autoEnter: true, aspectRatio: const (239, 100));
    } catch(e) {
      debugPrint("Error starting foreground task: $e");
    }
  }

  Future<void> pauseTimer() async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();

    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: 'mode');
    
    SimplePip().setAutoPipMode(autoEnter: false);
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _elapsedTime = 0;
    notifyListeners();
    
    SimplePip().setAutoPipMode(autoEnter: false);
    await FlutterForegroundTask.stopService();
  }

  // Guardar la actividad completada
  Future<void> saveActivity({
    required String title,
    required String category,
    required String notes,
  }) async {
    if (_elapsedTime == 0) return;

    await _service.saveEntry(
      title: title,
      duration: _elapsedTime,
      category: category,
      notes: notes,
    );

    resetTimer();
    loadEntries();
  }

  // Añadir una entrada directamente (para el Temporizador)
  Future<void> addEntry(String title, String category, int duration) async {
    await _service.saveEntry(
      title: title,
      duration: duration,
      category: category,
      notes: '',
    );
    loadEntries();
  }

  // Actualizar una entrada
  Future<void> updateEntry(StopwatchEntry entry) async {
    await _service.updateEntry(entry);
    loadEntries();
  }

  // Eliminar una entrada
  Future<void> deleteEntry(dynamic key) async {
    await _service.deleteEntry(key);
    loadEntries();
  }

  // Restaurar una entrada
  Future<void> restoreEntry(StopwatchEntry entry) async {
    await _service.restoreEntry(entry);
    loadEntries();
  }

  // Eliminar todo el historial
  Future<void> clearHistory() async {
    await _service.clearAll();
    loadEntries();
  }

  // Buscar
  void search(String query) {
    _filterQuery = query;
    if (query.isEmpty) {
      _filteredEntries = [];
    } else {
      _filteredEntries = _service.searchByTitle(query);
    }
    notifyListeners();
  }

  // Filtrar por categoría
  void filterByCategory(String category) {

    if (category == 'Todos') {
      _filteredEntries = [];
    } else {
      _filteredEntries = _service.getByCategory(category);
    }
    notifyListeners();
  }

  // Obtener categorías
  List<String> getCategories() {
    return _service.getCategories();
  }

  // Obtener estadísticas
  Map<String, dynamic> getStats() {
    return _service.getStats();
  }

  // Exportar
  String exportData() {
    return _service.exportAsText();
  }

  String exportCSVData() {
    return _service.exportAsCSV();
  }

  Future<int> importCSVData(String csvData) async {
    final count = await _service.importFromCSV(csvData);
    loadEntries();
    return count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
