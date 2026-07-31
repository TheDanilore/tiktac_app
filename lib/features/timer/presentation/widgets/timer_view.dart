import 'package:flutter/material.dart';
import 'package:tiktac_app/features/timer/presentation/widgets/timer_display.dart';

class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: const TimerDisplay()),
      ],
    );
  }
}
