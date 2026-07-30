import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StopwatchProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón Play/Pause
            FloatingActionButton.large(
              onPressed: provider.toggleTimer,
              backgroundColor:
                  provider.isRunning ? Colors.red.shade600 : Colors.green.shade600,
              child: Icon(
                provider.isRunning ? Icons.pause : Icons.play_arrow,
                size: 36,
              ),
            ),
            const SizedBox(width: 24),
            // Botón Reset
            FloatingActionButton.large(
              onPressed: provider.resetTimer,
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.stop, size: 36),
            ),
          ],
        );
      },
    );
  }
}
