import 'package:flutter/material.dart';
import 'package:tiktac_app/screens/widgets/stopwatch_display.dart';
import 'package:tiktac_app/screens/widgets/control_buttons.dart';
import 'package:tiktac_app/screens/widgets/save_activity_modal.dart';

class StopwatchView extends StatelessWidget {
  const StopwatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StopwatchDisplay(),
            const SizedBox(height: 64),
            ControlButtons(
              onSave: () => SaveActivityModal.show(context, onSaved: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
