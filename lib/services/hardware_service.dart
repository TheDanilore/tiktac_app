import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktac_app/services/logger_service.dart';

class HardwareService {
  final LoggerService _logger;

  HardwareService(this._logger);

  Future<void> playAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      final isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      
      if (isSoundEnabled) {
        FlutterRingtonePlayer().playAlarm(looping: true);
      }
      if (isVibrationEnabled) {
        // Vibrar en patrón para notificar la alarma
        Vibration.vibrate(pattern: [0, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000]);
      }
    } catch (e, stack) {
      _logger.e("Error al reproducir alarma de hardware", e, stack);
    }
  }

  Future<void> stopAlarm() async {
    try {
      FlutterRingtonePlayer().stop();
      Vibration.cancel();
    } catch (e, stack) {
      _logger.e("Error al detener alarma de hardware", e, stack);
    }
  }
}
