// App-wide constants
class AppConstants {
  static const String baseUrl = 'https://apk--production.up.railway.app';
  static const String apiBase = '$baseUrl/api/v2';

  // Local storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Sync settings
  static const int syncIntervalMinutes = 30;
  static const String syncTaskName = 'getfit_background_sync';
}
