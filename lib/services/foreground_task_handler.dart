import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  bool _isTimer = false; // true if countdown, false if stopwatch
  int _targetMillis = 0; // for timer
  int _startMillis = 0; // for both
  int _accumulatedMillis = 0;
  bool _isRunning = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Read initial data
    final mode = await FlutterForegroundTask.getData<String>(key: 'mode') ?? 'stopwatch';
    _isTimer = mode == 'timer';
    _targetMillis = await FlutterForegroundTask.getData<int>(key: 'targetMillis') ?? 0;
    _startMillis = await FlutterForegroundTask.getData<int>(key: 'startMillis') ?? DateTime.now().millisecondsSinceEpoch;
    _accumulatedMillis = await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ?? 0;
    
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    
    _isRunning = true;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_isRunning) return;

    final currentMillis = timestamp.millisecondsSinceEpoch;
    final elapsed = _accumulatedMillis + (currentMillis - _startMillis);
    
    String timeStr = '';
    if (_isTimer) {
      final remaining = _targetMillis - elapsed;
      if (remaining <= 0) {
        // Timer finished
        _isRunning = false;
        timeStr = '00:00';
        _savePendingSession(_targetMillis);
        
        if (_isSoundEnabled) {
          FlutterRingtonePlayer().playAlarm(looping: true);
        }
        if (_isVibrationEnabled) {
          Vibration.vibrate(pattern: [0, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000]);
        }
        
        FlutterForegroundTask.wakeUpScreen();
        
        FlutterForegroundTask.updateService(
          notificationTitle: '¡Tiempo completado!',
          notificationText: 'Toca para detener la alarma.',
          notificationButtons: [
            const NotificationButton(id: 'btn_stop_alarm', text: 'PARAR ALARMA')
          ],
        );
        return;
      }
      timeStr = _formatDuration(Duration(milliseconds: remaining));
    } else {
      timeStr = _formatDuration(Duration(milliseconds: elapsed));
    }

    FlutterForegroundTask.updateService(
      notificationTitle: _isTimer ? 'Temporizador' : 'Cronómetro',
      notificationText: timeStr,
    );
  }

  @override
  void onNotificationButtonPressed(String id) async {
    if (id == 'btn_stop') {
      _isRunning = false;
      final currentMillis = DateTime.now().millisecondsSinceEpoch;
      final elapsed = _accumulatedMillis + (currentMillis - _startMillis);
      
      // Guardar sesión pendiente para que la app la procese cuando se abra
      await _savePendingSession(elapsed);
      
      await FlutterForegroundTask.stopService();
    } else if (id == 'btn_stop_alarm') {
      FlutterRingtonePlayer().stop();
      Vibration.cancel();
      await FlutterForegroundTask.stopService();
    }
  }
  
  Future<void> _savePendingSession(int timeElapsed) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = {
      'timeElapsed': timeElapsed,
      'isTimer': _isTimer,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final pendingSessionsStr = prefs.getStringList('pending_sessions') ?? [];
    pendingSessionsStr.add(jsonEncode(sessionData));
    await prefs.setStringList('pending_sessions', pendingSessionsStr);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _isRunning = false;
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
  }
  
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}
