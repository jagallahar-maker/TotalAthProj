import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/exercise.dart';

class RoutineService {
  static const String _storageKey = 'routines';
  final _uuid = const Uuid();

  Future<List<Routine>> getAllRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      if (data == null) {
        final sampleData = _getSampleRoutines();
        await _saveRoutines(sampleData);
        return sampleData;
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final routines = jsonList.map((json) {
        try {
          return Routine.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted routine entry: $e');
          return null;
        }
      }).whereType<Routine>().toList();
      
      return routines;
    } catch (e) {
      debugPrint('Failed to load routines: $e');
      return [];
    }
  }

  Future<Routine?> getRoutineById(String id) async {
    final routines = await getAllRoutines();
    try {
      return routines.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Routine>> getRoutinesByUserId(String userId) async {
    final routines = await getAllRoutines();
    return routines.where((r) => r.userId == userId).toList();
  }

  Future<void> addRoutine(Routine routine) async {
    final routines = await getAllRoutines();
    routines.add(routine);
    await _saveRoutines(routines);
  }

  Future<void> updateRoutine(Routine routine) async {
    final routines = await getAllRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      routines[index] = routine;
      await _saveRoutines(routines);
    }
  }

  Future<void> deleteRoutine(String id) async {
    final routines = await getAllRoutines();
    routines.removeWhere((r) => r.id == id);
    await _saveRoutines(routines);
  }

  Future<void> _saveRoutines(List<Routine> routines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(routines.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save routines: $e');
    }
  }

  List<Routine> _getSampleRoutines() {
    final now = DateTime.now();
    final userId = 'user_1';
    
    return [
      Routine(
        id: _uuid.v4(),
        userId: userId,
        name: 'Push Day A',
        exerciseIds: [
          'bench_press',
          'incline_dumbbell_press',
          'overhead_press',
          'lateral_raises',
          'cable_flyes',
          'tricep_pushdowns',
          'overhead_tricep_extension',
          'dips',
        ],
        targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.arms],
        estimatedDurationMinutes: 75,
        notes: 'Focus on progressive overload, chest and shoulder hypertrophy',
        createdAt: now,
        updatedAt: now,
      ),
      Routine(
        id: _uuid.v4(),
        userId: userId,
        name: 'Leg Hypertrophy',
        exerciseIds: [
          'back_squat',
          'leg_press',
          'romanian_deadlift',
          'walking_lunges',
          'leg_curl',
          'leg_extension',
        ],
        targetMuscleGroups: [MuscleGroup.legs],
        estimatedDurationMinutes: 90,
        notes: 'High volume leg day for quad and glute development',
        createdAt: now,
        updatedAt: now,
      ),
      Routine(
        id: _uuid.v4(),
        userId: userId,
        name: 'Back & Biceps',
        exerciseIds: [
          'deadlift',
          'pull_ups',
          'barbell_rows',
          't_bar_row',
          'face_pulls',
          'barbell_curl',
          'hammer_curls',
        ],
        targetMuscleGroups: [MuscleGroup.back, MuscleGroup.arms],
        estimatedDurationMinutes: 60,
        notes: 'Heavy pulls with bicep volume',
        createdAt: now,
        updatedAt: now,
      ),
      Routine(
        id: _uuid.v4(),
        userId: userId,
        name: 'Full Body Power',
        exerciseIds: [
          'back_squat',
          'bench_press',
          'deadlift',
          'overhead_press',
          'pull_ups',
        ],
        targetMuscleGroups: [MuscleGroup.legs, MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders],
        estimatedDurationMinutes: 70,
        notes: 'Compound movements for strength and power',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
