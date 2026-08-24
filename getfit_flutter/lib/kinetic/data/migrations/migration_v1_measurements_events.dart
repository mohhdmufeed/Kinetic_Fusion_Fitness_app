import 'package:drift/drift.dart';
import '../migration.dart';

/// Migration V1: Core Tables for Measurement System, Event Ledger, and Derived State Separation
class MigrationV1MeasurementsEvents extends Migration {
  @override
  int get version => 1;

  @override
  String get name => 'create_measurements_events_and_derived_layers';

  @override
  Future<void> up(QueryExecutor executor) async {
    // 1. RAW MEASUREMENTS (Generalized, metric-agnostic table)
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_measurements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        metric TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT NOT NULL,
        quality TEXT NOT NULL, -- 'observed', 'estimated', 'stale', 'missing', 'unreliable'
        is_stale INTEGER NOT NULL DEFAULT 0,
        is_estimated INTEGER NOT NULL DEFAULT 0,
        metadata_json TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_measurements_user_metric_time 
      ON kinetic_measurements (user_id, metric, timestamp);
    ''');

    // 2. IMMUTABLE EVENT HISTORY LOG
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        payload_json TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_events_user_type_time 
      ON kinetic_events (user_id, event_type, timestamp);
    ''');

    // 3. DERIVED FEATURES LAYER (RAW -> FEATURE)
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_derived_features (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        feature_name TEXT NOT NULL,
        value REAL NOT NULL,
        window_start TEXT,
        window_end TEXT,
        source_raw_ids_json TEXT NOT NULL DEFAULT '[]',
        calculated_at TEXT NOT NULL
      );
    ''');

    // 4. LATENT STATE ESTIMATES (FEATURE -> ESTIMATE)
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_state_estimates (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        state_name TEXT NOT NULL, -- 'recovery', 'fatigue', 'readiness', 'adaptation'
        score REAL NOT NULL,
        confidence REAL NOT NULL,
        contributing_factors_json TEXT NOT NULL DEFAULT '[]',
        estimated_at TEXT NOT NULL,
        model_version TEXT NOT NULL
      );
    ''');

    // 5. PREDICTIONS LAYER (ESTIMATE -> PREDICTION)
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_predictions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        prediction_type TEXT NOT NULL,
        predicted_value REAL NOT NULL,
        target_timestamp TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        model_version TEXT NOT NULL
      );
    ''');

    // 6. RECOMMENDATIONS LAYER (PREDICTION -> RECOMMENDATION)
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_recommendations (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        action TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1,
        headline TEXT NOT NULL,
        rationale TEXT NOT NULL,
        evidence_json TEXT NOT NULL DEFAULT '[]',
        model_version TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(QueryExecutor executor) async {
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_recommendations;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_predictions;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_state_estimates;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_derived_features;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_events;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_measurements;');
  }
}
