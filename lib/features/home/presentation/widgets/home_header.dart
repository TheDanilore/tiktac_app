import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/home/presentation/widgets/custom_tab.dart';
import 'package:tiktac_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';

class HomeHeader extends StatelessWidget {
  final bool isTablet;
  final TabController tabController;

  const HomeHeader({
    super.key,
    required this.isTablet,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Icon(
                  Icons.timer,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('TikTac', style: theme.textTheme.titleLarge),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v2.0',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
              animation: tabController,
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
                        child: CustomTab(
                          icon: Icons.timer,
                          text: 'Cronómetro',
                          isSelected: tabController.index == 0,
                          onTap: () => tabController.animateTo(0),
                        ),
                      ),
                      Expanded(
                        child: CustomTab(
                          icon: Icons.hourglass_bottom,
                          text: 'Timer',
                          isSelected: tabController.index == 1,
                          onTap: () => tabController.animateTo(1),
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<StopwatchCubit, StopwatchState>(
                          buildWhen: (previous, current) =>
                              previous.entries.length != current.entries.length,
                          builder: (context, state) {
                            return CustomTab(
                              icon: Icons.history,
                              text: 'Historial',
                              badge: state.entries.length.toString(),
                              isSelected: tabController.index == 2,
                              onTap: () => tabController.animateTo(2),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
