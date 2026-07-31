import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';
import 'package:flutter/services.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onSave;
  final int localElapsedTime;

  const ControlButtons({super.key, required this.onSave, required this.localElapsedTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<StopwatchCubit, StopwatchState>(
      builder: (context, state) {
        final isRunning = state.status == StopwatchStatus.running;
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón Iniciar/Pausar
                SizedBox(
                  width: 140,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (isRunning) {
                         context.read<StopwatchCubit>().pauseTimer(exactElapsedTime: localElapsedTime);
                      } else {
                         final isPipEnabled = context.read<SettingsProvider>().isPipEnabled;
                         context.read<StopwatchCubit>().startTimer(isPipEnabled: isPipEnabled);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isRunning
                              ? theme.colorScheme.outline
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isRunning ? Icons.pause : Icons.play_arrow),
                        const SizedBox(width: 8),
                        Text(
                          isRunning ? 'Pausar' : 'Iniciar',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Botón Guardar
                SizedBox(
                  width: 140,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (localElapsedTime > 0 || state.elapsedTime > 0)
                        ? () {
                            HapticFeedback.mediumImpact();
                            onSave();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (localElapsedTime > 0 || state.elapsedTime > 0)
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<StopwatchCubit>().resetTimer();
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Reiniciar cronómetro'),
              ),
          ],
        );
      },
    );
  }
}
