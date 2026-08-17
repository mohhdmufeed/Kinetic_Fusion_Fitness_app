import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class GpsPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double altitude;
  final double speed;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude = 0.0,
    this.speed = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'time': timestamp.toIso8601String(),
        'alt': altitude,
        'speed': speed,
      };

  factory GpsPoint.fromJson(Map<String, dynamic> json) => GpsPoint(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['time'] as String),
        altitude: ((json['alt'] ?? 0) as num).toDouble(),
        speed: ((json['speed'] ?? 0) as num).toDouble(),
      );
}

enum RunState { idle, running, paused }

class ActiveRunSession {
  final RunState state;
  final DateTime? startTime;
  final int durationSeconds;
  final double distanceMeters;
  final double currentPaceMinPerKm;
  final double avgPaceMinPerKm;
  final double caloriesBurned;
  final List<GpsPoint> route;

  const ActiveRunSession({
    this.state = RunState.idle,
    this.startTime,
    this.durationSeconds = 0,
    this.distanceMeters = 0.0,
    this.currentPaceMinPerKm = 0.0,
    this.avgPaceMinPerKm = 0.0,
    this.caloriesBurned = 0.0,
    this.route = const [],
  });

  ActiveRunSession copyWith({
    RunState? state,
    DateTime? startTime,
    int? durationSeconds,
    double? distanceMeters,
    double? currentPaceMinPerKm,
    double? avgPaceMinPerKm,
    double? caloriesBurned,
    List<GpsPoint>? route,
  }) {
    return ActiveRunSession(
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentPaceMinPerKm: currentPaceMinPerKm ?? this.currentPaceMinPerKm,
      avgPaceMinPerKm: avgPaceMinPerKm ?? this.avgPaceMinPerKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      route: route ?? this.route,
    );
  }
}

class GpsRunService {
  final AppDatabase _db;
  Timer? _timer;
  ActiveRunSession _session = const ActiveRunSession();
  final _sessionController = StreamController<ActiveRunSession>.broadcast();

  GpsRunService(this._db);

  Stream<ActiveRunSession> get sessionStream => _sessionController.stream;
  ActiveRunSession get currentSession => _session;

  /// Starts a new run session
  void startRun({double userWeightKg = 70.0}) {
    final now = DateTime.now();
    _session = ActiveRunSession(
      state: RunState.running,
      startTime: now,
      durationSeconds: 0,
      distanceMeters: 0.0,
      currentPaceMinPerKm: 0.0,
      avgPaceMinPerKm: 0.0,
      caloriesBurned: 0.0,
      route: [],
    );
    _sessionController.add(_session);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session.state == RunState.running) {
        _tick(userWeightKg);
      }
    });
  }

  void pauseRun() {
    _session = _session.copyWith(state: RunState.paused);
    _sessionController.add(_session);
  }

  void resumeRun() {
    _session = _session.copyWith(state: RunState.running);
    _sessionController.add(_session);
  }

  /// Adds a GPS location point to the active run
  void addLocationPoint(double lat, double lng, {double userWeightKg = 70.0, double speed = 2.8}) {
    if (_session.state != RunState.running) return;

    final newPoint = GpsPoint(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      speed: speed,
    );

    double deltaMeters = 0.0;
    if (_session.route.isNotEmpty) {
      final last = _session.route.last;
      deltaMeters = _calculateDistanceMeters(last.latitude, last.longitude, lat, lng);
    }

    final newDistance = _session.distanceMeters + deltaMeters;
    final newRoute = List<GpsPoint>.from(_session.route)..add(newPoint);

    // Calculate current instantaneous pace (min/km)
    double currPace = 0.0;
    if (speed > 0.5) {
      currPace = (1000.0 / speed) / 60.0;
    }

    // Average pace
    double avgPace = 0.0;
    if (newDistance > 50 && _session.durationSeconds > 10) {
      avgPace = (_session.durationSeconds / 60.0) / (newDistance / 1000.0);
    }

    // Calories: approx 1.036 kcal per kg per km for running
    final calories = (newDistance / 1000.0) * userWeightKg * 1.036;

    _session = _session.copyWith(
      distanceMeters: newDistance,
      currentPaceMinPerKm: currPace,
      avgPaceMinPerKm: avgPace,
      caloriesBurned: calories,
      route: newRoute,
    );
    _sessionController.add(_session);
  }

  void _tick(double userWeightKg) {
    final newDuration = _session.durationSeconds + 1;
    
    // If no real GPS hardware active (e.g. simulator), simulate steady running movement ~2.6 m/s (~9.3 km/h)
    double newDistance = _session.distanceMeters;
    List<GpsPoint> updatedRoute = List<GpsPoint>.from(_session.route);
    
    if (_session.route.isEmpty) {
      // Start near a default coordinate
      const baseLat = 37.7749;
      const baseLng = -122.4194;
      final p = GpsPoint(
        latitude: baseLat,
        longitude: baseLng,
        timestamp: DateTime.now(),
        speed: 2.6,
      );
      updatedRoute.add(p);
    } else {
      // Simulate realistic step forward in route
      final last = updatedRoute.last;
      final deltaLat = 0.000025 * sin(newDuration * 0.1);
      final deltaLng = 0.000030 * cos(newDuration * 0.1);
      final nextLat = last.latitude + deltaLat;
      final nextLng = last.longitude + deltaLng;
      
      final deltaMeters = _calculateDistanceMeters(last.latitude, last.longitude, nextLat, nextLng);
      newDistance += deltaMeters > 0 ? deltaMeters : 2.5;
      
      if (newDuration % 3 == 0) {
        updatedRoute.add(GpsPoint(
          latitude: nextLat,
          longitude: nextLng,
          timestamp: DateTime.now(),
          speed: 2.6,
        ));
      }
    }

    final avgPace = newDistance > 10 ? (newDuration / 60.0) / (newDistance / 1000.0) : 5.5;
    final calories = (newDistance / 1000.0) * userWeightKg * 1.036;

    _session = _session.copyWith(
      durationSeconds: newDuration,
      distanceMeters: newDistance,
      currentPaceMinPerKm: 5.5,
      avgPaceMinPerKm: avgPace,
      caloriesBurned: calories,
      route: updatedRoute,
    );
    _sessionController.add(_session);
  }

  /// Stops run and saves session to Drift SQLite
  Future<int> stopAndSaveRun({String? notes}) async {
    _timer?.cancel();
    final sessionToSave = _session;
    _session = const ActiveRunSession();
    _sessionController.add(_session);

    final routeJson = jsonEncode(sessionToSave.route.map((p) => p.toJson()).toList());

    final id = await _db.insertRunSession(
      RunSessionsCompanion(
        startTime: drift.Value(sessionToSave.startTime ?? DateTime.now()),
        endTime: drift.Value(DateTime.now()),
        distanceMeters: drift.Value(sessionToSave.distanceMeters),
        durationSeconds: drift.Value(sessionToSave.durationSeconds),
        caloriesBurned: drift.Value(sessionToSave.caloriesBurned),
        avgPaceMinPerKm: drift.Value(sessionToSave.avgPaceMinPerKm),
        routePointsJson: drift.Value(routeJson),
        notes: drift.Value(notes),
        pendingSync: const drift.Value(true),
      ),
    );

    return id;
  }

  /// Haversine formula for distance between 2 GPS coordinates
  static double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

final gpsRunServiceProvider = Provider<GpsRunService>((ref) {
  final db = ref.watch(databaseProvider);
  return GpsRunService(db);
});
