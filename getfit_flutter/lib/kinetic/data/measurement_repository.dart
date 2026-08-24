import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';

/// Repository for generalized measurements and raw observation data quality
class MeasurementRepository {
  final QueryExecutor executor;

  MeasurementRepository(this.executor);

  /// Inserts a raw measurement with full quality metadata
  Future<void> recordMeasurement(Measurement m) async {
    final isStale = m.quality == DataQuality.stale ? 1 : 0;
    final isEstimated = m.quality == DataQuality.estimated ? 1 : 0;

    await executor.runCustom('''
      INSERT INTO kinetic_measurements (
        id, user_id, metric, value, unit, timestamp, source, quality, is_stale, is_estimated, metadata_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      m.id,
      m.userId,
      m.metric,
      m.value,
      m.unit,
      m.timestamp.toIso8601String(),
      m.source,
      m.quality.name,
      isStale,
      isEstimated,
      jsonEncode(m.metadata),
      DateTime.now().toIso8601String(),
    ]);
  }

  /// Inserts a batch of measurements atomically
  Future<void> recordBatch(List<Measurement> batch) async {
    for (final m in batch) {
      await recordMeasurement(m);
    }
  }

  /// Retrieves measurements filtered by metric and optional date range
  Future<List<Measurement>> getMeasurements({
    required String userId,
    String? metric,
    DateTime? from,
    DateTime? to,
    bool includeStale = true,
  }) async {
    final List<String> whereClauses = ['user_id = ?'];
    final List<dynamic> args = [userId];

    if (metric != null) {
      whereClauses.add('metric = ?');
      args.add(metric);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      args.add(to.toIso8601String());
    }
    if (!includeStale) {
      whereClauses.add('is_stale = 0');
    }

    final sql = '''
      SELECT * FROM kinetic_measurements 
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY timestamp ASC;
    ''';

    final rows = await executor.runSelect(sql, args);
    return rows.map((r) => _mapRow(r)).toList();
  }

  /// Retrieves a measurement by its unique ID
  Future<Measurement?> getById(String id) async {
    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_measurements WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  /// Maps a SQLite row to the Measurement domain model
  Measurement _mapRow(Map<String, dynamic> row) {
    DataQuality quality = DataQuality.observed;
    try {
      quality = DataQuality.values.byName(row['quality'] as String);
    } catch (_) {}

    Map<String, dynamic> meta = {};
    try {
      meta = jsonDecode(row['metadata_json'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    return Measurement(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      metric: row['metric'] as String,
      value: (row['value'] as num).toDouble(),
      unit: row['unit'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      source: row['source'] as String,
      quality: quality,
      metadata: meta,
    );
  }
}
