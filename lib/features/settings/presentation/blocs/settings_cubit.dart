import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tiktac_app/features/settings/domain/models/app_settings.dart';
import 'package:tiktac_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_state.dart';

@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> init() async {
    try {
      emit(state.copyWith(isLoading: true));
      final settings = await _repository.getSettings();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e, stackTrace) {
      developer.log(
        'Error inicializando SettingsCubit',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsCubit',
      );
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los ajustes.',
      ));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    final updatedSettings = state.settings.copyWith(themeMode: mode);
    emit(state.copyWith(settings: updatedSettings));
    await _persistSettings(updatedSettings);
  }

  Future<void> setPipEnabled(bool enabled) async {
    if (state.isPipEnabled == enabled) return;
    final updatedSettings = state.settings.copyWith(isPipEnabled: enabled);
    emit(state.copyWith(settings: updatedSettings));
    await _persistSettings(updatedSettings);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    if (state.isVibrationEnabled == enabled) return;
    final updatedSettings = state.settings.copyWith(isVibrationEnabled: enabled);
    emit(state.copyWith(settings: updatedSettings));
    await _persistSettings(updatedSettings);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (state.isSoundEnabled == enabled) return;
    final updatedSettings = state.settings.copyWith(isSoundEnabled: enabled);
    emit(state.copyWith(settings: updatedSettings));
    await _persistSettings(updatedSettings);
  }

  Future<void> setHasShownNotificationPrompt(bool shown) async {
    if (state.hasShownNotificationPrompt == shown) return;
    final updatedSettings = state.settings.copyWith(hasShownNotificationPrompt: shown);
    emit(state.copyWith(settings: updatedSettings));
    await _persistSettings(updatedSettings);
  }

  Future<void> _persistSettings(AppSettings updatedSettings) async {
    try {
      await _repository.saveSettings(updatedSettings);
    } catch (e, stackTrace) {
      developer.log(
        'Error al guardar ajustes en repositorio',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsCubit',
      );
      emit(state.copyWith(
        errorMessage: 'Error guardando cambios.',
      ));
    }
  }
}
