import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models.dart';

enum OuraConnectionStatus {
  disconnected,
  connected,
  expired,
  revoked,
}

/// Ingestion client for Oura Ring v2 API conforming strictly to raw physiological data extraction
class OuraService {
  final FlutterSecureStorage _storage;
  static const String _accessTokenKey = 'oura_access_token';
  static const String _refreshTokenKey = 'oura_refresh_token';
  static const String _tokenExpiryKey = 'oura_token_expiry';

  OuraConnectionStatus _status = OuraConnectionStatus.disconnected;
  OuraConnectionStatus get status => _status;

  OuraService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Saves OAuth2 token securely using platform-level encryption
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _tokenExpiryKey, value: expiresAt.toIso8601String());
    _status = OuraConnectionStatus.connected;
  }

  /// Checks active OAuth status and validates token expiry
  Future<OuraConnectionStatus> checkConnectionStatus() async {
    final token = await _storage.read(key: _accessTokenKey);
    final expiryStr = await _storage.read(key: _tokenExpiryKey);

    if (token == null || expiryStr == null) {
      _status = OuraConnectionStatus.disconnected;
      return _status;
    }

    try {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().toUtc().isAfter(expiry)) {
        _status = OuraConnectionStatus.expired;
        return _status;
      }
    } catch (_) {
      _status = OuraConnectionStatus.expired;
      return _status;
    }

    _status = OuraConnectionStatus.connected;
    return _status;
  }

  /// Revokes Oura connection and purges stored credentials
  Future<void> revokeConnection() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    _status = OuraConnectionStatus.revoked;
  }

  /// Sets status directly for testing
  void setStatusForTesting(OuraConnectionStatus status) {
    _status = status;
  }

  /// Ingests raw Oura physiological samples (Extracts RAW physiological signals ONLY — NO opinionated scores)
  Future<List<Measurement>> readRawMetrics({
    required String userId,
    required DateTime start,
    required DateTime end,
    List<Map<String, dynamic>>? mockOuraDailyDocuments,
  }) async {
    if (_status == OuraConnectionStatus.disconnected ||
        _status == OuraConnectionStatus.expired ||
        _status == OuraConnectionStatus.revoked) {
      return [];
    }

    final List<Measurement> measurements = [];

    if (mockOuraDailyDocuments != null) {
      for (final doc in mockOuraDailyDocuments) {
        final timestamp = doc['day'] != null
            ? DateTime.parse(doc['day'] as String).toUtc()
            : DateTime.now().toUtc();

        // 1. Raw Average Nocturnal HRV (rMSSD in milliseconds)
        if (doc['average_hrv'] != null) {
          final hrvVal = (doc['average_hrv'] as num).toDouble();
          measurements.add(Measurement(
            id: 'oura_hrv_${timestamp.millisecondsSinceEpoch}',
            userId: userId,
            metric: 'hrv_rmssd',
            value: hrvVal,
            unit: 'ms',
            timestamp: timestamp,
            source: 'oura',
            quality: DataQuality.observed,
            metadata: {'source': 'Oura Ring v2', 'type': 'nocturnal_rmssd'},
          ));
        }

        // 2. Raw Lowest / Resting Heart Rate (bpm)
        if (doc['lowest_heart_rate'] != null || doc['resting_heart_rate'] != null) {
          final hrVal = ((doc['lowest_heart_rate'] ?? doc['resting_heart_rate']) as num).toDouble();
          measurements.add(Measurement(
            id: 'oura_rhr_${timestamp.millisecondsSinceEpoch}',
            userId: userId,
            metric: 'rhr',
            value: hrVal,
            unit: 'bpm',
            timestamp: timestamp,
            source: 'oura',
            quality: DataQuality.observed,
            metadata: {'source': 'Oura Ring v2', 'type': 'lowest_resting_hr'},
          ));
        }

        // 3. Raw Total Sleep Duration (converted from seconds to hours)
        if (doc['total_sleep_duration'] != null) {
          final seconds = (doc['total_sleep_duration'] as num).toDouble();
          final hours = seconds / 3600.0;
          measurements.add(Measurement(
            id: 'oura_sleep_${timestamp.millisecondsSinceEpoch}',
            userId: userId,
            metric: 'sleep_duration_hrs',
            value: double.parse(hours.toStringAsFixed(2)),
            unit: 'hours',
            timestamp: timestamp,
            source: 'oura',
            quality: DataQuality.observed,
            metadata: {'source': 'Oura Ring v2', 'type': 'total_sleep_duration'},
          ));
        }

        // 4. Raw Steps
        if (doc['steps'] != null) {
          final stepsVal = (doc['steps'] as num).toDouble();
          measurements.add(Measurement(
            id: 'oura_steps_${timestamp.millisecondsSinceEpoch}',
            userId: userId,
            metric: 'steps',
            value: stepsVal,
            unit: 'count',
            timestamp: timestamp,
            source: 'oura',
            quality: DataQuality.observed,
            metadata: {'source': 'Oura Ring v2', 'type': 'daily_steps'},
          ));
        }

        // NOTE: Oura's proprietary 'readiness_score', 'sleep_score', or 'activity_score' is intentionally IGNORED
        // per specification to preserve engine autonomy and avoid double-counting opinions.
      }
    }

    return measurements;
  }
}
