import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:flutter/services.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onSave;

  const ControlButtons({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<StopwatchProvider>(
      builder: (context, provider, child) {
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
                      provider.toggleTimer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isRunning
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: provider.isRunning
                              ? theme.colorScheme.outline
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(provider.isRunning ? Icons.pause : Icons.play_arrow),
                        const SizedBox(width: 8),
                        Text(
                          provider.isRunning ? 'Pausar' : 'Iniciar',
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
                    onPressed: provider.elapsedTime > 0
                        ? () {
                            HapticFeedback.mediumImpact();
                            onSave();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: const Color(0xFF75B798),
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
            if (provider.elapsedTime > 0)
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.resetTimer();
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
