import '../domain/models.dart';

/// Abstract contract for feature extraction from raw observations
abstract class FeatureExtractor<TInput, TOutput> {
  String get version;
  TOutput extractFeatures(TInput rawData);
}

/// Abstract contract for latent physiological state estimation.
/// [deterministicTimestamp]: callers that require reproducibility (tests,
/// simulations) must supply an explicit timestamp so the pure function
/// produces the same output given the same inputs.
abstract class StateEstimator<TObservations, TContext> {
  String get version;
  LatentPhysiologicalState estimateState(
    TObservations observations,
    TContext context, {
    DateTime? deterministicTimestamp,
  });
}

/// Abstract contract for prediction models
abstract class Predictor<TFeatures, TPrediction> {
  String get version;
  TPrediction predict(TFeatures features);
}

/// Abstract contract for scoring candidate actions or parameters
abstract class Scorer<TCandidate, TContext, TScore> {
  String get version;
  TScore score(TCandidate candidate, TContext context);
}

/// Abstract contract for recommendation and decision policies
abstract class Policy<TState, TGoal, TAction> {
  String get version;
  Recommendation selectAction(TState state, TGoal goal, List<TAction> candidateActions);
}

/// Abstract contract for optimization algorithms
abstract class Optimizer<TProblem, TSolution> {
  String get version;
  TSolution optimize(TProblem problem);
}
