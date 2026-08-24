import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/backup.dart';

// ── Sample Test Migrations (Forward & Backward) ──

class MigrationV1 extends Migration {
  @override
  int get version => 1;
  @override
  String get name => 'create_test_items_table';

  @override
  Future<void> up(QueryExecutor executor) async {
    await executor.runCustom('''
      CREATE TABLE test_items (
        id TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(QueryExecutor executor) async {
    await executor.runCustom('DROP TABLE IF EXISTS test_items;');
  }
}

class MigrationV2 extends Migration {
  @override
  int get version => 2;
  @override
  String get name => 'create_test_tags_table';

  @override
  Future<void> up(QueryExecutor executor) async {
    await executor.runCustom('''
      CREATE TABLE test_tags (
        id TEXT PRIMARY KEY,
        tag_name TEXT NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(QueryExecutor executor) async {
    await executor.runCustom('DROP TABLE IF EXISTS test_tags;');
  }
}

void main() {
  late MigrationRegistry registry;
  late KineticDatabaseManager dbManager;

  setUp(() {
    registry = MigrationRegistry();
    registry.register(MigrationV1());
    registry.register(MigrationV2());
    dbManager = KineticDatabaseManager.inMemory(registry: registry);
  });

  tearDown(() async {
    await dbManager.close();
  });

  group('Local Data Layer — Migration Infrastructure', () {
    test('Initial schema version is 0 before migrations are executed', () async {
      final version = await dbManager.getCurrentVersion();
      expect(version, equals(0));
    });

    test('Forward migration (UP): migrates step-by-step to version 1 and version 2', () async {
      // Migrate to V1
      await dbManager.migrateTo(1);
      expect(await dbManager.getCurrentVersion(), equals(1));

      // Verify test_items exists by inserting and selecting
      await dbManager.executor.runCustom("INSERT INTO test_items (id, value) VALUES ('item_1', 100);");
      final items = await dbManager.executor.runSelect("SELECT * FROM test_items WHERE id = 'item_1';", []);
      expect(items.first['value'], equals(100));

      // Migrate to V2
      await dbManager.migrateTo(2);
      expect(await dbManager.getCurrentVersion(), equals(2));

      // Verify test_tags exists
      await dbManager.executor.runCustom("INSERT INTO test_tags (id, tag_name) VALUES ('tag_1', 'cardio');");
      final tags = await dbManager.executor.runSelect("SELECT * FROM test_tags WHERE id = 'tag_1';", []);
      expect(tags.first['tag_name'], equals('cardio'));
    });

    test('Backward migration (DOWN / ROLLBACK): rolls back from version 2 to 1 and down to 0', () async {
      // Migrate to latest (v2)
      await dbManager.migrateToLatest();
      expect(await dbManager.getCurrentVersion(), equals(2));

      // Rollback to v1
      await dbManager.migrateTo(1);
      expect(await dbManager.getCurrentVersion(), equals(1));

      // Verify test_tags table was dropped during down migration
      final tagTableCheck = await dbManager.executor.runSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='test_tags';",
        [],
      );
      expect(tagTableCheck.isEmpty, isTrue);

      // Verify test_items still exists in v1
      final itemTableCheck = await dbManager.executor.runSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='test_items';",
        [],
      );
      expect(itemTableCheck.isNotEmpty, isTrue);

      // Rollback to v0
      await dbManager.migrateTo(0);
      expect(await dbManager.getCurrentVersion(), equals(0));
    });
  });

  group('Local Data Layer — Transaction Infrastructure', () {
    test('Transaction commits changes on successful execution', () async {
      await dbManager.migrateTo(1);

      await dbManager.transaction((tx) async {
        await tx.runCustom("INSERT INTO test_items (id, value) VALUES ('tx_item_1', 42);");
        await tx.runCustom("INSERT INTO test_items (id, value) VALUES ('tx_item_2', 84);");
      });

      final rows = await dbManager.executor.runSelect('SELECT COUNT(*) as cnt FROM test_items;', []);
      expect(rows.first['cnt'], equals(2));
    });

    test('Transaction automatically rolls back all changes on failure/exception', () async {
      await dbManager.migrateTo(1);

      try {
        await dbManager.transaction((tx) async {
          await tx.runCustom("INSERT INTO test_items (id, value) VALUES ('rollback_item', 99);");
          // Intentionally throw error inside transaction
          throw Exception('Simulated database error during write');
        });
      } catch (_) {}

      // Verify no changes were committed
      final rows = await dbManager.executor.runSelect(
        "SELECT * FROM test_items WHERE id = 'rollback_item';",
        [],
      );
      expect(rows.isEmpty, isTrue, reason: 'Transaction rollback should have discarded uncommitted rows');
    });
  });

  group('Local Data Layer — Clean Test Reset & Snapshot Backup', () {
    test('resetToCleanState() purges all user data and re-migrates to clean schema', () async {
      await dbManager.migrateToLatest();

      // Populate dummy data
      await dbManager.executor.runCustom("INSERT INTO test_items (id, value) VALUES ('dirty_1', 1);");
      await dbManager.executor.runCustom("INSERT INTO test_tags (id, tag_name) VALUES ('dirty_tag', 'hiit');");

      // Execute clean reset
      await dbManager.resetToCleanState();

      // Verify version is latest and tables are completely empty
      expect(await dbManager.getCurrentVersion(), equals(2));
      final items = await dbManager.executor.runSelect('SELECT COUNT(*) as cnt FROM test_items;', []);
      final tags = await dbManager.executor.runSelect('SELECT COUNT(*) as cnt FROM test_tags;', []);
      expect(items.first['cnt'], equals(0));
      expect(tags.first['cnt'], equals(0));
    });

    test('Backup export and import snapshot restores exact database state', () async {
      await dbManager.migrateToLatest();
      await dbManager.executor.runCustom("INSERT INTO test_items (id, value) VALUES ('snapshot_1', 777);");
      await dbManager.executor.runCustom("INSERT INTO test_tags (id, tag_name) VALUES ('tag_snap', 'recovery');");

      // Export snapshot
      final snapshot = await dbManager.exportSnapshot();
      expect(snapshot.schemaVersion, equals(2));
      expect(snapshot.tables['test_items']?.first['value'], equals(777));

      // Reset and import snapshot
      await dbManager.resetToCleanState();
      await dbManager.importSnapshot(snapshot);

      // Verify restored content
      final restoredItem = await dbManager.executor.runSelect("SELECT * FROM test_items WHERE id = 'snapshot_1';", []);
      expect(restoredItem.first['value'], equals(777));
    });
  });
}
