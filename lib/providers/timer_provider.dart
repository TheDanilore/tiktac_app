import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:tiktac_app/services/foreground_task_handler.dart';
import 'package:tiktac_app/providers/settings_provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:vibration/vibration.dart';

class TimerProvider extends ChangeNotifier {
  int _initialSeconds = 0;
  int _remainingTimeMillis = 0;
  int _targetTimeMillis = 0;
  Timer? _timer;
  bool _isRunning = false;

  int get secondsRemaining => (_remainingTimeMillis / 1000).ceil();
  int get initialSeconds => _initialSeconds;
  bool get isRunning => _isRunning;

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

  double get progress {
    if (_targetTimeMillis == 0) return 0.0;
    return 1 - (_remainingTimeMillis / _targetTimeMillis);
  }

  Future<void> init(BuildContext context) async {
    if (await FlutterForegroundTask.isRunningService) {
      final mode = await FlutterForegroundTask.getData<String>(key: 'mode');
      if (mode == 'timer') {
        _isRunning = true;
        final targetMillis = await FlutterForegroundTask.getData<int>(key: 'targetMillis') ?? _targetTimeMillis;
        _targetTimeMillis = targetMillis;
        final accumulatedMillis = await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ?? 0;
        final startMillis = await FlutterForegroundTask.getData<int>(key: 'startMillis') ?? DateTime.now().millisecondsSinceEpoch;
        
        final elapsed = accumulatedMillis + (DateTime.now().millisecondsSinceEpoch - startMillis);
        _remainingTimeMillis = _targetTimeMillis - elapsed;
        
        if (_remainingTimeMillis <= 0) {
          _remainingTimeMillis = 0;
          _isRunning = false;
          if (context.mounted) _onTimerFinished(context);
        } else {
          _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
            if (_remainingTimeMillis > 0) {
              _remainingTimeMillis -= 10;
              notifyListeners();
            } else {
              _onTimerFinished(context);
            }
          });
          notifyListeners();
        }
      }
    }
  }

  void addTime(int minutes) {
    if (_isRunning) return;
    _initialSeconds += minutes * 60;
    _targetTimeMillis = _initialSeconds * 1000;
    _remainingTimeMillis = _targetTimeMillis;
    notifyListeners();
  }

  void setTime(int seconds) {
    if (_isRunning) return;
    _initialSeconds = seconds;
    _targetTimeMillis = _initialSeconds * 1000;
    _remainingTimeMillis = _targetTimeMillis;
    notifyListeners();
  }

  Future<void> pauseTimer() async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
    await FlutterForegroundTask.stopService();
    SimplePip().setAutoPipMode(autoEnter: false);
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _initialSeconds = 0;
    _targetTimeMillis = 0;
    _remainingTimeMillis = 0;
    notifyListeners();
    await FlutterForegroundTask.stopService();
    SimplePip().setAutoPipMode(autoEnter: false);
  }

  void toggle(BuildContext context) {
    if (_isRunning) {
      pauseTimer();
    } else {
      if (_remainingTimeMillis > 0) {
        startTimer(context);
      }
    }
  }

  Future<void> startTimer(BuildContext context) async {
    if (_isRunning || _remainingTimeMillis == 0) return;
    _isRunning = true;
    notifyListeners();

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
    
    SimplePip().setAutoPipMode(autoEnter: true, aspectRatio: const (239, 100));

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_remainingTimeMillis > 0) {
        _remainingTimeMillis -= 10;
        notifyListeners();
      } else {
        _onTimerFinished(context);
      }
    });
  }

  Future<void> _onTimerFinished(BuildContext context) async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
    
    await FlutterForegroundTask.stopService();

    if (!context.mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);

    if (settings.isVibrationEnabled) {
      if (!kIsWeb) {
        Vibration.vibrate(duration: 50, amplitude: 128);
      }
    }

    if (settings.isSoundEnabled) {
      if (!kIsWeb) {
        FlutterRingtonePlayer().playNotification();
      }
    }
    
    // Auto save the session
    stopwatchProvider.addEntry('Temporizador completado', 'Focus', _initialSeconds * 1000);
    _initialSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
