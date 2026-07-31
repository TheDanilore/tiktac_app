import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:tiktac_app/features/settings/domain/models/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

@LazySingleton(as: SettingsLocalDataSource)
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _boxName = 'settings_box';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    try {
      _box = await Hive.openBox(_boxName);
      return _box!;
    } catch (e, stackTrace) {
      developer.log(
        'Error abriendo Box de Hive de Ajustes',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsLocalDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<AppSettings> getSettings() async {
    try {
      final box = await _getBox();

      final themeModeIndex = box.get('themeMode', defaultValue: ThemeMode.system.index) as int;
      final themeMode = (themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length)
          ? ThemeMode.values[themeModeIndex]
          : ThemeMode.system;

      final isPipEnabled = box.get('isPipEnabled', defaultValue: true) as bool;
      final isVibrationEnabled = box.get('isVibrationEnabled', defaultValue: true) as bool;
      final isSoundEnabled = box.get('isSoundEnabled', defaultValue: true) as bool;
      final hasShownNotificationPrompt = box.get('hasShownNotificationPrompt', defaultValue: false) as bool;

      return AppSettings(
        themeMode: themeMode,
        isPipEnabled: isPipEnabled,
        isVibrationEnabled: isVibrationEnabled,
        isSoundEnabled: isSoundEnabled,
        hasShownNotificationPrompt: hasShownNotificationPrompt,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error al obtener ajustes de Hive, retornando defaults',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsLocalDataSource',
      );
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final box = await _getBox();
      await box.put('themeMode', settings.themeMode.index);
      await box.put('isPipEnabled', settings.isPipEnabled);
      await box.put('isVibrationEnabled', settings.isVibrationEnabled);
      await box.put('isSoundEnabled', settings.isSoundEnabled);
      await box.put('hasShownNotificationPrompt', settings.hasShownNotificationPrompt);
    } catch (e, stackTrace) {
      developer.log(
        'Error guardando ajustes en Hive',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsLocalDataSource',
      );
      rethrow;
    }
  }
}
