import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

/// Simple volume-based calorie estimation for resistance training
/// 
/// Calculates calories based on total lifting volume (weight × reps × sets)
/// with realistic multipliers per exercise category
class CalorieCalculator {
  /// Calculate estimated calories burned for an entire workout
  static double calculateWorkoutCalories(
    Workout workout, {
    double? userBodyweightKg,
  }) {
    double totalCalories = 0.0;
    
    for (final exercise in workout.exercises) {
      totalCalories += calculateExerciseCalories(
        exercise,
        userBodyweightKg: userBodyweightKg,
      );
    }
    
    return totalCalories;
  }
  
  /// Calculate estimated calories burned for a single exercise
  static double calculateExerciseCalories(
    WorkoutExercise workoutExercise, {
    double? userBodyweightKg,
  }) {
    final exercise = workoutExercise.exercise;
    final completedSets = workoutExercise.sets.where((set) => 
      set.isCompleted && set.weight > 0 && set.reps > 0
    ).toList();
    
    if (completedSets.isEmpty) return 0.0;
    
    // Calculate total volume for this exercise
    double totalVolumeLb = 0.0;
    
    for (final set in completedSets) {
      // Convert all weights to pounds for consistent calculation
      final weightLb = UnitConversion.convert(set.weight, set.unit, 'lb');
      final volume = weightLb * set.reps;
      totalVolumeLb += volume;
    }
    
    // Get multiplier based on exercise type
    final multiplier = _getExerciseMultiplier(exercise);
    
    // Calculate calories: volume × multiplier
    return totalVolumeLb * multiplier;
  }
  
  /// Get calorie multiplier based on exercise calorie category
  /// 
  /// Base multipliers per category (applied to total volume in lb):
  /// - Compound Lower Body: 1.0x (highest calorie burn)
  /// - Compound Upper Body: 0.85x
  /// - Isolation: 0.65x
  /// - Bodyweight/Core: 0.55x
  /// 
  /// These multipliers produce realistic totals:
  /// - Small single exercise: ~10-30 kcal
  /// - Typical upper body workout: ~150-300 kcal
  /// - Heavy leg workout: ~250-450 kcal
  static double _getExerciseMultiplier(Exercise exercise) {
    // Use the calorie category to determine multiplier
    switch (exercise.calorieCategory) {
      case CalorieCategory.compoundLowerBody:
        return 0.008; // 1.0x relative scale
      case CalorieCategory.compoundUpperBody:
        return 0.0068; // 0.85x relative scale
      case CalorieCategory.isolation:
        return 0.0052; // 0.65x relative scale
      case CalorieCategory.bodyweightCore:
        return 0.0044; // 0.55x relative scale
    }
  }
  
  /// Calculate average calories per minute for the workout
  /// Useful for displaying workout intensity
  static double calculateCaloriesPerMinute(Workout workout, {double? userBodyweightKg}) {
    final totalCalories = calculateWorkoutCalories(workout, userBodyweightKg: userBodyweightKg);
    final durationMinutes = workout.duration.inMinutes;
    
    if (durationMinutes <= 0) return 0.0;
    return totalCalories / durationMinutes;
  }
}
