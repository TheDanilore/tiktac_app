import 'dart:developer' as developer;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TimerLocalDataSource {
  Future<int> getLastSelectedSeconds();
  Future<void> saveLastSelectedSeconds(int seconds);
}

@LazySingleton(as: TimerLocalDataSource)
class TimerLocalDataSourceImpl implements TimerLocalDataSource {
  static const String _keyLastSelectedSeconds = 'lastSelectedSeconds';

  @override
  Future<int> getLastSelectedSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyLastSelectedSeconds) ?? 0;
    } catch (e, s) {
      developer.log(
        'Error reading lastSelectedSeconds from SharedPreferences',
        error: e,
        stackTrace: s,
        name: 'TimerLocalDataSource',
      );
      return 0;
    }
  }

  @override
  Future<void> saveLastSelectedSeconds(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSelectedSeconds, seconds);
    } catch (e, s) {
      developer.log(
        'Error saving lastSelectedSeconds to SharedPreferences',
        error: e,
        stackTrace: s,
        name: 'TimerLocalDataSource',
      );
    }
  }
}
