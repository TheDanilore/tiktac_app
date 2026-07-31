import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
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
  String _lastNotifiedText = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      final mode =
          await FlutterForegroundTask.getData<String>(key: 'mode') ??
          'stopwatch';
      _isTimer = mode == 'timer';
      _targetMillis =
          await FlutterForegroundTask.getData<int>(key: 'targetMillis') ?? 0;
      _startMillis =
          await FlutterForegroundTask.getData<int>(key: 'startMillis') ??
          DateTime.now().millisecondsSinceEpoch;
      _accumulatedMillis =
          await FlutterForegroundTask.getData<int>(key: 'accumulatedMillis') ??
          0;

      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _lastNotifiedText = '';

      _isRunning = true;
    } catch (e, s) {
      developer.log(
        'Error in TimerTaskHandler.onStart',
        error: e,
        stackTrace: s,
        name: 'TimerTaskHandler',
      );
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (!_isRunning) return;

    try {
      final currentMillis = timestamp.millisecondsSinceEpoch;
      final elapsed = _accumulatedMillis + (currentMillis - _startMillis);

      String timeStr = '';
      if (_isTimer) {
        final remaining = _targetMillis - elapsed;
        if (remaining <= 0) {
          // Timer finished
          _isRunning = false;
          timeStr = '00:00';
          await _savePendingSession(_targetMillis);

          if (_isSoundEnabled) {
            try {
              FlutterRingtonePlayer().playAlarm(looping: true);
            } catch (e, s) {
              developer.log(
                'Error playing ringtone',
                error: e,
                stackTrace: s,
                name: 'TimerTaskHandler',
              );
            }
          }
          if (_isVibrationEnabled) {
            try {
              final hasVibrator = await Vibration.hasVibrator();
              if (hasVibrator == true) {
                Vibration.vibrate(
                  pattern: [
                    0,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                    1000,
                  ],
                );
              }
            } catch (e, s) {
              developer.log(
                'Error triggering vibration',
                error: e,
                stackTrace: s,
                name: 'TimerTaskHandler',
              );
            }
          }

          FlutterForegroundTask.wakeUpScreen();

          FlutterForegroundTask.updateService(
            notificationTitle: '¡Tiempo completado!',
            notificationText: 'Toca para detener la alarma.',
            notificationButtons: [
              const NotificationButton(
                id: 'btn_stop_alarm',
                text: 'PARAR ALARMA',
              ),
            ],
          );
          return;
        }
        timeStr = _formatDuration(Duration(milliseconds: remaining));
      } else {
        timeStr = _formatDuration(Duration(milliseconds: elapsed));
      }

      if (timeStr != _lastNotifiedText) {
        _lastNotifiedText = timeStr;
        FlutterForegroundTask.updateService(
          notificationTitle: _isTimer ? 'Temporizador' : 'Cronómetro',
          notificationText: timeStr,
        );
      }
    } catch (e, s) {
      developer.log(
        'Error in TimerTaskHandler.onRepeatEvent',
        error: e,
        stackTrace: s,
        name: 'TimerTaskHandler',
      );
    }
  }

  @override
  void onNotificationButtonPressed(String id) async {
    try {
      if (id == 'btn_stop') {
        _isRunning = false;
        final currentMillis = DateTime.now().millisecondsSinceEpoch;
        final elapsed = _accumulatedMillis + (currentMillis - _startMillis);

        await _savePendingSession(elapsed);
        await FlutterForegroundTask.stopService();
      } else if (id == 'btn_stop_alarm') {
        try {
          FlutterRingtonePlayer().stop();
        } catch (_) {}
        try {
          Vibration.cancel();
        } catch (_) {}
        await FlutterForegroundTask.stopService();
      }
    } catch (e, s) {
      developer.log(
        'Error handling notification button click',
        error: e,
        stackTrace: s,
        name: 'TimerTaskHandler',
      );
    }
  }

  Future<void> _savePendingSession(int timeElapsed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'timeElapsed': timeElapsed,
        'isTimer': _isTimer,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final pendingSessionsStr = prefs.getStringList('pending_sessions') ?? [];
      pendingSessionsStr.add(jsonEncode(sessionData));
      await prefs.setStringList('pending_sessions', pendingSessionsStr);
    } catch (e, s) {
      developer.log(
        'Error saving pending session in background handler',
        error: e,
        stackTrace: s,
        name: 'TimerTaskHandler',
      );
    }
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
    try {
      _isRunning = false;
      try {
        FlutterRingtonePlayer().stop();
      } catch (_) {}
      try {
        Vibration.cancel();
      } catch (_) {}
    } catch (e, s) {
      developer.log(
        'Error in TimerTaskHandler.onDestroy',
        error: e,
        stackTrace: s,
        name: 'TimerTaskHandler',
      );
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}
