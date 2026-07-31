abstract class TimerState {
  final int initialSeconds;
  const TimerState(this.initialSeconds);
}

class TimerInitial extends TimerState {
  final int lastSelectedSeconds;

  const TimerInitial(super.initialSeconds, this.lastSelectedSeconds);
}

class TimerRunning extends TimerState {
  final int secondsRemaining;

  const TimerRunning(super.initialSeconds, this.secondsRemaining);
}

class TimerPaused extends TimerState {
  final int secondsRemaining;

  const TimerPaused(super.initialSeconds, this.secondsRemaining);
}

class TimerFinished extends TimerState {
  const TimerFinished(super.initialSeconds);
}
