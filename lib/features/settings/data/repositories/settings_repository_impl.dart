import 'package:injectable/injectable.dart';
import 'package:tiktac_app/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:tiktac_app/features/settings/domain/models/app_settings.dart';
import 'package:tiktac_app/features/settings/domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<AppSettings> getSettings() {
    return _localDataSource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _localDataSource.saveSettings(settings);
  }
}
