import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/timer_provider.dart';

import 'package:flutter/cupertino.dart';

void _showTimePicker(BuildContext context, TimerProvider provider) {
  Duration tempDuration = Duration(seconds: provider.initialSeconds);

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
                      provider.setTime(tempDuration.inSeconds);
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
    return Consumer<TimerProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: provider.initialSeconds > 0 ? provider.progress : 1.0,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      provider.secondsRemaining == 0 && provider.initialSeconds > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: provider.isRunning ? null : () {
                    _showTimePicker(context, provider);
                  },
                  child: Text(
                    provider.formattedTime,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: provider.secondsRemaining == 0 && provider.initialSeconds > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!provider.isRunning && provider.secondsRemaining == 0 && !provider.isAlarmRinging)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _TimeButton(minutes: 1, label: '+1m', onTap: () => provider.addTime(1)),
                  _TimeButton(minutes: 5, label: '+5m', onTap: () => provider.addTime(5)),
                  _TimeButton(minutes: 10, label: '+10m', onTap: () => provider.addTime(10)),
                  _TimeButton(minutes: 25, label: '+25m', onTap: () => provider.addTime(25)),
                ],
              ),
            const SizedBox(height: 32),
            if (provider.isAlarmRinging)
              ElevatedButton.icon(
                onPressed: () => provider.stopAlarm(),
                icon: const Icon(Icons.alarm_off, size: 28),
                label: const Text('Parar Alarma', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'timer_play_pause',
                    onPressed: () => provider.toggle(context),
                    backgroundColor: provider.isRunning ? theme.colorScheme.error : theme.colorScheme.primary,
                    child: Icon(provider.isRunning ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'timer_stop',
                    onPressed: () => provider.resetTimer(),
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    child: const Icon(Icons.stop),
                  ),
                ],
              ),
          ],
        );
      },
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
