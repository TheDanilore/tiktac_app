import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktac_app/features/stopwatch/domain/repositories/stopwatch_repository.dart';
import 'package:tiktac_app/features/stopwatch/domain/models/stopwatch_entry.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:tiktac_app/core/services/foreground_task_handler.dart';
import 'package:injectable/injectable.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'dart:developer' as developer;

@injectable
class StopwatchCubit extends Cubit<StopwatchState> {
  final StopwatchRepository _repository;

  StopwatchCubit(this._repository) : super(const StopwatchState());

  Future<void> init() async {
    try {
      emit(state.copyWith(isLoading: true));
      await _repository.init();
      loadEntries();
      await _checkPendingSessions();
      emit(state.copyWith(isLoading: false));
    } catch (e, s) {
      developer.log('Error initializing StopwatchCubit', error: e, stackTrace: s);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al inicializar el cronómetro',
      ));
    }
  }

  Future<void> _checkPendingSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_sessions') ?? [];
      if (pending.isNotEmpty) {
        for (final sessionStr in pending) {
          final data = jsonDecode(sessionStr);
          final elapsed = data['timeElapsed'] as int;
          if (data['isTimer'] == false) {
            await addEntry('Sesión de Cronómetro', 'General', elapsed);
          } else {
            await addEntry('Sesión de Temporizador', 'General', elapsed);
          }
        }
        await prefs.setStringList('pending_sessions', []);
      }
      
      if (await FlutterForegroundTask.isRunningService) {
        final mode = await FlutterForegroundTask.getData<String>(key: 'mode');
        if (mode == 'stopwatch') {
          int elapsed = await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ?? 0;
          final startMillis = await FlutterForegroundTask.getData<int>(key: 'startMillis') ?? DateTime.now().millisecondsSinceEpoch;
          
          elapsed += (DateTime.now().millisecondsSinceEpoch - startMillis);
          
          emit(state.copyWith(
            status: StopwatchStatus.running,
            elapsedTime: elapsed,
            startMillis: startMillis,
          ));
        }
      }
    } catch (e, s) {
      developer.log('Error checking pending sessions', error: e, stackTrace: s);
    }
  }

  void loadEntries() {
    try {
      final entries = _repository.getAll();
      emit(state.copyWith(
        entries: entries,
        filterQuery: '',
        filteredEntries: [],
      ));
    } catch (e, s) {
      developer.log('Error loading entries', error: e, stackTrace: s);
      emit(state.copyWith(errorMessage: 'No se pudieron cargar las sesiones.'));
    }
  }

  void toggleTimer({required bool isPipEnabled}) {
    if (state.status == StopwatchStatus.running) {
      pauseTimer();
    } else {
      startTimer(isPipEnabled: isPipEnabled);
    }
  }

  Future<void> startTimer({required bool isPipEnabled}) async {
    if (state.status == StopwatchStatus.running) return;
    
    final startMillis = DateTime.now().millisecondsSinceEpoch;
    emit(state.copyWith(status: StopwatchStatus.running, startMillis: startMillis));

    SimplePip().setAutoPipMode(autoEnter: isPipEnabled);

    try {
      await FlutterForegroundTask.saveData(key: 'mode', value: 'stopwatch');
      await FlutterForegroundTask.saveData(key: 'startMillis', value: startMillis);
      await FlutterForegroundTask.saveData(key: 'accumulatedMillis', value: state.elapsedTime);

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Cronómetro activo',
          notificationText: 'Tiempo corriendo...',
          callback: startCallback,
        );
      }
    } catch(e, s) {
      developer.log('Error starting foreground task', error: e, stackTrace: s);
      emit(state.copyWith(errorMessage: 'Error al iniciar servicio en segundo plano'));
    }
  }

  Future<void> pauseTimer({int? exactElapsedTime}) async {
    try {
      int newElapsed = exactElapsedTime ?? state.elapsedTime;
      if (exactElapsedTime == null && state.startMillis != null) {
        newElapsed += (DateTime.now().millisecondsSinceEpoch - state.startMillis!);
      }
      
      emit(state.copyWith(status: StopwatchStatus.paused, elapsedTime: newElapsed, startMillis: null));
      
      await FlutterForegroundTask.stopService();
      await FlutterForegroundTask.removeData(key: 'mode');
      SimplePip().setAutoPipMode(autoEnter: false);
    } catch (e, s) {
      developer.log('Error pausing timer', error: e, stackTrace: s);
    }
  }

  Future<void> resetTimer() async {
    try {
      emit(state.copyWith(status: StopwatchStatus.initial, elapsedTime: 0));
      await FlutterForegroundTask.stopService();
      await FlutterForegroundTask.removeData(key: 'mode');
      SimplePip().setAutoPipMode(autoEnter: false);
    } catch (e, s) {
      developer.log('Error resetting timer', error: e, stackTrace: s);
    }
  }

  Future<void> saveActivity({
    required String title,
    required String category,
    required String notes,
    required int finalElapsedTime,
  }) async {
    if (finalElapsedTime == 0) return;

    try {
      emit(state.copyWith(isLoading: true));
      await _repository.saveEntry(
        title: title,
        duration: finalElapsedTime,
        category: category,
        notes: notes,
      );
      await resetTimer();
      loadEntries();
      emit(state.copyWith(isLoading: false));
    } catch (e, s) {
      developer.log('Error saving activity', error: e, stackTrace: s);
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo guardar la sesión.'));
    }
  }

  Future<void> addEntry(String title, String category, int duration) async {
    try {
      await _repository.saveEntry(
        title: title,
        duration: duration,
        category: category,
        notes: '',
      );
      loadEntries();
    } catch (e, s) {
      developer.log('Error adding entry', error: e, stackTrace: s);
      emit(state.copyWith(errorMessage: 'No se pudo agregar la entrada.'));
    }
  }

  Future<void> updateEntry(StopwatchEntry entry) async {
    try {
      await _repository.updateEntry(entry);
      loadEntries();
    } catch (e, s) {
      developer.log('Error updating entry', error: e, stackTrace: s);
      emit(state.copyWith(errorMessage: 'No se pudo actualizar la entrada.'));
    }
  }

  Future<void> deleteEntry(dynamic key) async {
    // Optimistic Update: Actualizamos la UI instantáneamente
    final updatedEntries = state.entries.where((e) => e.id != key).toList();
    final updatedFiltered = state.filteredEntries.where((e) => e.id != key).toList();
    emit(state.copyWith(entries: updatedEntries, filteredEntries: updatedFiltered));
    try {
      await _repository.deleteEntry(key);
    } catch (e, s) {
      developer.log('Error deleting entry', error: e, stackTrace: s);
      loadEntries(); // Revertir en caso de error
      emit(state.copyWith(errorMessage: 'No se pudo eliminar la entrada.'));
    }
  }

  Future<void> restoreEntry(StopwatchEntry entry) async {
    try {
      await _repository.restoreEntry(entry);
      loadEntries();
    } catch (e, s) {
      developer.log('Error restoring entry', error: e, stackTrace: s);
      emit(state.copyWith(errorMessage: 'No se pudo restaurar la entrada.'));
    }
  }

  Future<void> searchEntries(String query) async {
    emit(state.copyWith(isLoading: true));
    try {
      final filtered = _repository.searchByTitle(query);
      emit(state.copyWith(
        filterQuery: query,
        filteredEntries: filtered,
        isLoading: false,
      ));
    } catch (e, stack) {
      developer.log('Error searching entries', error: e, stackTrace: stack);
      emit(state.copyWith(
        errorMessage: 'Error al buscar entradas',
        isLoading: false,
      ));
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearAll();
      loadEntries();
    } catch (e, stack) {
      developer.log('Error clearing history', error: e, stackTrace: stack);
      emit(state.copyWith(errorMessage: 'No se pudo borrar el historial'));
    }
  }

  String exportCSVData() {
    if (state.entries.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('ID,Título,Categoría,Duración(ms),Fecha');
    
    for (var entry in state.entries) {
      final title = entry.title.replaceAll(',', ' ');
      final category = entry.category.replaceAll(',', ' ');
      buffer.writeln('${entry.id},$title,$category,${entry.duration},${entry.createdAt.toIso8601String()}');
    }
    
    return buffer.toString();
  }

  Future<int> importCSVData(String csvString) async {
    int importedCount = 0;
    try {
      final lines = csvString.split('\n');
      if (lines.isEmpty) return 0;
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length >= 5) {
          final title = parts[1];
          final category = parts[2];
          final elapsedMillis = int.tryParse(parts[3]) ?? 0;
          
          if (elapsedMillis > 0) {
            await _repository.saveEntry(
              title: title,
              duration: elapsedMillis,
              category: category,
              notes: '',
            );
            importedCount++;
          }
        }
      }
      
      if (importedCount > 0) {
        loadEntries();
      }
    } catch (e, stack) {
      developer.log('Error importing CSV', error: e, stackTrace: stack);
      emit(state.copyWith(errorMessage: 'Error al importar datos CSV'));
    }
    return importedCount;
  }

  void search(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filterQuery: '', filteredEntries: []));
    } else {
      final filtered = _repository.searchByTitle(query);
      emit(state.copyWith(filterQuery: query, filteredEntries: filtered));
    }
  }

  void filterByCategory(String category) {
    if (category == 'Todos') {
      emit(state.copyWith(filterQuery: '', filteredEntries: []));
    } else {
      final filtered = _repository.getByCategory(category);
      emit(state.copyWith(filterQuery: category, filteredEntries: filtered));
    }
  }

  List<String> getCategories() {
    return _repository.getCategories();
  }

  Map<String, dynamic> getStats() {
    return _repository.getStats();
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
