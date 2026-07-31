import 'package:flutter/material.dart';
import 'package:tiktac_app/features/history/presentation/widgets/stat_card.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';

class StatsPanel extends StatelessWidget {
  final StopwatchState state;

  const StatsPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final totalCount = state.entries.length;
    final totalTime = state.entries.fold(
      0,
      (sum, entry) => sum + entry.duration,
    );
    final averageTime = totalCount > 0 ? (totalTime ~/ totalCount) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADÍSTICAS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Sesiones',
                  value: totalCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Tiempo total',
                  value: _formatDuration(totalTime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Promedio',
                  value: _formatDuration(averageTime),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds == 0) return '0.0s';
    final hours = (milliseconds ~/ 3600000);
    final minutes = ((milliseconds ~/ 60000) % 60);
    final seconds = ((milliseconds ~/ 1000) % 60);

    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
