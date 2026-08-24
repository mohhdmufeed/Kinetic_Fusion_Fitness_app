import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Database schema version
const int kKineticSchemaVersion = 1;

/// SQLite Connection and Migration Manager for Kinetic Precision
class KineticDatabaseConnection {
  final DatabaseConnection _connection;
  final bool isInMemory;

  KineticDatabaseConnection._(this._connection, {this.isInMemory = false});

  /// Creates an in-memory SQLite connection (ideal for isolated unit & smoke tests)
  factory KineticDatabaseConnection.inMemory() {
    return KineticDatabaseConnection._(
      DatabaseConnection(NativeDatabase.memory(logStatements: false)),
      isInMemory: true,
    );
  }

  /// Verifies SQLite connectivity and executes initial schema migrations
  Future<bool> connectAndMigrate() async {
    final executor = _connection.executor;
    await executor.ensureOpen(_KineticUserAgent());

    // Execute migration v1
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS _kinetic_schema_version (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      );
    ''');

    await executor.runCustom('''
      INSERT OR IGNORE INTO _kinetic_schema_version (version, applied_at)
      VALUES ($kKineticSchemaVersion, '${DateTime.now().toIso8601String()}');
    ''');

    // Run smoke health check table
    await executor.runCustom('''
      CREATE TABLE IF NOT EXISTS _kinetic_smoke_health (
        id TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        checked_at TEXT NOT NULL
      );
    ''');

    await executor.runCustom('''
      INSERT OR REPLACE INTO _kinetic_smoke_health (id, status, checked_at)
      VALUES ('health_check_01', 'HEALTHY', '${DateTime.now().toIso8601String()}');
    ''');

    // Query back to verify read/write capability
    final result = await executor.runSelect(
      "SELECT status FROM _kinetic_smoke_health WHERE id = 'health_check_01';",
      [],
    );

    return result.isNotEmpty && result.first['status'] == 'HEALTHY';
  }

  /// Closes database connection
  Future<void> close() async {
    await _connection.executor.close();
  }
}

class _KineticUserAgent extends QueryExecutorUser {
  @override
  int get schemaVersion => kKineticSchemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
