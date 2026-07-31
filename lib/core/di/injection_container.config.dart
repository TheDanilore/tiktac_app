// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/settings/data/datasources/settings_local_data_source.dart'
    as _i599;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/domain/repositories/settings_repository.dart'
    as _i674;
import '../../features/settings/presentation/blocs/settings_cubit.dart'
    as _i573;
import '../../features/stopwatch/data/datasources/stopwatch_local_data_source.dart'
    as _i316;
import '../../features/stopwatch/data/repositories/stopwatch_repository_impl.dart'
    as _i1011;
import '../../features/stopwatch/domain/repositories/stopwatch_repository.dart'
    as _i977;
import '../../features/stopwatch/presentation/blocs/stopwatch_cubit.dart'
    as _i707;
import '../../features/timer/data/datasources/timer_local_data_source.dart'
    as _i172;
import '../../features/timer/data/repositories/timer_repository_impl.dart'
    as _i104;
import '../../features/timer/domain/repositories/timer_repository.dart'
    as _i835;
import '../../features/timer/presentation/blocs/timer_cubit.dart' as _i816;
import '../services/hardware_service.dart' as _i616;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i616.HardwareService>(() => _i616.HardwareService());
    gh.lazySingleton<_i316.StopwatchLocalDataSource>(
        () => _i316.StopwatchLocalDataSource());
    gh.lazySingleton<_i977.StopwatchRepository>(() =>
        _i1011.StopwatchRepositoryImpl(gh<_i316.StopwatchLocalDataSource>()));
    gh.lazySingleton<_i599.SettingsLocalDataSource>(
        () => _i599.SettingsLocalDataSourceImpl());
    gh.lazySingleton<_i172.TimerLocalDataSource>(
        () => _i172.TimerLocalDataSourceImpl());
    gh.lazySingleton<_i674.SettingsRepository>(() =>
        _i955.SettingsRepositoryImpl(gh<_i599.SettingsLocalDataSource>()));
    gh.factory<_i707.StopwatchCubit>(
        () => _i707.StopwatchCubit(gh<_i977.StopwatchRepository>()));
    gh.lazySingleton<_i573.SettingsCubit>(
        () => _i573.SettingsCubit(gh<_i674.SettingsRepository>()));
    gh.lazySingleton<_i835.TimerRepository>(
        () => _i104.TimerRepositoryImpl(gh<_i172.TimerLocalDataSource>()));
    gh.factory<_i816.TimerCubit>(() => _i816.TimerCubit(
          gh<_i616.HardwareService>(),
          gh<_i835.TimerRepository>(),
        ));
    return this;
  }
}
