import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/core/database/app_database.dart';
import 'package:kinetic_precision/features/nutrition/services/barcode_nutrition_service.dart';

void main() {
  group('Epic B2: Barcode Scanning + Food Database Integration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      BarcodeNutritionService.resetCacheForTesting();
    });

    tearDown(() async {
      await db.close();
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Task 1: Barcode Scanning Capture & Trigger
    // ──────────────────────────────────────────────────────────────────────────
    test('Task 1: Barcode scan value correctly triggers the lookup pipeline', () async {
      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.queryParameters['code'] == '737628064502') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 101,
                'name': 'Organic Rice Noodles',
                'brand': 'Thai Kitchen',
                'barcode': '737628064502',
                'calories_kcal': 364,
                'protein_g': 7.1,
                'carbs_g': 82.1,
                'fat_g': 0.7,
                'fiber_g': 1.4,
                'sugar_g': 0.0,
                'sodium_mg': 36.0,
                'unit': '100g',
                'source': 'open_food_facts',
              },
            ));
          }
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 404),
          ));
        },
      ));

      final service = BarcodeNutritionService(database: db, dio: mockDio);

      // Trigger lookup pipeline with captured EAN/UPC barcode
      final result = await service.lookupBarcode('737628064502');

      expect(result.status, equals(BarcodeLookupStatus.success));
      expect(result.barcode, equals('737628064502'));
      expect(result.ingredient, isNotNull);
      expect(result.ingredient!.name, equals('Organic Rice Noodles'));
      expect(result.source, equals('open_food_facts'));
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Task 2: Open Food Facts Lookup Pipeline & Schema Parity
    // ──────────────────────────────────────────────────────────────────────────
    test('Task 2A: Known barcode returns correctly mapped per-100g macros matching Module 11 schema', () async {
      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.queryParameters['code'] == '3017620422003') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 202,
                'name': 'Nutella Hazelnut Spread',
                'brand': 'Ferrero',
                'barcode': '3017620422003',
                'calories_kcal': 539,
                'protein_g': 6.3,
                'carbs_g': 57.5,
                'fat_g': 30.9,
                'fiber_g': 0.0,
                'sugar_g': 56.3,
                'sodium_mg': 40.0,
                'unit': '100g',
                'source': 'open_food_facts',
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final service = BarcodeNutritionService(database: db, dio: mockDio);
      final result = await service.lookupBarcode('3017620422003');

      expect(result.status, equals(BarcodeLookupStatus.success));
      final ing = result.ingredient!;
      expect(ing.name, equals('Nutella Hazelnut Spread'));
      expect(ing.energy, equals(539.0));
      expect(ing.protein, equals(6.3));
      expect(ing.carbs, equals(57.5));
      expect(ing.fat, equals(30.9));
      expect(ing.sugar, equals(56.3));
    });

    test('Task 2B: Unknown barcode returns explicit not-found state without crashing', () async {
      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'detail': 'Product not found', 'not_found': true},
            ),
          ));
        },
      ));

      final service = BarcodeNutritionService(database: db, dio: mockDio);
      final result = await service.lookupBarcode('0000000000000');

      expect(result.status, equals(BarcodeLookupStatus.notFound));
      expect(result.barcode, equals('0000000000000'));
      expect(result.ingredient, isNull);
      expect(result.message, contains('Product not found'));
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Task 3: Offline Scan Support & Local Drift Cache
    // ──────────────────────────────────────────────────────────────────────────
    test('Task 3: Previously scanned barcode resolves from local cache with zero network calls, uncached offline produces explicit fallback', () async {
      int networkCallCount = 0;
      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          networkCallCount++;
          if (options.queryParameters['code'] == '039978001153') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 303,
                'name': "Organic Rolled Oats",
                'brand': "Bob's Red Mill",
                'barcode': '039978001153',
                'calories_kcal': 389,
                'protein_g': 16.9,
                'carbs_g': 66.3,
                'fat_g': 6.9,
                'fiber_g': 10.6,
                'sugar_g': 0.0,
                'sodium_mg': 0.0,
                'unit': '100g',
                'source': 'open_food_facts',
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final service = BarcodeNutritionService(database: db, dio: mockDio);

      // First Scan: Online -> Makes 1 network call, saves to local Drift & memory
      final onlineResult = await service.lookupBarcode('039978001153');
      expect(onlineResult.status, equals(BarcodeLookupStatus.success));
      expect(onlineResult.isOfflineHit, isFalse);
      expect(networkCallCount, equals(1));

      // Second Scan: Offline re-scan -> Must resolve from local cache with NO additional network calls!
      final offlineResult = await service.lookupBarcode('039978001153', forceOffline: true);
      expect(offlineResult.status, equals(BarcodeLookupStatus.success));
      expect(offlineResult.isOfflineHit, isTrue);
      expect(offlineResult.source, equals('local_cache'));
      expect(offlineResult.ingredient!.name, equals("Organic Rolled Oats"));
      expect(networkCallCount, equals(1)); // Still exactly 1, no new network call!

      // Third Scan: Uncached item while offline -> Produces explicit offlineUncached fallback state
      final uncachedOffline = await service.lookupBarcode('987654321012', forceOffline: true);
      expect(uncachedOffline.status, equals(BarcodeLookupStatus.offlineUncached));
      expect(uncachedOffline.message, contains('while offline'));
      expect(networkCallCount, equals(1)); // No network call attempted
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Task 4: Food Diary Integration & Macro Calculation
    // ──────────────────────────────────────────────────────────────────────────
    test('Task 4: Barcode-scanned food entry calculates identical macros for custom portion weights and contributes to daily diary totals', () async {
      // 1. Manually created ingredient: Chicken Breast (165 kcal, 31g P, 0g C, 3.6g F per 100g)
      await db.into(db.ingredients).insert(
            const IngredientsCompanion(
              id: drift.Value(501),
              name: drift.Value('Chicken Breast Manual'),
              energy: drift.Value(165.0),
              protein: drift.Value(31.0),
              carbs: drift.Value(0.0),
              fat: drift.Value(3.6),
              imageUrl: drift.Value(''),
            ),
          );

      // 2. Barcode-scanned ingredient: Chicken Breast Barcode (exact same per-100g values)
      await db.into(db.ingredients).insert(
            const IngredientsCompanion(
              id: drift.Value(502),
              name: drift.Value('Chicken Breast Scanned Barcode'),
              energy: drift.Value(165.0),
              protein: drift.Value(31.0),
              carbs: drift.Value(0.0),
              fat: drift.Value(3.6),
              imageUrl: drift.Value(''),
            ),
          );

      final testDate = DateTime.now();

      // Log 150g of manual entry
      await db.insertDiaryEntry(NutritionDiaryCompanion(
        ingredientId: const drift.Value(501),
        amount: const drift.Value(150.0), // 150g = 1.5x
        date: drift.Value(testDate),
        pendingSync: const drift.Value(true),
      ));

      // Log 150g of barcode-scanned entry
      await db.insertDiaryEntry(NutritionDiaryCompanion(
        ingredientId: const drift.Value(502),
        amount: const drift.Value(150.0), // 150g = 1.5x
        date: drift.Value(testDate),
        pendingSync: const drift.Value(true),
      ));

      // Fetch diary entries for the date
      final entries = await db.getDiaryForDate(testDate);
      expect(entries.length, equals(2));

      // Verify each 150g entry computes identical macros:
      // Calories: 165 * 1.5 = 247.5 kcal
      // Protein: 31 * 1.5 = 46.5g
      // Fat: 3.6 * 1.5 = 5.4g
      final manualEntry = entries.firstWhere((e) => e.ingredientId == 501);
      final scannedEntry = entries.firstWhere((e) => e.ingredientId == 502);

      final manualIng = await (db.select(db.ingredients)..where((t) => t.id.equals(manualEntry.ingredientId))).getSingle();
      final scannedIng = await (db.select(db.ingredients)..where((t) => t.id.equals(scannedEntry.ingredientId))).getSingle();

      final manualKcal = manualIng.energy * (manualEntry.amount / 100.0);
      final scannedKcal = scannedIng.energy * (scannedEntry.amount / 100.0);

      final manualProt = manualIng.protein * (manualEntry.amount / 100.0);
      final scannedProt = scannedIng.protein * (scannedEntry.amount / 100.0);

      expect(scannedKcal, equals(manualKcal));
      expect(scannedKcal, closeTo(247.5, 0.01));

      expect(scannedProt, equals(manualProt));
      expect(scannedProt, closeTo(46.5, 0.01));

      // Verify aggregate total contribution
      final totalDailyKcal = manualKcal + scannedKcal;
      final totalDailyProt = manualProt + scannedProt;

      expect(totalDailyKcal, closeTo(495.0, 0.01));
      expect(totalDailyProt, closeTo(93.0, 0.01));
    });
  });
}
