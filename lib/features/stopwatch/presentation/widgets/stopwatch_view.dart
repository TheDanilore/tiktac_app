import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/stopwatch_display.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/control_buttons.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/save_activity_modal.dart';

class StopwatchView extends StatefulWidget {
  const StopwatchView({super.key});

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView> {
  late final ValueNotifier<int> _timeNotifier;

  @override
  void initState() {
    super.initState();
    final initialTime = context.read<StopwatchCubit>().state.elapsedTime;
    _timeNotifier = ValueNotifier<int>(initialTime);
  }

  @override
  void dispose() {
    _timeNotifier.dispose();
    super.dispose();
  }

  void _onTimeTick(int time) {
    _timeNotifier.value = time;
  }

  void _showSaveModal() {
    SaveActivityModal.show(
      context, 
      finalElapsedTime: _timeNotifier.value,
      onSaved: () {
        _timeNotifier.value = 0;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StopwatchDisplay(
              onTimeTick: _onTimeTick,
            ),
            const SizedBox(height: 64),
            ValueListenableBuilder<int>(
              valueListenable: _timeNotifier,
              builder: (context, currentLocalTime, _) {
                return ControlButtons(
                  onSave: _showSaveModal,
                  localElapsedTime: currentLocalTime,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
