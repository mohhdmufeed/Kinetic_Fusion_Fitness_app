import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/math/time_series.dart';
import 'package:kinetic_precision/kinetic/math/baseline_calc.dart';

void main() {
  group('SPEC 10: Time-Series Engine — Hand-Checked Synthetic Sequences', () {
    test('1. Rolling Mean: [10, 20, 30, 40, 50] with window 3 produces exact [20.0, 30.0, 40.0]', () {
      final input = [10.0, 20.0, 30.0, 40.0, 50.0];
      final result = TimeSeriesEngine.computeRollingMean(input, 3);
      expect(result, equals([20.0, 30.0, 40.0]));
    });

    test('2. Rolling Median: [10, 100, 20, 5, 30] with window 3 produces exact [20.0, 20.0, 20.0]', () {
      final input = [10.0, 100.0, 20.0, 5.0, 30.0];
      final result = TimeSeriesEngine.computeRollingMedian(input, 3);
      expect(result, equals([20.0, 20.0, 20.0]));
    });

    test('3. EWMA: [10.0, 20.0, 30.0] with alpha=0.5 produces exact 22.5', () {
      // Step 0: 10.0
      // Step 1: 0.5 * 20.0 + 0.5 * 10.0 = 15.0
      // Step 2: 0.5 * 30.0 + 0.5 * 15.0 = 22.5
      final input = [10.0, 20.0, 30.0];
      final result = TimeSeriesEngine.computeEWMA(input, alpha: 0.5);
      expect(result, equals(22.5));

      final series = TimeSeriesEngine.computeEWMASeries(input, alpha: 0.5);
      expect(series, equals([10.0, 15.0, 22.5]));
    });

    test('4. Moving Variance & Standard Deviation: [2, 4, 4, 4, 5, 5, 7, 9]', () {
      final input = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      // Mean = 5.0
      // SumSqDiff = 9 + 1 + 1 + 1 + 0 + 0 + 4 + 16 = 32
      // Unbiased variance (N-1 = 7) = 32 / 7 = 4.57142857...
      // StdDev = sqrt(32/7) = 2.1380899...
      final variance = TimeSeriesEngine.computeVariance(input);
      final stdDev = TimeSeriesEngine.computeStandardDeviation(input);

      expect(variance, closeTo(32.0 / 7.0, 0.0001));
      expect(stdDev, closeTo(2.138089, 0.0001));
    });

    test('5. Linear Trend Slope: [2.0, 4.0, 6.0, 8.0, 10.0] produces exact slope of 2.0', () {
      final input = [2.0, 4.0, 6.0, 8.0, 10.0];
      final slope = TimeSeriesEngine.computeTrendSlope(input);
      expect(slope, closeTo(2.0, 0.00001));
    });

    test('6. Baseline Deviation: Z-Score and Percentage delta', () {
      // Current = 85, Baseline Mean = 70, Baseline Std = 10
      // Z = (85 - 70) / 10 = 1.5
      // % Delta = ((85 - 70) / 70) * 100 = 21.42857%
      final z = TimeSeriesEngine.computeZScore(85.0, 70.0, 10.0);
      final pct = TimeSeriesEngine.computePercentageDeviation(85.0, 70.0);

      expect(z, equals(1.5));
      expect(pct, closeTo(21.42857, 0.001));
    });

    test('7. Rate of Change: [10, 15, 12, 20] produces [5, -3, 8]', () {
      final input = [10.0, 15.0, 12.0, 20.0];
      final deltas = TimeSeriesEngine.computeRateOfChange(input);
      expect(deltas, equals([5.0, -3.0, 8.0]));
    });

    test('8. Cumulative Load: [100, 200, 150, 300] with window 2 produces [300.0, 350.0, 450.0]', () {
      final input = [100.0, 200.0, 150.0, 300.0];
      final cumulative = TimeSeriesEngine.computeCumulativeLoad(input, 2);
      expect(cumulative, equals([300.0, 350.0, 450.0]));
    });

    test('9. Missing-Data Linear Interpolation: [10.0, null, null, 40.0] produces [10, 20, 30, 40]', () {
      final input = [10.0, null, null, 40.0];
      final interpolated = TimeSeriesEngine.imputeMissingLinear(input);
      expect(interpolated, equals([10.0, 20.0, 30.0, 40.0]));
    });

    test('10. Outlier Detection (Tukey IQR): filters spurious spike 100 from clean cluster', () {
      final input = [10.0, 12.0, 11.0, 13.0, 12.0, 100.0, 11.0];
      final filtered = TimeSeriesEngine.filterOutliersIQR(input);

      expect(filtered.contains(100.0), isFalse);
      expect(filtered.length, equals(6));
    });
  });

  group('SPEC 9: Personal Baseline Calculators for 8 Core Metrics', () {
    test('Calculates baselines for HR, HRV, Sleep, Activity, Volume, RPE, Weight, and Performance', () {
      // 1. Resting Heart Rate (bpm)
      final rhrHistory = [54.0, 52.0, 53.0, 55.0, 51.0, 53.0, 52.0];
      final rhrBaseline = BaselineEngine.computeRHRBaseline(rhrHistory);
      expect(rhrBaseline.metric, equals('rhr'));
      expect(rhrBaseline.mean, closeTo(52.7, 1.0));
      expect(rhrBaseline.sampleCount, equals(7));

      // 2. Heart Rate Variability RMSSD (ms)
      final hrvHistory = [70.0, 68.0, 72.0, 75.0, 71.0, 69.0, 73.0];
      final hrvBaseline = BaselineEngine.computeHRVBaseline(hrvHistory);
      expect(hrvBaseline.metric, equals('hrv_rmssd'));
      expect(hrvBaseline.mean, closeTo(71.0, 1.5));

      // 3. Sleep Duration (hours)
      final sleepHistory = [7.5, 8.0, 7.8, 8.2, 7.6, 8.0, 7.9];
      final sleepBaseline = BaselineEngine.computeSleepBaseline(sleepHistory);
      expect(sleepBaseline.metric, equals('sleep_duration_hrs'));
      expect(sleepBaseline.mean, closeTo(7.9, 0.5));

      // 4. Daily Steps (steps)
      final stepsHistory = [10500.0, 11200.0, 9800.0, 12400.0, 10800.0];
      final activityBaseline = BaselineEngine.computeActivityBaseline(stepsHistory);
      expect(activityBaseline.metric, equals('steps'));
      expect(activityBaseline.mean, closeTo(10900.0, 200.0));

      // 5. Training Volume Load (AU)
      final volumeHistory = [400.0, 450.0, 380.0, 500.0, 420.0];
      final volumeBaseline = BaselineEngine.computeVolumeBaseline(volumeHistory);
      expect(volumeBaseline.metric, equals('session_load'));

      // 6. RPE Response (scale 1-10)
      final rpeHistory = [7.5, 8.0, 7.0, 8.5, 8.0];
      final rpeBaseline = BaselineEngine.computeRPEBaseline(rpeHistory);
      expect(rpeBaseline.metric, equals('set_rpe'));
      expect(rpeBaseline.mean, closeTo(7.8, 0.5));

      // 7. Body Weight (kg)
      final weightHistory = [80.5, 80.4, 80.6, 80.3, 80.5];
      final weightBaseline = BaselineEngine.computeWeightBaseline(weightHistory);
      expect(weightBaseline.metric, equals('weight_kg'));
      expect(weightBaseline.mean, closeTo(80.45, 0.2));

      // 8. Performance Estimated 1RM (kg)
      final benchHistory = [100.0, 102.5, 102.5, 105.0, 105.0];
      final perfBaseline = BaselineEngine.computePerformanceBaseline('bench_press', benchHistory);
      expect(perfBaseline.metric, equals('1rm_bench_press'));
      expect(perfBaseline.mean, closeTo(103.5, 1.5));
    });

    test('Online Adaptive Baseline: dynamically updates and adapts upward as user progresses', () {
      final initialBaseline = BaselineEngine.computeHRVBaseline([60.0, 60.0, 60.0, 60.0]);
      expect(initialBaseline.mean, equals(60.0));

      // User experiences chronic HRV improvement (new samples at 80 ms)
      var adapted = initialBaseline;
      for (int i = 0; i < 10; i++) {
        adapted = BaselineEngine.updateBaselineOnline(adapted, 80.0, adaptationRate: 0.1);
      }

      // Baseline adapted upward rather than staying frozen at 60.0
      expect(adapted.mean > 70.0, isTrue);
      expect(adapted.sampleCount, equals(14));
      expect(adapted.max, equals(80.0));
    });
  });
}
