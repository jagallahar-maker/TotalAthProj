/// Utility class for weight unit conversions
/// 
/// Weights are stored in their original unit with the unit type saved separately.
/// Conversion only happens when displaying in a different unit than stored.
class UnitConversion {
  static const double kgToLbRatio = 2.20462;
  static const double lbToKgRatio = 0.453592;

  /// Convert weight from one unit to another
  /// Returns the weight unchanged if units are the same
  static double convert(double weight, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return weight;
    
    if (fromUnit == 'kg' && toUnit == 'lb') {
      return weight * kgToLbRatio;
    } else if (fromUnit == 'lb' && toUnit == 'kg') {
      return weight * lbToKgRatio;
    }
    return weight;
  }

  /// Get display weight - converts from stored unit to preferred display unit
  static double getDisplayWeight(double storedWeight, String storedUnit, String displayUnit) {
    return convert(storedWeight, storedUnit, displayUnit);
  }

  /// Format weight for display with unit label
  /// Converts from stored unit to display unit if needed
  static String formatWeight(double storedWeight, String storedUnit, String displayUnit, {int decimals = 1}) {
    final displayWeight = getDisplayWeight(storedWeight, storedUnit, displayUnit);
    return '${displayWeight.toStringAsFixed(decimals)} $displayUnit';
  }

  /// Get unit label
  static String getUnitLabel(String unit) {
    return unit;
  }

  /// Check if unit is metric
  static bool isMetric(String unit) {
    return unit == 'kg';
  }

  /// Get plate weights for the given unit
  static List<double> getPlateWeights(String unit) {
    if (unit == 'lb') {
      return [45, 35, 25, 10, 5, 2.5];
    }
    return [25, 20, 15, 10, 5, 2.5, 1.25];
  }

  /// Get bar weight for the given unit
  static double getBarWeight(String unit) {
    if (unit == 'lb') {
      return 45.0;
    }
    return 20.0;
  }

  /// Convert any weight to kg for internal storage/comparison
  static double toKg(double weight, String unit) {
    return convert(weight, unit, 'kg');
  }

  /// DEPRECATED: Legacy method for backwards compatibility
  /// Use getDisplayWeight instead
  @Deprecated('Use getDisplayWeight with stored unit parameter')
  static double toDisplayUnit(double weightInKg, String preferredUnit) {
    return convert(weightInKg, 'kg', preferredUnit);
  }

  /// DEPRECATED: This method should no longer be used
  /// Weights should be stored in their original unit
  @Deprecated('Store weights in original unit instead of converting')
  static double toStorageUnit(double displayWeight, String preferredUnit) {
    return convert(displayWeight, preferredUnit, 'kg');
  }
}
