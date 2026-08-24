import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';

void main() {
  group('Phase 3: Normalization & Time-Series Feature Engine Tests', () {
    test('1. Rolling Calculations: Rolling mean, rolling median, and variance', () {
      final data = [10.0, 20.0, 30.0, 40.0, 50.0];

      // Mean: (10 + 20 + 30 + 40 + 50) / 5 = 30.0
      expect(TimeSeriesEngine.computeMean(data), equals(30.0));

      // Median of [10, 20, 30, 40, 50] = 30.0
      expect(TimeSeriesEngine.computeMedian(data), equals(30.0));

      // Rolling mean with window = 3:
      // [10,20,30] -> 20.0, [20,30,40] -> 30.0, [30,40,50] -> 40.0
      final rollingMean = TimeSeriesEngine.computeRollingMean(data, 3);
      expect(rollingMean, equals([20.0, 30.0, 40.0]));

      // Rolling median with window = 3:
      final rollingMedian = TimeSeriesEngine.computeRollingMedian(data, 3);
      expect(rollingMedian, equals([20.0, 30.0, 40.0]));

      // Sample Variance of [10, 20, 30, 40, 50]:
      // diffs from mean (30): -20, -10, 0, 10, 20 -> squared: 400, 100, 0, 100, 400 -> sum = 1000
      // s^2 = 1000 / (5 - 1) = 250.0
      expect(TimeSeriesEngine.computeVariance(data), equals(250.0));
      // Sample StdDev = sqrt(250) ~ 15.8113883
      expect(TimeSeriesEngine.computeStandardDeviation(data), closeTo(15.811, 0.001));
    });

    test('2. EWMA (Exponentially Weighted Moving Average) Smoothing', () {
      final data = [10.0, 20.0, 30.0, 40.0];
      // With alpha = 0.5:
      // S0 = 10.0
      // S1 = 0.5 * 20 + 0.5 * 10 = 15.0
      // S2 = 0.5 * 30 + 0.5 * 15 = 22.5
      // S3 = 0.5 * 40 + 0.5 * 22.5 = 31.25
      final ewmaSeries = TimeSeriesEngine.computeEWMASeries(data, alpha: 0.5);
      expect(ewmaSeries, equals([10.0, 15.0, 22.5, 31.25]));

      final finalEWMA = TimeSeriesEngine.computeEWMA(data, alpha: 0.5);
      expect(finalEWMA, equals(31.25));
    });

    test('3. Trend Slope & Rate of Change (OLS Linear Regression)', () {
      // Perfectly linear data: y = 2x + 5 -> x=[0,1,2,3,4], y=[5, 7, 9, 11, 13]
      final linearData = [5.0, 7.0, 9.0, 11.0, 13.0];
      final slope = TimeSeriesEngine.computeTrendSlope(linearData);
      expect(slope, closeTo(2.0, 0.0001));

      // Rate of change: differences between adjacent points [2, 2, 2, 2]
      final roc = TimeSeriesEngine.computeRateOfChange(linearData);
      expect(roc, equals([2.0, 2.0, 2.0, 2.0]));

      // Negative slope: y = -1.5x + 10 -> [10, 8.5, 7.0, 5.5]
      final negData = [10.0, 8.5, 7.0, 5.5];
      final negSlope = TimeSeriesEngine.computeTrendSlope(negData);
      expect(negSlope, closeTo(-1.5, 0.0001));
    });

    test('4. Outlier Detection: Tukey IQR and Z-Score filtering', () {
      // Dataset with extreme high outlier: [50, 52, 51, 49, 50, 53, 50, 250]
      final dataset = [50.0, 52.0, 51.0, 49.0, 50.0, 53.0, 50.0, 250.0];

      // Tukey IQR filter should remove 250.0
      final iqrFiltered = TimeSeriesEngine.filterOutliersIQR(dataset);
      expect(iqrFiltered.contains(250.0), isFalse);
      expect(iqrFiltered.length, equals(7));

      // Z-Score outlier filter should remove 250.0
      final zFiltered = TimeSeriesEngine.filterOutliersZScore(dataset, threshold: 2.0);
      expect(zFiltered.contains(250.0), isFalse);
      expect(zFiltered.length, equals(7));
    });

    test('5. Missing Data Imputation: Linear interpolation and forward fill', () {
      final withHoles = [10.0, null, null, 40.0, null, 60.0];

      // Linear interpolation:
      // index 1: 10 + (40-10)/3 * 1 = 20.0
      // index 2: 10 + (40-10)/3 * 2 = 30.0
      // index 4: 40 + (60-40)/2 * 1 = 50.0
      final interpolated = TimeSeriesEngine.imputeMissingLinear(withHoles);
      expect(interpolated, equals([10.0, 20.0, 30.0, 40.0, 50.0, 60.0]));

      // Forward fill:
      final forwardFilled = TimeSeriesEngine.imputeMissingForwardFill(withHoles, fallback: 0.0);
      expect(forwardFilled, equals([10.0, 10.0, 10.0, 40.0, 40.0, 60.0]));
    });

    test('6. 5-Stage Normalization Pipeline: Raw -> Normalized -> Validated -> Stored', () {
      final pipeline = NormalizationPipeline();
      final now = DateTime.parse('2026-08-18T10:00:00+05:30'); // Non-UTC input

      // 1. Stage 1 -> 2: Parse raw provider input
      final rawObservation = pipeline.parseProviderData(
        id: 'raw_test_1',
        userId: 'user_norm',
        metric: 'weight_kg',
        rawValue: 165.3467, // pounds
        rawUnit: 'lbs',
        rawTimestamp: now,
        source: 'apple_health',
      );
      expect(rawObservation.unit, equals('lbs'));

      // 2. Stage 2 -> 3: Normalize to SI units and UTC timestamp
      final normalized = pipeline.normalizeObservation(rawObservation);
      expect(normalized.unit, equals('kg'));
      expect(normalized.timestamp.isUtc, isTrue);
      expect(normalized.value, closeTo(75.0, 0.01)); // 165.3467 * 0.45359237 ~ 75.0

      // 3. Stage 3 -> 4: Validate physiological bounds
      final validated = pipeline.validateObservation(normalized);
      expect(validated.quality, equals(DataQuality.observed));

      // 4. Test Anomalous Value Validation: extreme out of bounds HR = 450 bpm
      final crazyHR = Measurement(
        id: 'crazy_hr',
        userId: 'user_norm',
        metric: 'heart_rate',
        value: 450.0,
        unit: 'bpm',
        timestamp: now.toUtc(),
        source: 'faulty_sensor',
      );
      final validatedCrazy = pipeline.validateObservation(crazyHR);
      expect(validatedCrazy.quality, equals(DataQuality.unreliable));
      expect(validatedCrazy.metadata['validation_warning'], contains('Physiologically out of bounds'));
    });

    test('7. Determinism: Bit-for-bit identical KineticFeatureSet extraction', () {
      final now = DateTime.utc(2026, 8, 18, 12, 0);
      final extractor = TimeFeatureExtractor();

      final measurements = {
        'hrv_rmssd': [
          Measurement(id: 'h1', userId: 'u1', metric: 'hrv_rmssd', value: 65.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 6)), source: 'sensor'),
          Measurement(id: 'h2', userId: 'u1', metric: 'hrv_rmssd', value: 62.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 5)), source: 'sensor'),
          Measurement(id: 'h3', userId: 'u1', metric: 'hrv_rmssd', value: 70.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 4)), source: 'sensor'),
          Measurement(id: 'h4', userId: 'u1', metric: 'hrv_rmssd', value: 68.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 3)), source: 'sensor'),
          Measurement(id: 'h5', userId: 'u1', metric: 'hrv_rmssd', value: 64.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 2)), source: 'sensor'),
          Measurement(id: 'h6', userId: 'u1', metric: 'hrv_rmssd', value: 72.0, unit: 'ms', timestamp: now.subtract(const Duration(days: 1)), source: 'sensor'),
          Measurement(id: 'h7', userId: 'u1', metric: 'hrv_rmssd', value: 75.0, unit: 'ms', timestamp: now, source: 'sensor'),
        ],
        'rhr': [
          Measurement(id: 'r1', userId: 'u1', metric: 'rhr', value: 58.0, unit: 'bpm', timestamp: now.subtract(const Duration(days: 2)), source: 'sensor'),
          Measurement(id: 'r2', userId: 'u1', metric: 'rhr', value: 56.0, unit: 'bpm', timestamp: now.subtract(const Duration(days: 1)), source: 'sensor'),
          Measurement(id: 'r3', userId: 'u1', metric: 'rhr', value: 54.0, unit: 'bpm', timestamp: now, source: 'sensor'),
        ],
        'sleep_duration_hrs': [
          Measurement(id: 's1', userId: 'u1', metric: 'sleep_duration_hrs', value: 8.0, unit: 'hours', timestamp: now, source: 'tracker'),
        ],
        'training_load': [
          Measurement(id: 'l1', userId: 'u1', metric: 'training_load', value: 250.0, unit: 'au', timestamp: now, source: 'engine'),
        ],
      };

      final baselines = {
        'hrv_rmssd': PersonalBaseline(
          metric: 'hrv_rmssd',
          mean: 65.0,
          stdDev: 5.0,
          min: 45.0,
          max: 85.0,
          sampleCount: 30,
          lastCalculated: now,
        ),
        'rhr': PersonalBaseline(
          metric: 'rhr',
          mean: 55.0,
          stdDev: 3.0,
          min: 48.0,
          max: 68.0,
          sampleCount: 30,
          lastCalculated: now,
        ),
      };

      // Run extraction twice
      final setA = extractor.extract(
        userId: 'u1',
        timestamp: now,
        measurements: measurements,
        baselines: baselines,
      );

      final setB = extractor.extract(
        userId: 'u1',
        timestamp: now,
        measurements: measurements,
        baselines: baselines,
      );

      // Verify exact equality across all extracted features
      expect(setA.version, equals(setB.version));
      expect(setA.features.keys, equals(setB.features.keys));

      for (final key in setA.features.keys) {
        final featA = setA.features[key]!;
        final featB = setB.features[key]!;
        expect(featA.value, equals(featB.value));
        expect(featA.name, equals(featB.name));
        expect(featA.calculationVersion, equals(featB.calculationVersion));
      }

      // Check specific math outputs
      // HRV Z-score for value 75 vs baseline (mean 65, std 5) = (75 - 65) / 5 = +2.0
      expect(setA.getDouble('hrv_z_score'), equals(2.0));
      // RHR Delta for value 54 vs baseline (mean 55) = 54 - 55 = -1.0
      expect(setA.getDouble('rhr_delta'), equals(-1.0));
    });
  });
}
