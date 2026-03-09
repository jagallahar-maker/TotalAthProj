import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/training_program.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/exercise.dart';

class TrainingProgramService {
  static const String _storageKey = 'training_programs';
  final _uuid = const Uuid();

  Future<List<TrainingProgram>> getAllPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      if (data == null) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final programs = jsonList.map((json) {
        try {
          return TrainingProgram.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted program entry: $e');
          return null;
        }
      }).whereType<TrainingProgram>().toList();
      
      return programs;
    } catch (e) {
      debugPrint('Failed to load programs: $e');
      return [];
    }
  }

  Future<List<TrainingProgram>> getProgramsByUserId(String userId) async {
    final programs = await getAllPrograms();
    return programs.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<TrainingProgram?> getProgramById(String id) async {
    final programs = await getAllPrograms();
    try {
      return programs.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addProgram(TrainingProgram program) async {
    final programs = await getAllPrograms();
    programs.add(program);
    await _savePrograms(programs);
  }

  Future<void> updateProgram(TrainingProgram program) async {
    final programs = await getAllPrograms();
    final index = programs.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      programs[index] = program;
      await _savePrograms(programs);
    }
  }

  Future<void> deleteProgram(String id) async {
    final programs = await getAllPrograms();
    programs.removeWhere((p) => p.id == id);
    await _savePrograms(programs);
  }

  Future<void> _savePrograms(List<TrainingProgram> programs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(programs.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save programs: $e');
    }
  }

  /// Get starter program templates
  List<StarterProgram> getStarterPrograms() {
    return [
      StarterProgram(
        name: 'Push Pull Legs',
        description: '6-day split focusing on push, pull, and leg muscle groups. Ideal for intermediate to advanced lifters.',
        goal: ProgramGoal.hypertrophy,
        routineTemplates: [
          RoutineTemplate(
            name: 'Push Day',
            exerciseNames: [
              'Barbell Bench Press',
              'Incline Dumbbell Press',
              'Cable Fly',
              'Dumbbell Shoulder Press',
              'Dumbbell Lateral Raise',
              'Rope Pushdown',
            ],
            estimatedDurationMinutes: 75,
            notes: 'Focus on chest, shoulders, and triceps',
          ),
          RoutineTemplate(
            name: 'Pull Day',
            exerciseNames: [
              'Lat Pulldown',
              'Barbell Bent Over Row',
              'Smith Machine Row',
              'Face Pulls',
              'Barbell Curl',
              'Hammer Curls',
            ],
            estimatedDurationMinutes: 75,
            notes: 'Focus on back and biceps',
          ),
          RoutineTemplate(
            name: 'Legs Day',
            exerciseNames: [
              'Back Squat',
              'Leg Press',
              'Romanian Deadlift',
              'Leg Extension',
              'Lying Leg Curl',
              'Smith Machine Calf Raises',
            ],
            estimatedDurationMinutes: 90,
            notes: 'Complete leg development',
          ),
        ],
      ),
      StarterProgram(
        name: 'Upper Lower',
        description: '4-day split alternating between upper and lower body. Great for balanced strength and hypertrophy.',
        goal: ProgramGoal.strength,
        routineTemplates: [
          RoutineTemplate(
            name: 'Upper A',
            exerciseNames: [
              'Barbell Bench Press',
              'Barbell Bent Over Row',
              'Dumbbell Shoulder Press',
              'Pull-Ups',
              'Cable Lateral Raise',
              'Barbell Curl',
            ],
            estimatedDurationMinutes: 70,
            notes: 'Heavy compound focus',
          ),
          RoutineTemplate(
            name: 'Lower A',
            exerciseNames: [
              'Back Squat',
              'Romanian Deadlift',
              'Leg Press',
              'Leg Curl',
              'Standing Calf Raise',
            ],
            estimatedDurationMinutes: 75,
            notes: 'Squat and hinge focus',
          ),
          RoutineTemplate(
            name: 'Upper B',
            exerciseNames: [
              'Incline Dumbbell Press',
              'Lat Pulldown',
              'Dumbbell Fly',
              'Seated Cable Row',
              'Face Pulls',
              'Hammer Curls',
              'Rope Pushdown',
            ],
            estimatedDurationMinutes: 70,
            notes: 'Volume and accessory work',
          ),
          RoutineTemplate(
            name: 'Lower B',
            exerciseNames: [
              'Front Squat',
              'Leg Press',
              'Bulgarian Split Squat',
              'Leg Extension',
              'Seated Leg Curl',
              'Seated Calf Raise',
            ],
            estimatedDurationMinutes: 75,
            notes: 'Quad emphasis and unilateral work',
          ),
        ],
      ),
      StarterProgram(
        name: 'Full Body 3 Day',
        description: '3-day full body split. Perfect for beginners or those with limited training days per week.',
        goal: ProgramGoal.generalFitness,
        routineTemplates: [
          RoutineTemplate(
            name: 'Full Body A',
            exerciseNames: [
              'Back Squat',
              'Barbell Bench Press',
              'Lat Pulldown',
              'Dumbbell Shoulder Press',
              'Leg Curl',
              'Barbell Curl',
            ],
            estimatedDurationMinutes: 60,
            notes: 'Compound movement emphasis',
          ),
          RoutineTemplate(
            name: 'Full Body B',
            exerciseNames: [
              'Deadlift',
              'Incline Dumbbell Press',
              'Pull-Ups',
              'Leg Press',
              'Dumbbell Lateral Raise',
              'Rope Pushdown',
            ],
            estimatedDurationMinutes: 60,
            notes: 'Balanced full body workout',
          ),
          RoutineTemplate(
            name: 'Full Body C',
            exerciseNames: [
              'Front Squat',
              'Dumbbell Bench Press',
              'Barbell Bent Over Row',
              'Romanian Deadlift',
              'Face Pulls',
              'Hammer Curls',
            ],
            estimatedDurationMinutes: 60,
            notes: 'Variety and muscle balance',
          ),
        ],
      ),
      StarterProgram(
        name: 'Arnold Split',
        description: 'Classic bodybuilding split popularized by Arnold Schwarzenegger. Chest & back, shoulders & arms, legs.',
        goal: ProgramGoal.hypertrophy,
        routineTemplates: [
          RoutineTemplate(
            name: 'Chest & Back',
            exerciseNames: [
              'Barbell Bench Press',
              'Barbell Bent Over Row',
              'Incline Dumbbell Press',
              'Pull-Ups',
              'Cable Fly',
              'Seated Cable Row',
              'Dumbbell Fly',
            ],
            estimatedDurationMinutes: 80,
            notes: 'Antagonist superset training',
          ),
          RoutineTemplate(
            name: 'Shoulders & Arms',
            exerciseNames: [
              'Barbell Overhead Press',
              'Dumbbell Lateral Raise',
              'Face Pulls',
              'Barbell Curl',
              'Rope Pushdown',
              'Hammer Curls',
              'Overhead Cable Tricep Extension',
            ],
            estimatedDurationMinutes: 70,
            notes: 'High volume arm work',
          ),
          RoutineTemplate(
            name: 'Legs',
            exerciseNames: [
              'Back Squat',
              'Romanian Deadlift',
              'Leg Press',
              'Walking Lunge',
              'Leg Extension',
              'Lying Leg Curl',
              'Standing Calf Raise',
            ],
            estimatedDurationMinutes: 85,
            notes: 'Complete leg development',
          ),
        ],
      ),
    ];
  }

  /// Create a program from a starter template
  Future<({TrainingProgram program, List<Routine> routines})> createProgramFromStarter({
    required String userId,
    required StarterProgram starter,
    required List<Exercise> exercises,
  }) async {
    final now = DateTime.now();
    final createdRoutines = <Routine>[];

    // Create routines from templates
    for (final template in starter.routineTemplates) {
      // Find exercise IDs by name
      final exerciseIds = template.exerciseNames
          .map((name) {
            final exercise = exercises.where((e) => e.name == name).firstOrNull;
            return exercise?.id;
          })
          .whereType<String>()
          .toList();

      if (exerciseIds.isEmpty) {
        debugPrint('Warning: No exercises found for routine "${template.name}"');
        continue;
      }

      // Determine target muscle groups from exercises
      final targetMuscles = <MuscleGroup>{};
      for (final exerciseId in exerciseIds) {
        final exercise = exercises.firstWhere((e) => e.id == exerciseId);
        targetMuscles.add(exercise.primaryMuscleGroup);
        targetMuscles.addAll(exercise.secondaryMuscleGroups);
      }

      final routine = Routine(
        id: _uuid.v4(),
        userId: userId,
        name: template.name,
        exerciseIds: exerciseIds,
        targetMuscleGroups: targetMuscles.toList(),
        estimatedDurationMinutes: template.estimatedDurationMinutes,
        notes: template.notes,
        createdAt: now,
        updatedAt: now,
      );
      createdRoutines.add(routine);
    }

    // Create the program
    final program = TrainingProgram(
      id: _uuid.v4(),
      userId: userId,
      name: starter.name,
      description: starter.description,
      goal: starter.goal,
      routineIds: createdRoutines.map((r) => r.id).toList(),
      createdAt: now,
      updatedAt: now,
    );

    return (program: program, routines: createdRoutines);
  }
}

/// Starter program template
class StarterProgram {
  final String name;
  final String description;
  final ProgramGoal goal;
  final List<RoutineTemplate> routineTemplates;

  const StarterProgram({
    required this.name,
    required this.description,
    required this.goal,
    required this.routineTemplates,
  });
}

/// Routine template for starter programs
class RoutineTemplate {
  final String name;
  final List<String> exerciseNames; // Exercise names to match from library
  final int estimatedDurationMinutes;
  final String notes;

  const RoutineTemplate({
    required this.name,
    required this.exerciseNames,
    required this.estimatedDurationMinutes,
    required this.notes,
  });
}
