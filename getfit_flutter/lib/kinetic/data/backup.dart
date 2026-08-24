import 'dart:convert';

/// Snapshot container for database backup and export
class DatabaseSnapshot {
  final int schemaVersion;
  final DateTime exportedAt;
  final Map<String, List<Map<String, dynamic>>> tables;

  const DatabaseSnapshot({
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'tables': tables,
      };

  factory DatabaseSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTables = json['tables'] as Map<String, dynamic>? ?? {};
    final tables = <String, List<Map<String, dynamic>>>{};

    rawTables.forEach((tableName, rows) {
      if (rows is List) {
        tables[tableName] = rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      }
    });

    return DatabaseSnapshot(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now(),
      tables: tables,
    );
  }

  String toSerializedJson() => jsonEncode(toJson());
}

/// Abstract contract for database backup and export operations
abstract class BackupService {
  /// Exports full database snapshot to a structured object
  Future<DatabaseSnapshot> exportSnapshot();

  /// Restores a snapshot into the local database
  Future<void> importSnapshot(DatabaseSnapshot snapshot);
}
