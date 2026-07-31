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
  int _currentLocalElapsedTime = 0;

  @override
  void initState() {
    super.initState();
    // Leer tiempo inicial si ya está corriendo o pausado
    _currentLocalElapsedTime = context.read<StopwatchCubit>().state.elapsedTime;
  }

  void _onTimeTick(int time) {
    _currentLocalElapsedTime = time;
  }

  void _showSaveModal() {
    SaveActivityModal.show(
      context, 
      finalElapsedTime: _currentLocalElapsedTime,
      onSaved: () {},
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
            ControlButtons(
              onSave: _showSaveModal,
              localElapsedTime: _currentLocalElapsedTime,
            ),
          ],
        ),
      ),
    );
  }
}
