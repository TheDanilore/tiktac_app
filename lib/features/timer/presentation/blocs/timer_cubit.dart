import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:injectable/injectable.dart';
import 'package:simple_pip_mode/simple_pip.dart';

import 'package:tiktac_app/core/services/hardware_service.dart';
import 'package:tiktac_app/core/services/foreground_task_handler.dart';
import 'package:tiktac_app/features/stopwatch/domain/repositories/stopwatch_repository.dart';
import 'package:tiktac_app/features/timer/domain/repositories/timer_repository.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_state.dart';

@injectable
class TimerCubit extends Cubit<TimerState> {
  final HardwareService _hardware;
  final TimerRepository _repository;
  final StopwatchRepository _stopwatchRepository;

  Timer? _ticker;
  int _targetTimeMillis = 0;
  int _remainingTimeMillis = 0;

  TimerCubit(this._hardware, this._repository, this._stopwatchRepository) : super(const TimerInitial(0, 0)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final lastSelectedSeconds = await _repository.getLastSelectedSeconds();
      
      if (await FlutterForegroundTask.isRunningService) {
        final mode = await FlutterForegroundTask.getData<String>(key: 'mode');
        if (mode == 'timer') {
          _targetTimeMillis = await FlutterForegroundTask.getData<int>(key: 'targetMillis') ?? 0;
          final accumulatedMillis = await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ?? 0;
          final startMillis = await FlutterForegroundTask.getData<int>(key: 'startMillis') ?? DateTime.now().millisecondsSinceEpoch;
          
          final elapsed = accumulatedMillis + (DateTime.now().millisecondsSinceEpoch - startMillis);
          _remainingTimeMillis = _targetTimeMillis - elapsed;

          final initialSeconds = _targetTimeMillis ~/ 1000;
          
          if (_remainingTimeMillis <= 0) {
            _remainingTimeMillis = 0;
            emit(TimerFinished(initialSeconds));
          } else {
            _startTicker(initialSeconds);
          }
          return;
        }
      }
      
      _updateInitial(lastSelectedSeconds);
    } catch (e, stack) {
      developer.log("Error initializing TimerCubit", error: e, stackTrace: stack);
    }
  }

  void addTime(int minutes) {
    if (state is TimerRunning) return;
    
    const maxSeconds = 86399; // 23:59:59
    int newInitial = state.initialSeconds + (minutes * 60);
    if (newInitial > maxSeconds) newInitial = maxSeconds;
    
    _updateInitial(newInitial);
  }

  void setTime(int seconds) {
    if (state is TimerRunning) return;
    
    const maxSeconds = 86399; // 23:59:59
    int newInitial = seconds > maxSeconds ? maxSeconds : seconds;
    
    _updateInitial(newInitial);
  }

  void _updateInitial(int seconds) {
    _targetTimeMillis = seconds * 1000;
    _remainingTimeMillis = _targetTimeMillis;
    if (seconds > 0) {
      _repository.saveLastSelectedSeconds(seconds);
    }
    emit(TimerInitial(seconds, seconds));
  }

  Future<void> toggle({required bool isPipEnabled}) async {
    if (state is TimerRunning) {
      await pauseTimer();
    } else {
      if (_remainingTimeMillis > 0) {
        await startTimer(isPipEnabled: isPipEnabled);
      }
    }
  }

  Future<void> startTimer({required bool isPipEnabled}) async {
    if (state is TimerRunning || _remainingTimeMillis == 0) return;
    
    SimplePip().setAutoPipMode(autoEnter: isPipEnabled);
    
    final initialSeconds = state.initialSeconds;
    _startTicker(initialSeconds);

    try {
      await FlutterForegroundTask.saveData(key: 'mode', value: 'timer');
      await FlutterForegroundTask.saveData(key: 'targetMillis', value: _targetTimeMillis);
      await FlutterForegroundTask.saveData(key: 'startMillis', value: DateTime.now().millisecondsSinceEpoch);
      await FlutterForegroundTask.saveData(key: 'accumulatedMillis', value: _targetTimeMillis - _remainingTimeMillis);

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Temporizador activo',
          notificationText: 'Tiempo corriendo...',
          callback: startCallback,
        );
      }
    } catch (e, stack) {
      developer.log('Failed to start foreground task', error: e, stackTrace: stack);
    }
  }

  void _startTicker(int initialSeconds) {
    _ticker?.cancel();
    final endTime = DateTime.now().millisecondsSinceEpoch + _remainingTimeMillis;
    
    emit(TimerRunning(initialSeconds, (_remainingTimeMillis / 1000).ceil()));
    
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (endTime > now) {
        _remainingTimeMillis = endTime - now;
        final newRemaining = (_remainingTimeMillis / 1000).ceil();
        if (state is! TimerRunning || (state as TimerRunning).secondsRemaining != newRemaining) {
          emit(TimerRunning(initialSeconds, newRemaining));
        }
      } else {
        _remainingTimeMillis = 0;
        _onTimerFinished(initialSeconds);
      }
    });
  }

  Future<void> pauseTimer() async {
    _ticker?.cancel();
    emit(TimerPaused(state.initialSeconds, (_remainingTimeMillis / 1000).ceil()));
    try {
      await FlutterForegroundTask.stopService();
      SimplePip().setAutoPipMode(autoEnter: false);
    } catch (e, stack) {
      developer.log('Error pausing timer', error: e, stackTrace: stack);
    }
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    _targetTimeMillis = state.initialSeconds * 1000;
    _remainingTimeMillis = _targetTimeMillis;
    
    emit(TimerInitial(state.initialSeconds, state.initialSeconds));
    try {
      await FlutterForegroundTask.stopService();
      SimplePip().setAutoPipMode(autoEnter: false);
    } catch (e, stack) {
      developer.log("Error resetting timer", error: e, stackTrace: stack);
    }
  }

  Future<void> _onTimerFinished(int initialSeconds) async {
    _ticker?.cancel();
    emit(TimerFinished(initialSeconds));
    SimplePip().setAutoPipMode(autoEnter: false);

    try {
      await _stopwatchRepository.saveEntry(
        title: 'Temporizador',
        duration: initialSeconds * 1000,
        category: 'General',
        notes: '',
      );
    } catch (e, s) {
      developer.log('Error al guardar historial del temporizador', error: e, stackTrace: s);
    }

    final isServiceRunning = await FlutterForegroundTask.isRunningService;
    if (!isServiceRunning && !kIsWeb) {
      await _hardware.playAlarm();
    }
  }

  Future<void> stopAlarm() async {
    await _hardware.stopAlarm();
    await FlutterForegroundTask.stopService();
    SimplePip().setAutoPipMode(autoEnter: false);
    emit(TimerInitial(0, state.initialSeconds));
  }
  
  double get progress {
    if (_targetTimeMillis == 0) return 0.0;
    return 1 - (_remainingTimeMillis / _targetTimeMillis);
  }

  String get formattedTime {
    final totalSeconds = (_remainingTimeMillis / 1000).ceil();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
