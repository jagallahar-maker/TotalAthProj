import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/utils/format_utils.dart';

enum ExerciseChartType {
  bestSet,
  estimatedOneRM,
  highestVolume,
  totalVolume,
}

class ExerciseProgressScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
  ExerciseChartType _selectedChartType = ExerciseChartType.estimatedOneRM;
  int _selectedFilterDays = 90;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    
    // Get all completed workouts
    final completedWorkouts = provider.workouts
        .where((w) => w.isCompleted)
        .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Filter workouts containing this exercise
    final exerciseWorkouts = <Map<String, dynamic>>[];
    WorkoutSet? bestSet;
    var bestWeightKg = 0.0;
    double bestE1RM = 0.0;
    WorkoutSet? highestVolumeSet;
    var highestVolume = 0.0;
    var lifetimeTotalVolume = 0.0;
    var totalWorkouts = 0;
    var totalCompletedSets = 0;
    var totalWeight = 0.0;
    var totalReps = 0;

    for (var workout in completedWorkouts) {
      for (var workoutExercise in workout.exercises) {
        if (workoutExercise.exercise.id == widget.exerciseId) {
          final completedSets = workoutExercise.sets
              .where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)
              .toList();
          
          if (completedSets.isEmpty) continue;

          totalWorkouts++;

          // Find best set in this workout
          var workoutBestSet = completedSets.first;
          var workoutBestWeightKg = workoutBestSet.unit == 'kg' 
              ? workoutBestSet.weight 
              : workoutBestSet.weight * 0.453592;

          // Find highest volume set in this workout
          var workoutHighestVolumeSet = completedSets.first;
          var workoutHighestVolume = workoutHighestVolumeSet.weight * workoutHighestVolumeSet.reps;

          // Calculate workout volume
          var workoutVolume = 0.0;

          for (var set in completedSets) {
            totalCompletedSets++;
            totalReps += set.reps;
            
            // Convert to kg for consistent tracking
            final weightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
            totalWeight += weightKg;
            
            final setVolume = set.weight * set.reps;
            workoutVolume += setVolume;

            // Check best set
            if (weightKg > workoutBestWeightKg || 
                (weightKg == workoutBestWeightKg && set.reps > workoutBestSet.reps)) {
              workoutBestWeightKg = weightKg;
              workoutBestSet = set;
            }

            // Check highest volume set
            if (setVolume > workoutHighestVolume) {
              workoutHighestVolume = setVolume;
              workoutHighestVolumeSet = set;
            }
          }

          lifetimeTotalVolume += workoutVolume;

          // Calculate e1RM for workout best set
          final workoutE1RM = workoutBestWeightKg * (1 + workoutBestSet.reps / 30);

          // Update overall bests
          if (workoutBestWeightKg > bestWeightKg || 
              (workoutBestWeightKg == bestWeightKg && workoutBestSet.reps > (bestSet?.reps ?? 0))) {
            bestWeightKg = workoutBestWeightKg;
            bestSet = workoutBestSet;
            bestE1RM = workoutE1RM;
          }

          if (workoutHighestVolume > highestVolume) {
            highestVolume = workoutHighestVolume;
            highestVolumeSet = workoutHighestVolumeSet;
          }

          exerciseWorkouts.add({
            'date': workout.startTime,
            'workoutName': workout.name,
            'workoutExercise': workoutExercise,
            'bestSet': workoutBestSet,
            'bestSetWeightKg': workoutBestWeightKg,
            'estimatedOneRM': workoutE1RM,
            'highestVolumeSet': workoutHighestVolumeSet,
            'totalVolume': workoutVolume,
          });
        }
      }
    }

    // Calculate averages
    final avgWorkingWeight = totalCompletedSets > 0 ? totalWeight / totalCompletedSets : 0.0;
    final avgReps = totalCompletedSets > 0 ? totalReps / totalCompletedSets : 0.0;

    // Filter by selected time range
    final cutoff = DateTime.now().subtract(Duration(days: _selectedFilterDays));
    final filteredWorkouts = _selectedFilterDays == 0
        ? exerciseWorkouts
        : exerciseWorkouts.where((w) => (w['date'] as DateTime).isAfter(cutoff)).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: exerciseWorkouts.isEmpty
          ? _buildEmptyState(context, isDark)
          : SingleChildScrollView(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PR Overview Card
                  _buildPROverviewCard(
                    context,
                    isDark,
                    preferredUnit,
                    bestSet,
                    bestE1RM,
                    highestVolumeSet,
                    lifetimeTotalVolume,
                    totalWorkouts,
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Card
                  _buildStatsCard(
                    context,
                    isDark,
                    preferredUnit,
                    avgWorkingWeight,
                    avgReps,
                  ),
                  const SizedBox(height: 24),
                  
                  // Chart Type Selector
                  _buildChartTypeSelector(context, isDark),
                  const SizedBox(height: 16),
                  
                  // Time Filter
                  _buildTimeFilter(context, isDark),
                  const SizedBox(height: 24),
                  
                  // Progress Chart
                  _buildProgressChart(
                    context,
                    isDark,
                    preferredUnit,
                    filteredWorkouts,
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Sessions
                  _buildRecentSessions(
                    context,
                    isDark,
                    preferredUnit,
                    exerciseWorkouts.reversed.take(10).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: (isDark ? AppColors.darkHint : AppColors.lightHint).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No workout history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? AppColors.darkHint : AppColors.lightHint,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete workouts with this exercise to see progress',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPROverviewCard(
    BuildContext context,
    bool isDark,
    String preferredUnit,
    WorkoutSet? bestSet,
    double bestE1RM,
    WorkoutSet? highestVolumeSet,
    double lifetimeTotalVolume,
    int totalWorkouts,
  ) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            isDark 
                ? AppColors.darkPrimary.withValues(alpha: 0.8) 
                : AppColors.lightPrimary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Personal Records',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPRStatCard(
                  context,
                  isDark,
                  'Best Set',
                  bestSet != null
                      ? '${FormatUtils.formatWeight(bestSet.weight, preferredUnit, storedUnit: bestSet.unit)} × ${bestSet.reps}'
                      : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPRStatCard(
                  context,
                  isDark,
                  'Est. 1RM',
                  bestE1RM > 0
                      ? FormatUtils.formatWeight(bestE1RM, preferredUnit, storedUnit: 'kg')
                      : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPRStatCard(
                  context,
                  isDark,
                  'Highest Volume Set',
                  highestVolumeSet != null
                      ? '${FormatUtils.formatWeight(highestVolumeSet.weight, preferredUnit, storedUnit: highestVolumeSet.unit)} × ${highestVolumeSet.reps}'
                      : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPRStatCard(
                  context,
                  isDark,
                  'Total Workouts',
                  totalWorkouts.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPRStatCard(
            context,
            isDark,
            'Lifetime Volume',
            FormatUtils.formatVolume(lifetimeTotalVolume, preferredUnit),
          ),
        ],
      ),
    );
  }

  Widget _buildPRStatCard(BuildContext context, bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkOnPrimary.withValues(alpha: 0.15)
            : AppColors.lightOnPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.darkOnPrimary.withValues(alpha: 0.8)
                  : AppColors.lightOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    bool isDark,
    String preferredUnit,
    double avgWorkingWeight,
    double avgReps,
  ) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Performance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  isDark,
                  'Avg. Weight',
                  FormatUtils.formatWeight(avgWorkingWeight, preferredUnit, storedUnit: 'kg'),
                  Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  isDark,
                  'Avg. Reps',
                  avgReps.toStringAsFixed(1),
                  Icons.repeat_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, bool isDark, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeSelector(BuildContext context, bool isDark) {
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
          Text(
            'Chart Type',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChartTypeChip(context, isDark, 'Best Set', ExerciseChartType.bestSet),
              _buildChartTypeChip(context, isDark, 'Est. 1RM', ExerciseChartType.estimatedOneRM),
              _buildChartTypeChip(context, isDark, 'Volume/Set', ExerciseChartType.highestVolume),
              _buildChartTypeChip(context, isDark, 'Total Volume', ExerciseChartType.totalVolume),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeChip(BuildContext context, bool isDark, String label, ExerciseChartType type) {
    final isSelected = _selectedChartType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary)
                : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTimeFilterChip(context, isDark, '7 Days', 7),
          const SizedBox(width: 8),
          _buildTimeFilterChip(context, isDark, '30 Days', 30),
          const SizedBox(width: 8),
          _buildTimeFilterChip(context, isDark, '90 Days', 90),
          const SizedBox(width: 8),
          _buildTimeFilterChip(context, isDark, 'All Time', 0),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(BuildContext context, bool isDark, String label, int days) {
    final isSelected = _selectedFilterDays == days;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterDays = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary)
                : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart(
    BuildContext context,
    bool isDark,
    String preferredUnit,
    List<Map<String, dynamic>> workouts,
  ) {
    if (workouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        child: Center(
          child: Text(
            'No data for selected time range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
        ),
      );
    }

    // Prepare data for chart
    final spots = <FlSpot>[];
    for (int i = 0; i < workouts.length; i++) {
      final workout = workouts[i];
      double yValue = 0.0;

      switch (_selectedChartType) {
        case ExerciseChartType.bestSet:
          final weightKg = workout['bestSetWeightKg'] as double;
          yValue = weightKg;
          break;
        case ExerciseChartType.estimatedOneRM:
          yValue = workout['estimatedOneRM'] as double;
          break;
        case ExerciseChartType.highestVolume:
          final set = workout['highestVolumeSet'] as WorkoutSet;
          final volumeKg = (set.unit == 'kg' ? set.weight : set.weight * 0.453592) * set.reps;
          yValue = volumeKg;
          break;
        case ExerciseChartType.totalVolume:
          final totalVolume = workout['totalVolume'] as double;
          yValue = totalVolume;
          break;
      }

      spots.add(FlSpot(i.toDouble(), yValue));
    }

    // Find min and max for Y axis
    final yValues = spots.map((s) => s.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15;

    return Container(
      padding: AppSpacing.paddingLg,
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
                Icons.show_chart_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progress Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: (isDark ? AppColors.darkDivider : AppColors.lightDivider)
                          .withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: workouts.length > 10 ? (workouts.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < workouts.length) {
                          final date = workouts[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                    left: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    ),
                  ),
                ),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          strokeWidth: 2,
                          strokeColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                              .withValues(alpha: 0.2),
                          (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                              .withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => isDark 
                        ? AppColors.darkBackground 
                        : AppColors.lightBackground,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final workout = workouts[spot.x.toInt()];
                        final date = workout['date'] as DateTime;
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)}',
                          Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(
    BuildContext context,
    bool isDark,
    String preferredUnit,
    List<Map<String, dynamic>> sessions,
  ) {
    return Container(
      padding: AppSpacing.paddingLg,
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
                Icons.history_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sessions.map((session) {
            final date = session['date'] as DateTime;
            final workoutName = session['workoutName'] as String;
            final workoutExercise = session['workoutExercise'] as WorkoutExercise;
            final totalVolume = session['totalVolume'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          workoutName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...workoutExercise.sets
                      .where((s) => s.isCompleted)
                      .map((set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${FormatUtils.formatWeight(set.weight, preferredUnit, storedUnit: set.unit)} × ${set.reps} reps',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Volume: ${FormatUtils.formatVolume(totalVolume, preferredUnit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        fontWeight: FontWeight.bold,
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
