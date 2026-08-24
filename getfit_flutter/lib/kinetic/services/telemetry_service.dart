import '../persistence/kinetic_store.dart';

class WhyExplanationViewModel {
  final String recommendationHeadline;
  final String action;
  final String primaryRationale;
  final List<String> physiologicalEvidence;
  final List<String> reasonCodes;
  final Map<String, dynamic> rawInputsSnapshot;
  final Map<String, dynamic> derivedFeaturesSnapshot;
  final List<Map<String, dynamic>> competingOptionsEvaluated;
  final DateTime generatedAt;
  final String modelVersion;

  const WhyExplanationViewModel({
    required this.recommendationHeadline,
    required this.action,
    required this.primaryRationale,
    required this.physiologicalEvidence,
    required this.reasonCodes,
    required this.rawInputsSnapshot,
    required this.derivedFeaturesSnapshot,
    required this.competingOptionsEvaluated,
    required this.generatedAt,
    required this.modelVersion,
  });
}

/// Telemetry and "WHY" Diagnostic Explanation Service
class TelemetryService {
  final KineticStore store;

  TelemetryService({KineticStore? store}) : store = store ?? KineticStore.instance;

  /// Retrieves the complete explanation and decision trace for a recommendation
  WhyExplanationViewModel? explainRecommendation(String recommendationId) {
    final trace = store.getTrace(recommendationId);
    final rec = store.getLatestRecommendation();

    if (trace == null || rec == null) return null;

    return WhyExplanationViewModel(
      recommendationHeadline: rec.headline,
      action: rec.action,
      primaryRationale: rec.rationale,
      physiologicalEvidence: rec.evidence,
      reasonCodes: trace.reasonCodes,
      rawInputsSnapshot: trace.rawInputs,
      derivedFeaturesSnapshot: trace.derivedFeatures,
      competingOptionsEvaluated: trace.candidateEvaluations,
      generatedAt: trace.timestamp,
      modelVersion: trace.modelVersion,
    );
  }

  /// Exports full telemetry log stream for dev auditing
  List<Map<String, dynamic>> exportEventAuditLog() {
    return store.getEvents().map((e) => e.toJson()).toList();
  }
}
