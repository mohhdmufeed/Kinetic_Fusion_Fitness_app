import 'package:drift/drift.dart';

/// Contract for a versioned, reversible database migration
abstract class Migration {
  /// Unique incrementing version number (e.g. 1, 2, 3)
  int get version;

  /// Human-readable descriptor for the migration
  String get name;

  /// Forward migration: applies schema changes
  Future<void> up(QueryExecutor executor);

  /// Backward migration: cleanly reverses schema changes
  Future<void> down(QueryExecutor executor);
}

/// Central registry of available migrations in ascending order
class MigrationRegistry {
  final List<Migration> _migrations = [];

  MigrationRegistry();

  /// Registers a new migration
  void register(Migration migration) {
    if (_migrations.any((m) => m.version == migration.version)) {
      throw ArgumentError('Migration version ${migration.version} is already registered.');
    }
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Retrieves all registered migrations
  List<Migration> get migrations => List.unmodifiable(_migrations);

  /// Maximum version available in the registry
  int get latestVersion => _migrations.isEmpty ? 0 : _migrations.last.version;

  /// Retrieves a migration by version
  Migration? getByVersion(int version) {
    try {
      return _migrations.firstWhere((m) => m.version == version);
    } catch (_) {
      return null;
    }
  }
}
