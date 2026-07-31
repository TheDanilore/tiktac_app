import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool isPipEnabled;
  final bool isVibrationEnabled;
  final bool isSoundEnabled;
  final bool hasShownNotificationPrompt;
  final bool hasShownStoragePrompt;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.isPipEnabled = true,
    this.isVibrationEnabled = true,
    this.isSoundEnabled = true,
    this.hasShownNotificationPrompt = false,
    this.hasShownStoragePrompt = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? isPipEnabled,
    bool? isVibrationEnabled,
    bool? isSoundEnabled,
    bool? hasShownNotificationPrompt,
    bool? hasShownStoragePrompt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isPipEnabled: isPipEnabled ?? this.isPipEnabled,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      hasShownNotificationPrompt:
          hasShownNotificationPrompt ?? this.hasShownNotificationPrompt,
      hasShownStoragePrompt:
          hasShownStoragePrompt ?? this.hasShownStoragePrompt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isPipEnabled == other.isPipEnabled &&
          isVibrationEnabled == other.isVibrationEnabled &&
          isSoundEnabled == other.isSoundEnabled &&
          hasShownNotificationPrompt == other.hasShownNotificationPrompt &&
          hasShownStoragePrompt == other.hasShownStoragePrompt;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      isPipEnabled.hashCode ^
      isVibrationEnabled.hashCode ^
      isSoundEnabled.hashCode ^
      hasShownNotificationPrompt.hashCode ^
      hasShownStoragePrompt.hashCode;
}
