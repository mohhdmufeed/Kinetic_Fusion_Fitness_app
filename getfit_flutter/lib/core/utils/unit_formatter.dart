import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const double kgToLbConstant = 2.20462262185;

/// Centralized Flutter Unit Formatter
/// Guarantees that canonical storage and computations are strictly Kilograms (kg),
/// with presentation-only conversions and drift-free rounding.
class UnitFormatter {
  UnitFormatter._();

  /// Converts canonical kg to display value (e.g. 84.0 kg -> 185.2 lb or 84.0 kg)
  static double toDisplay(double kg, bool useKilograms, {int decimals = 1}) {
    if (useKilograms) {
      return double.parse(kg.toStringAsFixed(decimals));
    }
    return double.parse((kg * kgToLbConstant).toStringAsFixed(decimals));
  }

  /// Converts user input in display mode to canonical kg for database storage
  static double fromInput(double displayValue, bool useKilograms, {int decimals = 2}) {
    if (useKilograms) {
      return double.parse(displayValue.toStringAsFixed(decimals));
    }
    return double.parse((displayValue / kgToLbConstant).toStringAsFixed(decimals));
  }

  /// Formats weight with unit label (e.g. "84.0 kg" or "185.2 lb")
  static String formatWeight(double kg, bool useKilograms, {int decimals = 1}) {
    final val = toDisplay(kg, useKilograms, decimals: decimals);
    final unit = useKilograms ? 'kg' : 'lb';
    return '$val $unit';
  }

  /// Returns unit label string
  static String unitLabel(bool useKilograms) => useKilograms ? 'kg' : 'lb';
}

/// Global Unit Preference Notifier & Provider (Single Source of Truth)
class UnitPreferenceNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _key = 'user_pref_use_kilograms';

  UnitPreferenceNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final val = await _storage.read(key: _key);
    if (val != null) {
      state = val.toLowerCase() == 'true';
    }
  }

  Future<void> setUseKilograms(bool value) async {
    state = value;
    await _storage.write(key: _key, value: value.toString());
  }

  Future<void> toggle() async {
    await setUseKilograms(!state);
  }
}

final unitPreferenceProvider = StateNotifierProvider<UnitPreferenceNotifier, bool>((ref) {
  return UnitPreferenceNotifier();
});
