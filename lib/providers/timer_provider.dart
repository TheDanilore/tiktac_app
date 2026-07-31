import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:tiktac_app/providers/settings_provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';

class TimerProvider extends ChangeNotifier {
  int _secondsRemaining = 0;
  int _initialSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  int get secondsRemaining => _secondsRemaining;
  int get initialSeconds => _initialSeconds;
  bool get isRunning => _isRunning;

  String get formattedTime {
    final hours = _secondsRemaining ~/ 3600;
    final minutes = (_secondsRemaining % 3600) ~/ 60;
    final seconds = _secondsRemaining % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (_initialSeconds == 0) return 0.0;
    return 1 - (_secondsRemaining / _initialSeconds);
  }

  void addTime(int minutes) {
    if (_isRunning) return;
    _initialSeconds += minutes * 60;
    _secondsRemaining = _initialSeconds;
    notifyListeners();
  }

  void resetTime() {
    stop();
    _initialSeconds = 0;
    _secondsRemaining = 0;
    notifyListeners();
  }

  void toggle(BuildContext context) {
    if (_isRunning) {
      stop();
    } else {
      if (_secondsRemaining > 0) {
        start(context);
      }
    }
  }

  void start(BuildContext context) {
    if (_isRunning || _secondsRemaining <= 0) return;
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        stop();
        _onTimerFinished(context);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  Future<void> _onTimerFinished(BuildContext context) async {
    if (!context.mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);

    if (settings.isVibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [500, 1000, 500, 2000, 500, 1000]);
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
