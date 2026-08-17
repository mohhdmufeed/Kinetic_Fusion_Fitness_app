import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../constants.dart';
import '../database/app_database.dart';

class SyncService {
  final AppDatabase _db;
  final AuthService _auth;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SyncService(this._db, this._auth);

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
  }

  Future<void> sync() async {
    if (!await _isOnline()) return;
    if (!await _auth.isLoggedIn()) return;

    final token = await _auth.getToken();
    final api = WgerApiClient(token);

    try {
      await _uploadPendingWorkoutLogs(api);
      await _uploadPendingDiaryEntries(api);
      await _uploadPendingWeightEntries(api);
      await _downloadExercises(api);
      await _downloadIngredients(api);
      await _downloadWeightEntries(api);
      await _downloadNutritionDiary(api);

      // Save last sync time
      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _storage.write(key: AppConstants.lastSyncKey, value: now);
    } catch (e) {
      // Sync failed silently — data is safe locally
      rethrow;
    }
  }

  // ── UPLOAD ───────────────────────────────────

  Future<void> _uploadPendingWorkoutLogs(WgerApiClient api) async {
    final pending = await _db.getPendingWorkoutLogs();
    for (final log in pending) {
      try {
        final resp = await api.postWorkoutLog({
          'exercise': log.exerciseId,
          'reps': log.reps,
          'weight': log.weight,
          'date': DateFormat('yyyy-MM-dd').format(log.date),
        });
        final serverId = resp['id'] as int?;
        await (_db.update(_db.workoutLogs)
              ..where((t) => t.id.equals(log.id)))
            .write(WorkoutLogsCompanion(
          pendingSync: const Value(false),
          serverId: Value(serverId),
        ));
      } catch (_) {
        // keep pending, will retry next sync
      }
    }
  }

  Future<void> _uploadPendingDiaryEntries(WgerApiClient api) async {
    final pending = await _db.getPendingDiaryEntries();
    for (final entry in pending) {
      try {
        final resp = await api.postNutritionDiary({
          'ingredient': entry.ingredientId,
          'amount': entry.amount,
          'datetime': entry.date.toIso8601String(),
          if (entry.planId != null) 'plan': entry.planId,
        });
        final serverId = resp['id'] as int?;
        await (_db.update(_db.nutritionDiary)
              ..where((t) => t.id.equals(entry.id)))
            .write(NutritionDiaryCompanion(
          pendingSync: const Value(false),
          serverId: Value(serverId),
        ));
      } catch (_) {}
    }
  }

  Future<void> _uploadPendingWeightEntries(WgerApiClient api) async {
    final pending = await _db.getPendingWeightEntries();
    for (final entry in pending) {
      try {
        final resp = await api.postWeightEntry({
          'weight': entry.weight,
          'date': DateFormat('yyyy-MM-dd').format(entry.date),
        });
        final serverId = resp['id'] as int?;
        await (_db.update(_db.weightEntries)
              ..where((t) => t.id.equals(entry.id)))
            .write(WeightEntriesCompanion(
          pendingSync: const Value(false),
          serverId: Value(serverId),
        ));
      } catch (_) {}
    }
  }

  // ── DOWNLOAD ─────────────────────────────────

  Future<void> _downloadExercises(WgerApiClient api) async {
    // Only sync if we have no exercises yet (or force refresh)
    final existing = await _db.getAllExercises();
    if (existing.length > 100) return; // already seeded

    int offset = 0;
    while (true) {
      final items = await api.fetchExerciseTranslations(offset: offset);
      if (items.isEmpty) break;
      for (final item in items) {
        try {
          final translations =
              (item['translations'] as List?) ?? [];
          final en = translations.firstWhere(
            (t) => t['language'] == 2,
            orElse: () => translations.isNotEmpty ? translations.first : null,
          );
          if (en == null) continue;
          final category = (item['category'] as Map?)?['name'] ?? '';
          final muscles = (item['muscles'] as List?)
                  ?.map((m) => m['name_en'] ?? m['name'])
                  .toList()
                  .toString() ??
              '[]';
          final equipment = (item['equipment'] as List?)
                  ?.map((e) => e['name'])
                  .toList()
                  .toString() ??
              '[]';
          await _db.into(_db.exercises).insertOnConflictUpdate(
                ExercisesCompanion(
                  id: Value(item['id'] as int),
                  uuid: Value(item['uuid'] as String? ?? ''),
                  name: Value(en['name'] as String? ?? 'Unknown'),
                  description: Value(en['description'] as String? ?? ''),
                  category: Value(category),
                  muscles: Value(muscles),
                  equipment: Value(equipment),
                ),
              );
        } catch (_) {}
      }
      offset += items.length;
      if (items.length < 100) break;
    }
  }

  Future<void> _downloadIngredients(WgerApiClient api) async {
    final existing = await _db.searchIngredients('');
    if (existing.length > 100) return;

    int offset = 0;
    while (true) {
      final items = await api.fetchIngredients(offset: offset);
      if (items.isEmpty) break;
      for (final item in items) {
        try {
          await _db.into(_db.ingredients).insertOnConflictUpdate(
                IngredientsCompanion(
                  id: Value(item['id'] as int),
                  name: Value(item['name'] as String? ?? 'Unknown'),
                  energy: Value(
                      double.tryParse(item['energy']?.toString() ?? '0') ?? 0),
                  protein: Value(
                      double.tryParse(item['protein']?.toString() ?? '0') ?? 0),
                  carbs: Value(double.tryParse(
                          item['carbohydrates']?.toString() ?? '0') ??
                      0),
                  fat: Value(
                      double.tryParse(item['fat']?.toString() ?? '0') ?? 0),
                ),
              );
        } catch (_) {}
      }
      offset += items.length;
      if (items.length < 100) break;
    }
  }

  Future<void> _downloadWeightEntries(WgerApiClient api) async {
    final lastSync = await _storage.read(key: AppConstants.lastSyncKey);
    final items = await api.fetchWeightEntries(since: lastSync);
    for (final item in items) {
      try {
        await _db.into(_db.weightEntries).insertOnConflictUpdate(
              WeightEntriesCompanion(
                serverId: Value(item['id'] as int),
                weight: Value(
                    double.tryParse(item['weight']?.toString() ?? '0') ?? 0),
                date: Value(DateTime.tryParse(item['date'] ?? '') ?? DateTime.now()),
                pendingSync: const Value(false),
              ),
            );
      } catch (_) {}
    }
  }

  Future<void> _downloadNutritionDiary(WgerApiClient api) async {
    final lastSync = await _storage.read(key: AppConstants.lastSyncKey);
    final items = await api.fetchNutritionDiary(since: lastSync);
    for (final item in items) {
      try {
        await _db.into(_db.nutritionDiary).insertOnConflictUpdate(
              NutritionDiaryCompanion(
                serverId: Value(item['id'] as int),
                ingredientId: Value(item['ingredient'] as int),
                amount: Value(
                    double.tryParse(item['amount']?.toString() ?? '100') ??
                        100),
                date: Value(DateTime.tryParse(item['datetime'] ?? '') ?? DateTime.now()),
                pendingSync: const Value(false),
              ),
            );
      } catch (_) {}
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.read(databaseProvider);
  final auth = ref.read(authServiceProvider);
  return SyncService(db, auth);
});
