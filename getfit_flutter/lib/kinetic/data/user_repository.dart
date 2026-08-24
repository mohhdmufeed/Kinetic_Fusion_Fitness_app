import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';

class UserRepository {
  final QueryExecutor executor;

  UserRepository(this.executor);

  /// Inserts a new user into the database
  Future<void> createUser(KineticUser user) async {
    await executor.runCustom('''
      INSERT INTO kinetic_users (
        id, created_at, updated_at, sex, age, height_cm, weight_kg, units, timezone, preferences_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      user.id,
      user.createdAt.toIso8601String(),
      user.updatedAt.toIso8601String(),
      user.sex,
      user.age,
      user.heightCm,
      user.weightKg,
      user.units,
      user.timezone,
      jsonEncode(user.preferences),
    ]);
  }

  /// Updates an existing user in the database
  Future<void> updateUser(KineticUser user) async {
    await executor.runCustom('''
      UPDATE kinetic_users SET
        updated_at = ?,
        sex = ?,
        age = ?,
        height_cm = ?,
        weight_kg = ?,
        units = ?,
        timezone = ?,
        preferences_json = ?
      WHERE id = ?;
    ''', [
      DateTime.now().toIso8601String(),
      user.sex,
      user.age,
      user.heightCm,
      user.weightKg,
      user.units,
      user.timezone,
      jsonEncode(user.preferences),
      user.id,
    ]);
  }

  /// Retrieves a user by their unique ID
  Future<KineticUser?> getUser(String id) async {
    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_users WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  KineticUser _mapRow(Map<String, dynamic> row) {
    Map<String, dynamic> prefs = {};
    try {
      prefs = jsonDecode(row['preferences_json'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    return KineticUser(
      id: row['id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      sex: row['sex'] as String?,
      age: row['age'] as int?,
      heightCm: (row['height_cm'] as num?)?.toDouble(),
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
      units: row['units'] as String? ?? 'metric',
      timezone: row['timezone'] as String? ?? 'UTC',
      preferences: prefs,
    );
  }
}
