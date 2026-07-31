import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiktac_app/models/stopwatch_entry.dart';
import 'package:tiktac_app/services/stopwatch_service.dart';

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

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _elapsedTime += 10;
      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _elapsedTime = 0;
    notifyListeners();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
