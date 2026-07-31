import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:tiktac_app/core/di/injection_container.dart';
import 'package:tiktac_app/core/theme/app_theme.dart';
import 'package:tiktac_app/features/home/presentation/screens/home_screen.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_cubit.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_state.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_cubit.dart';

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

  try {
    FlutterForegroundTask.initCommunicationPort();
    _initForegroundTask();
    
    await Hive.initFlutter();

    // Inicializar inyección de dependencias
    initDI();
  } catch (e, s) {
    developer.log(
      'Error durante la inicialización principal de la app',
      error: e,
      stackTrace: s,
      name: 'main',
    );
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..init(),
        ),
        BlocProvider<StopwatchCubit>(
          create: (_) => sl<StopwatchCubit>()..init(),
        ),
        BlocProvider<TimerCubit>(
          create: (_) => sl<TimerCubit>(),
        ),
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
