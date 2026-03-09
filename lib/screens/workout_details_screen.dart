import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailsScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {

  Future<void> _showDatePicker(BuildContext context, Workout workout, AppProvider provider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: workout.startTime,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              onPrimary: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
              surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              onSurface: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Preserve the time from the current workout
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        workout.startTime.hour,
        workout.startTime.minute,
        workout.startTime.second,
      );
      
      // Update the workout with the new date
      final updatedWorkout = workout.copyWith(
        startTime: newDateTime,
        endTime: workout.endTime != null
            ? DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                workout.endTime!.hour,
                workout.endTime!.minute,
                workout.endTime!.second,
              )
            : null,
        updatedAt: DateTime.now(),
      );
      
      await provider.updateWorkout(updatedWorkout);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout date updated to ${FormatUtils.formatDate(newDateTime)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    
    final workout = provider.workouts.firstWhere(
      (w) => w.id == widget.workoutId,
      orElse: () => throw Exception('Workout not found'),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Workout Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Workout Header Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimary, AppColors.darkPrimary.withValues(alpha: 0.8)]
                        : [AppColors.lightPrimary, AppColors.lightPrimary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Editable Date Picker
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: InkWell(
                            onTap: () => _showDatePicker(context, workout, provider),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary).withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FormatUtils.formatDate(workout.startTime),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary).withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary).withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary).withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          FormatUtils.formatDuration(workout.duration),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary).withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Volume',
                      value: FormatUtils.formatVolume(workout.totalVolume, preferredUnit),
                      icon: Icons.fitness_center_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Sets',
                      value: '${workout.completedSets}',
                      icon: Icons.format_list_numbered_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Exercises',
                      value: '${workout.exercises.length}',
                      icon: Icons.list_alt_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Calories',
                      value: FormatUtils.formatCalories(workout.getCaloriesBurned(userBodyweightKg: userBodyweightKg)),
                      icon: Icons.local_fire_department_rounded,
                      isDark: isDark,
                      valueColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Load Score Card (full width)
              _LoadScoreCard(
                workout: workout,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Exercises List Header
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Exercises List
              ...workout.exercises.map((workoutExercise) => _ExerciseCard(
                workoutExercise: workoutExercise,
                isDark: isDark,
                preferredUnit: preferredUnit,
              )),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkHint : AppColors.lightHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final bool isDark;
  final String preferredUnit;

  const _ExerciseCard({
    required this.workoutExercise,
    required this.isDark,
    required this.preferredUnit,
  });

  @override
  Widget build(BuildContext context) {
    final completedSets = workoutExercise.sets.where((s) => s.isCompleted).toList();
    final exerciseVolume = workoutExercise.totalVolume;

    return GestureDetector(
      onTap: () {
        context.push(
          '/exercise-progress/${workoutExercise.exercise.id}?name=${Uri.encodeComponent(workoutExercise.exercise.name)}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      Text(
                        '${completedSets.length} sets • ${FormatUtils.formatVolume(exerciseVolume, preferredUnit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  size: 20,
                ),
              ],
            ),

            if (completedSets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                thickness: 0.5,
              ),
              const SizedBox(height: 8),

              // Sets List
              ...completedSets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              FormatUtils.formatWeight(set.weight, preferredUnit, storedUnit: set.unit),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '×',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkHint : AppColors.lightHint,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${set.reps} reps',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatUtils.formatVolume(set.weight * set.reps, preferredUnit),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadScoreCard extends StatelessWidget {
  final Workout workout;
  final bool isDark;

  const _LoadScoreCard({
    required this.workout,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loadScore = workout.loadScore;
    final loadScoreLabel = LoadScoreCalculator.getLoadScoreLabel(loadScore);
    final loadScoreColorHex = LoadScoreCalculator.getLoadScoreColor(loadScore, isDark);
    final loadScoreColor = Color(int.parse(loadScoreColorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Row(
        children: [
          // Icon and Label
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: loadScoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 22,
                    color: loadScoreColor,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load Score',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkHint : AppColors.lightHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loadScore > 0 ? loadScore.toStringAsFixed(0) : '--',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Difficulty Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: loadScoreColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              loadScoreLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
