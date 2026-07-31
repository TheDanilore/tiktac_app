import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';

class StopwatchDisplay extends StatelessWidget {
  const StopwatchDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<StopwatchProvider>(
      builder: (context, provider, child) {
        final timeParts = provider.formattedTime.split('.');
        final mainTime = timeParts[0]; // e.g., 00:00
        final milliseconds = timeParts.length > 1 ? '.${timeParts[1]}' : '';

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  mainTime,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  milliseconds,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: provider.isRunning ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isRunning ? 'EN PROGRESO' : (provider.elapsedTime > 0 ? 'PAUSADO' : 'LISTO PARA INICIAR'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: provider.isRunning
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
