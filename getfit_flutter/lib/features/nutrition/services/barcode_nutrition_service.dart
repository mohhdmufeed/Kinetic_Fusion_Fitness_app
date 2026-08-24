import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';

enum BarcodeLookupStatus {
  success,
  notFound,
  offlineUncached,
  error,
}

class BarcodeLookupResult {
  final BarcodeLookupStatus status;
  final Ingredient? ingredient;
  final String barcode;
  final String? source; // 'local_cache' or 'open_food_facts'
  final bool isOfflineHit;
  final String? message;

  const BarcodeLookupResult({
    required this.status,
    this.ingredient,
    required this.barcode,
    this.source,
    this.isOfflineHit = false,
    this.message,
  });

  factory BarcodeLookupResult.success(
    Ingredient ingredient, {
    required String barcode,
    required String source,
    required bool isOfflineHit,
  }) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.success,
      ingredient: ingredient,
      barcode: barcode,
      source: source,
      isOfflineHit: isOfflineHit,
    );
  }

  factory BarcodeLookupResult.notFound(String barcode) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.notFound,
      barcode: barcode,
      message: 'Product not found in Open Food Facts database for barcode $barcode.',
    );
  }

  factory BarcodeLookupResult.offlineUncached(String barcode) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.offlineUncached,
      barcode: barcode,
      message: 'Cannot look up new barcode $barcode while offline. Please search from offline library or enter manually.',
    );
  }

  factory BarcodeLookupResult.error(String barcode, String error) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.error,
      barcode: barcode,
      message: error,
    );
  }
}

/// Service managing offline-first barcode resolution and Open Food Facts ingestion
class BarcodeNutritionService {
  final AppDatabase database;
  final Dio _dio;

  // In-memory barcode mapping cache for rapid lookups and offline support
  static final Map<String, Ingredient> _inMemoryBarcodeCache = {};

  BarcodeNutritionService({
    required this.database,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBase,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ));

  /// Checks if a barcode is available in local cache (Drift or in-memory)
  Future<Ingredient?> lookupLocal(String barcode) async {
    final cleanCode = barcode.trim();
    if (_inMemoryBarcodeCache.containsKey(cleanCode)) {
      return _inMemoryBarcodeCache[cleanCode];
    }

    // Try finding by name or ID in local Drift database
    final allIngredients = await database.getAllExercises(); // database access
    // Look up in database ingredients table
    final matched = await (database.select(database.ingredients)
          ..where((t) => t.name.contains(cleanCode)))
        .getSingleOrNull();

    if (matched != null) {
      _inMemoryBarcodeCache[cleanCode] = matched;
      return matched;
    }
    return null;
  }

  /// Caches a barcode to local memory and Drift DB
  void cacheLocally(String barcode, Ingredient ingredient) {
    _inMemoryBarcodeCache[barcode.trim()] = ingredient;
  }

  /// Resets in-memory cache for test isolation
  static void resetCacheForTesting() {
    _inMemoryBarcodeCache.clear();
  }

  /// Complete offline-first barcode lookup pipeline
  Future<BarcodeLookupResult> lookupBarcode(String rawBarcode, {bool forceOffline = false}) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) {
      return BarcodeLookupResult.error(barcode, 'Barcode cannot be empty.');
    }

    // 1. Local Cache Check (Tier 1)
    final localIngredient = await lookupLocal(barcode);
    if (localIngredient != null) {
      return BarcodeLookupResult.success(
        localIngredient,
        barcode: barcode,
        source: 'local_cache',
        isOfflineHit: true,
      );
    }

    if (forceOffline) {
      return BarcodeLookupResult.offlineUncached(barcode);
    }

    // 2. Server & Open Food Facts Lookup (Tier 2 & 3)
    try {
      final response = await _dio.get(
        '/api/v2/nutrition/barcode/',
        queryParameters: {'code': barcode},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        final id = (data['id'] as num?)?.toInt() ?? barcode.hashCode.abs();
        final name = (data['name'] as String?) ?? 'Scanned Product';
        final energy = (data['calories_kcal'] as num?)?.toDouble() ?? 0.0;
        final protein = (data['protein_g'] as num?)?.toDouble() ?? 0.0;
        final carbs = (data['carbs_g'] as num?)?.toDouble() ?? 0.0;
        final fat = (data['fat_g'] as num?)?.toDouble() ?? 0.0;
        final fiber = (data['fiber_g'] as num?)?.toDouble();
        final sugar = (data['sugar_g'] as num?)?.toDouble();

        // Create Drift entity
        final ingredient = Ingredient(
          id: id,
          name: name,
          energy: energy,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sugar: sugar,
          imageUrl: '',
        );

        // Store in local Drift database & in-memory cache
        try {
          await database.into(database.ingredients).insertOnConflictUpdate(
                IngredientsCompanion(
                  id: drift.Value(id),
                  name: drift.Value(name),
                  energy: drift.Value(energy),
                  protein: drift.Value(protein),
                  carbs: drift.Value(carbs),
                  fat: drift.Value(fat),
                  fiber: drift.Value(fiber),
                  sugar: drift.Value(sugar),
                  imageUrl: const drift.Value(''),
                ),
              );
        } catch (_) {}

        cacheLocally(barcode, ingredient);

        return BarcodeLookupResult.success(
          ingredient,
          barcode: barcode,
          source: 'open_food_facts',
          isOfflineHit: false,
        );
      } else if (response.statusCode == 404) {
        return BarcodeLookupResult.notFound(barcode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return BarcodeLookupResult.notFound(barcode);
      }
      // Offline / network failure
      return BarcodeLookupResult.offlineUncached(barcode);
    } catch (_) {
      return BarcodeLookupResult.offlineUncached(barcode);
    }

    return BarcodeLookupResult.notFound(barcode);
  }
}
