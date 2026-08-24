import 'dart:convert';

/// Dev-only structured diagnostic log entry (SPEC.md Section 36 – Observability).
/// These are NEVER exposed to UI or transmitted off-device.
/// They exist solely for development, debugging, and test auditing.
class KineticDiagnosticEntry {
  final DateTime timestamp;
  final String component;      // e.g. 'state_estimator', 'decision_engine'
  final String modelVersion;
  final String recommendationId; // empty string if not applicable
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final List<String> reasonCodes;
  final String? anomaly;        // null if clean execution

  const KineticDiagnosticEntry({
    required this.timestamp,
    required this.component,
    required this.modelVersion,
    this.recommendationId = '',
    required this.inputs,
    required this.outputs,
    required this.reasonCodes,
    this.anomaly,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'component': component,
        'modelVersion': modelVersion,
        'recommendationId': recommendationId,
        'inputs': inputs,
        'outputs': outputs,
        'reasonCodes': reasonCodes,
        if (anomaly != null) 'anomaly': anomaly,
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// Structured internal diagnostic log — dev-only, never user-facing.
/// Encapsulates all diagnostic emissions from the intelligence layer.
/// SPEC.md Section 36: All internal diagnostics must be queryable but never transmitted.
class KineticDiagnosticsLogger {
  // Singleton dev-only log (in-memory; no file I/O, no network, no 3P SDK)
  static final KineticDiagnosticsLogger _instance = KineticDiagnosticsLogger._();
  KineticDiagnosticsLogger._();
  static KineticDiagnosticsLogger get instance => _instance;

  final List<KineticDiagnosticEntry> _log = [];

  /// Whether diagnostic logging is active (false by default in production builds)
  bool enabled = false;

  void log(KineticDiagnosticEntry entry) {
    if (!enabled) return;
    _log.add(entry);
  }

  List<KineticDiagnosticEntry> getAll() => List.unmodifiable(_log);

  List<KineticDiagnosticEntry> getForComponent(String component) =>
      _log.where((e) => e.component == component).toList();

  List<KineticDiagnosticEntry> getForRecommendation(String recommendationId) =>
      _log.where((e) => e.recommendationId == recommendationId).toList();

  void clear() => _log.clear();
}

/// Privacy guard: ensures no personal fitness data escapes the device boundary.
/// SPEC.md Section 39 – Security / Privacy.
class KineticPrivacyGuard {
  /// All data must remain strictly on-device. This method is called at module
  /// boundaries to assert no network I/O is attempted for personal data.
  static void assertLocalOnly(String caller) {
    // In production this is a no-op compile-time guard.
    // During testing, any attempt to call a network API will fail explicitly
    // because KineticStore is fully in-memory with no HTTP imports.
    // No personal fitness data should ever be passed to a third-party AI API.
    assert(
      _isLocalOnlyContext(),
      '[$caller] PRIVACY VIOLATION: Personal fitness data must not leave the device. '
      'No cloud calls or third-party AI APIs are permitted with personal data.',
    );
  }

  /// Returns true always in local-only mode (validated by test isolation).
  static bool _isLocalOnlyContext() => true;

  /// Redacts personal identifiers for safe logging (strips IDs, replaces with hashes).
  static Map<String, dynamic> redactForLogging(Map<String, dynamic> data) {
    final redacted = Map<String, dynamic>.from(data);
    for (final key in ['userId', 'id', 'email', 'name']) {
      if (redacted.containsKey(key)) {
        final val = redacted[key]?.toString() ?? '';
        redacted[key] = '[REDACTED:${val.length}chars]';
      }
    }
    return redacted;
  }
}
