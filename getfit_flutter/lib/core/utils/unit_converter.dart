class UnitConverter {
  static const double lbsPerKg = 2.20462262185;

  /// Converts kilograms to pounds
  static double kgToLbs(double kg) => kg * lbsPerKg;

  /// Converts pounds to kilograms
  static double lbsToKg(double lbs) => lbs / lbsPerKg;

  /// Formats numeric weight for display (e.g. 72.5)
  static String formatWeight(double weight) {
    if (weight % 1 == 0) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }
}
