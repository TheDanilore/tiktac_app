import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:tiktac_app/providers/timer_provider.dart';
import 'package:tiktac_app/providers/settings_provider.dart';
import 'package:tiktac_app/screens/settings_screen.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tiktac_app/screens/widgets/history_view.dart';
import 'package:tiktac_app/screens/widgets/stopwatch_view.dart';
import 'package:tiktac_app/screens/widgets/timer_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    Future.microtask(() {
      if (mounted) {
        Provider.of<TimerProvider>(context, listen: false).init();
        _checkPermissions();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hasShownNotificationPrompt) return;

    if (await Permission.notification.isDenied) {
      if (!mounted || WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
      settings.setHasShownNotificationPrompt(true);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso de Notificaciones'),
          content: const Text(
            'Necesitamos el permiso de notificaciones para poder mostrarte '
            'el progreso del cronómetro y temporizador cuando la aplicación '
            'está minimizada o en segundo plano.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Omitir'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
                ? Consumer<TimerProvider>(
                    builder: (context, timer, _) {
                      final progress = timer.initialSeconds > 0 ? timer.progress : 1.0;
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
                                const Icon(Icons.hourglass_empty, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      timer.formattedTime,
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
                : Consumer<StopwatchProvider>(
                    builder: (context, stopwatch, _) => Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                stopwatch.formattedTime,
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
                        _buildHeader(context, isTablet: true),
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
                  const Expanded(
                    flex: 1,
                    child: HistoryView(),
                  ),
                ],
              );
            }

            // Mobile: Tabbed View
            return Column(
              children: [
                _buildHeader(context, isTablet: false),
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

  Widget _buildHeader(BuildContext context, {required bool isTablet}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.timer, color: theme.colorScheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TikTac',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('v2.0', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(
                      'Tiempo bajo control',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          if (!isTablet) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CustomTab(
                          icon: Icons.timer,
                          text: 'Cronómetro',
                          isSelected: _tabController.index == 0,
                          onTap: () => _tabController.animateTo(0),
                        ),
                      ),
                      Expanded(
                        child: _CustomTab(
                          icon: Icons.hourglass_bottom,
                          text: 'Timer',
                          isSelected: _tabController.index == 1,
                          onTap: () => _tabController.animateTo(1),
                        ),
                      ),
                      Expanded(
                        child: Consumer<StopwatchProvider>(
                          builder: (context, provider, child) {
                            return _CustomTab(
                              icon: Icons.history,
                              text: 'Historial',
                              badge: provider.entries.length.toString(),
                              isSelected: _tabController.index == 2,
                              onTap: () => _tabController.animateTo(2),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ]
        ],
      ),
    );
  }
}

class _CustomTab extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomTab({
    required this.icon,
    required this.text,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


