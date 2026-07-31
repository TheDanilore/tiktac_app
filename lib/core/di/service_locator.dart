import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:tiktac_app/core/di/service_locator.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void setupLocator() => getIt.init();
