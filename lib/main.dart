import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:tiktac_app/blocs/timer/timer_cubit.dart';
import 'package:tiktac_app/providers/settings_provider.dart';
import 'package:tiktac_app/screens/home_screen.dart';
import 'package:tiktac_app/services/stopwatch_service.dart';
import 'package:tiktac_app/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tiktac_app/core/di/service_locator.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription: 'Esta notificación aparece cuando el cronómetro está en uso.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterForegroundTask.initCommunicationPort();
  _initForegroundTask();
  
  await Hive.initFlutter();

  // Inicializar inyección de dependencias
  setupLocator();

  final service = StopwatchService();
  await service.init();

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(
          create: (_) => StopwatchProvider(service)..init(),
        ),
        BlocProvider<TimerCubit>(create: (_) => TimerCubit()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Cronómetro',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
