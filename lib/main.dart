import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/home/presentation/screens/home_screen.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_cubit.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_state.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_cubit.dart';

import 'package:tiktac_app/features/stopwatch/data/datasources/stopwatch_service.dart';
import 'package:tiktac_app/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tiktac_app/core/di/injection_container.dart';

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
  initDI();

  final service = sl<StopwatchService>();
  await service.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..init(),
        ),
        BlocProvider<StopwatchCubit>(
          create: (_) => sl<StopwatchCubit>()..init(),
        ),
        BlocProvider<TimerCubit>(create: (_) => sl<TimerCubit>()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) => previous.themeMode != current.themeMode,
      builder: (context, state) {
        return MaterialApp(
          title: 'Cronómetro',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
