import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:tiktac_app/services/foreground_task_handler.dart';
import 'package:tiktac_app/providers/settings_provider.dart';
import 'package:vibration/vibration.dart';

class TimerProvider extends ChangeNotifier {
  int _initialSeconds = 0;
  int _lastSelectedSeconds = 0;
  int _remainingTimeMillis = 0;
  int _targetTimeMillis = 0;
  Timer? _timer;
  bool _isRunning = false;

  int get secondsRemaining => (_remainingTimeMillis / 1000).ceil();
  int get initialSeconds => _initialSeconds;
  int get lastSelectedSeconds => _lastSelectedSeconds > 0 ? _lastSelectedSeconds : 0;
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
    final prefs = await SharedPreferences.getInstance();
    _lastSelectedSeconds = prefs.getInt('lastSelectedSeconds') ?? 0;
    if (_lastSelectedSeconds > 0 && _initialSeconds == 0) {
      _initialSeconds = _lastSelectedSeconds;
      _targetTimeMillis = _initialSeconds * 1000;
      _remainingTimeMillis = _targetTimeMillis;
    }

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
          _isAlarmRinging = true; // Timer finished in background
          _onTimerFinished();
        } else {
          final endTime = DateTime.now().millisecondsSinceEpoch + _remainingTimeMillis;
          _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (endTime > now) {
              _remainingTimeMillis = endTime - now;
              notifyListeners();
            } else {
              _remainingTimeMillis = 0;
              _onTimerFinished();
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
    if (_initialSeconds > 0) {
      _lastSelectedSeconds = _initialSeconds;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('lastSelectedSeconds', _initialSeconds));
    }
    notifyListeners();
  }

  void setTime(int seconds) {
    if (_isRunning) return;
    _initialSeconds = seconds;
    if (seconds > 0) {
      _lastSelectedSeconds = seconds;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('lastSelectedSeconds', seconds));
    }
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
    _initialSeconds = _lastSelectedSeconds;
    _targetTimeMillis = _initialSeconds * 1000;
    _remainingTimeMillis = _targetTimeMillis;
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
    
    final endTime = DateTime.now().millisecondsSinceEpoch + _remainingTimeMillis;
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (endTime > now) {
        _remainingTimeMillis = endTime - now;
        notifyListeners();
      } else {
        _remainingTimeMillis = 0;
        _onTimerFinished();
      }
    });
    
    notifyListeners();

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
      
      if (!context.mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.isPipEnabled) {
        SimplePip().setAutoPipMode(autoEnter: true, aspectRatio: const (2, 1));
      }
    } catch(e) {
      debugPrint("Error starting foreground task: $e");
    }
  }

  bool _isAlarmRinging = false;
  Timer? _vibrationTimer;

  bool get isAlarmRinging => _isAlarmRinging;

  Future<void> _onTimerFinished() async {
    _timer?.cancel();
    _isRunning = false;
    _isAlarmRinging = true;
    
    SimplePip().setAutoPipMode(autoEnter: false);
    notifyListeners();

    final isServiceRunning = await FlutterForegroundTask.isRunningService;
    if (!isServiceRunning && !kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      final isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      
      if (isSoundEnabled) {
        FlutterRingtonePlayer().playAlarm(looping: true);
      }
      if (isVibrationEnabled) {
        _vibrationTimer?.cancel();
        _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (_isAlarmRinging) {
            Vibration.vibrate(duration: 1000, amplitude: 255);
          } else {
            timer.cancel();
          }
        });
      }
    }
    
    _initialSeconds = 0;
    notifyListeners();
  }

  void stopAlarm() {
    _isAlarmRinging = false;
    _vibrationTimer?.cancel();
    if (!kIsWeb) {
      FlutterRingtonePlayer().stop();
      Vibration.cancel();
    }
    SimplePip().setAutoPipMode(autoEnter: false);
    FlutterForegroundTask.stopService();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }
}
