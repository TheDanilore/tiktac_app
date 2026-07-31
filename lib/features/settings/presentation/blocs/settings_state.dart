import 'package:flutter/material.dart';
import 'package:tiktac_app/features/settings/domain/models/app_settings.dart';

class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
    this.errorMessage,
  });

  ThemeMode get themeMode => settings.themeMode;
  bool get isPipEnabled => settings.isPipEnabled;
  bool get isVibrationEnabled => settings.isVibrationEnabled;
  bool get isSoundEnabled => settings.isSoundEnabled;
  bool get hasShownNotificationPrompt => settings.hasShownNotificationPrompt;
  bool get hasShownStoragePrompt => settings.hasShownStoragePrompt;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          settings == other.settings &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      settings.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;
}
