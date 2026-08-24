import 'package:drift/drift.dart';
import '../migration.dart';

/// Migration V2: Schema tables for Users, Goals, Exercises, Sessions, Prescriptions, and Sets
class MigrationV2DomainModels extends Migration {
  @override
  int get version => 2;

  @override
  String get name => 'create_domain_models_tables';

  @override
  Future<void> up(QueryExecutor executor) async {
    // 1. KINETIC USERS
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_users (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sex TEXT,
        age INTEGER,
        height_cm REAL,
        weight_kg REAL,
        units TEXT NOT NULL DEFAULT 'metric',
        timezone TEXT NOT NULL DEFAULT 'UTC',
        preferences_json TEXT NOT NULL DEFAULT '{}'
      );
    ''');

    // 2. KINETIC GOALS
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL, -- hypertrophy, strength, endurance, etc.
        priority INTEGER NOT NULL DEFAULT 1,
        target_value REAL,
        target_metric TEXT,
        deadline TEXT,
        constraints_json TEXT NOT NULL DEFAULT '{}',
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES kinetic_users (id) ON DELETE CASCADE
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_goals_user_active
      ON kinetic_goals (user_id, is_active);
    ''');

    // 3. KINETIC EXERCISES
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        movement_pattern TEXT NOT NULL, -- squat, hinge, etc.
        primary_muscles_json TEXT NOT NULL DEFAULT '[]',
        secondary_muscles_json TEXT NOT NULL DEFAULT '[]',
        equipment_json TEXT NOT NULL DEFAULT '[]',
        default_rest_seconds REAL NOT NULL DEFAULT 90.0,
        is_compound INTEGER NOT NULL DEFAULT 1,
        difficulty TEXT NOT NULL DEFAULT 'medium'
      );
    ''');

    // 4. KINETIC SESSIONS
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        goal TEXT NOT NULL,
        focus TEXT NOT NULL,
        average_rpe REAL,
        training_load REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'planned', -- 'planned', 'in_progress', 'completed', 'cancelled'
        estimated_duration_minutes INTEGER,
        FOREIGN KEY (user_id) REFERENCES kinetic_users (id) ON DELETE CASCADE
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_sessions_user_status
      ON kinetic_sessions (user_id, status);
    ''');

    // 5. KINETIC PRESCRIPTIONS
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_prescriptions (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        target_load_kg REAL NOT NULL,
        target_rpe REAL NOT NULL DEFAULT 8.0,
        rest_seconds INTEGER NOT NULL DEFAULT 90,
        tempo TEXT NOT NULL DEFAULT '2-0-1-0',
        priority INTEGER NOT NULL DEFAULT 1,
        reason_code TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES kinetic_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES kinetic_exercises (id) ON DELETE CASCADE
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_prescriptions_session
      ON kinetic_prescriptions (session_id);
    ''');

    // 6. KINETIC SETS
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS kinetic_sets (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        prescribed_load_kg REAL NOT NULL,
        actual_load_kg REAL NOT NULL,
        prescribed_reps INTEGER NOT NULL,
        actual_reps INTEGER NOT NULL,
        target_rpe REAL NOT NULL,
        actual_rpe REAL NOT NULL,
        rest_seconds INTEGER NOT NULL DEFAULT 90,
        timestamp TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (session_id) REFERENCES kinetic_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES kinetic_exercises (id) ON DELETE CASCADE
      );
    ''');

    await executor.runCustom('''
      CREATE INDEX IF NOT EXISTS idx_sets_session_exercise
      ON kinetic_sets (session_id, exercise_id);
    ''');
  }

  @override
  Future<void> down(QueryExecutor executor) async {
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_sets;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_prescriptions;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_sessions;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_exercises;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_goals;');
    await executor.runCustom('DROP TABLE IF EXISTS kinetic_users;');
  }
}
