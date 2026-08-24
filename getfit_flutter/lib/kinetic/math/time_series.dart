import 'dart:math';

/// Mathematical and Time-Series Computation Engine for Kinetic Precision
/// Implements deterministic smoothing, rolling statistics, rate of change,
/// cumulative loads, missing data handling, and outlier rejection.
class TimeSeriesEngine {
  /// Engine semantic version
  static const String version = 'time_series_engine_v1.0';

  // ── 1. Exponentially Weighted Moving Average (EWMA) ─────────────────────────

  /// Computes the final Exponentially Weighted Moving Average (EWMA).
  ///
  /// **Formula**:
  /// $S_0 = Y_0$
  /// $S_t = \alpha Y_t + (1 - \alpha) S_{t-1}$ for $t \ge 1$
  /// where $\alpha = \frac{2}{N + 1}$ if [span] $N$ is provided.
  ///
  /// **Assumptions**:
  /// - Input sequence is ordered chronologically at uniform intervals.
  /// - $0 < \alpha \le 1.0$.
  ///
  /// **Inputs**: [values] list of doubles, optional [alpha] (0.0 to 1.0), optional [span] $N \ge 1$.
  /// **Outputs**: Final smoothed double value.
  static double computeEWMA(List<double> values, {double? alpha, int? span}) {
    if (values.isEmpty) return 0.0;
    final a = alpha ?? (span != null ? 2.0 / (span + 1.0) : 0.2);
    double ewma = values.first;
    for (int i = 1; i < values.length; i++) {
      ewma = (a * values[i]) + ((1.0 - a) * ewma);
    }
    return ewma;
  }

  /// Computes the complete EWMA series corresponding to each step in [values].
  static List<double> computeEWMASeries(List<double> values, {double? alpha, int? span}) {
    if (values.isEmpty) return [];
    final a = alpha ?? (span != null ? 2.0 / (span + 1.0) : 0.2);
    final List<double> series = [values.first];
    for (int i = 1; i < values.length; i++) {
      final nextVal = (a * values[i]) + ((1.0 - a) * series.last);
      series.add(nextVal);
    }
    return series;
  }

  // ── 2. Arithmetic & Rolling Statistics ───────────────────────────────────────

  /// Computes sample arithmetic mean: $\mu = \frac{1}{N} \sum_{i=1}^N x_i$.
  ///
  /// **Inputs**: [values] list of doubles.
  /// **Outputs**: Mean double value (or 0.0 if empty).
  static double computeMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold(0.0, (acc, v) => acc + v);
    return sum / values.length;
  }

  /// Computes rolling mean series over a sliding window of size [windowSize].
  ///
  /// **Inputs**: [values] list of doubles, [windowSize] $\ge 1$.
  /// **Outputs**: List of rolling mean doubles of length `values.length - windowSize + 1`.
  static List<double> computeRollingMean(List<double> values, int windowSize) {
    if (values.length < windowSize || windowSize <= 0) return [];
    final List<double> result = [];
    double currentSum = 0.0;

    for (int i = 0; i < windowSize; i++) {
      currentSum += values[i];
    }
    result.add(currentSum / windowSize);

    for (int i = windowSize; i < values.length; i++) {
      currentSum += values[i] - values[i - windowSize];
      result.add(currentSum / windowSize);
    }
    return result;
  }

  /// Computes sample median (middle value if odd, average of two middle values if even).
  static double computeMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }

  /// Computes rolling median series over a sliding window of size [windowSize].
  static List<double> computeRollingMedian(List<double> values, int windowSize) {
    if (values.length < windowSize || windowSize <= 0) return [];
    final List<double> result = [];
    for (int i = 0; i <= values.length - windowSize; i++) {
      final window = values.sublist(i, i + windowSize);
      result.add(computeMedian(window));
    }
    return result;
  }

  /// Computes unbiased sample variance: $s^2 = \frac{1}{N - 1} \sum_{i=1}^N (x_i - \mu)^2$.
  static double computeVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = computeMean(values);
    final sumSqDiff = values.fold(0.0, (acc, v) => acc + pow(v - mean, 2));
    return sumSqDiff / (values.length - 1);
  }

  /// Computes sample standard deviation: $s = \sqrt{s^2}$.
  static double computeStandardDeviation(List<double> values) {
    return sqrt(computeVariance(values));
  }

  /// Computes rolling standard deviation series over a sliding window of size [windowSize].
  static List<double> computeRollingStandardDeviation(List<double> values, int windowSize) {
    if (values.length < windowSize || windowSize < 2) return [];
    final List<double> result = [];
    for (int i = 0; i <= values.length - windowSize; i++) {
      final window = values.sublist(i, i + windowSize);
      result.add(computeStandardDeviation(window));
    }
    return result;
  }

  // ── 3. Trends & Rate of Change ──────────────────────────────────────────────

  /// Computes linear trend slope (first-order linear regression slope $\beta$).
  ///
  /// **Formula**: $\beta = \frac{N \sum xy - \sum x \sum y}{N \sum x^2 - (\sum x)^2}$
  ///
  /// **Inputs**: [values] equidistant time-series points.
  /// **Outputs**: Slope double representing change per unit step.
  static double computeTrendSlope(List<double> values) {
    if (values.length < 2) return 0.0;
    final n = values.length;
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denom = (n * sumX2) - (sumX * sumX);
    if (denom.abs() < 1e-9) return 0.0;
    return ((n * sumXY) - (sumX * sumY)) / denom;
  }

  /// Computes step-by-step rate of change (first difference $\Delta y = y_t - y_{t-1}$).
  static List<double> computeRateOfChange(List<double> values) {
    if (values.length < 2) return [];
    final List<double> deltas = [];
    for (int i = 1; i < values.length; i++) {
      deltas.add(values[i] - values[i - 1]);
    }
    return deltas;
  }

  // ── 4. Baseline Deviation ───────────────────────────────────────────────────

  /// Computes standardized Z-score deviation from personal baseline:
  /// $Z = \frac{x - \mu}{\sigma}$
  ///
  /// **Inputs**: [value] current reading, [baselineMean] $\mu$, [baselineStd] $\sigma$.
  /// **Outputs**: Dimensionless Z-score.
  static double computeZScore(double value, double baselineMean, double baselineStd) {
    if (baselineStd.abs() < 1e-6) return 0.0;
    return (value - baselineMean) / baselineStd;
  }

  /// Computes percentage deviation from baseline: $\frac{x - \mu}{\mu} \times 100$.
  static double computePercentageDeviation(double value, double baselineMean) {
    if (baselineMean.abs() < 1e-6) return 0.0;
    return ((value - baselineMean) / baselineMean) * 100.0;
  }

  // ── 5. Cumulative & Exponentially Weighted Load ─────────────────────────────

  /// Computes rolling cumulative sum over a window of [windowSize] points.
  static List<double> computeCumulativeLoad(List<double> values, int windowSize) {
    if (values.length < windowSize || windowSize <= 0) return [];
    final List<double> result = [];
    double currentSum = 0.0;

    for (int i = 0; i < windowSize; i++) {
      currentSum += values[i];
    }
    result.add(currentSum);

    for (int i = windowSize; i < values.length; i++) {
      currentSum += values[i] - values[i - windowSize];
      result.add(currentSum);
    }
    return result;
  }

  /// Computes exponentially decaying cumulative training load (Impulse Response).
  ///
  /// **Formula**: $TL_t = TL_{t-1} \times e^{-1 / \tau} + \text{Load}_t$
  ///
  /// **Inputs**: [dailyLoads] list of daily training loads, [decayTimeConstant] $\tau$ (e.g. 7 for acute, 28 for chronic).
  /// **Outputs**: Final decaying workload double.
  static double computeDecayingLoad(List<double> dailyLoads, {double decayTimeConstant = 7.0}) {
    if (dailyLoads.isEmpty) return 0.0;
    final lambda = exp(-1.0 / decayTimeConstant);
    double accumulated = 0.0;
    for (final load in dailyLoads) {
      accumulated = (accumulated * lambda) + load;
    }
    return accumulated;
  }

  // ── 6. Missing Data Handling ────────────────────────────────────────────────

  /// Imputes missing values (`null`) using Linear Interpolation between valid anchors.
  static List<double> imputeMissingLinear(List<double?> rawValues) {
    if (rawValues.isEmpty) return [];
    final List<double> result = List.filled(rawValues.length, 0.0);

    int? firstValidIndex;
    for (int i = 0; i < rawValues.length; i++) {
      if (rawValues[i] != null) {
        firstValidIndex = i;
        break;
      }
    }

    if (firstValidIndex == null) return result; // All nulls

    // Backfill leading nulls with first valid value
    for (int i = 0; i < firstValidIndex; i++) {
      result[i] = rawValues[firstValidIndex]!;
    }

    int lastValidIndex = firstValidIndex;
    result[firstValidIndex] = rawValues[firstValidIndex]!;

    for (int i = firstValidIndex + 1; i < rawValues.length; i++) {
      if (rawValues[i] != null) {
        final startVal = rawValues[lastValidIndex]!;
        final endVal = rawValues[i]!;
        final steps = i - lastValidIndex;
        final stepSize = (endVal - startVal) / steps;

        for (int k = 1; k < steps; k++) {
          result[lastValidIndex + k] = startVal + (k * stepSize);
        }
        result[i] = endVal;
        lastValidIndex = i;
      }
    }

    // Forward fill trailing nulls
    for (int i = lastValidIndex + 1; i < rawValues.length; i++) {
      result[i] = rawValues[lastValidIndex]!;
    }

    return result;
  }

  /// Imputes missing values (`null`) using Forward Fill (carry last observation forward).
  static List<double> imputeMissingForwardFill(List<double?> rawValues, {double fallback = 0.0}) {
    final List<double> result = [];
    double lastKnown = fallback;
    for (final v in rawValues) {
      if (v != null) {
        lastKnown = v;
      }
      result.add(lastKnown);
    }
    return result;
  }

  // ── 7. Outlier Detection & Filtering ────────────────────────────────────────

  /// Identifies and filters outliers using Z-score threshold (default $|Z| > 3.0$).
  static List<double> filterOutliersZScore(List<double> values, {double threshold = 3.0}) {
    if (values.length < 4) return List.from(values);
    final mean = computeMean(values);
    final std = computeStandardDeviation(values);
    if (std < 1e-6) return List.from(values);

    return values.where((v) {
      final z = (v - mean).abs() / std;
      return z <= threshold;
    }).toList();
  }

  /// Filters outliers using Tukey Interquartile Range (IQR) method:
  /// $[\text{Q1} - k \cdot \text{IQR}, \; \text{Q3} + k \cdot \text{IQR}]$.
  static List<double> filterOutliersIQR(List<double> values, {double k = 1.5}) {
    if (values.length < 4) return List.from(values);
    final sorted = List<double>.from(values)..sort();
    final q1 = computeMedian(sorted.sublist(0, sorted.length ~/ 2));
    final q2Start = (sorted.length % 2 == 0) ? (sorted.length ~/ 2) : (sorted.length ~/ 2 + 1);
    final q3 = computeMedian(sorted.sublist(q2Start));
    final iqr = q3 - q1;
    final lowerBound = q1 - (k * iqr);
    final upperBound = q3 + (k * iqr);

    return values.where((v) => v >= lowerBound && v <= upperBound).toList();
  }

  /// Returns a boolean mask indicating outlier status for each element in [values].
  static List<bool> detectOutlierMask(List<double> values, {double threshold = 3.0}) {
    if (values.length < 4) return List.filled(values.length, false);
    final mean = computeMean(values);
    final std = computeStandardDeviation(values);
    if (std < 1e-6) return List.filled(values.length, false);

    return values.map((v) {
      final z = (v - mean).abs() / std;
      return z > threshold;
    }).toList();
  }
}
