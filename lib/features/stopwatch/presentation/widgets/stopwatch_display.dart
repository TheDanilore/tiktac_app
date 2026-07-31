import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';

class StopwatchDisplay extends StatefulWidget {
  final Function(int) onTimeTick;
  
  const StopwatchDisplay({super.key, required this.onTimeTick});

  @override
  State<StopwatchDisplay> createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends State<StopwatchDisplay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  int _localElapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final state = context.read<StopwatchCubit>().state;
      if (state.status == StopwatchStatus.running && state.startMillis != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _localElapsedTime = state.elapsedTime + (now - state.startMillis!);
        });
        widget.onTimeTick(_localElapsedTime);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _formatTime(int millisecondsTotal) {
    final hours = (millisecondsTotal ~/ 3600000).toString().padLeft(2, '0');
    final minutes = ((millisecondsTotal ~/ 60000) % 60).toString().padLeft(2, '0');
    final seconds = ((millisecondsTotal ~/ 1000) % 60).toString().padLeft(2, '0');
    final milliseconds = ((millisecondsTotal ~/ 10) % 100).toString().padLeft(2, '0');
    
    if (millisecondsTotal >= 3600000) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<StopwatchCubit, StopwatchState>(
      listenWhen: (previous, current) => previous.status != current.status || previous.elapsedTime != current.elapsedTime,
      listener: (context, state) {
        if (state.status == StopwatchStatus.running) {
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
          setState(() {
            _localElapsedTime = state.elapsedTime;
          });
        }
      },
      builder: (context, state) {
        // En primer renderizado, asegurar que muestra el tiempo correcto si ya corría.
        if (state.status == StopwatchStatus.running && state.startMillis != null && !_ticker.isActive) {
           _ticker.start();
        }
        
        final displayTime = state.status == StopwatchStatus.running ? _localElapsedTime : state.elapsedTime;
        final formattedTime = _formatTime(displayTime);
        final timeParts = formattedTime.split('.');
        final mainTime = timeParts[0]; 
        final millisecondsStr = timeParts.length > 1 ? '.${timeParts[1]}' : '';
        final isRunning = state.status == StopwatchStatus.running;

        return Column(
          children: [
            RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      mainTime,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      millisecondsStr,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isRunning ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isRunning ? 'EN PROGRESO' : (displayTime > 0 ? 'PAUSADO' : 'LISTO PARA INICIAR'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isRunning
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
