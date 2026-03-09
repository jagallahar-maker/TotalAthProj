import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';

class WorkoutService {
  static const String _storageKey = 'workouts';
  final _uuid = const Uuid();

  Future<List<Workout>> getAllWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      // Only populate sample data on first run (when key doesn't exist)
      // If data exists but is empty array, keep it empty (user reset)
      if (data == null) {
        final sampleData = _getSampleWorkouts();
        await _saveWorkouts(sampleData);
        return sampleData;
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final workouts = jsonList.map((json) {
        try {
          return Workout.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted workout entry: $e');
          return null;
        }
      }).whereType<Workout>().toList();
      
      if (workouts.isEmpty && jsonList.isNotEmpty) {
        await prefs.setString(_storageKey, json.encode([]));
      }
      
      return workouts;
    } catch (e) {
      debugPrint('Failed to load workouts: $e');
      return [];
    }
  }

  Future<Workout?> getWorkoutById(String id) async {
    final workouts = await getAllWorkouts();
    try {
      return workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Workout>> getWorkoutsByUserId(String userId) async {
    final workouts = await getAllWorkouts();
    return workouts.where((w) => w.userId == userId).toList();
  }

  Future<List<Workout>> getCompletedWorkouts(String userId) async {
    final workouts = await getWorkoutsByUserId(userId);
    return workouts.where((w) => w.isCompleted).toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<List<Workout>> getRecentWorkouts(String userId, {int limit = 10}) async {
    final workouts = await getCompletedWorkouts(userId);
    return workouts.take(limit).toList();
  }

  Future<Workout?> getActiveWorkout(String userId) async {
    final workouts = await getWorkoutsByUserId(userId);
    try {
      return workouts.firstWhere((w) => !w.isCompleted);
    } catch (e) {
      return null;
    }
  }

  Future<void> addWorkout(Workout workout) async {
    final workouts = await getAllWorkouts();
    workouts.add(workout);
    await _saveWorkouts(workouts);
  }

  Future<void> updateWorkout(Workout workout) async {
    final workouts = await getAllWorkouts();
    final index = workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      workouts[index] = workout;
      await _saveWorkouts(workouts);
    }
  }

  Future<void> deleteWorkout(String id) async {
    final workouts = await getAllWorkouts();
    workouts.removeWhere((w) => w.id == id);
    await _saveWorkouts(workouts);
  }

  Future<void> _saveWorkouts(List<Workout> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(workouts.map((w) => w.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save workouts: $e');
    }
  }

  /// Get the most recent completed workout that contains a specific exercise
  Future<WorkoutExercise?> getLastExerciseOccurrence(String userId, String exerciseId) async {
    final completedWorkouts = await getCompletedWorkouts(userId);
    
    // Search through completed workouts from most recent to oldest
    for (final workout in completedWorkouts) {
      for (final workoutExercise in workout.exercises) {
        if (workoutExercise.exercise.id == exerciseId) {
          // Only return if there are completed sets
          final completedSets = workoutExercise.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isNotEmpty) {
            // Return a copy with only completed sets
            return workoutExercise.copyWith(sets: completedSets);
          }
        }
      }
    }
    
    return null;
  }

  /// Get all completed workout occurrences of a specific exercise
  Future<List<Map<String, dynamic>>> getExerciseHistory(String userId, String exerciseId) async {
    final completedWorkouts = await getCompletedWorkouts(userId);
    final List<Map<String, dynamic>> history = [];
    
    for (final workout in completedWorkouts) {
      for (final workoutExercise in workout.exercises) {
        if (workoutExercise.exercise.id == exerciseId) {
          final completedSets = workoutExercise.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isNotEmpty) {
            history.add({
              'date': workout.startTime,
              'workoutName': workout.name,
              'exercise': workoutExercise.copyWith(sets: completedSets),
            });
          }
        }
      }
    }
    
    // Sort by date descending (most recent first)
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return history;
  }

  /// Calculate estimated 1RM using the formula: 1RM = weight × (1 + reps / 30)
  double calculateOneRepMax(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * (1 + reps / 30);
  }

  /// Get the best estimated 1RM from a list of sets
  double getBestOneRepMax(List<WorkoutSet> sets) {
    double best = 0;
    for (final set in sets) {
      if (set.isCompleted && set.weight > 0 && set.reps > 0) {
        final e1rm = calculateOneRepMax(set.weight, set.reps);
        if (e1rm > best) best = e1rm;
      }
    }
    return best;
  }

  /// Get the best set ever for a specific exercise across all workout history
  Future<WorkoutSet?> getBestSetEver(String userId, String exerciseId) async {
    final history = await getExerciseHistory(userId, exerciseId);
    
    WorkoutSet? bestSet;
    double bestE1RM = 0;
    
    for (final entry in history) {
      final exercise = entry['exercise'] as WorkoutExercise;
      for (final set in exercise.sets) {
        if (set.isCompleted && set.weight > 0 && set.reps > 0) {
          final e1rm = calculateOneRepMax(set.weight, set.reps);
          if (e1rm > bestE1RM) {
            bestE1RM = e1rm;
            bestSet = set;
          }
        }
      }
    }
    
    return bestSet;
  }

  /// Get exercise statistics for a specific time period
  Future<Map<String, dynamic>> getExerciseStats(String userId, String exerciseId, {int days = 30}) async {
    final history = await getExerciseHistory(userId, exerciseId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    // Filter to only include workouts within the time period
    final recentHistory = history.where((h) => 
      (h['date'] as DateTime).isAfter(cutoffDate)
    ).toList();
    
    double totalVolume = 0;
    double bestE1RM = 0;
    WorkoutSet? bestSet;
    
    for (final entry in recentHistory) {
      final exercise = entry['exercise'] as WorkoutExercise;
      totalVolume += exercise.totalVolume;
      
      for (final set in exercise.sets) {
        if (set.isCompleted) {
          final e1rm = calculateOneRepMax(set.weight, set.reps);
          if (e1rm > bestE1RM) {
            bestE1RM = e1rm;
            bestSet = set;
          }
        }
      }
    }
    
    return {
      'totalVolume': totalVolume,
      'workoutCount': recentHistory.length,
      'bestE1RM': bestE1RM,
      'bestSet': bestSet,
    };
  }

  /// Get volume progression data for charting
  Future<List<Map<String, dynamic>>> getVolumeProgression(String userId, String exerciseId, {int days = 30}) async {
    final history = await getExerciseHistory(userId, exerciseId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentHistory = history.where((h) => 
      (h['date'] as DateTime).isAfter(cutoffDate)
    ).toList();
    
    return recentHistory.map((entry) {
      final exercise = entry['exercise'] as WorkoutExercise;
      return {
        'date': entry['date'] as DateTime,
        'volume': exercise.totalVolume,
      };
    }).toList()..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  /// Get top weight progression data for charting
  Future<List<Map<String, dynamic>>> getWeightProgression(String userId, String exerciseId, {int days = 30}) async {
    final history = await getExerciseHistory(userId, exerciseId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentHistory = history.where((h) => 
      (h['date'] as DateTime).isAfter(cutoffDate)
    ).toList();
    
    return recentHistory.map((entry) {
      final exercise = entry['exercise'] as WorkoutExercise;
      double topWeight = 0;
      
      for (final set in exercise.sets) {
        if (set.isCompleted && set.weight > topWeight) {
          topWeight = set.weight;
        }
      }
      
      return {
        'date': entry['date'] as DateTime,
        'weight': topWeight,
      };
    }).toList()..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  /// Generate smart progression suggestion based on last completed workout
  /// Returns a map with 'suggestedWeight' and 'reason'
  Future<Map<String, dynamic>?> getProgressionSuggestion(String userId, String exerciseId) async {
    final lastExercise = await getLastExerciseOccurrence(userId, exerciseId);
    if (lastExercise == null || lastExercise.sets.isEmpty) {
      return null;
    }

    final completedSets = lastExercise.sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) {
      return null;
    }

    // Get working sets (exclude warmup - typically sets with consistent weight)
    // Find the most common weight used
    final weightCounts = <double, int>{};
    for (final set in completedSets) {
      weightCounts[set.weight] = (weightCounts[set.weight] ?? 0) + 1;
    }
    
    // Find the heaviest weight used in multiple sets (working weight)
    double workingWeight = 0;
    int maxCount = 0;
    for (final entry in weightCounts.entries) {
      if (entry.value >= maxCount && entry.key >= workingWeight) {
        workingWeight = entry.key;
        maxCount = entry.value;
      }
    }

    // Get all sets with working weight
    final workingSets = completedSets.where((s) => s.weight == workingWeight).toList();
    if (workingSets.isEmpty) {
      return null;
    }

    // Analyze performance across working sets
    final repsPerSet = workingSets.map((s) => s.reps).toList();
    final avgReps = repsPerSet.reduce((a, b) => a + b) / repsPerSet.length;
    final minReps = repsPerSet.reduce((a, b) => a < b ? a : b);
    final maxReps = repsPerSet.reduce((a, b) => a > b ? a : b);
    final repDropOff = maxReps - minReps;

    // Determine target rep range (common ranges: 1-5, 6-8, 8-12, 12-15, 15+)
    int targetReps;
    if (avgReps <= 5) {
      targetReps = 5;
    } else if (avgReps <= 8) {
      targetReps = 8;
    } else if (avgReps <= 12) {
      targetReps = 12;
    } else {
      targetReps = 15;
    }

    // Decision logic
    String reason;
    double suggestedWeight;

    // Rule 1: All sets hit target reps or higher -> increase weight
    if (minReps >= targetReps) {
      // Suggest 2.5-5% increase depending on exercise type
      final increment = workingWeight < 50 ? 2.5 : (workingWeight * 0.025).roundToDouble();
      suggestedWeight = workingWeight + increment;
      reason = 'All sets hit $targetReps+ reps. Time to increase weight!';
    }
    // Rule 2: Most sets close to target (within 1-2 reps) -> keep weight
    else if (avgReps >= targetReps - 2 && repDropOff <= 3) {
      suggestedWeight = workingWeight;
      reason = 'Close to target. Try to beat ${maxReps} reps on all sets.';
    }
    // Rule 3: Significant drop-off across sets -> hold or reduce slightly
    else if (repDropOff > 4 || minReps < targetReps - 3) {
      final reduction = workingWeight < 50 ? 2.5 : (workingWeight * 0.025).roundToDouble();
      suggestedWeight = (workingWeight - reduction).clamp(0, double.infinity);
      reason = 'Reps dropped significantly. Consider reducing weight slightly.';
    }
    // Rule 4: Default - keep same weight and push for more reps
    else {
      suggestedWeight = workingWeight;
      reason = 'Keep the weight and aim for ${targetReps} reps on all sets.';
    }

    return {
      'suggestedWeight': suggestedWeight,
      'reason': reason,
      'lastWeight': workingWeight,
      'lastReps': repsPerSet,
    };
  }

  List<Workout> _getSampleWorkouts() {
    final now = DateTime.now();
    final userId = 'user_1';
    
    // Create sample workouts with historical dates
    final workout3DaysAgo = now.subtract(const Duration(days: 3));
    final workout5DaysAgo = now.subtract(const Duration(days: 5));
    final workout7DaysAgo = now.subtract(const Duration(days: 7));
    
    return [
      // Most recent workout - 3 days ago
      Workout(
        id: _uuid.v4(),
        userId: userId,
        name: 'Upper Push',
        exercises: [
          WorkoutExercise(
            id: _uuid.v4(),
            exercise: Exercise(
              id: 'bench_press',
              name: 'Bench Press',
              primaryMuscleGroup: MuscleGroup.chest,
              equipment: EquipmentType.barbell,
              calorieCategory: CalorieCategory.compoundUpperBody,
              createdAt: workout3DaysAgo,
              updatedAt: workout3DaysAgo,
            ),
            sets: [
              WorkoutSet(id: _uuid.v4(), setNumber: 1, weight: 100, unit: 'kg', reps: 10, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 2, weight: 100, unit: 'kg', reps: 9, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 3, weight: 100, unit: 'kg', reps: 8, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
            ],
            createdAt: workout3DaysAgo,
            updatedAt: workout3DaysAgo,
          ),
          WorkoutExercise(
            id: _uuid.v4(),
            exercise: Exercise(
              id: 'overhead_press',
              name: 'Overhead Press',
              primaryMuscleGroup: MuscleGroup.shoulders,
              equipment: EquipmentType.barbell,
              calorieCategory: CalorieCategory.compoundUpperBody,
              createdAt: workout3DaysAgo,
              updatedAt: workout3DaysAgo,
            ),
            sets: [
              WorkoutSet(id: _uuid.v4(), setNumber: 1, weight: 60, unit: 'kg', reps: 10, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 2, weight: 60, unit: 'kg', reps: 9, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 3, weight: 60, unit: 'kg', reps: 8, isCompleted: true, completedAt: workout3DaysAgo, createdAt: workout3DaysAgo, updatedAt: workout3DaysAgo),
            ],
            createdAt: workout3DaysAgo,
            updatedAt: workout3DaysAgo,
          ),
        ],
        startTime: workout3DaysAgo,
        endTime: workout3DaysAgo.add(const Duration(hours: 1, minutes: 15)),
        isCompleted: true,
        createdAt: workout3DaysAgo,
        updatedAt: workout3DaysAgo,
      ),
      // 5 days ago workout
      Workout(
        id: _uuid.v4(),
        userId: userId,
        name: 'Lower Body',
        exercises: [
          WorkoutExercise(
            id: _uuid.v4(),
            exercise: Exercise(
              id: 'back_squat',
              name: 'Back Squat',
              primaryMuscleGroup: MuscleGroup.legs,
              equipment: EquipmentType.barbell,
              calorieCategory: CalorieCategory.compoundLowerBody,
              createdAt: workout5DaysAgo,
              updatedAt: workout5DaysAgo,
            ),
            sets: [
              WorkoutSet(id: _uuid.v4(), setNumber: 1, weight: 120, unit: 'kg', reps: 10, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 2, weight: 120, unit: 'kg', reps: 9, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 3, weight: 120, unit: 'kg', reps: 8, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 4, weight: 120, unit: 'kg', reps: 7, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
            ],
            createdAt: workout5DaysAgo,
            updatedAt: workout5DaysAgo,
          ),
          WorkoutExercise(
            id: _uuid.v4(),
            exercise: Exercise(
              id: 'deadlift',
              name: 'Deadlift',
              primaryMuscleGroup: MuscleGroup.back,
              equipment: EquipmentType.barbell,
              calorieCategory: CalorieCategory.compoundLowerBody,
              createdAt: workout5DaysAgo,
              updatedAt: workout5DaysAgo,
            ),
            sets: [
              WorkoutSet(id: _uuid.v4(), setNumber: 1, weight: 140, unit: 'kg', reps: 8, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 2, weight: 140, unit: 'kg', reps: 7, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 3, weight: 140, unit: 'kg', reps: 6, isCompleted: true, completedAt: workout5DaysAgo, createdAt: workout5DaysAgo, updatedAt: workout5DaysAgo),
            ],
            createdAt: workout5DaysAgo,
            updatedAt: workout5DaysAgo,
          ),
        ],
        startTime: workout5DaysAgo,
        endTime: workout5DaysAgo.add(const Duration(hours: 1, minutes: 30)),
        isCompleted: true,
        createdAt: workout5DaysAgo,
        updatedAt: workout5DaysAgo,
      ),
      // 7 days ago workout
      Workout(
        id: _uuid.v4(),
        userId: userId,
        name: 'Upper Pull',
        exercises: [
          WorkoutExercise(
            id: _uuid.v4(),
            exercise: Exercise(
              id: 'pull_ups',
              name: 'Pull-Ups',
              primaryMuscleGroup: MuscleGroup.back,
              equipment: EquipmentType.bodyweight,
              calorieCategory: CalorieCategory.compoundUpperBody,
              createdAt: workout7DaysAgo,
              updatedAt: workout7DaysAgo,
            ),
            sets: [
              WorkoutSet(id: _uuid.v4(), setNumber: 1, weight: 0, unit: 'kg', reps: 12, isCompleted: true, completedAt: workout7DaysAgo, createdAt: workout7DaysAgo, updatedAt: workout7DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 2, weight: 0, unit: 'kg', reps: 10, isCompleted: true, completedAt: workout7DaysAgo, createdAt: workout7DaysAgo, updatedAt: workout7DaysAgo),
              WorkoutSet(id: _uuid.v4(), setNumber: 3, weight: 0, unit: 'kg', reps: 8, isCompleted: true, completedAt: workout7DaysAgo, createdAt: workout7DaysAgo, updatedAt: workout7DaysAgo),
            ],
            createdAt: workout7DaysAgo,
            updatedAt: workout7DaysAgo,
          ),
        ],
        startTime: workout7DaysAgo,
        endTime: workout7DaysAgo.add(const Duration(hours: 1)),
        isCompleted: true,
        createdAt: workout7DaysAgo,
        updatedAt: workout7DaysAgo,
      ),
    ];
  }
}
