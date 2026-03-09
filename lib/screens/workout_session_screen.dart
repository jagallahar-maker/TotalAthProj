import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Workout? _workout;
  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _exerciseKeys = {};

  @override
  void initState() {
    super.initState();
    _loadWorkout();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_workout != null) {
        setState(() {
          _sessionDuration = DateTime.now().difference(_workout!.startTime);
        });
      }
    });
  }

  Future<void> _loadWorkout() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final workouts = provider.workouts;
    final workout = workouts.firstWhere((w) => w.id == widget.workoutId);
    setState(() {
      _workout = workout;
      // Initialize keys for each exercise
      for (int i = 0; i < workout.exercises.length; i++) {
        if (!_exerciseKeys.containsKey(i)) {
          _exerciseKeys[i] = GlobalKey();
        }
      }
    });
    
    // Log workout context to Crashlytics
    final crashlytics = CrashlyticsService();
    await crashlytics.setWorkoutContext(
      workoutId: workout.id,
      workoutName: workout.name,
      exerciseCount: workout.exercises.length,
    );
    await crashlytics.logScreen('WorkoutSession');
  }

  Future<void> _refreshWorkout() async {
    await _loadWorkout();
    // Scroll to next unfinished exercise after refresh
    _scrollToNextUnfinishedExercise();
  }
  
  void _scrollToNextUnfinishedExercise() {
    if (_workout == null) return;
    
    // Find the first exercise that is not completed
    final nextExerciseIndex = _workout!.exercises.indexWhere((ex) {
      final completedSets = ex.sets.where((set) => set.isCompleted).length;
      final totalSets = ex.sets.length;
      return completedSets < totalSets;
    });
    
    if (nextExerciseIndex >= 0 && _exerciseKeys.containsKey(nextExerciseIndex)) {
      // Wait for build to complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _exerciseKeys[nextExerciseIndex];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.2, // Position near top of viewport
          );
        }
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_workout == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.updateWorkout(_workout!);
  }

  void _finishWorkout() async {
    if (_workout == null) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Filter out exercises with no completed sets
    final exercisesWithCompletedSets = _workout!.exercises.where((ex) {
      return ex.sets.any((set) => set.isCompleted);
    }).map((ex) {
      // For each exercise, keep only completed sets
      final completedSets = ex.sets.where((set) => set.isCompleted).toList();
      return ex.copyWith(sets: completedSets);
    }).toList();

    // Check if there are any completed sets
    final hasCompletedSets = exercisesWithCompletedSets.isNotEmpty;

    if (!hasCompletedSets) {
      // No completed sets - show discard confirmation
      _showExitConfirmation(hasCompletedSets: false);
      return;
    }

    // Has completed sets - show save/discard confirmation
    _showExitConfirmation(hasCompletedSets: true, exercisesWithCompletedSets: exercisesWithCompletedSets);
  }

  void _showExitConfirmation({
    required bool hasCompletedSets,
    List<WorkoutExercise>? exercisesWithCompletedSets,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          hasCompletedSets ? 'Save Workout?' : 'Discard Workout?',
          style: TextStyle(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        content: Text(
          hasCompletedSets
              ? 'You have completed ${exercisesWithCompletedSets!.fold<int>(0, (sum, ex) => sum + ex.sets.length)} sets across ${exercisesWithCompletedSets.length} exercise${exercisesWithCompletedSets.length == 1 ? '' : 's'}. Would you like to save this workout?'
              : 'You haven\'t completed any sets. This workout will be discarded.',
          style: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          if (hasCompletedSets)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _discardWorkout();
              },
              child: Text(
                'Discard',
                style: TextStyle(color: isDark ? AppColors.darkError : AppColors.lightError),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!hasCompletedSets) {
                _discardWorkout();
              }
            },
            child: Text(
              hasCompletedSets ? 'Cancel' : 'OK',
              style: TextStyle(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            ),
          ),
          if (hasCompletedSets)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _saveAndFinishWorkout(exercisesWithCompletedSets!);
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );
  }

  void _saveAndFinishWorkout(List<WorkoutExercise> exercisesWithCompletedSets) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Save workout with only completed sets
    final completedWorkout = _workout!.copyWith(
      exercises: exercisesWithCompletedSets,
      endTime: DateTime.now(),
      isCompleted: true,
      updatedAt: DateTime.now(),
    );

    await provider.updateWorkout(completedWorkout);

    if (mounted) {
      // Navigate back to home
      context.go('/');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout saved! ${exercisesWithCompletedSets.length} exercise${exercisesWithCompletedSets.length == 1 ? '' : 's'} logged.'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.lightSuccess,
        ),
      );
    }
  }

  void _discardWorkout() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.deleteWorkout(_workout!.id);

    if (mounted) {
      context.go('/');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;

    if (_workout == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _finishWorkout,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _workout!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            WorkoutDatePicker(
                              selectedDate: _workout!.startTime,
                              onDateChanged: (date) {
                                setState(() {
                                  _workout = _workout!.copyWith(
                                    startTime: date,
                                    updatedAt: DateTime.now(),
                                  );
                                });
                                _saveWorkout();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _finishWorkout,
                        child: Text(
                          'Finish',
                          style: TextStyle(
                            color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Session timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_sessionDuration),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Workout stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Exercises', '${_workout!.exercises.length}'),
                        Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        _buildStatItem(context, 'Completed Sets', '${_workout!.completedSets}/${_workout!.totalSets}'),
                        Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        _buildStatItem(context, 'Volume', FormatUtils.formatWeight(_workout!.totalVolume, preferredUnit)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Exercise list
            Expanded(
              child: _workout!.exercises.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingLg,
                      itemCount: _workout!.exercises.length,
                      itemBuilder: (context, index) {
                        final workoutExercise = _workout!.exercises[index];
                        return _buildExerciseCard(workoutExercise, index, isDark, preferredUnit);
                      },
                    ),
            ),
            // Add exercise button
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/log-exercise/${widget.workoutId}');
                    // Refresh workout when returning from exercise selection
                    _refreshWorkout();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 80,
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Exercise" to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatus(WorkoutExercise workoutExercise, bool isDark, String preferredUnit) {
    final completedSets = workoutExercise.sets.where((set) => set.isCompleted).toList();
    final totalSets = workoutExercise.sets.length;
    final isComplete = completedSets.length == totalSets && totalSets > 0;
    
    if (isComplete) {
      return Row(
        children: [
          Icon(
            Icons.check_rounded,
            size: 16,
            color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
          ),
          const SizedBox(width: 6),
          Text(
            'Completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (completedSets.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: 16,
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
          ),
          const SizedBox(width: 6),
          Text(
            'Not started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkHint : AppColors.lightHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      // Show most recent completed set
      final lastSet = completedSets.last;
      final displayWeight = FormatUtils.formatWeight(lastSet.weight, preferredUnit, storedUnit: lastSet.unit);
      
      return Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            'Last: $displayWeight × ${lastSet.reps}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index, bool isDark, String preferredUnit) {
    final completedSets = workoutExercise.completedSets;
    final totalSets = workoutExercise.sets.length;
    final isComplete = completedSets == totalSets && totalSets > 0;
    final hasStarted = completedSets > 0;
    
    // Find if this is the next unfinished exercise
    final nextUnfinishedIndex = _workout!.exercises.indexWhere((ex) {
      final completed = ex.sets.where((set) => set.isCompleted).length;
      final total = ex.sets.length;
      return completed < total;
    });
    final isNextUp = index == nextUnfinishedIndex && !isComplete;

    return GestureDetector(
      key: _exerciseKeys[index],
      onTap: () async {
        await context.push('/log-exercise/${widget.workoutId}?exerciseIndex=$index');
        // Refresh workout when returning from exercise
        _refreshWorkout();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isComplete
                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                : isNextUp
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            width: (isComplete || isNextUp) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNextUp ? 0.1 : 0.05),
              blurRadius: isNextUp ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next up indicator
            if (isNextUp)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 14,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NEXT UP',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                        : isNextUp
                            ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                            : hasStarted
                                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isNextUp || hasStarted
                                  ? Colors.white
                                  : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutExercise.exercise.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.museum_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            FormatUtils.formatMuscleGroup(workoutExercise.exercise.primaryMuscleGroup.name),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkHint : AppColors.lightHint,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, height: 1),
            const SizedBox(height: 12),
            // Progress summary
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set progress
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: isComplete
                          ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                          : hasStarted
                              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                              : (isDark ? AppColors.darkHint : AppColors.lightHint),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completedSets/$totalSets sets',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isComplete
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : hasStarted
                                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Last set or status
                _buildProgressStatus(workoutExercise, isDark, preferredUnit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
