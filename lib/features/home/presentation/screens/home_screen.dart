import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:tiktac_app/features/history/presentation/widgets/history_view.dart';
import 'package:tiktac_app/features/home/presentation/widgets/home_header.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/stopwatch_view.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_cubit.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_state.dart';
import 'package:tiktac_app/features/timer/presentation/widgets/timer_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      if (mounted) {
        _checkPermissions();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final settingsCubit = context.read<SettingsCubit>();

    // Esperar a que los ajustes se hayan cargado desde Hive para no leer el estado por defecto (false)
    while (settingsCubit.state.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!settingsCubit.state.hasShownStoragePrompt) {
      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.storage.isDenied) {
        if (!mounted ||
            WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
          return;
        }
        settingsCubit.setHasShownStoragePrompt(true);
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permiso de Almacenamiento'),
            content: const Text(
              'Para poder exportar tu historial y crear copias de seguridad en la carpeta de descargas (TikTac), '
              'necesitamos acceso al almacenamiento. Puedes configurarlo más tarde en Ajustes.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Omitir'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  if (await Permission.manageExternalStorage.isDenied) {
                    await Permission.manageExternalStorage.request();
                  }
                  if (await Permission.storage.isDenied) {
                    await Permission.storage.request();
                  }
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    }

    if (!mounted) return;

    if (settingsCubit.state.hasShownNotificationPrompt) return;

    if (await Permission.notification.isDenied) {
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      settingsCubit.setHasShownNotificationPrompt(true);
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Permiso de Notificaciones'),
          content: const Text(
            'Necesitamos el permiso de notificaciones para poder mostrarte '
            'el progreso del cronómetro y temporizador cuando la aplicación '
            'está minimizada o en segundo plano.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Omitir'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Permission.notification.request();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PipWidget(
      pipBuilder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _tabController.index == 1
                ? BlocBuilder<TimerCubit, TimerState>(
                    builder: (context, state) {
                      final cubit = context.read<TimerCubit>();
                      final progress = state.initialSeconds > 0
                          ? cubit.progress
                          : 1.0;
                      return Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                color: const Color(0xFF6C63FF).withAlpha(60),
                              ),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      cubit.formattedTime,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : BlocSelector<StopwatchCubit, StopwatchState, int>(
                    selector: (state) => state.elapsedTime,
                    builder: (context, elapsedTime) {
                      final hours = (elapsedTime ~/ 3600000).toString().padLeft(
                        2,
                        '0',
                      );
                      final minutes = ((elapsedTime ~/ 60000) % 60)
                          .toString()
                          .padLeft(2, '0');
                      final seconds = ((elapsedTime ~/ 1000) % 60)
                          .toString()
                          .padLeft(2, '0');
                      final formattedTime = elapsedTime >= 3600000
                          ? '$hours:$minutes:$seconds'
                          : '$minutes:$seconds';

                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
      builder: (context) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 800;

                if (isTablet) {
                  // Tablet / Desktop: Split View
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Stopwatch
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            HomeHeader(
                              isTablet: true,
                              tabController: _tabController,
                            ),
                            const Expanded(child: StopwatchView()),
                          ],
                        ),
                      ),
                      // Divider
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      // Right Panel: History
                      const Expanded(flex: 1, child: HistoryView()),
                    ],
                  );
                }

                // Mobile: Tabbed View
                return Column(
                  children: [
                    HomeHeader(isTablet: false, tabController: _tabController),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          StopwatchView(),
                          TimerView(),
                          HistoryView(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
