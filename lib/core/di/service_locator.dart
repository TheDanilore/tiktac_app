import 'package:get_it/get_it.dart';
import 'package:tiktac_app/services/logger_service.dart';
import 'package:tiktac_app/services/hardware_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<HardwareService>(() => HardwareService(getIt<LoggerService>()));
}
