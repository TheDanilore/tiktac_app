import 'package:injectable/injectable.dart';
import 'package:tiktac_app/features/timer/data/datasources/timer_local_data_source.dart';
import 'package:tiktac_app/features/timer/domain/repositories/timer_repository.dart';

@LazySingleton(as: TimerRepository)
class TimerRepositoryImpl implements TimerRepository {
  final TimerLocalDataSource _localDataSource;

  TimerRepositoryImpl(this._localDataSource);

  @override
  Future<int> getLastSelectedSeconds() =>
      _localDataSource.getLastSelectedSeconds();

  @override
  Future<void> saveLastSelectedSeconds(int seconds) =>
      _localDataSource.saveLastSelectedSeconds(seconds);
}
