import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

/// Load Score Calculator
/// 
/// Calculates training stress by combining volume and intensity.
/// This provides a better metric for comparing workouts than volume alone.
/// 
/// Formula: Load Score = total volume (kg) × average intensity factor
/// 
/// Intensity factor is calculated per set based on weight relative to estimated 1RM,
/// then averaged across all completed sets.
class LoadScoreCalculator {
  /// Calculate Load Score for a workout
  /// 
  /// Returns a score that reflects both how much weight was moved (volume)
  /// and how heavy the sets were relative to max capacity (intensity)
  static double calculateWorkoutLoadScore(Workout workout) {
    if (!workout.isCompleted) return 0.0;
    
    final completedSets = <_SetData>[];
    
    // Collect all completed sets with their intensity data
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        if (set.isCompleted && set.weight > 0 && set.reps > 0) {
          // Convert weight to kg for consistent calculation
          final weightKg = UnitConversion.convert(set.weight, set.unit, 'kg');
          final estimated1RM = _estimateOneRepMax(weightKg, set.reps);
          final intensityFactor = _calculateIntensityFactor(weightKg, set.reps, estimated1RM);
          final volumeKg = weightKg * set.reps;
          
          completedSets.add(_SetData(
            volumeKg: volumeKg,
            intensityFactor: intensityFactor,
          ));
        }
      }
    }
    
    if (completedSets.isEmpty) return 0.0;
    
    // Calculate total volume and average intensity
    final totalVolume = completedSets.fold<double>(0.0, (sum, s) => sum + s.volumeKg);
    final avgIntensity = completedSets.fold<double>(0.0, (sum, s) => sum + s.intensityFactor) / completedSets.length;
    
    // Load Score = volume × average intensity
    // Scale by 0.01 to keep scores in readable range (100-1000 for most workouts)
    return totalVolume * avgIntensity * 0.01;
  }
  
  /// Calculate Load Score for a specific exercise within a workout
  static double calculateExerciseLoadScore(WorkoutExercise workoutExercise) {
    final completedSets = <_SetData>[];
    
    for (final set in workoutExercise.sets) {
      if (set.isCompleted && set.weight > 0 && set.reps > 0) {
        final weightKg = UnitConversion.convert(set.weight, set.unit, 'kg');
        final estimated1RM = _estimateOneRepMax(weightKg, set.reps);
        final intensityFactor = _calculateIntensityFactor(weightKg, set.reps, estimated1RM);
        final volumeKg = weightKg * set.reps;
        
        completedSets.add(_SetData(
          volumeKg: volumeKg,
          intensityFactor: intensityFactor,
        ));
      }
    }
    
    if (completedSets.isEmpty) return 0.0;
    
    final totalVolume = completedSets.fold<double>(0.0, (sum, s) => sum + s.volumeKg);
    final avgIntensity = completedSets.fold<double>(0.0, (sum, s) => sum + s.intensityFactor) / completedSets.length;
    
    return totalVolume * avgIntensity * 0.01;
  }
  
  /// Estimate one-rep max using Epley formula
  /// Formula: 1RM = weight × (1 + reps / 30)
  static double _estimateOneRepMax(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }
  
  /// Calculate intensity factor for a set
  /// Based on percentage of estimated 1RM being lifted
  /// 
  /// Returns a value typically between 0.5 and 1.0:
  /// - Light sets (40-60% 1RM): 0.5-0.7
  /// - Moderate sets (60-80% 1RM): 0.7-0.9
  /// - Heavy sets (80-95% 1RM): 0.9-1.0
  /// - Max effort sets (95%+ 1RM): 1.0+
  static double _calculateIntensityFactor(double weight, int reps, double estimated1RM) {
    if (estimated1RM <= 0) return 0.5; // Default for edge cases
    
    // Calculate percentage of 1RM
    final percentOf1RM = weight / estimated1RM;
    
    // Intensity factor scales non-linearly with % of 1RM
    // This reflects that heavier sets are disproportionately harder
    if (percentOf1RM >= 0.95) return 1.2; // Max effort
    if (percentOf1RM >= 0.90) return 1.1; // Very heavy
    if (percentOf1RM >= 0.85) return 1.0; // Heavy
    if (percentOf1RM >= 0.80) return 0.95;
    if (percentOf1RM >= 0.75) return 0.9;
    if (percentOf1RM >= 0.70) return 0.85;
    if (percentOf1RM >= 0.65) return 0.8;
    if (percentOf1RM >= 0.60) return 0.75;
    if (percentOf1RM >= 0.55) return 0.7;
    if (percentOf1RM >= 0.50) return 0.65;
    return 0.6; // Very light
  }
  
  /// Get difficulty label based on Load Score
  /// Provides human-readable classification of workout difficulty
  static String getLoadScoreLabel(double loadScore) {
    if (loadScore == 0) return 'No Data';
    if (loadScore < 100) return 'Very Light';
    if (loadScore < 200) return 'Light';
    if (loadScore < 350) return 'Moderate';
    if (loadScore < 500) return 'Hard';
    if (loadScore < 700) return 'Very Hard';
    return 'Extreme';
  }
  
  /// Get color for Load Score label
  /// Returns a color based on difficulty level
  static String getLoadScoreColor(double loadScore, bool isDark) {
    if (loadScore == 0) return isDark ? '#6B7280' : '#9CA3AF'; // Gray
    if (loadScore < 200) return isDark ? '#10B981' : '#059669'; // Green (light)
    if (loadScore < 350) return isDark ? '#3B82F6' : '#2563EB'; // Blue (moderate)
    if (loadScore < 500) return isDark ? '#F59E0B' : '#D97706'; // Orange (hard)
    if (loadScore < 700) return isDark ? '#EF4444' : '#DC2626'; // Red (very hard)
    return isDark ? '#9333EA' : '#7C3AED'; // Purple (extreme)
  }
  
  /// Calculate average Load Score for a list of workouts
  static double calculateAverageLoadScore(List<Workout> workouts) {
    if (workouts.isEmpty) return 0.0;
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    if (completedWorkouts.isEmpty) return 0.0;
    
    final totalScore = completedWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + calculateWorkoutLoadScore(w),
    );
    
    return totalScore / completedWorkouts.length;
  }
  
  /// Calculate Load Score trend (percentage change)
  /// Compares recent period to previous period
  static double calculateLoadScoreTrend({
    required List<Workout> allWorkouts,
    required int days,
  }) {
    final now = DateTime.now();
    final recentCutoff = now.subtract(Duration(days: days));
    final previousCutoff = now.subtract(Duration(days: days * 2));
    
    final recentWorkouts = allWorkouts
        .where((w) => w.isCompleted && w.startTime.isAfter(recentCutoff))
        .toList();
    
    final previousWorkouts = allWorkouts
        .where((w) => 
          w.isCompleted && 
          w.startTime.isAfter(previousCutoff) && 
          w.startTime.isBefore(recentCutoff)
        )
        .toList();
    
    final recentAvg = calculateAverageLoadScore(recentWorkouts);
    final previousAvg = calculateAverageLoadScore(previousWorkouts);
    
    if (previousAvg == 0) return 0.0;
    
    return ((recentAvg - previousAvg) / previousAvg) * 100;
  }
}

/// Internal class to hold set data for calculation
class _SetData {
  final double volumeKg;
  final double intensityFactor;
  
  _SetData({
    required this.volumeKg,
    required this.intensityFactor,
  });
}
