import 'package:flutter/foundation.dart';
import 'package:total_athlete/models/user.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/bodyweight_log.dart';
import 'package:total_athlete/models/personal_record.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/training_program.dart';
import 'package:total_athlete/services/user_service.dart';
import 'package:total_athlete/services/workout_service.dart';
import 'package:total_athlete/services/exercise_service.dart';
import 'package:total_athlete/services/bodyweight_service.dart';
import 'package:total_athlete/services/personal_record_service.dart';
import 'package:total_athlete/services/routine_service.dart';
import 'package:total_athlete/services/training_program_service.dart';
import 'package:total_athlete/services/weight_migration_service.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class AppProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseService _exerciseService = ExerciseService();
  final BodyweightService _bodyweightService = BodyweightService();
  final PersonalRecordService _prService = PersonalRecordService();
  final RoutineService _routineService = RoutineService();
  final TrainingProgramService _programService = TrainingProgramService();

  User? _currentUser;
  List<Workout> _workouts = [];
  List<Exercise> _exercises = [];
  List<BodyweightLog> _bodyweightLogs = [];
  List<PersonalRecord> _personalRecords = [];
  List<Routine> _routines = [];
  List<TrainingProgram> _programs = [];
  Workout? _activeWorkout;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<Workout> get workouts => _workouts;
  List<Exercise> get exercises => _exercises;
  List<BodyweightLog> get bodyweightLogs => _bodyweightLogs;
  List<PersonalRecord> get personalRecords => _personalRecords;
  List<Routine> get routines => _routines;
  List<TrainingProgram> get programs => _programs;
  Workout? get activeWorkout => _activeWorkout;
  bool get isLoading => _isLoading;
  WorkoutService get workoutService => _workoutService;
  TrainingProgramService get trainingProgramService => _programService;
  
  /// Get the current user's preferred unit ('kg' or 'lb')
  String get preferredUnit => _currentUser?.preferredUnit ?? 'kg';

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    final crashlytics = CrashlyticsService();
    
    try {
      // Run weight migration first (before loading data)
      await WeightMigrationService.runMigrationIfNeeded();
      
      _currentUser = await _userService.getCurrentUser();
      if (_currentUser != null) {
        // Set Crashlytics user context
        await crashlytics.setUserIdentifier(_currentUser!.id);
        await crashlytics.setUnitPreference(_currentUser!.preferredUnit);
        
        await Future.wait([
          loadWorkouts(),
          loadExercises(),
          loadBodyweightLogs(),
          loadPersonalRecords(),
          loadRoutines(),
          loadPrograms(),
        ]);
        _activeWorkout = await _workoutService.getActiveWorkout(_currentUser!.id);
        
        // Rebuild PRs from all completed workouts if we have workouts but no PRs
        final completedWorkouts = _workouts.where((w) => w.isCompleted).toList();
        if (completedWorkouts.isNotEmpty && _personalRecords.isEmpty) {
          debugPrint('🔄 Rebuilding PRs from ${completedWorkouts.length} completed workouts...');
          await _rebuildPersonalRecordsFromHistory();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize app: $e');
      await crashlytics.recordError(e, stackTrace, reason: 'App initialization failed');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkouts() async {
    if (_currentUser == null) return;
    _workouts = await _workoutService.getWorkoutsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> loadExercises() async {
    _exercises = await _exerciseService.getAllExercises();
    notifyListeners();
  }

  Future<void> loadBodyweightLogs() async {
    if (_currentUser == null) return;
    _bodyweightLogs = await _bodyweightService.getLogsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> loadPersonalRecords() async {
    if (_currentUser == null) return;
    _personalRecords = await _prService.getRecordsByUserId(_currentUser!.id);
    notifyListeners();
  }

  /// Detect and update personal records from a completed workout
  /// Checks for: heaviest single set, best estimated 1RM, and highest volume workout
  Future<void> _detectAndUpdatePersonalRecords(Workout workout) async {
    if (_currentUser == null || !workout.isCompleted) return;
    
    final userId = _currentUser!.id;
    bool hasNewPR = false;
    
    // Process each exercise in the completed workout
    for (var workoutExercise in workout.exercises) {
      final exercise = workoutExercise.exercise;
      final completedSets = workoutExercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0).toList();
      
      if (completedSets.isEmpty) continue;
      
      // Find the best set from this workout (by weight first, then reps)
      var bestSet = completedSets.first;
      var bestWeightKg = bestSet.unit == 'kg' ? bestSet.weight : bestSet.weight * 0.453592;
      
      for (var set in completedSets) {
        // Convert to kg for consistent comparison
        final weightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
        
        // Compare by weight first, then reps for ties
        if (weightKg > bestWeightKg || (weightKg == bestWeightKg && set.reps > bestSet.reps)) {
          bestWeightKg = weightKg;
          bestSet = set;
        }
      }
      
      // Calculate estimated 1RM for this set
      final bestE1RM = bestWeightKg * (1 + bestSet.reps / 30);
      
      // Get existing PR for this exercise (if any)
      final existingPR = _personalRecords.cast<PersonalRecord?>().firstWhere(
        (pr) => pr?.exerciseId == exercise.id,
        orElse: () => null,
      );
      
      // Determine if this is a new PR
      bool isNewPR = false;
      
      if (existingPR == null) {
        // No existing PR - this is automatically a new PR
        isNewPR = true;
      } else {
        // Convert existing PR weight to kg for comparison
        final existingWeightKg = existingPR.unit == 'kg' ? existingPR.weight : existingPR.weight * 0.453592;
        
        // Compare by weight first, then reps for ties
        if (bestWeightKg > existingWeightKg || (bestWeightKg == existingWeightKg && bestSet.reps > existingPR.reps)) {
          isNewPR = true;
        }
      }
      
      if (isNewPR) {
        // Create or update PR
        final now = DateTime.now();
        final newPR = PersonalRecord(
          id: existingPR?.id ?? _generateUuid(),
          userId: userId,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          weight: bestSet.weight,
          unit: bestSet.unit,
          reps: bestSet.reps,
          estimatedOneRepMax: bestE1RM,
          achievedDate: workout.startTime,
          createdAt: existingPR?.createdAt ?? now,
          updatedAt: now,
        );
        
        if (existingPR == null) {
          await _prService.addRecord(newPR);
          debugPrint('🏆 NEW PR: ${exercise.name} - ${bestSet.weight}${bestSet.unit} x ${bestSet.reps} (e1RM: ${bestE1RM.toStringAsFixed(1)}kg)');
        } else {
          await _prService.updateRecord(newPR);
          debugPrint('🏆 UPDATED PR: ${exercise.name} - ${bestSet.weight}${bestSet.unit} x ${bestSet.reps} (e1RM: ${bestE1RM.toStringAsFixed(1)}kg)');
        }
        
        hasNewPR = true;
      }
    }
    
    // Reload PRs if any were updated
    if (hasNewPR) {
      await loadPersonalRecords();
    }
  }
  
  String _generateUuid() {
    // Simple UUID generation (timestamp-based)
    return 'pr_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
  }

  /// Rebuild all personal records from workout history
  /// Used when initializing the app or after data import
  Future<void> _rebuildPersonalRecordsFromHistory() async {
    if (_currentUser == null) return;
    
    final userId = _currentUser!.id;
    final completedWorkouts = _workouts.where((w) => w.isCompleted).toList();
    
    if (completedWorkouts.isEmpty) return;
    
    // Map to track best performance per exercise: exerciseId -> best PR data
    final exerciseBestPRs = <String, Map<String, dynamic>>{};
    
    // Process all completed workouts
    for (var workout in completedWorkouts) {
      for (var workoutExercise in workout.exercises) {
        final exercise = workoutExercise.exercise;
        final completedSets = workoutExercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0).toList();
        
        if (completedSets.isEmpty) continue;
        
        // Find the best set from this workout
        for (var set in completedSets) {
          // Convert to kg for consistent comparison
          final weightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          // Calculate estimated 1RM
          final e1rm = weightKg * (1 + set.reps / 30);
          
          // Check if this is better than current best for this exercise
          final currentBest = exerciseBestPRs[exercise.id];
          
          if (currentBest == null) {
            // No existing best - this is the first
            exerciseBestPRs[exercise.id] = {
              'exerciseName': exercise.name,
              'weight': set.weight,
              'unit': set.unit,
              'reps': set.reps,
              'weightKg': weightKg,
              'estimatedOneRepMax': e1rm,
              'achievedDate': workout.startTime,
            };
          } else {
            // Compare by weight first, then reps for ties
            final currentBestWeightKg = currentBest['weightKg'] as double;
            final currentBestReps = currentBest['reps'] as int;
            
            if (weightKg > currentBestWeightKg || (weightKg == currentBestWeightKg && set.reps > currentBestReps)) {
              exerciseBestPRs[exercise.id] = {
                'exerciseName': exercise.name,
                'weight': set.weight,
                'unit': set.unit,
                'reps': set.reps,
                'weightKg': weightKg,
                'estimatedOneRepMax': e1rm,
                'achievedDate': workout.startTime,
              };
            }
          }
        }
      }
    }
    
    // Create PR records from best performances
    final now = DateTime.now();
    for (var entry in exerciseBestPRs.entries) {
      final exerciseId = entry.key;
      final prData = entry.value;
      
      final newPR = PersonalRecord(
        id: _generateUuid(),
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: prData['exerciseName'] as String,
        weight: prData['weight'] as double,
        unit: prData['unit'] as String,
        reps: prData['reps'] as int,
        estimatedOneRepMax: prData['estimatedOneRepMax'] as double,
        achievedDate: prData['achievedDate'] as DateTime,
        createdAt: now,
        updatedAt: now,
      );
      
      await _prService.addRecord(newPR);
      debugPrint('✅ Detected PR: ${newPR.exerciseName} - ${newPR.weight}${newPR.unit} x ${newPR.reps}');
    }
    
    // Reload PRs
    await loadPersonalRecords();
    debugPrint('🏆 Rebuilt ${exerciseBestPRs.length} personal records from workout history');
  }

  Future<void> loadRoutines() async {
    if (_currentUser == null) return;
    _routines = await _routineService.getRoutinesByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> addRoutine(Routine routine) async {
    await _routineService.addRoutine(routine);
    await loadRoutines();
  }

  Future<void> updateRoutine(Routine routine) async {
    await _routineService.updateRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(String id) async {
    await _routineService.deleteRoutine(id);
    await loadRoutines();
  }

  Future<void> loadPrograms() async {
    if (_currentUser == null) return;
    _programs = await _programService.getProgramsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> addProgram(TrainingProgram program) async {
    await _programService.addProgram(program);
    await loadPrograms();
  }

  Future<void> updateProgram(TrainingProgram program) async {
    await _programService.updateProgram(program);
    await loadPrograms();
  }

  Future<void> deleteProgram(String id) async {
    await _programService.deleteProgram(id);
    await loadPrograms();
  }

  Future<void> addWorkout(Workout workout) async {
    await _workoutService.addWorkout(workout);
    await loadWorkouts();
    if (!workout.isCompleted) {
      _activeWorkout = workout;
    }
    notifyListeners();
  }

  Future<void> updateWorkout(Workout workout) async {
    await _workoutService.updateWorkout(workout);
    await loadWorkouts();
    if (workout.isCompleted) {
      _activeWorkout = null;
      // Detect and update PRs after completing a workout
      await _detectAndUpdatePersonalRecords(workout);
    } else {
      _activeWorkout = workout;
    }
    notifyListeners();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutService.deleteWorkout(workoutId);
    await loadWorkouts();
    // Clear active workout if it was deleted
    if (_activeWorkout?.id == workoutId) {
      _activeWorkout = null;
    }
    notifyListeners();
  }

  Future<void> addBodyweightLog(BodyweightLog log) async {
    await _bodyweightService.addLog(log);
    await loadBodyweightLogs();
    
    // Update current weight if this is the most recent log
    if (_currentUser != null && _bodyweightLogs.isNotEmpty) {
      final mostRecentLog = _bodyweightLogs.first; // Logs are sorted by date descending
      if (mostRecentLog.id == log.id) {
        final updatedUser = _currentUser!.copyWith(
          currentWeight: log.weight,
          updatedAt: DateTime.now(),
        );
        await _userService.updateUser(updatedUser);
        _currentUser = updatedUser;
        notifyListeners();
      }
    }
  }

  Future<void> addPersonalRecord(PersonalRecord record) async {
    await _prService.addRecord(record);
    await loadPersonalRecords();
  }

  Future<void> updateUser(User user) async {
    await _userService.updateUser(user);
    _currentUser = user;
    notifyListeners();
  }

  /// Update the user's preferred unit (kg or lb)
  Future<void> updateUnitPreference(String unit) async {
    if (_currentUser == null) return;
    if (unit != 'kg' && unit != 'lb') return;
    
    final updatedUser = _currentUser!.copyWith(
      preferredUnit: unit,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    
    // Update Crashlytics context
    await CrashlyticsService().setUnitPreference(unit);
    
    notifyListeners();
  }

  /// Update the smith machine bar weight
  Future<void> updateSmithMachineBarWeight({double? kg, double? lb}) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      smithMachineBarWeightKg: kg ?? _currentUser!.smithMachineBarWeightKg,
      smithMachineBarWeightLb: lb ?? _currentUser!.smithMachineBarWeightLb,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Analytics Helper Methods

  /// Get all completed workouts from today
  List<Workout> getTodaysWorkouts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(today))
        .toList();
  }

  /// Get all completed workouts from the last 7 days
  List<Workout> getWeeklyWorkouts() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
  }

  /// Get muscle groups trained today
  Set<String> getMusclesTrainedToday() {
    final todayWorkouts = getTodaysWorkouts();
    final muscles = <String>{};
    for (var workout in todayWorkouts) {
      for (var exercise in workout.exercises) {
        muscles.add(_formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name));
      }
    }
    return muscles;
  }

  /// Get sets per muscle group for the week
  Map<String, int> getWeeklyMuscleGroupSets() {
    final weeklyWorkouts = getWeeklyWorkouts();
    final muscleGroupSets = <String, int>{};
    
    for (var workout in weeklyWorkouts) {
      for (var exercise in workout.exercises) {
        final muscle = _formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name);
        muscleGroupSets[muscle] = (muscleGroupSets[muscle] ?? 0) + exercise.completedSets;
      }
    }
    
    return muscleGroupSets;
  }

  /// Get last workout date for each muscle group (for recovery tracking)
  Map<String, DateTime> getLastWorkoutByMuscleGroup() {
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    final lastWorkoutDates = <String, DateTime>{};
    
    for (var workout in completedWorkouts) {
      for (var exercise in workout.exercises) {
        final muscle = _formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name);
        if (!lastWorkoutDates.containsKey(muscle)) {
          lastWorkoutDates[muscle] = workout.startTime;
        }
      }
    }
    
    return lastWorkoutDates;
  }

  /// Get volume trend for the last N workouts
  List<double> getVolumeTrend(int count) {
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return completedWorkouts
        .take(count)
        .map((w) => w.totalVolume)
        .toList()
        .reversed
        .toList();
  }

  /// Calculate volume change percentage from previous period
  double getVolumeChangePercentage() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    final thisWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
    final lastWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(twoWeeksAgo) && w.startTime.isBefore(weekAgo))
        .toList();
    
    final thisWeekVolume = thisWeekWorkouts.fold<double>(0.0, (sum, w) => sum + w.totalVolume);
    final lastWeekVolume = lastWeekWorkouts.fold<double>(0.0, (sum, w) => sum + w.totalVolume);
    
    if (lastWeekVolume == 0) return 0.0;
    return ((thisWeekVolume - lastWeekVolume) / lastWeekVolume) * 100;
  }

  /// Get training insights based on recent data
  List<String> getTrainingInsights() {
    final insights = <String>[];
    final weeklyWorkouts = getWeeklyWorkouts();
    
    if (weeklyWorkouts.isEmpty) {
      insights.add('Start your first workout this week');
      return insights;
    }
    
    // Volume trend insight
    final volumeChange = getVolumeChangePercentage();
    if (volumeChange > 10) {
      insights.add('Volume up ${volumeChange.toStringAsFixed(1)}% from last week - great progressive overload');
    } else if (volumeChange < -10) {
      insights.add('Volume down ${volumeChange.abs().toStringAsFixed(1)}% - consider a deload week');
    } else {
      insights.add('Volume stable - maintaining current training load');
    }
    
    // Frequency insight
    if (weeklyWorkouts.length >= 4) {
      insights.add('${weeklyWorkouts.length} sessions this week - excellent consistency');
    } else if (weeklyWorkouts.length >= 2) {
      insights.add('${weeklyWorkouts.length} sessions this week - solid training frequency');
    } else {
      insights.add('Only ${weeklyWorkouts.length} session this week - aim for 3-5 weekly');
    }
    
    // Muscle balance insight
    final muscleGroupSets = getWeeklyMuscleGroupSets();
    final maxSets = muscleGroupSets.values.isEmpty ? 0 : muscleGroupSets.values.reduce((a, b) => a > b ? a : b);
    final minSets = muscleGroupSets.values.isEmpty ? 0 : muscleGroupSets.values.reduce((a, b) => a < b ? a : b);
    
    if (maxSets > 0 && minSets == 0 && muscleGroupSets.length < 3) {
      insights.add('Focus on more muscle groups for balanced development');
    } else if (maxSets - minSets > 15) {
      insights.add('Consider balancing volume across muscle groups');
    }
    
    return insights;
  }

  String _formatMuscleGroup(String muscle) {
    return muscle[0].toUpperCase() + muscle.substring(1);
  }

  /// Get the user's most recent bodyweight in kilograms
  /// Returns null if no bodyweight logs exist
  double? getMostRecentBodyweightKg() {
    if (_bodyweightLogs.isEmpty) return null;
    
    // Sort by log date descending and get the most recent
    final sortedLogs = List<BodyweightLog>.from(_bodyweightLogs)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));
    
    final mostRecent = sortedLogs.first;
    
    // Convert to kg if needed
    if (mostRecent.unit == 'kg') {
      return mostRecent.weight;
    } else {
      // Convert lb to kg
      return mostRecent.weight * 0.453592;
    }
  }

  /// Force a complete reload of all app data (used after data reset)
  Future<void> forceReloadAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reload user (which may have cleared goals)
      _currentUser = await _userService.getCurrentUser();
      
      if (_currentUser != null) {
        // Reload all data from services
        await Future.wait([
          loadWorkouts(),
          loadExercises(),
          loadBodyweightLogs(),
          loadPersonalRecords(),
          loadRoutines(),
        ]);
        
        // Check for active workout
        _activeWorkout = await _workoutService.getActiveWorkout(_currentUser!.id);
      }
      
      debugPrint('✅ Complete data reload finished');
      debugPrint('   - Workouts: ${_workouts.length}');
      debugPrint('   - Bodyweight logs: ${_bodyweightLogs.length}');
      debugPrint('   - Personal records: ${_personalRecords.length}');
      debugPrint('   - Active workout: ${_activeWorkout != null ? "Yes" : "None"}');
    } catch (e) {
      debugPrint('❌ Failed to reload app data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Manually rebuild all Personal Records from workout history
  /// Clears existing PRs and recalculates from scratch using the correct ranking logic
  /// (highest weight first, then highest reps for ties)
  Future<void> rebuildPersonalRecords() async {
    if (_currentUser == null) return;
    
    try {
      debugPrint('🔄 Manually rebuilding Personal Records...');
      
      // Clear existing PRs
      await _prService.clearAllRecords(_currentUser!.id);
      _personalRecords.clear();
      notifyListeners();
      
      // Rebuild from workout history
      await _rebuildPersonalRecordsFromHistory();
      
      debugPrint('✅ Personal Records rebuilt successfully');
      
      // Final notify to ensure UI updates
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error rebuilding Personal Records: $e');
      // Reload PRs even if rebuild fails to show current state
      await loadPersonalRecords();
      rethrow;
    }
  }

  /// Calculate average intensity from workouts in a given time period
  /// Intensity = (weight used / best weight) for each exercise
  /// Uses PRs if available, otherwise uses the best set from all workouts
  /// Returns null if no data available
  double? calculateAverageIntensity({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(cutoff))
        .toList();
    
    if (recentWorkouts.isEmpty) return null;
    
    // Build a map of exercise ID -> best estimated 1RM (from all completed workouts)
    final exerciseBestE1RM = <String, double>{};
    
    for (var workout in _workouts.where((w) => w.isCompleted)) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        
        // Calculate best e1RM from this exercise's sets
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)) {
          // Convert to kg for consistent comparison
          double setWeightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          // Calculate estimated 1RM: weight × (1 + reps / 30)
          double e1rm = setWeightKg * (1 + set.reps / 30);
          
          if (!exerciseBestE1RM.containsKey(exerciseId) || e1rm > exerciseBestE1RM[exerciseId]!) {
            exerciseBestE1RM[exerciseId] = e1rm;
          }
        }
      }
    }
    
    if (exerciseBestE1RM.isEmpty) return null;
    
    double totalIntensity = 0.0;
    int totalCompletedSets = 0;
    
    // Now calculate intensity for recent workouts
    for (var workout in recentWorkouts) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        final bestE1RM = exerciseBestE1RM[exerciseId];
        
        // Skip if we don't have a baseline for this exercise
        if (bestE1RM == null) continue;
        
        // Calculate intensity for each completed set
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)) {
          // Convert weight to kg for comparison
          double setWeightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          // Calculate e1RM for this set
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          
          // Intensity = this set's e1RM / best e1RM ever
          final intensity = setE1RM / bestE1RM;
          totalIntensity += intensity;
          totalCompletedSets++;
        }
      }
    }
    
    if (totalCompletedSets == 0) return null;
    
    // Return average as percentage (0.0 to 1.0 range)
    return totalIntensity / totalCompletedSets;
  }

  /// Calculate intensity change percentage comparing two periods
  /// Returns null if insufficient data
  double? getIntensityChangePercentage() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    // Get workouts for this week and last week
    final thisWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
    final lastWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(twoWeeksAgo) && w.startTime.isBefore(weekAgo))
        .toList();
    
    if (thisWeekWorkouts.isEmpty || lastWeekWorkouts.isEmpty) return null;
    
    // Build exercise baseline map (best e1RM for each exercise from all time)
    final exerciseBestE1RM = <String, double>{};
    for (var workout in _workouts.where((w) => w.isCompleted)) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)) {
          double setWeightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          double e1rm = setWeightKg * (1 + set.reps / 30);
          if (!exerciseBestE1RM.containsKey(exerciseId) || e1rm > exerciseBestE1RM[exerciseId]!) {
            exerciseBestE1RM[exerciseId] = e1rm;
          }
        }
      }
    }
    
    if (exerciseBestE1RM.isEmpty) return null;
    
    // Calculate this week's average intensity
    double thisWeekTotal = 0.0;
    int thisWeekSets = 0;
    for (var workout in thisWeekWorkouts) {
      for (var exercise in workout.exercises) {
        final bestE1RM = exerciseBestE1RM[exercise.exercise.id];
        if (bestE1RM == null) continue;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)) {
          double setWeightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          thisWeekTotal += setE1RM / bestE1RM;
          thisWeekSets++;
        }
      }
    }
    
    // Calculate last week's average intensity
    double lastWeekTotal = 0.0;
    int lastWeekSets = 0;
    for (var workout in lastWeekWorkouts) {
      for (var exercise in workout.exercises) {
        final bestE1RM = exerciseBestE1RM[exercise.exercise.id];
        if (bestE1RM == null) continue;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)) {
          double setWeightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          lastWeekTotal += setE1RM / bestE1RM;
          lastWeekSets++;
        }
      }
    }
    
    if (thisWeekSets == 0 || lastWeekSets == 0) return null;
    
    final thisWeekIntensity = thisWeekTotal / thisWeekSets;
    final lastWeekIntensity = lastWeekTotal / lastWeekSets;
    
    // Calculate percentage change
    return ((thisWeekIntensity - lastWeekIntensity) / lastWeekIntensity) * 100;
  }

  /// Calculate strength progress data for major lifts
  /// Returns a list of ExerciseStrengthData for exercises with enough data
  List<Map<String, dynamic>> getStrengthProgressData({int days = 30}) {
    // Major lifts to track (by exercise name)
    final majorLiftNames = [
      'Barbell Bench Press',
      'Back Squat',
      'Deadlift',
      'Barbell Overhead Press',
      'Pull-Ups',
      'Leg Press',
    ];

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final results = <Map<String, dynamic>>[];

    // Process each major lift
    for (final liftName in majorLiftNames) {
      // Find the exercise in our exercise list
      final exercise = _exercises.cast<Exercise?>().firstWhere(
        (e) => e?.name == liftName,
        orElse: () => null,
      );

      if (exercise == null) continue; // Exercise not found

      // Collect all sets for this exercise across all workouts
      final allDataPoints = <Map<String, dynamic>>[];
      
      for (var workout in completedWorkouts) {
        for (var workoutExercise in workout.exercises) {
          if (workoutExercise.exercise.id == exercise.id) {
            // Find the best set in this workout
            final completedSets = workoutExercise.sets
                .where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)
                .toList();

            if (completedSets.isEmpty) continue;

            // Find the best set by weight first, then reps
            var bestSet = completedSets.first;
            var bestWeightKg = bestSet.unit == 'kg' ? bestSet.weight : bestSet.weight * 0.453592;

            // Find highest volume set (weight × reps)
            var highestVolumeSet = completedSets.first;
            var highestVolume = highestVolumeSet.weight * highestVolumeSet.reps;

            for (var set in completedSets) {
              // Convert to kg for consistent comparison
              final weightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
              
              // Compare by weight first, then reps for ties
              if (weightKg > bestWeightKg || (weightKg == bestWeightKg && set.reps > bestSet.reps)) {
                bestWeightKg = weightKg;
                bestSet = set;
              }

              // Check for highest volume
              final setVolume = set.weight * set.reps;
              if (setVolume > highestVolume) {
                highestVolume = setVolume;
                highestVolumeSet = set;
              }
            }
            
            // Calculate estimated 1RM for the best set
            final bestE1RM = bestWeightKg * (1 + bestSet.reps / 30);

            // Calculate total volume for this exercise in this workout
            final totalVolume = completedSets.fold<double>(
              0.0,
              (sum, set) => sum + (set.weight * set.reps),
            );

            allDataPoints.add({
              'date': workout.startTime,
              'estimatedOneRepMax': bestE1RM,
              'bestSet': bestSet,
              'weightKg': bestWeightKg,
              'highestVolumeSet': highestVolumeSet,
              'totalVolume': totalVolume,
            });
          }
        }
      }

      // Need at least 2 data points to show progress
      if (allDataPoints.length < 2) continue;

      // Get data points from the last 30 days
      final recentDataPoints = allDataPoints
          .where((dp) => (dp['date'] as DateTime).isAfter(cutoff))
          .toList();

      // Get the best overall set by weight first, then reps
      final bestOverall = allDataPoints.reduce((a, b) {
        final aWeightKg = a['weightKg'] as double;
        final bWeightKg = b['weightKg'] as double;
        final aReps = (a['bestSet'] as WorkoutSet).reps;
        final bReps = (b['bestSet'] as WorkoutSet).reps;
        
        if (aWeightKg > bWeightKg || (aWeightKg == bWeightKg && aReps > bReps)) {
          return a;
        }
        return b;
      });

      // Get the highest volume set overall
      final highestVolumeOverall = allDataPoints.reduce((a, b) {
        final aVolume = (a['highestVolumeSet'] as WorkoutSet).weight * (a['highestVolumeSet'] as WorkoutSet).reps;
        final bVolume = (b['highestVolumeSet'] as WorkoutSet).weight * (b['highestVolumeSet'] as WorkoutSet).reps;
        return aVolume > bVolume ? a : b;
      });

      // Calculate 30-day change
      double thirtyDayChange = 0.0;
      if (recentDataPoints.length >= 2) {
        final oldest = recentDataPoints.first;
        final newest = recentDataPoints.last;
        final oldE1RM = oldest['estimatedOneRepMax'] as double;
        final newE1RM = newest['estimatedOneRepMax'] as double;
        
        if (oldE1RM > 0) {
          thirtyDayChange = ((newE1RM - oldE1RM) / oldE1RM) * 100;
        }
      }

      results.add({
        'exercise': exercise,
        'bestSet': bestOverall['bestSet'],
        'estimatedOneRepMax': bestOverall['estimatedOneRepMax'],
        'highestVolumeSet': highestVolumeOverall['highestVolumeSet'],
        'thirtyDayChange': thirtyDayChange,
        'dataPoints': recentDataPoints.isEmpty ? allDataPoints.take(10).toList() : recentDataPoints,
        'hasEnoughData': true,
      });
    }

    return results;
  }
}
