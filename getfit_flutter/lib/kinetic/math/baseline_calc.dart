import 'dart:math';
import '../domain/models.dart';
import 'time_series.dart';

/// Baseline Calculation Engine for Kinetic Precision
/// Computes and adaptively updates personal physiological and performance baselines.
/// Baselines adapt continuously over time and never freeze after onboarding.
class BaselineEngine {
  /// Engine semantic version
  static const String version = 'baseline_engine_v1.0';

  // ── General Baseline Calculator ─────────────────────────────────────────────

  /// Computes an adaptive personal baseline from a time-series history of a metric.
  ///
  /// **Inputs**:
  /// - [metric]: Canonical metric identifier (e.g. `'hrv_rmssd'`, `'rhr'`, `'weight_kg'`).
  /// - [history]: Time-series values ordered chronologically.
  /// - [outlierFilter]: Whether to apply Tukey IQR outlier filtering before calculating baseline.
  ///
  /// **Outputs**: `PersonalBaseline` containing mean $\mu$, std $\sigma$, range, and confidence.
  static PersonalBaseline computeBaseline(
    String metric,
    List<double> history, {
    bool outlierFilter = true,
  }) {
    if (history.isEmpty) {
      return PersonalBaseline(
        metric: metric,
        mean: 0.0,
        stdDev: 1.0,
        min: 0.0,
        max: 0.0,
        sampleCount: 0,
        lastCalculated: DateTime.now(),
      );
    }

    final cleanData = outlierFilter ? TimeSeriesEngine.filterOutliersIQR(history) : history;
    final data = cleanData.isNotEmpty ? cleanData : history;

    // Use arithmetic mean for initial small samples (< 14), EWMA for adaptive long-term history (>= 14)
    final mean = (data.length < 14)
        ? TimeSeriesEngine.computeMean(data)
        : TimeSeriesEngine.computeEWMA(data, span: 28);
    final stdDev = TimeSeriesEngine.computeStandardDeviation(data);

    double minVal = data.first;
    double maxVal = data.first;
    for (final v in data) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    return PersonalBaseline(
      metric: metric,
      mean: (mean * 1000).round() / 1000.0,
      stdDev: stdDev < 1e-6 ? 1.0 : (stdDev * 1000).round() / 1000.0,
      min: minVal,
      max: maxVal,
      sampleCount: history.length,
      lastCalculated: DateTime.now(),
    );
  }

  // ── Specialized Metric Calculators ──────────────────────────────────────────

  /// 1. Heart Rate Baseline Calculator (RHR)
  /// **Units**: Beats per minute (bpm).
  /// **Normal range**: 40 – 90 bpm.
  static PersonalBaseline computeRHRBaseline(List<double> rhrSamples) {
    return computeBaseline('rhr', rhrSamples);
  }

  /// 2. Heart Rate Variability Baseline Calculator (HRV RMSSD)
  /// **Units**: Milliseconds (ms).
  /// **Normal range**: 20 – 150 ms.
  static PersonalBaseline computeHRVBaseline(List<double> hrvSamples) {
    return computeBaseline('hrv_rmssd', hrvSamples);
  }

  /// 3. Sleep Duration Baseline Calculator
  /// **Units**: Hours.
  /// **Normal range**: 5.0 – 10.0 hours.
  static PersonalBaseline computeSleepBaseline(List<double> sleepDurationHours) {
    return computeBaseline('sleep_duration_hrs', sleepDurationHours);
  }

  /// 4. Daily Activity Baseline Calculator (Steps / Active Energy)
  /// **Units**: Steps or kcal.
  static PersonalBaseline computeActivityBaseline(List<double> dailyActivitySteps) {
    return computeBaseline('steps', dailyActivitySteps);
  }

  /// 5. Weekly Training Volume Baseline Calculator
  /// **Units**: Volume load (kg $\times$ reps) or arbitrary load units (AU).
  static PersonalBaseline computeVolumeBaseline(List<double> sessionLoads) {
    return computeBaseline('session_load', sessionLoads);
  }

  /// 6. RPE Response Baseline Calculator
  /// **Units**: Borg CR-10 RPE scale (1.0 – 10.0).
  static PersonalBaseline computeRPEBaseline(List<double> setRPEHistory) {
    return computeBaseline('set_rpe', setRPEHistory);
  }

  /// 7. Body Weight Baseline Calculator
  /// **Units**: Kilograms (kg).
  static PersonalBaseline computeWeightBaseline(List<double> weightHistory) {
    return computeBaseline('weight_kg', weightHistory);
  }

  /// 8. Performance Baseline Calculator (Estimated 1RM / Work Capacity)
  /// **Units**: kg or kg $\times$ reps.
  static PersonalBaseline computePerformanceBaseline(String exerciseId, List<double> estimated1RMHistory) {
    return computeBaseline('1rm_$exerciseId', estimated1RMHistory);
  }

  /// 9. Active Heart Rate Baseline Calculator
  /// **Units**: Beats per minute (bpm).
  static PersonalBaseline computeHeartRateBaseline(List<double> hrSamples) {
    return computeBaseline('heart_rate', hrSamples);
  }

  // ── Online Adaptive Update Step ─────────────────────────────────────────────

  /// Incrementally updates an existing baseline with a new incoming measurement.
  /// Adapts $\mu$ and $\sigma$ using Welford/EWMA online update without needing full history reload.
  ///
  /// **Inputs**: [current] previous baseline, [newValue] incoming sample, optional [adaptationRate] $\alpha$.
  /// **Outputs**: Updated `PersonalBaseline`.
  static PersonalBaseline updateBaselineOnline(
    PersonalBaseline current,
    double newValue, {
    double adaptationRate = 0.05, // ~20-day adaptation half-life
  }) {
    if (current.sampleCount == 0) {
      return PersonalBaseline(
        metric: current.metric,
        mean: newValue,
        stdDev: 1.0,
        min: newValue,
        max: newValue,
        sampleCount: 1,
        lastCalculated: DateTime.now(),
      );
    }

    final newMean = (adaptationRate * newValue) + ((1.0 - adaptationRate) * current.mean);
    final delta = newValue - current.mean;
    final varianceDelta = (adaptationRate * (delta * delta)) + ((1.0 - adaptationRate) * (current.stdDev * current.stdDev));
    final newStd = sqrt(varianceDelta > 0.0001 ? varianceDelta : 1.0);

    return PersonalBaseline(
      metric: current.metric,
      mean: (newMean * 1000).round() / 1000.0,
      stdDev: (newStd * 1000).round() / 1000.0,
      min: newValue < current.min ? newValue : current.min,
      max: newValue > current.max ? newValue : current.max,
      sampleCount: current.sampleCount + 1,
      lastCalculated: DateTime.now(),
    );
  }
}
