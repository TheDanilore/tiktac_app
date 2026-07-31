import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings_box';
  late Box _box;

  // Settings
  ThemeMode _themeMode = ThemeMode.system;
  bool _isPipEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isPipEnabled => _isPipEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    
    // Load theme mode
    final themeModeIndex = _box.get('themeMode', defaultValue: ThemeMode.system.index);
    _themeMode = ThemeMode.values[themeModeIndex];

    // Load other settings
    _isPipEnabled = _box.get('isPipEnabled', defaultValue: true);
    _isVibrationEnabled = _box.get('isVibrationEnabled', defaultValue: true);
    _isSoundEnabled = _box.get('isSoundEnabled', defaultValue: true);
    
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _box.put('themeMode', mode.index);
    notifyListeners();
  }

  void setPipEnabled(bool enabled) {
    if (_isPipEnabled == enabled) return;
    _isPipEnabled = enabled;
    _box.put('isPipEnabled', enabled);
    notifyListeners();
  }

  void setVibrationEnabled(bool enabled) {
    if (_isVibrationEnabled == enabled) return;
    _isVibrationEnabled = enabled;
    _box.put('isVibrationEnabled', enabled);
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    if (_isSoundEnabled == enabled) return;
    _isSoundEnabled = enabled;
    _box.put('isSoundEnabled', enabled);
    notifyListeners();
  }
}
