import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';

class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  DateTime _selectedWorkoutDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeWorkout = provider.activeWorkout;
    final routines = provider.routines;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Training', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Select a routine or start fresh', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    child: Text('TA', style: TextStyle(color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Continue Last Workout (if exists)
              if (activeWorkout != null) ...[
                GestureDetector(
                  onTap: () => context.push('/workout-session/${activeWorkout.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
                          isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5)).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Continue Workout',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    activeWorkout.name,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.7), size: 28),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.fitness_center_rounded,
                              label: '${activeWorkout.exercises.length} exercises',
                              isDark: true,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: '${activeWorkout.completedSets}/${activeWorkout.totalSets} sets',
                              isDark: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // My Routines Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Routines', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create routine coming soon!'))),
                    child: Text('Create New', style: TextStyle(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Routine Cards
              ...routines.map((routine) => RoutineCard(
                routine: routine,
                exercises: provider.exercises,
                onTap: () => _startRoutineWorkout(context, provider, user?.id ?? 'user_1', routine),
              )),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text('Quick Start', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Workout Date Picker
              WorkoutDatePicker(
                selectedDate: _selectedWorkoutDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedWorkoutDate = date;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.add_rounded,
                      label: 'Empty Session',
                      bgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1976D2),
                      onTap: () => _startEmptyWorkout(context, provider, user?.id ?? 'user_1'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Generate',
                      bgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI generation coming soon!'))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startEmptyWorkout(BuildContext context, AppProvider provider, String userId) async {
    // Check if there's already an active (incomplete) workout
    final activeWorkout = provider.workouts.firstWhere(
      (w) => w.userId == userId && !w.isCompleted,
      orElse: () => Workout(
        id: const Uuid().v4(),
        userId: userId,
        name: 'New Workout',
        exercises: [],
        startTime: _selectedWorkoutDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    // Only add to list if it's a new workout (not already in the list)
    final isNewWorkout = !provider.workouts.any((w) => w.id == activeWorkout.id);
    if (isNewWorkout) {
      await provider.addWorkout(activeWorkout);
    }
    
    if (context.mounted) {
      context.push('/workout-session/${activeWorkout.id}');
    }
  }

  void _startRoutineWorkout(BuildContext context, AppProvider provider, String userId, Routine routine) async {
    // Get all exercises in the routine
    final exercisesInRoutine = provider.exercises
        .where((e) => routine.exerciseIds.contains(e.id))
        .toList();

    // Create workout exercises with auto-generated sets from history
    final workoutExercises = <WorkoutExercise>[];
    final preferredUnit = provider.preferredUnit;
    
    for (final exercise in exercisesInRoutine) {
      // Get last occurrence of this exercise
      final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(userId, exercise.id);
      
      List<WorkoutSet> sets;
      if (lastOccurrence != null && lastOccurrence.sets.isNotEmpty) {
        // Use previous workout's sets as template (but mark as not completed)
        sets = lastOccurrence.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final previousSet = entry.value;
          return WorkoutSet(
            id: const Uuid().v4(),
            setNumber: index + 1,
            weight: previousSet.weight,
            unit: previousSet.unit, // Preserve unit from previous set
            reps: previousSet.reps,
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } else {
        // No history - create 3 default sets using user's preferred unit
        sets = List.generate(3, (index) => WorkoutSet(
          id: const Uuid().v4(),
          setNumber: index + 1,
          weight: 60.0,
          unit: preferredUnit, // Use user's preferred unit
          reps: 10,
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      workoutExercises.add(WorkoutExercise(
        id: const Uuid().v4(),
        exercise: exercise,
        sets: sets,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // Create the workout
    final workout = Workout(
      id: const Uuid().v4(),
      userId: userId,
      name: routine.name,
      exercises: workoutExercises,
      startTime: _selectedWorkoutDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await provider.addWorkout(workout);
    
    if (context.mounted) {
      context.push('/workout-session/${workout.id}');
    }
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionCard({super.key, required this.icon, required this.label, required this.bgColor, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final List<Exercise> exercises;
  final VoidCallback onTap;

  const RoutineCard({super.key, required this.routine, required this.exercises, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get exercises in this routine
    final routineExercises = exercises
        .where((e) => routine.exerciseIds.contains(e.id))
        .take(3)
        .toList();
    
    // Format muscle groups
    final muscleGroupLabels = routine.targetMuscleGroups
        .map((m) => _formatMuscleGroup(m.name))
        .take(2)
        .toList();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: AppSpacing.paddingLg,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${muscleGroupLabels.join(", ")} • ${routine.exerciseCount} Exercises',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                    children: [
                      Icon(Icons.timer_rounded, size: 14, color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                      const SizedBox(width: 4),
                      Text('${routine.estimatedDurationMinutes} min', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                    ],
                  ),
                ),
              ],
            ),
            
            // Exercise Preview
            if (routineExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              const SizedBox(height: 12),
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...routineExercises.map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: isDark ? AppColors.darkHint : AppColors.lightHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              if (routine.exerciseCount > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${routine.exerciseCount - 3} more exercises',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkHint : AppColors.lightHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            
            const SizedBox(height: 12),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: muscleGroupLabels.map((label) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MuscleTag(label: label),
                  )).toList(),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkHint : AppColors.lightHint, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMuscleGroup(String muscle) {
    return muscle[0].toUpperCase() + muscle.substring(1);
  }
}

class MuscleTag extends StatelessWidget {
  final String label;

  const MuscleTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
    );
  }
}
