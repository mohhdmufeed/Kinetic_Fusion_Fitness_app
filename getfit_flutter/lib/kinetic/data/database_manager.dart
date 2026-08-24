import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'migration.dart';
import 'backup.dart';

/// Database Manager handling connections, transactions, schema migrations, and backups
class KineticDatabaseManager implements BackupService {
  final DatabaseConnection connection;
  final MigrationRegistry registry;
  final bool isInMemory;

  KineticDatabaseManager({
    required this.connection,
    required this.registry,
    this.isInMemory = false,
  });

  /// Factory creating an isolated in-memory database instance for testing
  factory KineticDatabaseManager.inMemory({MigrationRegistry? registry}) {
    return KineticDatabaseManager(
      connection: DatabaseConnection(NativeDatabase.memory(logStatements: false)),
      registry: registry ?? MigrationRegistry(),
      isInMemory: true,
    );
  }

  QueryExecutor get executor => connection.executor;

  /// Ensures database connection is open and migrations ledger table exists
  Future<void> initialize() async {
    await executor.ensureOpen(_KineticManagerAgent());
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS _kinetic_migrations (
        version INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at TEXT NOT NULL
      );
    ''');
  }

  /// Returns the current maximum applied schema version
  Future<int> getCurrentVersion() async {
    await initialize();
    final result = await executor.runSelect(
      'SELECT MAX(version) as current_version FROM _kinetic_migrations;',
      [],
    );
    if (result.isEmpty || result.first['current_version'] == null) {
      return 0;
    }
    return result.first['current_version'] as int;
  }

  /// Migrates database schema to a specified [targetVersion]
  /// Supports both forward migration (up) and rollback (down)
  Future<void> migrateTo(int targetVersion) async {
    await initialize();
    int current = await getCurrentVersion();

    if (targetVersion > current) {
      // Forward migration (UP)
      for (final migration in registry.migrations) {
        if (migration.version > current && migration.version <= targetVersion) {
          await transaction((tx) async {
            await migration.up(tx);
            await tx.runCustom(
              'INSERT INTO _kinetic_migrations (version, name, applied_at) VALUES (?, ?, ?);',
              [migration.version, migration.name, DateTime.now().toIso8601String()],
            );
          });
        }
      }
    } else if (targetVersion < current) {
      // Rollback migration (DOWN)
      final reversed = registry.migrations.reversed.toList();
      for (final migration in reversed) {
        if (migration.version <= current && migration.version > targetVersion) {
          await transaction((tx) async {
            await migration.down(tx);
            await tx.runCustom(
              'DELETE FROM _kinetic_migrations WHERE version = ?;',
              [migration.version],
            );
          });
        }
      }
    }
  }

  /// Migrates database to the highest available migration version
  Future<void> migrateToLatest() async {
    await migrateTo(registry.latestVersion);
  }

  /// Executes [action] inside an atomic transaction.
  /// If [action] throws an error, the transaction automatically rolls back.
  Future<T> transaction<T>(Future<T> Function(QueryExecutor tx) action) async {
    await initialize();
    // Drift native database supports nested/atomic transactions
    return executor.runCustom('BEGIN TRANSACTION;').then((_) async {
      try {
        final result = await action(executor);
        await executor.runCustom('COMMIT;');
        return result;
      } catch (e) {
        await executor.runCustom('ROLLBACK;');
        rethrow;
      }
    });
  }

  /// Deterministic test reset: drops all tables, purges ledger, and re-migrates to clean latest state
  Future<void> resetToCleanState() async {
    await initialize();
    // Query all SQLite user tables (ignoring sqlite_ system tables)
    final tables = await executor.runSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      [],
    );

    // Disable foreign keys during purge
    await executor.runCustom('PRAGMA foreign_keys = OFF;');
    for (final row in tables) {
      final name = row['name'] as String;
      await executor.runCustom('DROP TABLE IF EXISTS $name;');
    }
    await executor.runCustom('PRAGMA foreign_keys = ON;');

    // Re-initialize ledger and migrate to latest version
    await initialize();
    await migrateToLatest();
  }

  @override
  Future<DatabaseSnapshot> exportSnapshot() async {
    await initialize();
    final tablesMeta = await executor.runSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != '_kinetic_migrations';",
      [],
    );

    final Map<String, List<Map<String, dynamic>>> dump = {};
    for (final row in tablesMeta) {
      final name = row['name'] as String;
      final rows = await executor.runSelect('SELECT * FROM $name;', []);
      dump[name] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }

    final currentVer = await getCurrentVersion();
    return DatabaseSnapshot(
      schemaVersion: currentVer,
      exportedAt: DateTime.now(),
      tables: dump,
    );
  }

  @override
  Future<void> importSnapshot(DatabaseSnapshot snapshot) async {
    await resetToCleanState();
    await migrateTo(snapshot.schemaVersion);

    for (final entry in snapshot.tables.entries) {
      final tableName = entry.key;
      final rows = entry.value;
      if (rows.isEmpty) continue;

      for (final row in rows) {
        final columns = row.keys.join(', ');
        final placeholders = row.keys.map((_) => '?').join(', ');
        final values = row.values.toList();

        await executor.runCustom(
          'INSERT INTO $tableName ($columns) VALUES ($placeholders);',
          values,
        );
      }
    }
  }

  /// Closes database connection
  Future<void> close() async {
    await connection.executor.close();
  }
}

class _KineticManagerAgent extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
