import 'dart:convert';
import 'package:drift/drift.dart';

class DerivedFeature {
  final String id;
  final String userId;
  final String featureName;
  final double value;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final List<String> sourceRawIds;
  final DateTime calculatedAt;

  const DerivedFeature({
    required this.id,
    required this.userId,
    required this.featureName,
    required this.value,
    this.windowStart,
    this.windowEnd,
    this.sourceRawIds = const [],
    required this.calculatedAt,
  });
}

class StateEstimate {
  final String id;
  final String userId;
  final String stateName;
  final double score;
  final double confidence;
  final List<String> contributingFactors;
  final DateTime estimatedAt;
  final String modelVersion;

  const StateEstimate({
    required this.id,
    required this.userId,
    required this.stateName,
    required this.score,
    required this.confidence,
    required this.contributingFactors,
    required this.estimatedAt,
    required this.modelVersion,
  });
}

/// Repository for Derived Features, Latent State Estimates, and Predictions
/// Enforces strict separation between raw measurements and derived calculations.
class DerivedStateRepository {
  final QueryExecutor executor;

  DerivedStateRepository(this.executor);

  /// Stores a computed feature derived from raw measurements
  Future<void> saveFeature(DerivedFeature feature) async {
    await executor.runCustom('''
      INSERT INTO kinetic_derived_features (
        id, user_id, feature_name, value, window_start, window_end, source_raw_ids_json, calculated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      feature.id,
      feature.userId,
      feature.featureName,
      feature.value,
      feature.windowStart?.toIso8601String(),
      feature.windowEnd?.toIso8601String(),
      jsonEncode(feature.sourceRawIds),
      feature.calculatedAt.toIso8601String(),
    ]);
  }

  /// Retrieves derived features by name
  Future<List<DerivedFeature>> getFeatures({
    required String userId,
    String? featureName,
  }) async {
    final List<String> where = ['user_id = ?'];
    final List<dynamic> args = [userId];

    if (featureName != null) {
      where.add('feature_name = ?');
      args.add(featureName);
    }

    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_derived_features WHERE ${where.join(' AND ')} ORDER BY calculated_at DESC;',
      args,
    );

    return rows.map((r) {
      List<String> rawIds = [];
      try {
        rawIds = List<String>.from(jsonDecode(r['source_raw_ids_json'] as String? ?? '[]'));
      } catch (_) {}

      return DerivedFeature(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        featureName: r['feature_name'] as String,
        value: (r['value'] as num).toDouble(),
        windowStart: r['window_start'] != null ? DateTime.parse(r['window_start'] as String) : null,
        windowEnd: r['window_end'] != null ? DateTime.parse(r['window_end'] as String) : null,
        sourceRawIds: rawIds,
        calculatedAt: DateTime.parse(r['calculated_at'] as String),
      );
    }).toList();
  }

  /// Stores a latent state estimate
  Future<void> saveStateEstimate(StateEstimate estimate) async {
    await executor.runCustom('''
      INSERT INTO kinetic_state_estimates (
        id, user_id, state_name, score, confidence, contributing_factors_json, estimated_at, model_version
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      estimate.id,
      estimate.userId,
      estimate.stateName,
      estimate.score,
      estimate.confidence,
      jsonEncode(estimate.contributingFactors),
      estimate.estimatedAt.toIso8601String(),
      estimate.modelVersion,
    ]);
  }

  /// Retrieves latent state estimates
  Future<List<StateEstimate>> getStateEstimates({
    required String userId,
    String? stateName,
  }) async {
    final List<String> where = ['user_id = ?'];
    final List<dynamic> args = [userId];

    if (stateName != null) {
      where.add('state_name = ?');
      args.add(stateName);
    }

    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_state_estimates WHERE ${where.join(' AND ')} ORDER BY estimated_at DESC;',
      args,
    );

    return rows.map((r) {
      List<String> factors = [];
      try {
        factors = List<String>.from(jsonDecode(r['contributing_factors_json'] as String? ?? '[]'));
      } catch (_) {}

      return StateEstimate(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        stateName: r['state_name'] as String,
        score: (r['score'] as num).toDouble(),
        confidence: (r['confidence'] as num).toDouble(),
        contributingFactors: factors,
        estimatedAt: DateTime.parse(r['estimated_at'] as String),
        modelVersion: r['model_version'] as String,
      );
    }).toList();
  }
}
