import 'package:flutter/material.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/theme.dart';

enum ConsistencyTrend { improving, stable, declining }

class TrainingConsistencyData {
  final int workoutsLast7Days;
  final int workoutsLast30Days;
  final double averageWorkoutsPerWeek;
  final int currentStreak;
  final ConsistencyTrend trend;

  const TrainingConsistencyData({
    required this.workoutsLast7Days,
    required this.workoutsLast30Days,
    required this.averageWorkoutsPerWeek,
    required this.currentStreak,
    required this.trend,
  });

  factory TrainingConsistencyData.fromWorkouts(List<Workout> workouts) {
    final now = DateTime.now();
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    
    // Count workouts in last 7 and 30 days
    final last7Days = completedWorkouts
        .where((w) => now.difference(w.startTime).inDays < 7)
        .length;
    final last30Days = completedWorkouts
        .where((w) => now.difference(w.startTime).inDays < 30)
        .length;
    
    // Calculate average workouts per week (based on last 30 days)
    final avgPerWeek = last30Days / 4.285; // 30 days ≈ 4.285 weeks
    
    // Calculate current streak (consecutive days with workouts)
    final streak = _calculateStreak(completedWorkouts);
    
    // Calculate trend (comparing last 7 days vs previous 7 days)
    final previous7Days = completedWorkouts
        .where((w) {
          final daysAgo = now.difference(w.startTime).inDays;
          return daysAgo >= 7 && daysAgo < 14;
        })
        .length;
    
    final trend = _calculateTrend(last7Days, previous7Days);
    
    return TrainingConsistencyData(
      workoutsLast7Days: last7Days,
      workoutsLast30Days: last30Days,
      averageWorkoutsPerWeek: avgPerWeek,
      currentStreak: streak,
      trend: trend,
    );
  }

  static int _calculateStreak(List<Workout> completedWorkouts) {
    if (completedWorkouts.isEmpty) return 0;
    
    // Sort workouts by date (most recent first)
    final sortedWorkouts = completedWorkouts.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    final now = DateTime.now();
    int streak = 0;
    
    // Check if there's a workout today or yesterday (to allow for grace period)
    final mostRecentWorkout = sortedWorkouts.first;
    final daysSinceLastWorkout = now.difference(mostRecentWorkout.startTime).inDays;
    
    if (daysSinceLastWorkout > 1) {
      return 0; // Streak is broken if no workout in last 2 days
    }
    
    // Calculate consecutive days with workouts
    final workoutDates = <DateTime>{};
    for (var workout in sortedWorkouts) {
      final workoutDate = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );
      workoutDates.add(workoutDate);
    }
    
    // Start from today and count backwards
    var checkDate = DateTime(now.year, now.month, now.day);
    
    // If no workout today, start from yesterday
    if (!workoutDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!workoutDates.contains(checkDate)) {
        return 0;
      }
    }
    
    // Count consecutive days
    while (workoutDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  static ConsistencyTrend _calculateTrend(int current, int previous) {
    if (current > previous) {
      return ConsistencyTrend.improving;
    } else if (current < previous && previous > 0) {
      return ConsistencyTrend.declining;
    } else {
      return ConsistencyTrend.stable;
    }
  }
}

class TrainingConsistencyCard extends StatelessWidget {
  final TrainingConsistencyData data;

  const TrainingConsistencyCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training Consistency',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your workout frequency and streaks',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              _TrendIndicator(trend: data.trend),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Last 7 Days',
                  value: '${data.workoutsLast7Days}',
                  subtitle: data.workoutsLast7Days == 1 ? 'workout' : 'workouts',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Last 30 Days',
                  value: '${data.workoutsLast30Days}',
                  subtitle: data.workoutsLast30Days == 1 ? 'workout' : 'workouts',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Avg/Week',
                  value: data.averageWorkoutsPerWeek.toStringAsFixed(1),
                  subtitle: 'workouts',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Current Streak',
                  value: '${data.currentStreak}',
                  subtitle: data.currentStreak == 1 ? 'day' : 'days',
                  icon: Icons.local_fire_department_rounded,
                  isHighlight: data.currentStreak >= 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final ConsistencyTrend trend;

  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color color;
    IconData icon;
    String label;
    
    switch (trend) {
      case ConsistencyTrend.improving:
        color = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
        icon = Icons.trending_up_rounded;
        label = 'Improving';
        break;
      case ConsistencyTrend.stable:
        color = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
        icon = Icons.trending_flat_rounded;
        label = 'Stable';
        break;
      case ConsistencyTrend.declining:
        color = isDark ? AppColors.darkAccent : AppColors.lightAccent;
        icon = Icons.trending_down_rounded;
        label = 'Declining';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isHighlight;

  const _StatBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isHighlight 
              ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.5)
              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isHighlight
                    ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                    : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
        ],
      ),
    );
  }
}
