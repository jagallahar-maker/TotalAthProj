import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/exercise.dart';

class ExerciseService {
  static const String _storageKey = 'exercises';
  final _uuid = const Uuid();

  Future<List<Exercise>> getAllExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      if (data == null) {
        final sampleData = _getSampleExercises();
        await _saveExercises(sampleData);
        return sampleData;
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final exercises = jsonList.map((json) {
        try {
          return Exercise.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted exercise entry: $e');
          return null;
        }
      }).whereType<Exercise>().toList();
      
      if (exercises.isEmpty && jsonList.isNotEmpty) {
        final sampleData = _getSampleExercises();
        await _saveExercises(sampleData);
        return sampleData;
      }
      
      // Migrate: Add missing Smith Machine exercises for existing users
      var updatedExercises = await _addMissingSmithMachineExercises(exercises);
      
      // Migrate: Standardize exercise names
      updatedExercises = await _standardizeExerciseNames(updatedExercises);
      
      // Migrate: Add missing exercises from expanded database
      updatedExercises = await _addMissingExpandedExercises(updatedExercises);
      
      // Migrate: Add calorie categories to existing exercises
      updatedExercises = await _addCalorieCategories(updatedExercises);
      
      return updatedExercises;
    } catch (e) {
      debugPrint('Failed to load exercises: $e');
      return _getSampleExercises();
    }
  }

  Future<Exercise?> getExerciseById(String id) async {
    final exercises = await getAllExercises();
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup group) async {
    final exercises = await getAllExercises();
    return exercises.where((e) => e.primaryMuscleGroup == group || e.secondaryMuscleGroups.contains(group)).toList();
  }

  Future<void> addExercise(Exercise exercise) async {
    final exercises = await getAllExercises();
    exercises.add(exercise);
    await _saveExercises(exercises);
  }

  Future<void> updateExercise(Exercise exercise) async {
    final exercises = await getAllExercises();
    final index = exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      exercises[index] = exercise;
      await _saveExercises(exercises);
    }
  }

  Future<void> deleteExercise(String id) async {
    final exercises = await getAllExercises();
    exercises.removeWhere((e) => e.id == id);
    await _saveExercises(exercises);
  }

  Future<void> _saveExercises(List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(exercises.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save exercises: $e');
    }
  }

  /// Add calorie categories to existing exercises
  Future<List<Exercise>> _addCalorieCategories(List<Exercise> existingExercises) async {
    // Map of exercise names to their calorie categories
    final categoryMap = _getCalorieCategoryMap();
    
    bool needsUpdate = false;
    final updatedExercises = existingExercises.map((exercise) {
      final category = categoryMap[exercise.name];
      if (category != null && exercise.calorieCategory != category) {
        debugPrint('Adding calorie category to: ${exercise.name} -> ${category.name}');
        needsUpdate = true;
        return exercise.copyWith(
          calorieCategory: category,
          updatedAt: DateTime.now(),
        );
      }
      return exercise;
    }).toList();

    if (needsUpdate) {
      debugPrint('✅ Added calorie categories to exercises');
      await _saveExercises(updatedExercises);
    }

    return updatedExercises;
  }

  /// Get calorie category mapping for all exercises
  Map<String, CalorieCategory> _getCalorieCategoryMap() {
    return {
      // COMPOUND LOWER BODY
      'Back Squat': CalorieCategory.compoundLowerBody,
      'Front Squat': CalorieCategory.compoundLowerBody,
      'Deadlift': CalorieCategory.compoundLowerBody,
      'Romanian Deadlift': CalorieCategory.compoundLowerBody,
      'Leg Press': CalorieCategory.compoundLowerBody,
      'Hack Squat': CalorieCategory.compoundLowerBody,
      'Smith Machine Squat': CalorieCategory.compoundLowerBody,
      'Smith Machine Romanian Deadlift': CalorieCategory.compoundLowerBody,
      'Smith Machine Split Squat': CalorieCategory.compoundLowerBody,
      'Smith Machine Hip Thrust': CalorieCategory.compoundLowerBody,
      'Walking Lunge': CalorieCategory.compoundLowerBody,
      'Bulgarian Split Squat': CalorieCategory.compoundLowerBody,
      'Goblet Squat': CalorieCategory.compoundLowerBody,
      'Dumbbell Step-Up': CalorieCategory.compoundLowerBody,
      
      // COMPOUND UPPER BODY
      'Barbell Bench Press': CalorieCategory.compoundUpperBody,
      'Dumbbell Bench Press': CalorieCategory.compoundUpperBody,
      'Incline Dumbbell Press': CalorieCategory.compoundUpperBody,
      'Decline Dumbbell Press': CalorieCategory.compoundUpperBody,
      'Smith Machine Bench Press': CalorieCategory.compoundUpperBody,
      'Smith Machine Incline Press': CalorieCategory.compoundUpperBody,
      'Smith Machine Decline Press': CalorieCategory.compoundUpperBody,
      'Barbell Overhead Press': CalorieCategory.compoundUpperBody,
      'Dumbbell Shoulder Press': CalorieCategory.compoundUpperBody,
      'Arnold Press': CalorieCategory.compoundUpperBody,
      'Pull-Ups': CalorieCategory.compoundUpperBody,
      'Weighted Pull-Ups': CalorieCategory.compoundUpperBody,
      'Chin-Ups': CalorieCategory.compoundUpperBody,
      'Weighted Chin-Ups': CalorieCategory.compoundUpperBody,
      'Barbell Bent Over Row': CalorieCategory.compoundUpperBody,
      'Smith Machine Row': CalorieCategory.compoundUpperBody,
      'Hammer Strength Row': CalorieCategory.compoundUpperBody,
      'Hammer Strength High Row': CalorieCategory.compoundUpperBody,
      'Chest Supported Row': CalorieCategory.compoundUpperBody,
      'One Arm Dumbbell Row': CalorieCategory.compoundUpperBody,
      'Lat Pulldown': CalorieCategory.compoundUpperBody,
      'Seated Cable Row': CalorieCategory.compoundUpperBody,
      'Hammer Strength Bench Press': CalorieCategory.compoundUpperBody,
      'Hammer Strength Incline Press': CalorieCategory.compoundUpperBody,
      'Hammer Strength Decline Press': CalorieCategory.compoundUpperBody,
      
      // ISOLATION
      'Cable Fly': CalorieCategory.isolation,
      'Low Cable Fly': CalorieCategory.isolation,
      'High Cable Fly': CalorieCategory.isolation,
      'Pec Deck': CalorieCategory.isolation,
      'Leg Extension': CalorieCategory.isolation,
      'Seated Leg Curl': CalorieCategory.isolation,
      'Lying Leg Curl': CalorieCategory.isolation,
      'Standing Calf Raise': CalorieCategory.isolation,
      'Seated Calf Raise': CalorieCategory.isolation,
      'Dumbbell Lateral Raise': CalorieCategory.isolation,
      'Cable Lateral Raise': CalorieCategory.isolation,
      'Cable Front Raise': CalorieCategory.isolation,
      'Rear Delt Fly': CalorieCategory.isolation,
      'Reverse Pec Deck': CalorieCategory.isolation,
      'Face Pulls': CalorieCategory.isolation,
      'Barbell Curl': CalorieCategory.isolation,
      'EZ Bar Curl': CalorieCategory.isolation,
      'Hammer Curls': CalorieCategory.isolation,
      'Incline Dumbbell Curl': CalorieCategory.isolation,
      'Cable Curl': CalorieCategory.isolation,
      'Rope Hammer Curl': CalorieCategory.isolation,
      'Rope Pushdown': CalorieCategory.isolation,
      'Tricep Pushdown': CalorieCategory.isolation,
      'Overhead Cable Tricep Extension': CalorieCategory.isolation,
      'EZ Bar Skull Crusher': CalorieCategory.isolation,
      'Smith Machine Shrugs': CalorieCategory.isolation,
      'Smith Machine Calf Raises': CalorieCategory.isolation,
      'Dumbbell Fly': CalorieCategory.isolation,
      'Incline Dumbbell Fly': CalorieCategory.isolation,
      'Machine Chest Press': CalorieCategory.isolation,
      'Incline Machine Press': CalorieCategory.isolation,
      'T Bar Row': CalorieCategory.isolation,
      'Straight Arm Pulldown': CalorieCategory.isolation,
      'Machine Row': CalorieCategory.isolation,
      'Dumbbell Lunge': CalorieCategory.isolation,
      'Dumbbell Romanian Deadlift': CalorieCategory.isolation,
      'Machine Shoulder Press': CalorieCategory.isolation,
      'Smith Machine Shoulder Press': CalorieCategory.isolation,
      'Smith Machine Close Grip Press': CalorieCategory.isolation,
      
      // BODYWEIGHT/CORE
      'Plank': CalorieCategory.bodyweightCore,
      'Weighted Plank': CalorieCategory.bodyweightCore,
      'Ab Wheel Rollout': CalorieCategory.bodyweightCore,
      'Hanging Leg Raise': CalorieCategory.bodyweightCore,
      'Cable Crunch': CalorieCategory.bodyweightCore,
      'Russian Twist': CalorieCategory.bodyweightCore,
      'Bench Dips': CalorieCategory.bodyweightCore,
      'Chest Dips': CalorieCategory.bodyweightCore,
    };
  }

  /// Add missing exercises for existing users (Smith Machine exercises)
  Future<List<Exercise>> _addMissingSmithMachineExercises(List<Exercise> existingExercises) async {
    final now = DateTime.now();
    final missingExercises = [
      // Smith Machine exercises
      ('Smith Machine Bench Press', MuscleGroup.chest, [MuscleGroup.shoulders, MuscleGroup.arms], EquipmentType.smithMachine, CalorieCategory.compoundUpperBody),
      ('Smith Machine Incline Press', MuscleGroup.chest, [MuscleGroup.shoulders], EquipmentType.smithMachine, CalorieCategory.compoundUpperBody),
      ('Smith Machine Decline Press', MuscleGroup.chest, [MuscleGroup.shoulders, MuscleGroup.arms], EquipmentType.smithMachine, CalorieCategory.compoundUpperBody),
      ('Smith Machine Row', MuscleGroup.back, <MuscleGroup>[], EquipmentType.smithMachine, CalorieCategory.compoundUpperBody),
      ('Smith Machine Squat', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.smithMachine, CalorieCategory.compoundLowerBody),
      ('Smith Machine Split Squat', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.smithMachine, CalorieCategory.compoundLowerBody),
      ('Smith Machine Calf Raises', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.smithMachine, CalorieCategory.isolation),
      ('Smith Machine Romanian Deadlift', MuscleGroup.legs, [MuscleGroup.back], EquipmentType.smithMachine, CalorieCategory.compoundLowerBody),
      ('Smith Machine Shoulder Press', MuscleGroup.shoulders, [MuscleGroup.arms], EquipmentType.smithMachine, CalorieCategory.isolation),
      ('Smith Machine Shrugs', MuscleGroup.shoulders, [MuscleGroup.back], EquipmentType.smithMachine, CalorieCategory.isolation),
      ('Smith Machine Close Grip Press', MuscleGroup.arms, [MuscleGroup.chest], EquipmentType.smithMachine, CalorieCategory.isolation),
    ];

    bool needsUpdate = false;
    final updatedExercises = List<Exercise>.from(existingExercises);

    for (final (name, primaryMuscle, secondaryMuscles, equipment, category) in missingExercises) {
      final exists = existingExercises.any((ex) => ex.name == name);
      if (!exists) {
        debugPrint('Adding missing exercise: $name');
        updatedExercises.add(Exercise(
          id: _uuid.v4(),
          name: name,
          primaryMuscleGroup: primaryMuscle,
          secondaryMuscleGroups: secondaryMuscles,
          equipment: equipment,
          calorieCategory: category,
          createdAt: now,
          updatedAt: now,
        ));
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      final addedCount = updatedExercises.length - existingExercises.length;
      debugPrint('✅ Added $addedCount new Smith Machine exercises to database');
      await _saveExercises(updatedExercises);
    }

    return updatedExercises;
  }

  /// Add missing exercises from expanded exercise library
  Future<List<Exercise>> _addMissingExpandedExercises(List<Exercise> existingExercises) async {
    final now = DateTime.now();
    final missingExercises = [
      // Missing chest exercises
      ('Pec Deck', MuscleGroup.chest, <MuscleGroup>[], EquipmentType.machine, CalorieCategory.isolation),
      ('Hammer Strength Decline Press', MuscleGroup.chest, [MuscleGroup.shoulders, MuscleGroup.arms], EquipmentType.machine, CalorieCategory.compoundUpperBody),
      
      // Missing leg exercises
      ('Front Squat', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.barbell, CalorieCategory.compoundLowerBody),
      ('Smith Machine Hip Thrust', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.smithMachine, CalorieCategory.compoundLowerBody),
      ('Dumbbell Step-Up', MuscleGroup.legs, <MuscleGroup>[], EquipmentType.dumbbell, CalorieCategory.compoundLowerBody),
      
      // Missing back exercises
      ('Weighted Pull-Ups', MuscleGroup.back, [MuscleGroup.arms], EquipmentType.bodyweight, CalorieCategory.compoundUpperBody),
      ('Chin-Ups', MuscleGroup.back, [MuscleGroup.arms], EquipmentType.bodyweight, CalorieCategory.compoundUpperBody),
      ('Weighted Chin-Ups', MuscleGroup.back, [MuscleGroup.arms], EquipmentType.bodyweight, CalorieCategory.compoundUpperBody),
      
      // Missing core/bodyweight exercises
      ('Chest Dips', MuscleGroup.arms, [MuscleGroup.chest], EquipmentType.bodyweight, CalorieCategory.bodyweightCore),
    ];

    bool needsUpdate = false;
    final updatedExercises = List<Exercise>.from(existingExercises);

    for (final (name, primaryMuscle, secondaryMuscles, equipment, category) in missingExercises) {
      final exists = existingExercises.any((ex) => ex.name == name);
      if (!exists) {
        debugPrint('Adding missing exercise: $name');
        updatedExercises.add(Exercise(
          id: _uuid.v4(),
          name: name,
          primaryMuscleGroup: primaryMuscle,
          secondaryMuscleGroups: secondaryMuscles,
          equipment: equipment,
          calorieCategory: category,
          createdAt: now,
          updatedAt: now,
        ));
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      final addedCount = updatedExercises.length - existingExercises.length;
      debugPrint('✅ Added $addedCount new exercises from expanded library');
      await _saveExercises(updatedExercises);
    }

    return updatedExercises;
  }

  /// Standardize exercise names for existing users (preserves all history/PRs by ID)
  Future<List<Exercise>> _standardizeExerciseNames(List<Exercise> existingExercises) async {
    final nameUpdates = {
      'Cable Flyes': 'Cable Fly',
      'Bent Over Row': 'Barbell Bent Over Row',
      'Smith Machine RDL': 'Smith Machine Romanian Deadlift',
      'Lateral Raises': 'Dumbbell Lateral Raise',
      'Overhead Press': 'Barbell Overhead Press',
      'Tricep Dips': 'Bench Dips',
      'Skull Crushers': 'EZ Bar Skull Crusher',
    };

    bool needsUpdate = false;
    final updatedExercises = existingExercises.map((exercise) {
      if (nameUpdates.containsKey(exercise.name)) {
        final newName = nameUpdates[exercise.name]!;
        debugPrint('Renaming exercise: "${exercise.name}" → "$newName"');
        needsUpdate = true;
        return exercise.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
      }
      return exercise;
    }).toList();

    if (needsUpdate) {
      debugPrint('✅ Standardized exercise names');
      await _saveExercises(updatedExercises);
    }

    return updatedExercises;
  }

  List<Exercise> _getSampleExercises() {
    final now = DateTime.now();
    return [
      // Chest exercises
      Exercise(id: _uuid.v4(), name: 'Barbell Bench Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundUpperBody, imageUrl: 'assets/images/Fitness_barbell_bench_press_null_1772913392372.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Bench Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Incline Dumbbell Press', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, imageUrl: 'assets/images/Incline_dumbbell_press_null_1772913395237.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Decline Dumbbell Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Fly', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Incline Dumbbell Fly', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Cable Fly', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Low Cable Fly', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'High Cable Fly', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Machine Chest Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Incline Machine Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Strength Bench Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Strength Incline Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Bench Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Incline Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Decline Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Pec Deck', primaryMuscleGroup: MuscleGroup.chest, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Strength Decline Press', primaryMuscleGroup: MuscleGroup.chest, secondaryMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.arms], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      
      // Back exercises
      Exercise(id: _uuid.v4(), name: 'Deadlift', primaryMuscleGroup: MuscleGroup.back, secondaryMuscleGroups: [MuscleGroup.legs], equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundLowerBody, imageUrl: 'assets/images/Heavy_barbell_deadlift_gym_null_1772913391827.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Pull-Ups', primaryMuscleGroup: MuscleGroup.back, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.compoundUpperBody, imageUrl: 'assets/images/Pull_ups_exercise_null_1772913393801.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Weighted Pull-Ups', primaryMuscleGroup: MuscleGroup.back, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Chin-Ups', primaryMuscleGroup: MuscleGroup.back, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Weighted Chin-Ups', primaryMuscleGroup: MuscleGroup.back, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Barbell Bent Over Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'One Arm Dumbbell Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'T Bar Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Lat Pulldown', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, imageUrl: 'assets/images/Lat_pulldown_exercise_null_1772913396363.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Seated Cable Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Straight Arm Pulldown', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Chest Supported Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Machine Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Strength Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Strength High Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Row', primaryMuscleGroup: MuscleGroup.back, equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      
      // Leg exercises
      Exercise(id: _uuid.v4(), name: 'Back Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundLowerBody, imageUrl: 'assets/images/Back_squat_exercise_gym_null_1772913393177.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Front Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Leg Press', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundLowerBody, imageUrl: 'assets/images/Leg_press_machine_null_1772913397094.jpg', createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hack Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Bulgarian Split Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Lunge', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Walking Lunge', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Goblet Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Step-Up', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Romanian Deadlift', primaryMuscleGroup: MuscleGroup.legs, secondaryMuscleGroups: [MuscleGroup.back], equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Romanian Deadlift', primaryMuscleGroup: MuscleGroup.legs, secondaryMuscleGroups: [MuscleGroup.back], equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Leg Extension', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Seated Leg Curl', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Lying Leg Curl', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Standing Calf Raise', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Seated Calf Raise', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Split Squat', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Romanian Deadlift', primaryMuscleGroup: MuscleGroup.legs, secondaryMuscleGroups: [MuscleGroup.back], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Calf Raises', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Hip Thrust', primaryMuscleGroup: MuscleGroup.legs, equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.compoundLowerBody, createdAt: now, updatedAt: now),
      
      // Shoulder exercises
      Exercise(id: _uuid.v4(), name: 'Barbell Overhead Press', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Shoulder Press', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Arnold Press', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.compoundUpperBody, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Dumbbell Lateral Raise', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Cable Lateral Raise', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Cable Front Raise', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Face Pulls', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Rear Delt Fly', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Reverse Pec Deck', primaryMuscleGroup: MuscleGroup.shoulders, equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Machine Shoulder Press', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.machine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Shoulder Press', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.arms], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Shrugs', primaryMuscleGroup: MuscleGroup.shoulders, secondaryMuscleGroups: [MuscleGroup.back], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      
      // Arm exercises
      Exercise(id: _uuid.v4(), name: 'Barbell Curl', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'EZ Bar Curl', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hammer Curls', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Incline Dumbbell Curl', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.dumbbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Cable Curl', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Rope Hammer Curl', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Bench Dips', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Chest Dips', primaryMuscleGroup: MuscleGroup.arms, secondaryMuscleGroups: [MuscleGroup.chest], equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'EZ Bar Skull Crusher', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.barbell, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Tricep Pushdown', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Rope Pushdown', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Overhead Cable Tricep Extension', primaryMuscleGroup: MuscleGroup.arms, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Smith Machine Close Grip Press', primaryMuscleGroup: MuscleGroup.arms, secondaryMuscleGroups: [MuscleGroup.chest], equipment: EquipmentType.smithMachine, calorieCategory: CalorieCategory.isolation, createdAt: now, updatedAt: now),
      
      // Core exercises
      Exercise(id: _uuid.v4(), name: 'Plank', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Weighted Plank', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.other, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Ab Wheel Rollout', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.other, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Hanging Leg Raise', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Cable Crunch', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.cable, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
      Exercise(id: _uuid.v4(), name: 'Russian Twist', primaryMuscleGroup: MuscleGroup.core, equipment: EquipmentType.bodyweight, calorieCategory: CalorieCategory.bodyweightCore, createdAt: now, updatedAt: now),
    ];
  }
}
