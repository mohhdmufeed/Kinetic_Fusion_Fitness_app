import '../domain/models.dart';
import '../math/time_series.dart';
import 'contracts.dart';

/// Normalized feature vector generated from raw time-series observations
class PhysiologicalFeatures {
  final double hrvZScore;
  final double rhrDeltaBpm;
  final double sleepDebtHours;
  final double sleepQualityScore; // 0 to 100
  final double acuteTrainingLoad;
  final double chronicTrainingLoad;
  final double acwr;
  final double activityStepsDelta;
  final double dataCompleteness; // 0.0 to 1.0
  final Map<String, dynamic> rawFeatureMap;

  const PhysiologicalFeatures({
    required this.hrvZScore,
    required this.rhrDeltaBpm,
    required this.sleepDebtHours,
    required this.sleepQualityScore,
    required this.acuteTrainingLoad,
    required this.chronicTrainingLoad,
    required this.acwr,
    required this.activityStepsDelta,
    required this.dataCompleteness,
    required this.rawFeatureMap,
  });
}

/// Feature extraction engine converting multi-modal raw observations into normalized features
class KineticFeatureEngine implements FeatureExtractor<Map<String, List<Measurement>>, PhysiologicalFeatures> {
  @override
  String get version => 'feature_engine_v1.0';

  final Map<String, PersonalBaseline> baselines;

  KineticFeatureEngine({required this.baselines});

  @override
  PhysiologicalFeatures extractFeatures(Map<String, List<Measurement>> rawMeasurements) {
    // 1. HRV extraction & baseline deviation
    final hrvMeasurements = rawMeasurements['hrv_rmssd'] ?? [];
    double hrvZ = 0.0;
    if (hrvMeasurements.isNotEmpty) {
      final latestHRV = hrvMeasurements.last.value;
      final baseline = baselines['hrv_rmssd'];
      if (baseline != null) {
        hrvZ = baseline.computeZScoreDeviation(latestHRV);
      }
    }

    // 2. Resting HR extraction & delta from baseline
    final rhrMeasurements = rawMeasurements['rhr'] ?? [];
    double rhrDelta = 0.0;
    if (rhrMeasurements.isNotEmpty) {
      final latestRHR = rhrMeasurements.last.value;
      final baseline = baselines['rhr'];
      if (baseline != null) {
        rhrDelta = latestRHR - baseline.mean;
      }
    }

    // 3. Sleep duration & sleep debt (vs 8h baseline or personal baseline)
    final sleepMeasurements = rawMeasurements['sleep_duration_hrs'] ?? [];
    double sleepDebt = 0.0;
    double sleepQuality = 80.0;
    if (sleepMeasurements.isNotEmpty) {
      final recentSleep = sleepMeasurements.map((m) => m.value).toList();
      final avgSleep = TimeSeriesEngine.computeMean(recentSleep);
      final targetSleep = baselines['sleep_duration_hrs']?.mean ?? 8.0;
      sleepDebt = (targetSleep - avgSleep).clamp(-2.0, 6.0);
      sleepQuality = (avgSleep / targetSleep * 100.0).clamp(30.0, 100.0);
    }

    // 4. Training load & ACWR
    final loadMeasurements = rawMeasurements['daily_training_load'] ?? [];
    final loadValues = loadMeasurements.map((m) => m.value).toList();
    final acuteLoad = TimeSeriesEngine.computeEWMA(
      loadValues.length > 7 ? loadValues.sublist(loadValues.length - 7) : loadValues,
      alpha: 0.25,
    );
    final chronicLoad = TimeSeriesEngine.computeEWMA(
      loadValues.length > 28 ? loadValues.sublist(loadValues.length - 28) : loadValues,
      alpha: 0.07,
    );
    final acwr = chronicLoad > 0.01 ? (acuteLoad / chronicLoad).clamp(0.2, 3.0) : 1.0;

    // 5. Steps delta
    final stepMeasurements = rawMeasurements['steps'] ?? [];
    double stepsDelta = 0.0;
    if (stepMeasurements.isNotEmpty) {
      final latestSteps = stepMeasurements.last.value;
      final baselineSteps = baselines['steps']?.mean ?? 8000.0;
      stepsDelta = latestSteps - baselineSteps;
    }

    // 6. Data completeness score
    const totalExpectedMetrics = 5;
    int populated = 0;
    if (hrvMeasurements.isNotEmpty) populated++;
    if (rhrMeasurements.isNotEmpty) populated++;
    if (sleepMeasurements.isNotEmpty) populated++;
    if (loadMeasurements.isNotEmpty) populated++;
    if (stepMeasurements.isNotEmpty) populated++;
    final completeness = populated / totalExpectedMetrics;

    return PhysiologicalFeatures(
      hrvZScore: hrvZ,
      rhrDeltaBpm: rhrDelta,
      sleepDebtHours: sleepDebt,
      sleepQualityScore: sleepQuality,
      acuteTrainingLoad: acuteLoad,
      chronicTrainingLoad: chronicLoad,
      acwr: acwr,
      activityStepsDelta: stepsDelta,
      dataCompleteness: completeness,
      rawFeatureMap: {
        'hrvZScore': hrvZ,
        'rhrDeltaBpm': rhrDelta,
        'sleepDebtHours': sleepDebt,
        'acwr': acwr,
        'acuteTrainingLoad': acuteLoad,
        'chronicTrainingLoad': chronicLoad,
        'dataCompleteness': completeness,
      },
    );
  }
}
