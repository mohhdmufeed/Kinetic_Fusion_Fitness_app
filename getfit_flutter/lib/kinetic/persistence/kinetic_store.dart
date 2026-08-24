import '../domain/models.dart';
import '../intelligence/feedback_loop.dart';

/// Local In-Memory Persistent Storage for Kinetic Precision engine.
///
/// SPEC.md Sections 32, 35, 39:
/// - All data stays strictly on-device (no network, no cloud, no 3P SDK).
/// - Duplicate measurements are silently de-duped by ID before insertion.
/// - Active workout sessions survive process restart by being kept in the
///   sessions list with status='in_progress' — getActiveSession() retrieves
///   the last such record for resume.
/// - The store is intentionally synchronous in-memory (no async gaps that
///   could leave the engine in a partial state on restart).
class KineticStore {
  static final KineticStore instance = KineticStore._internal();
  KineticStore._internal();

  KineticUser? _currentUser;
  final List<UserGoal> _goals = [];
  final List<Measurement> _measurements = [];
  final Set<String> _measurementIds = {}; // Duplicate guard (SPEC §32)
  final List<KineticEvent> _events = [];
  final Set<String> _eventIds = {};       // Duplicate guard for events
  final Map<String, PersonalBaseline> _baselines = {};
  final List<LatentPhysiologicalState> _latentStates = [];
  final List<WorkoutSession> _sessions = [];
  final List<Recommendation> _recommendations = [];
  final List<RecommendationTrace> _traces = [];
  final List<UserOverride> _overrides = [];
  final List<RecommendationOutcome> _outcomes = [];

  // ─── USER & GOALS ───
  KineticUser? getUser() => _currentUser;
  void saveUser(KineticUser user) => _currentUser = user;

  List<UserGoal> getGoals() => List.unmodifiable(_goals);
  void addGoal(UserGoal goal) {
    _goals.removeWhere((g) => g.id == goal.id);
    _goals.add(goal);
  }

  // ─── MEASUREMENTS & EVENTS ───

  List<Measurement> getMeasurements({String? metric, DateTime? since}) {
    return _measurements.where((m) {
      if (metric != null && m.metric != metric) return false;
      if (since != null && m.timestamp.isBefore(since)) return false;
      return true;
    }).toList();
  }

  /// Records a single measurement. Silently discards exact-ID duplicates
  /// to protect against double-delivery from sensors or provider sync (SPEC §32).
  void recordMeasurement(Measurement measurement) {
    if (_measurementIds.contains(measurement.id)) return; // idempotent
    _measurementIds.add(measurement.id);
    _measurements.add(measurement);
  }

  /// Batch insert with the same idempotency guarantee.
  void recordMeasurementsBatch(List<Measurement> batch) {
    for (final m in batch) {
      recordMeasurement(m);
    }
  }

  List<KineticEvent> getEvents({String? eventType}) {
    return _events.where((e) {
      if (eventType != null && e.eventType != eventType) return false;
      return true;
    }).toList();
  }

  /// Records an event. Silently discards exact-ID duplicates to prevent
  /// double-recording on retry (SPEC §32 – idempotent writes).
  void recordEvent(KineticEvent event) {
    if (_eventIds.contains(event.id)) return; // idempotent
    _eventIds.add(event.id);
    _events.add(event);
  }

  // ─── BASELINES ───
  Map<String, PersonalBaseline> getBaselines() => Map.unmodifiable(_baselines);
  PersonalBaseline? getBaseline(String metric) => _baselines[metric];
  void setBaseline(PersonalBaseline baseline) => _baselines[baseline.metric] = baseline;
  void saveBaseline(PersonalBaseline baseline) => setBaseline(baseline);

  // ─── LATENT STATES ───
  LatentPhysiologicalState? getLatestLatentState() =>
      _latentStates.isNotEmpty ? _latentStates.last : null;
  void recordLatentState(LatentPhysiologicalState state) => _latentStates.add(state);

  // ─── SESSIONS ───
  /// Returns all sessions (including completed/discarded for history).
  List<WorkoutSession> getSessions() => List.unmodifiable(_sessions);

  /// Returns the most-recently-started in-progress session, enabling mid-workout
  /// restart resilience: after an app crash, calling getActiveSession() returns
  /// the interrupted session so TrainingService can resume it (SPEC §32).
  WorkoutSession? getActiveSession() =>
      _sessions.where((s) => s.status == 'in_progress').lastOrNull;

  /// Upserts by session ID — allows in-progress updates without creating duplicates.
  void saveSession(WorkoutSession session) {
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
  }

  // ─── RECOMMENDATIONS & TRACES ───
  Recommendation? getLatestRecommendation() =>
      _recommendations.isNotEmpty ? _recommendations.last : null;
  void recordRecommendation(Recommendation rec) => _recommendations.add(rec);

  RecommendationTrace? getTrace(String recommendationId) =>
      _traces.where((t) => t.recommendationId == recommendationId).lastOrNull;
  void recordTrace(RecommendationTrace trace) => _traces.add(trace);

  // ─── OVERRIDES & FEEDBACK ───
  void recordOverride(UserOverride override) => _overrides.add(override);
  void recordOutcome(RecommendationOutcome outcome) => _outcomes.add(outcome);
  List<RecommendationOutcome> getOutcomes() => List.unmodifiable(_outcomes);

  /// Resets all store state for deterministic testing or full simulation reseeding.
  /// NOTE: this completely clears all data — only call in test setUp() or simulation init.
  void reset() {
    _currentUser = null;
    _goals.clear();
    _measurements.clear();
    _measurementIds.clear();
    _events.clear();
    _eventIds.clear();
    _baselines.clear();
    _latentStates.clear();
    _sessions.clear();
    _recommendations.clear();
    _traces.clear();
    _overrides.clear();
    _outcomes.clear();
  }
}
