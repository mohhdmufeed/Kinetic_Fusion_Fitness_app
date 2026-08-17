import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../constants.dart';

class WgerApiClient {
  late final Dio _dio;

  WgerApiClient(String? token) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBase,
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  // ── Auth ─────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final r = await _dio.get('/gym/userconfig/');
      return r.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Exercises ─────────────────────────────────

  Future<List<dynamic>> fetchExercises({int offset = 0, int limit = 100}) async {
    final r = await _dio.get('/exercise/', queryParameters: {
      'format': 'json',
      'language': 2, // English
      'offset': offset,
      'limit': limit,
    });
    return (r.data['results'] as List?) ?? [];
  }

  Future<List<dynamic>> fetchExerciseTranslations({int offset = 0}) async {
    final r = await _dio.get('/exerciseinfo/', queryParameters: {
      'format': 'json',
      'language': 2,
      'offset': offset,
      'limit': 100,
    });
    return (r.data['results'] as List?) ?? [];
  }

  // ── Routines ──────────────────────────────────

  Future<List<dynamic>> fetchRoutines() async {
    final r = await _dio.get('/routine/');
    return (r.data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> createRoutine(
      String name, String description) async {
    final r = await _dio
        .post('/routine/', data: {'name': name, 'description': description});
    return r.data as Map<String, dynamic>;
  }

  // ── Workout Logs ──────────────────────────────

  Future<List<dynamic>> fetchWorkoutLogs({String? since}) async {
    final r = await _dio.get('/workoutlog/', queryParameters: {
      'format': 'json',
      if (since != null) 'date__gte': since,
    });
    return (r.data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> postWorkoutLog(
      Map<String, dynamic> log) async {
    final r = await _dio.post('/workoutlog/', data: log);
    return r.data as Map<String, dynamic>;
  }

  // ── Ingredients ───────────────────────────────

  Future<List<dynamic>> fetchIngredients(
      {int offset = 0, int limit = 100}) async {
    final r = await _dio.get('/ingredient/', queryParameters: {
      'format': 'json',
      'offset': offset,
      'limit': limit,
    });
    return (r.data['results'] as List?) ?? [];
  }

  // ── Nutrition ─────────────────────────────────

  Future<List<dynamic>> fetchNutritionPlans() async {
    final r = await _dio.get('/nutritionplan/');
    return (r.data['results'] as List?) ?? [];
  }

  Future<List<dynamic>> fetchNutritionDiary({String? since}) async {
    final r = await _dio.get('/nutritiondiary/', queryParameters: {
      'format': 'json',
      if (since != null) 'datetime__gte': since,
    });
    return (r.data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> postNutritionDiary(
      Map<String, dynamic> entry) async {
    final r = await _dio.post('/nutritiondiary/', data: entry);
    return r.data as Map<String, dynamic>;
  }

  // ── Weight ────────────────────────────────────

  Future<List<dynamic>> fetchWeightEntries({String? since}) async {
    final r = await _dio.get('/weightentry/', queryParameters: {
      'format': 'json',
      if (since != null) 'date__gte': since,
    });
    return (r.data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> postWeightEntry(
      Map<String, dynamic> entry) async {
    final r = await _dio.post('/weightentry/', data: entry);
    return r.data as Map<String, dynamic>;
  }

  // ── Measurements ──────────────────────────────

  Future<List<dynamic>> fetchMeasurements() async {
    final r = await _dio.get('/measurement/');
    return (r.data['results'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> postMeasurement(
      Map<String, dynamic> entry) async {
    final r = await _dio.post('/measurement/', data: entry);
    return r.data as Map<String, dynamic>;
  }
}

final apiClientProvider = FutureProvider<WgerApiClient>((ref) async {
  final token = await ref.read(authServiceProvider).getToken();
  return WgerApiClient(token);
});
