import 'dart:developer' as developer;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

@lazySingleton
class HardwareService {
  HardwareService();

  Future<void> playAlarm({bool? isSoundEnabled, bool? isVibrationEnabled}) async {
    bool playSound = isSoundEnabled ?? true;
    bool triggerVibration = isVibrationEnabled ?? true;

    if (isSoundEnabled == null || isVibrationEnabled == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        playSound = isSoundEnabled ?? (prefs.getBool('sound_enabled') ?? true);
        triggerVibration = isVibrationEnabled ?? (prefs.getBool('vibration_enabled') ?? true);
      } catch (e, s) {
        developer.log(
          'Error reading SharedPreferences in HardwareService',
          error: e,
          stackTrace: s,
          name: 'HardwareService',
        );
      }
    }

    if (playSound) {
      try {
        FlutterRingtonePlayer().playAlarm(looping: true);
      } catch (e, s) {
        developer.log(
          'Error playing alarm ringtone',
          error: e,
          stackTrace: s,
          name: 'HardwareService',
        );
      }
    }

    if (triggerVibration) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(
            pattern: [0, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000],
          );
        }
      } catch (e, s) {
        developer.log(
          'Error triggering vibration pattern',
          error: e,
          stackTrace: s,
          name: 'HardwareService',
        );
      }
    }
  }

  Future<void> stopAlarm() async {
    try {
      FlutterRingtonePlayer().stop();
    } catch (e, s) {
      developer.log(
        'Error stopping ringtone player',
        error: e,
        stackTrace: s,
        name: 'HardwareService',
      );
    }

    try {
      Vibration.cancel();
    } catch (e, s) {
      developer.log(
        'Error canceling vibration',
        error: e,
        stackTrace: s,
        name: 'HardwareService',
      );
    }
  }
}
