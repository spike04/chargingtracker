abstract final class AppConstants {
  static const String appName = 'Charging Tracker';
  static const String databaseName = 'charging_tracker.db';
  static const int databaseVersion = 2;
  static const String sessionsTable = 'charging_sessions';

  static const int targetFastCharges = 4;
  static const int targetSlowCharges = 1;
  static const int cycleLength = targetFastCharges + targetSlowCharges;
}
