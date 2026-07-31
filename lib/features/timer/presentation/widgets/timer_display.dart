import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_cubit.dart';
import 'package:tiktac_app/features/timer/presentation/blocs/timer_state.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_cubit.dart';
import 'dart:ui';

void _showTimePicker(BuildContext context, TimerCubit cubit) {
  Duration tempDuration = Duration(seconds: cubit.state.initialSeconds > 0 ? cubit.state.initialSeconds : 0);

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (BuildContext builder) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                    ),
                    FilledButton(
                      onPressed: () {
                        cubit.setTime(tempDuration.inSeconds);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptative sizing for the circle (thumb friendly)
        double maxCircleSize = constraints.maxWidth > 500 ? 400.0 : constraints.maxWidth * 0.75;
        // Check if there is enough height, otherwise scale down
        if (maxCircleSize > constraints.maxHeight * 0.5) {
          maxCircleSize = constraints.maxHeight * 0.5;
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Hero Element: Time Circle
            _buildHeroCircle(context, maxCircleSize, theme),
            
            const Spacer(),
            
            // Control Island (Play/Stop & Quick Buttons)
            _buildControlIsland(context, theme),
            
            const SizedBox(height: 24),
          ],
        );
      }
    );
  }
  
  Widget _buildHeroCircle(BuildContext context, double size, ThemeData theme) {
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final cubit = context.read<TimerCubit>();
        final initialSeconds = state.initialSeconds;
        final progress = cubit.progress;
        final isFinished = state is TimerFinished && initialSeconds > 0;
        final isRunning = state is TimerRunning;
        
        Color ringColor = isFinished ? theme.colorScheme.error : theme.colorScheme.primary;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow effect
            if (isRunning || isFinished)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withOpacity(isFinished ? 0.3 : 0.15),
                      blurRadius: isFinished ? 60 : 30,
                      spreadRadius: isFinished ? 15 : 0,
                    ),
                  ],
                ),
              ),
              
            // Progress Indicator
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: progress, end: progress),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: initialSeconds > 0 ? value : 1.0,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round, // Premium touch
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  );
                }
              ),
            ),
            
            // Time Text
            GestureDetector(
              onTap: isRunning ? null : () => _showTimePicker(context, cubit),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cubit.formattedTime,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800, // Thicker font
                          fontFamily: 'monospace',
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isFinished ? theme.colorScheme.error : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (!isRunning && !isFinished) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.edit_rounded, color: theme.colorScheme.onSurfaceVariant, size: 28),
                      ]
                    ],
                  ),
                  if (initialSeconds > 0 && !isFinished)
                     Text(
                      isRunning ? 'Tiempo restante' : 'Toca para editar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlIsland(BuildContext context, ThemeData theme) {
    return BlocBuilder<TimerCubit, TimerState>(
      buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is TimerFinished) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.read<TimerCubit>().stopAlarm(),
                icon: const Icon(Icons.alarm_off, size: 32),
                label: const Text('Silenciar Alarma', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
          );
        }

        final isRunning = state is TimerRunning;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spacer to balance the Stop button
                  if (state is! TimerInitial) 
                    const SizedBox(width: 64), 
                    
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    width: 80,
                    child: FloatingActionButton.large(
                      heroTag: 'timer_play_pause',
                      elevation: isRunning ? 2 : 8,
                      onPressed: () {
                        final isPipEnabled = context.read<SettingsCubit>().state.isPipEnabled;
                        context.read<TimerCubit>().toggle(isPipEnabled: isPipEnabled);
                      },
                      backgroundColor: isRunning ? theme.colorScheme.secondaryContainer : theme.colorScheme.primary,
                      foregroundColor: isRunning ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: child.key == const ValueKey('icon1') 
                              ? Tween<double>(begin: 0.5, end: 1).animate(anim)
                              : Tween<double>(begin: 0.5, end: 1).animate(anim), 
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: Icon(
                          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey(isRunning ? 'icon1' : 'icon2'),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  
                  if (state is! TimerInitial) ...[
                    const SizedBox(width: 24),
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: FloatingActionButton(
                        heroTag: 'timer_stop',
                        elevation: 0,
                        onPressed: () => context.read<TimerCubit>().resetTimer(),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.stop_rounded, size: 28),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Quick Buttons (only when stopped)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: state is TimerInitial ? Column(
                  children: [
                    const SizedBox(height: 24),
                    Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuickBtn(context, theme, 1, '+1m'),
                          const SizedBox(width: 12),
                          _buildQuickBtn(context, theme, 5, '+5m'),
                          const SizedBox(width: 12),
                          _buildQuickBtn(context, theme, 10, '+10m'),
                          const SizedBox(width: 12),
                          _buildQuickBtn(context, theme, 25, '+25m'),
                        ],
                      ),
                    ),
                  ],
                ) : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickBtn(BuildContext context, ThemeData theme, int minutes, String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => context.read<TimerCubit>().addTime(minutes),
    );
  }
}
