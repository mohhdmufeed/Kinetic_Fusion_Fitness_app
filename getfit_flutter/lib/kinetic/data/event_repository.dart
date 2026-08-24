import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';

/// Repository for the immutable append-only event ledger
class EventRepository {
  final QueryExecutor executor;

  EventRepository(this.executor);

  /// Appends an event to the immutable ledger
  Future<void> appendEvent(KineticEvent event) async {
    await executor.runCustom('''
      INSERT INTO kinetic_events (
        id, user_id, event_type, timestamp, payload_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?);
    ''', [
      event.id,
      event.userId,
      event.eventType,
      event.timestamp.toIso8601String(),
      jsonEncode(event.payload),
      DateTime.now().toIso8601String(),
    ]);
  }

  /// Retrieves events filtered by event type and user
  Future<List<KineticEvent>> getEvents({
    required String userId,
    String? eventType,
    DateTime? from,
    DateTime? to,
  }) async {
    final List<String> whereClauses = ['user_id = ?'];
    final List<dynamic> args = [userId];

    if (eventType != null) {
      whereClauses.add('event_type = ?');
      args.add(eventType);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      args.add(to.toIso8601String());
    }

    final sql = '''
      SELECT * FROM kinetic_events 
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY timestamp ASC;
    ''';

    final rows = await executor.runSelect(sql, args);
    return rows.map((r) {
      Map<String, dynamic> payload = {};
      try {
        payload = jsonDecode(r['payload_json'] as String? ?? '{}') as Map<String, dynamic>;
      } catch (_) {}

      return KineticEvent(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        eventType: r['event_type'] as String,
        timestamp: DateTime.parse(r['timestamp'] as String),
        payload: payload,
      );
    }).toList();
  }
}
