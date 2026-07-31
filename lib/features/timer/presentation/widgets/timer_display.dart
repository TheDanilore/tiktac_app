import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_cubit.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_state.dart';

import 'package:flutter/cupertino.dart';

void _showTimePicker(BuildContext context, TimerCubit cubit) {
  Duration tempDuration = Duration(seconds: cubit.state.initialSeconds > 0 ? cubit.state.initialSeconds : 0);

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext builder) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      cubit.setTime(tempDuration.inSeconds);
                      Navigator.pop(context);
                    },
                    child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    pickerTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                    ),
                  ),
                ),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: tempDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    tempDuration = newDuration;
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: BlocBuilder<TimerCubit, TimerState>(
                builder: (context, state) {
                  final cubit = context.read<TimerCubit>();
                  final initialSeconds = state.initialSeconds;
                  final progress = cubit.progress;
                  
                  return CircularProgressIndicator(
                    value: initialSeconds > 0 ? progress : 1.0,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state is TimerFinished && initialSeconds > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary,
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<TimerCubit, TimerState>(
              builder: (context, state) {
                final cubit = context.read<TimerCubit>();
                final isRunning = state is TimerRunning;
                final formattedTime = cubit.formattedTime;
                final initialSeconds = state.initialSeconds;
                
                return GestureDetector(
                  onTap: isRunning ? null : () {
                    _showTimePicker(context, cubit);
                  },
                  child: Text(
                    formattedTime,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: state is TimerFinished && initialSeconds > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        BlocBuilder<TimerCubit, TimerState>(
          builder: (context, state) {
            if (state is TimerInitial) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _TimeButton(minutes: 1, label: '+1m', onTap: () => context.read<TimerCubit>().addTime(1)),
                  _TimeButton(minutes: 5, label: '+5m', onTap: () => context.read<TimerCubit>().addTime(5)),
                  _TimeButton(minutes: 10, label: '+10m', onTap: () => context.read<TimerCubit>().addTime(10)),
                  _TimeButton(minutes: 25, label: '+25m', onTap: () => context.read<TimerCubit>().addTime(25)),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 32),
        BlocBuilder<TimerCubit, TimerState>(
          builder: (context, state) {
            if (state is TimerFinished) {
              return ElevatedButton.icon(
                onPressed: () => context.read<TimerCubit>().stopAlarm(),
                icon: const Icon(Icons.alarm_off, size: 28),
                label: const Text('Parar Alarma', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              );
            } else {
              final isRunning = state is TimerRunning;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'timer_play_pause',
                    onPressed: () => context.read<TimerCubit>().toggle(),
                    backgroundColor: isRunning ? theme.colorScheme.error : theme.colorScheme.primary,
                    child: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'timer_stop',
                    onPressed: () => context.read<TimerCubit>().resetTimer(),
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    child: const Icon(Icons.stop),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final int minutes;
  final String label;
  final VoidCallback onTap;

  const _TimeButton({required this.minutes, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
