/// Recovery and freshness calculator for muscle training load decay
/// 
/// Applies time-based decay to muscle training load to reflect recovery status
class RecoveryCalculator {
  /// Recovery decay factors by days since training
  /// These values reflect diminishing muscle fatigue over time
  static const Map<int, double> _decayFactors = {
    0: 1.0,    // Same day - full load
    1: 0.75,   // 1 day ago - significant load remaining
    2: 0.55,   // 2 days ago - moderate load
    3: 0.35,   // 3 days ago - low load
    4: 0.2,    // 4 days ago - minimal load
    5: 0.1,    // 5 days ago - nearly recovered
    // 6+ days ago - fully recovered (0.0)
  };
  
  /// Get decay factor for a specific number of days ago
  /// 
  /// Returns a value from 0.0 (fully recovered) to 1.0 (fresh training)
  static double getDecayFactor(int daysAgo) {
    if (daysAgo < 0) return 1.0;
    if (daysAgo >= 6) return 0.0; // Fully recovered after 6+ days
    return _decayFactors[daysAgo] ?? 0.0;
  }
  
  /// Calculate decayed load for a muscle based on training history
  /// 
  /// [workoutDates] - Map of dates to load contributed on that date
  /// [referenceDate] - Date to calculate from (typically DateTime.now())
  /// 
  /// Returns the sum of all decayed loads
  static double calculateDecayedLoad({
    required Map<DateTime, double> workoutDates,
    DateTime? referenceDate,
  }) {
    final reference = referenceDate ?? DateTime.now();
    double totalDecayedLoad = 0.0;
    
    for (var entry in workoutDates.entries) {
      final workoutDate = entry.key;
      final loadOnDate = entry.value;
      
      // Calculate days difference (ignoring time of day)
      final daysAgo = reference.difference(workoutDate).inDays;
      final decayFactor = getDecayFactor(daysAgo);
      
      totalDecayedLoad += loadOnDate * decayFactor;
    }
    
    return totalDecayedLoad;
  }
  
  /// Calculate freshness score (inverse of recovery status)
  /// 
  /// [decayedLoad] - Current decayed load value
  /// [maxExpectedLoad] - Expected max load for normalization (default: 20)
  /// 
  /// Returns a value from 0.0 (overtrained/fatigued) to 1.0 (fully fresh)
  static double calculateFreshness({
    required double decayedLoad,
    double maxExpectedLoad = 20.0,
  }) {
    // Normalize load to 0-1 range, then invert
    final normalizedLoad = (decayedLoad / maxExpectedLoad).clamp(0.0, 1.0);
    return 1.0 - normalizedLoad;
  }
  
  /// Get recovery status label based on decayed load
  static String getRecoveryStatus(double decayedLoad) {
    if (decayedLoad >= 15) return 'Fatigued';
    if (decayedLoad >= 10) return 'Recovering';
    if (decayedLoad >= 5) return 'Moderate';
    if (decayedLoad >= 1) return 'Fresh';
    return 'Rested';
  }
  
  /// Get freshness status label (inverse of recovery)
  static String getFreshnessStatus(double decayedLoad) {
    if (decayedLoad >= 15) return 'Overworked';
    if (decayedLoad >= 10) return 'Worked';
    if (decayedLoad >= 5) return 'Neutral';
    if (decayedLoad >= 1) return 'Ready';
    return 'Undertrained';
  }
}
