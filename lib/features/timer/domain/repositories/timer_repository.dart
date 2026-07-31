abstract class TimerRepository {
  Future<int> getLastSelectedSeconds();
  Future<void> saveLastSelectedSeconds(int seconds);
}
