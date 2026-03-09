import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/models/detailed_muscle.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';

/// Detail screen for a specific muscle region
class MuscleDetailScreen extends StatelessWidget {
  final DetailedMuscle muscle;
  final DetailedMuscleData muscleData;
  final List<Workout> recentWorkouts; // Workouts affecting this muscle
  final String preferredUnit;
  final String timeFilter; // "Week", "Month", or "90 Days"
  
  const MuscleDetailScreen({
    super.key,
    required this.muscle,
    required this.muscleData,
    required this.recentWorkouts,
    required this.preferredUnit,
    required this.timeFilter,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          muscle.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary stats
              _SummaryStatsCard(
                muscleData: muscleData,
                timeFilter: timeFilter,
                preferredUnit: preferredUnit,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              // Top exercises
              _TopExercisesCard(
                topExercises: muscleData.topExercises,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              // Recent sessions
              _RecentSessionsCard(
                recentWorkouts: recentWorkouts,
                muscle: muscle,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  final DetailedMuscleData muscleData;
  final String timeFilter;
  final String preferredUnit;
  final bool isDark;
  
  const _SummaryStatsCard({
    required this.muscleData,
    required this.timeFilter,
    required this.preferredUnit,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary ($timeFilter)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Sets',
                  value: '${muscleData.totalSets}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Primary Sets',
                  value: '${muscleData.primarySets}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Secondary Sets',
                  value: '${muscleData.secondarySets}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Total Volume',
                  value: FormatUtils.formatVolume(muscleData.totalVolume, preferredUnit),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatItem(
            label: 'Weighted Load',
            value: '${muscleData.load.toStringAsFixed(1)} sets',
            isDark: isDark,
            description: 'Primary sets count as 1.0, secondary as 0.5',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final String? description;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _TopExercisesCard extends StatelessWidget {
  final List<String> topExercises;
  final bool isDark;
  
  const _TopExercisesCard({
    required this.topExercises,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Contributing Exercises',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (topExercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No exercises recorded for this muscle yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            )
          else
            ...topExercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<Workout> recentWorkouts;
  final DetailedMuscle muscle;
  final bool isDark;
  
  const _RecentSessionsCard({
    required this.recentWorkouts,
    required this.muscle,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sessions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (recentWorkouts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No recent workouts targeting this muscle.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            )
          else
            ...recentWorkouts.take(5).map((workout) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _WorkoutSessionRow(
                  workout: workout,
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _WorkoutSessionRow extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  
  const _WorkoutSessionRow({
    required this.workout,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    final exerciseCount = workout.exercises.length;
    final totalSets = workout.exercises
        .expand((e) => e.sets)
        .where((s) => s.isCompleted)
        .length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FormatUtils.formatDate(workout.startTime),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$exerciseCount exercises\n$totalSets sets',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
