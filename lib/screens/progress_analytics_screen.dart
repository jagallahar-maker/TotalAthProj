import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/models/personal_record.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/utils/recovery_calculator.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/widgets/muscle_heat_map.dart';
import 'package:total_athlete/widgets/strength_progress_card.dart';
import 'package:total_athlete/widgets/training_consistency_card.dart';
import 'package:total_athlete/widgets/daily_volume_chart.dart';
import 'package:total_athlete/widgets/detailed_muscle_heat_map.dart';
import 'package:total_athlete/widgets/load_score_trend_card.dart';
import 'package:total_athlete/models/detailed_muscle.dart';
import 'package:total_athlete/services/muscle_mapping_service.dart';
import 'package:total_athlete/screens/muscle_detail_screen.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

// Data models for muscle group analytics
class MuscleGroupData {
  final MuscleGroup muscle;
  final int sets;
  final double volume;

  const MuscleGroupData({
    required this.muscle,
    required this.sets,
    required this.volume,
  });

  MuscleGroupData copyWith({int? sets, double? volume}) {
    return MuscleGroupData(
      muscle: muscle,
      sets: sets ?? this.sets,
      volume: volume ?? this.volume,
    );
  }
}

class MuscleGroupAnalytics {
  final Map<MuscleGroup, MuscleGroupData> muscleData;
  final TimeFilter timeFilter;

  const MuscleGroupAnalytics({
    required this.muscleData,
    required this.timeFilter,
  });

  // Weekly set targets for hypertrophy
  static const Map<MuscleGroup, int> weeklyTargets = {
    MuscleGroup.chest: 16,
    MuscleGroup.back: 16,
    MuscleGroup.legs: 20,
    MuscleGroup.shoulders: 12,
    MuscleGroup.arms: 14,
    MuscleGroup.core: 10,
  };

  // High volume warning thresholds
  static const Map<MuscleGroup, int> warningThresholds = {
    MuscleGroup.chest: 24,
    MuscleGroup.back: 24,
    MuscleGroup.legs: 28,
    MuscleGroup.shoulders: 20,
    MuscleGroup.arms: 22,
    MuscleGroup.core: 18,
  };

  int getTarget(MuscleGroup muscle) {
    return weeklyTargets[muscle] ?? 12;
  }

  int getWarningThreshold(MuscleGroup muscle) {
    return warningThresholds[muscle] ?? 24;
  }

  bool isOverTraining(MuscleGroup muscle) {
    if (timeFilter != TimeFilter.weekly) return false;
    final sets = muscleData[muscle]?.sets ?? 0;
    return sets > getWarningThreshold(muscle);
  }

  List<String> getTrainingInsights() {
    if (timeFilter != TimeFilter.weekly) return [];
    
    final insights = <String>[];
    final sortedMuscles = muscleData.entries.toList()
      ..sort((a, b) => b.value.sets.compareTo(a.value.sets));

    // Check for undertrained muscle groups
    for (var entry in muscleData.entries) {
      final muscle = entry.key;
      final data = entry.value;
      final target = getTarget(muscle);
      
      if (data.sets > 0 && data.sets < target * 0.5) {
        insights.add('${_formatMuscleName(muscle)} volume is low (${data.sets}/${target} sets this week)');
      }
    }

    // Check for overemphasis/imbalance
    if (sortedMuscles.isNotEmpty && sortedMuscles.length >= 2) {
      final highest = sortedMuscles[0];
      final lowest = sortedMuscles.lastWhere((e) => e.value.sets > 0, orElse: () => sortedMuscles[0]);
      
      if (highest.value.sets > lowest.value.sets * 3 && lowest.value.sets > 0) {
        insights.add('${_formatMuscleName(highest.key)} volume is significantly higher than ${_formatMuscleName(lowest.key)} this week');
      }
    }

    // Check for ahead of target
    for (var entry in muscleData.entries) {
      final muscle = entry.key;
      final data = entry.value;
      final target = getTarget(muscle);
      
      if (data.sets >= target && data.sets < getWarningThreshold(muscle)) {
        insights.add('${_formatMuscleName(muscle)} volume is on track (${data.sets}/${target} sets)');
        break; // Only show one positive insight
      }
    }

    return insights;
  }

  String _formatMuscleName(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.core:
        return 'Core';
    }
  }
}

enum TimeFilter { weekly, monthly, ninetyDays }

// Shared muscle group color scheme for consistency across components
Map<MuscleGroup, Color> getMuscleGroupColors(bool isDark) {
  return {
    MuscleGroup.chest: isDark ? AppColors.darkAccent : AppColors.lightAccent,
    MuscleGroup.back: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
    MuscleGroup.legs: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
    MuscleGroup.shoulders: const Color(0xFF9575CD),
    MuscleGroup.arms: const Color(0xFFFFB74D),
    MuscleGroup.core: const Color(0xFF64B5F6),
  };
}

class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  TimeFilter _selectedFilter = TimeFilter.weekly;
  HeatMapMode _heatMapMode = HeatMapMode.trainingLoad;

  @override
  void initState() {
    super.initState();
    // Log screen view
    CrashlyticsService().logScreen('ProgressAnalytics');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final workouts = provider.workouts.where((w) => w.isCompleted).toList();
    final last30Days = workouts.where((w) => DateTime.now().difference(w.startTime).inDays <= 30).toList();
    final totalVolume = last30Days.fold<double>(0, (sum, w) => sum + w.totalVolume);

    // Calculate volume change percentage
    final volumeChange = provider.getVolumeChangePercentage();
    
    // Calculate average intensity (30 days)
    final avgIntensity = provider.calculateAverageIntensity(days: 30);
    
    // Calculate intensity change percentage
    final intensityChange = provider.getIntensityChangePercentage();

    // Get muscle group data based on selected filter
    final muscleAnalytics = _getMuscleGroupAnalytics(workouts, _selectedFilter);
    
    // Get strength progress data for major lifts
    final strengthProgressData = provider.getStrengthProgressData(days: 30);
    
    // Convert to ExerciseStrengthData objects
    final exerciseStrengthData = strengthProgressData.map((data) {
      return ExerciseStrengthData(
        exercise: data['exercise'] as Exercise,
        bestSet: data['bestSet'] as WorkoutSet?,
        estimatedOneRepMax: data['estimatedOneRepMax'] as double,
        highestVolumeSet: data['highestVolumeSet'] as WorkoutSet?,
        thirtyDayChange: data['thirtyDayChange'] as double,
        dataPoints: (data['dataPoints'] as List).map((dp) {
          return StrengthDataPoint(
            date: dp['date'] as DateTime,
            estimatedOneRepMax: dp['estimatedOneRepMax'] as double,
            bestSetOfDay: dp['bestSet'] as WorkoutSet,
            totalVolume: dp['totalVolume'] as double,
          );
        }).toList(),
        hasEnoughData: data['hasEnoughData'] as bool,
      );
    }).toList();

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
                      Text('Training Insights', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Your performance data for the last 30 days', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Volume',
                      value: FormatUtils.formatVolume(totalVolume, preferredUnit),
                      change: volumeChange.abs() >= 0.1 ? '${volumeChange >= 0 ? '+' : ''}${volumeChange.toStringAsFixed(0)}%' : '--',
                      isUp: volumeChange >= 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Avg. Intensity',
                      value: avgIntensity != null ? '${(avgIntensity * 100).toStringAsFixed(0)}%' : '--',
                      change: intensityChange != null && intensityChange.abs() >= 0.1 
                          ? '${intensityChange >= 0 ? '+' : ''}${intensityChange.toStringAsFixed(0)}%' 
                          : '--',
                      isUp: intensityChange != null ? intensityChange >= 0 : true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TrainingConsistencyCard(
                data: TrainingConsistencyData.fromWorkouts(workouts),
              ),
              const SizedBox(height: 24),
              LoadScoreTrendCard(
                workouts: workouts,
              ),
              const SizedBox(height: 24),
              StrengthProgressCard(
                exerciseData: exerciseStrengthData,
                preferredUnit: preferredUnit,
              ),
              const SizedBox(height: 24),
              MuscleHeatMapCard(
                muscleAnalytics: muscleAnalytics,
                selectedFilter: _selectedFilter,
                allWorkouts: workouts,
                heatMapMode: _heatMapMode,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                onModeChanged: (mode) {
                  setState(() {
                    _heatMapMode = mode;
                  });
                },
              ),
              const SizedBox(height: 24),
              MuscleGroupAnalyticsCard(
                muscleAnalytics: muscleAnalytics,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 24),
              DailyVolumeChartCard(
                workouts: workouts,
                preferredUnit: preferredUnit,
              ),
              const SizedBox(height: 24),
              PersonalRecordsCard(
                personalRecords: provider.personalRecords,
                preferredUnit: preferredUnit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  MuscleGroupAnalytics _getMuscleGroupAnalytics(List<Workout> allWorkouts, TimeFilter filter) {
    final int days = filter == TimeFilter.weekly ? 7 : filter == TimeFilter.monthly ? 30 : 90;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredWorkouts = allWorkouts.where((w) => w.startTime.isAfter(cutoffDate)).toList();

    final muscleData = <MuscleGroup, MuscleGroupData>{};
    
    // Initialize all muscle groups
    for (var muscle in MuscleGroup.values) {
      muscleData[muscle] = MuscleGroupData(muscle: muscle, sets: 0, volume: 0.0);
    }
    
    // Calculate sets and volume per muscle group
    for (var workout in filteredWorkouts) {
      for (var exercise in workout.exercises) {
        final muscle = exercise.exercise.primaryMuscleGroup;
        final completedSets = exercise.sets.where((s) => s.isCompleted).length;
        final exerciseVolume = exercise.sets
            .where((s) => s.isCompleted)
            .fold<double>(0.0, (sum, s) => sum + (s.weight * s.reps));
        
        muscleData[muscle] = muscleData[muscle]!.copyWith(
          sets: muscleData[muscle]!.sets + completedSets,
          volume: muscleData[muscle]!.volume + exerciseVolume,
        );
      }
    }
    
    return MuscleGroupAnalytics(
      muscleData: muscleData,
      timeFilter: filter,
    );
  }
}

class MuscleGroupAnalyticsCard extends StatelessWidget {
  final MuscleGroupAnalytics muscleAnalytics;
  final TimeFilter selectedFilter;
  final Function(TimeFilter) onFilterChanged;

  const MuscleGroupAnalyticsCard({
    super.key,
    required this.muscleAnalytics,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = muscleAnalytics.getTrainingInsights();
    
    // Prepare data for pie chart (only non-zero sets)
    final muscleGroupSets = muscleAnalytics.muscleData.entries
        .where((e) => e.value.sets > 0)
        .map((e) => MapEntry(e.key, e.value.sets))
        .fold<Map<MuscleGroup, int>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title
          Text('Muscle Group Volume', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            selectedFilter == TimeFilter.weekly 
                ? 'Weekly set targets and distribution'
                : 'Training distribution',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter chips in their own row
          Row(
            children: [
              _FilterChip(
                label: 'Week',
                isSelected: selectedFilter == TimeFilter.weekly,
                onTap: () => onFilterChanged(TimeFilter.weekly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Month',
                isSelected: selectedFilter == TimeFilter.monthly,
                onTap: () => onFilterChanged(TimeFilter.monthly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '90d',
                isSelected: selectedFilter == TimeFilter.ninetyDays,
                onTap: () => onFilterChanged(TimeFilter.ninetyDays),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Pie chart and muscle group list
          if (muscleGroupSets.isNotEmpty)
            Column(
              children: [
                // Donut chart centered with responsive sizing
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Limit chart size based on available width
                      final chartSize = (constraints.maxWidth * 0.5).clamp(120.0, 160.0);
                      return SizedBox(
                        width: chartSize,
                        height: chartSize,
                        child: MuscleGroupPieChart(muscleGroupSets: muscleGroupSets),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Muscle group list below chart
                ..._buildMuscleGroupList(isDark),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No workout data for selected period',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkHint : AppColors.lightHint,
                  ),
                ),
              ),
            ),
          
          // Training insights
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            const SizedBox(height: 16),
            Text(
              'Training Insights',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => _InsightRow(
              insight: insight,
              isDark: isDark,
            )),
          ],
          
          // Recovery warnings
          if (selectedFilter == TimeFilter.weekly)
            ..._buildRecoveryWarnings(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildMuscleGroupList(bool isDark) {
    final muscles = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.legs,
      MuscleGroup.shoulders,
      MuscleGroup.arms,
      MuscleGroup.core,
    ];

    final colors = getMuscleGroupColors(isDark);

    return muscles.map((muscle) {
      final data = muscleAnalytics.muscleData[muscle];
      final sets = data?.sets ?? 0;
      final target = muscleAnalytics.getTarget(muscle);
      final color = colors[muscle] ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _MuscleGroupRow(
          muscle: muscle,
          sets: sets,
          target: selectedFilter == TimeFilter.weekly ? target : null,
          color: color,
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecoveryWarnings(bool isDark) {
    final warnings = <Widget>[];
    
    for (var entry in muscleAnalytics.muscleData.entries) {
      if (muscleAnalytics.isOverTraining(entry.key)) {
        warnings.add(const SizedBox(height: 16));
        warnings.add(Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider));
        warnings.add(const SizedBox(height: 12));
        warnings.add(_RecoveryWarning(
          muscle: entry.key,
          sets: entry.value.sets,
          threshold: muscleAnalytics.getWarningThreshold(entry.key),
          isDark: isDark,
        ));
      }
    }
    
    return warnings;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                ? Colors.white
                : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MuscleGroupRow extends StatelessWidget {
  final MuscleGroup muscle;
  final int sets;
  final int? target;
  final Color color;

  const _MuscleGroupRow({
    required this.muscle,
    required this.sets,
    required this.target,
    required this.color,
  });

  String _getMuscleName(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.core:
        return 'Core';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getMuscleName(muscle),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            target != null ? '$sets / $target' : '$sets sets',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: target != null && sets >= (target ?? 0)
                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                  : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String insight;
  final bool isDark;

  const _InsightRow({
    required this.insight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = insight.contains('on track') || insight.contains('ahead');
    final isWarning = insight.contains('low') || insight.contains('higher than');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              isPositive ? Icons.check_circle_outline : 
              isWarning ? Icons.info_outline : Icons.lightbulb_outline,
              size: 18,
              color: isPositive 
                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                  : isWarning
                      ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                      : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryWarning extends StatelessWidget {
  final MuscleGroup muscle;
  final int sets;
  final int threshold;
  final bool isDark;

  const _RecoveryWarning({
    required this.muscle,
    required this.sets,
    required this.threshold,
    required this.isDark,
  });

  String _getMuscleName(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.core:
        return 'Core';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF8A80)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF8A80)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 22,
              color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF5252),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High ${_getMuscleName(muscle)} Volume',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sets sets this week (>$threshold threshold). Consider deload or extra recovery.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isUp;

  const StatCard({super.key, required this.label, required this.value, required this.change, required this.isUp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : (isDark ? AppColors.darkError : AppColors.lightError), size: 16),
              const SizedBox(width: 4),
              Text(change, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isUp ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : (isDark ? AppColors.darkError : AppColors.lightError))),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final String period;
  final Widget child;

  const ChartContainer({super.key, required this.title, required this.subtitle, required this.period, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text(period, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class PRRow extends StatelessWidget {
  final String exercise;
  final String lastSet;
  final String weight;
  final String change;

  const PRRow({super.key, required this.exercise, required this.lastSet, required this.weight, required this.change});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(Icons.fitness_center_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(lastSet, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(weight, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(change, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: change == 'Stable' ? (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText) : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess))),
            ],
          ),
        ],
      ),
    );
  }
}



class MuscleGroupPieChart extends StatelessWidget {
  final Map<MuscleGroup, int> muscleGroupSets;

  const MuscleGroupPieChart({super.key, required this.muscleGroupSets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorMap = getMuscleGroupColors(isDark);
    final sections = <PieChartSectionData>[];
    
    // Create pie sections with consistent muscle group colors
    muscleGroupSets.forEach((muscle, sets) {
      sections.add(
        PieChartSectionData(
          value: sets.toDouble(),
          color: colorMap[muscle] ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
          radius: 45,
          showTitle: false,
        ),
      );
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 35,
      ),
    );
  }
}

class PersonalRecordsCard extends StatelessWidget {
  final List<PersonalRecord> personalRecords;
  final String preferredUnit;

  const PersonalRecordsCard({
    super.key,
    required this.personalRecords,
    required this.preferredUnit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal Records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (personalRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No personal records yet.\nComplete workouts to set your first PR!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkHint : AppColors.lightHint,
                  ),
                ),
              ),
            )
          else
            ...personalRecords.take(5).map((pr) {
              final index = personalRecords.indexOf(pr);
              return Column(
                children: [
                  if (index > 0)
                    Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  PRRow(
                    exercise: pr.exerciseName,
                    lastSet: 'Best Set',
                    weight: '${FormatUtils.formatWeight(pr.weight, preferredUnit, storedUnit: pr.unit)} × ${pr.reps}',
                    change: FormatUtils.formatDate(pr.achievedDate),
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }
}

class MuscleHeatMapCard extends StatelessWidget {
  final MuscleGroupAnalytics muscleAnalytics;
  final TimeFilter selectedFilter;
  final Function(TimeFilter) onFilterChanged;
  final List<Workout> allWorkouts; // Need for detailed muscle calculations
  final HeatMapMode heatMapMode;
  final Function(HeatMapMode) onModeChanged;

  const MuscleHeatMapCard({
    super.key,
    required this.muscleAnalytics,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.allWorkouts,
    required this.heatMapMode,
    required this.onModeChanged,
  });

  /// Calculate detailed muscle data from workouts
  Map<DetailedMuscle, DetailedMuscleData> _calculateDetailedMuscleData(
    List<Workout> workouts,
    TimeFilter filter,
  ) {
    final int days = filter == TimeFilter.weekly ? 7 : filter == TimeFilter.monthly ? 30 : 90;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredWorkouts = workouts.where((w) => w.startTime.isAfter(cutoffDate)).toList();

    // Initialize all detailed muscles with default values of 0
    // This ensures no muscle region can ever be null
    final muscleData = <DetailedMuscle, DetailedMuscleData>{};
    for (var muscle in DetailedMuscle.values) {
      muscleData[muscle] = DetailedMuscleData(
        muscle: muscle,
        load: 0.0,
        primarySets: 0,
        secondarySets: 0,
        totalVolume: 0.0,
        topExercises: [],
      );
    }

    // Track exercise contributions per muscle
    final exerciseContributions = <DetailedMuscle, Map<String, double>>{};
    for (var muscle in DetailedMuscle.values) {
      exerciseContributions[muscle] = {};
    }

    // Track daily loads per muscle for decay calculation
    final dailyLoadsPerMuscle = <DetailedMuscle, Map<DateTime, double>>{};
    for (var muscle in DetailedMuscle.values) {
      dailyLoadsPerMuscle[muscle] = {};
    }

    // Process each workout
    for (var workout in filteredWorkouts) {
      final workoutDate = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );
      
      for (var workoutExercise in workout.exercises) {
        final exerciseName = workoutExercise.exercise.name;
        final completedSets = workoutExercise.sets.where((s) => s.isCompleted).toList();
        final setsCount = completedSets.length;
        final volume = completedSets.fold<double>(
          0.0,
          (sum, s) => sum + (s.weight * s.reps),
        );

        // Get weighted muscle contributions for this exercise
        final muscleContributions = MuscleMappingService.getMuscleContributions(exerciseName);
        
        for (var entry in muscleContributions.entries) {
          final muscle = entry.key;
          final contributionWeight = entry.value;
          
          // Use ?? operator for extra null safety
          final current = muscleData[muscle] ?? DetailedMuscleData(
            muscle: muscle,
            load: 0.0,
            primarySets: 0,
            secondarySets: 0,
            totalVolume: 0.0,
            topExercises: [],
          );
          
          // Calculate weighted load and volume
          final weightedLoad = setsCount * contributionWeight;
          final weightedVolume = volume * contributionWeight;
          
          // Categorize as primary (>= 0.8) or secondary (< 0.8)
          final isPrimary = contributionWeight >= 0.8;
          
          muscleData[muscle] = current.copyWith(
            load: current.load + weightedLoad,
            primarySets: isPrimary ? current.primarySets + setsCount : current.primarySets,
            secondarySets: !isPrimary ? current.secondarySets + setsCount : current.secondarySets,
            totalVolume: current.totalVolume + weightedVolume,
          );
          
          // Track daily loads for this muscle
          final dailyLoads = dailyLoadsPerMuscle[muscle] ?? {};
          dailyLoads[workoutDate] = (dailyLoads[workoutDate] ?? 0.0) + weightedLoad;
          dailyLoadsPerMuscle[muscle] = dailyLoads;
          
          // Track weighted contributions for top exercises calculation
          final contributions = exerciseContributions[muscle] ?? {};
          contributions[exerciseName] = (contributions[exerciseName] ?? 0.0) + weightedLoad;
          exerciseContributions[muscle] = contributions;
        }
      }
    }

    // Calculate top 3 exercises and decayed loads for each muscle
    for (var muscle in DetailedMuscle.values) {
      final contributions = exerciseContributions[muscle] ?? {};
      final sortedExercises = contributions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topExercises = sortedExercises.take(3).map((e) => e.key).toList();
      
      // Calculate decayed load using recovery calculator
      final dailyLoads = dailyLoadsPerMuscle[muscle] ?? {};
      final decayedLoad = RecoveryCalculator.calculateDecayedLoad(
        workoutDates: dailyLoads,
      );
      
      final current = muscleData[muscle] ?? DetailedMuscleData(
        muscle: muscle,
        load: 0.0,
        primarySets: 0,
        secondarySets: 0,
        totalVolume: 0.0,
        topExercises: [],
      );
      muscleData[muscle] = current.copyWith(
        topExercises: topExercises,
        decayedLoad: decayedLoad,
        dailyLoads: dailyLoads,
      );
    }

    return muscleData;
  }

  /// Get workouts that affect a specific muscle
  List<Workout> _getWorkoutsForMuscle(
    DetailedMuscle muscle,
    List<Workout> workouts,
    TimeFilter filter,
  ) {
    final int days = filter == TimeFilter.weekly ? 7 : filter == TimeFilter.monthly ? 30 : 90;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return workouts.where((workout) {
      if (workout.startTime.isBefore(cutoffDate)) return false;
      
      // Check if any exercise in this workout targets the muscle
      return workout.exercises.any((workoutExercise) {
        final exerciseName = workoutExercise.exercise.name;
        final primaryMuscles = MuscleMappingService.getPrimaryMuscles(exerciseName);
        final secondaryMuscles = MuscleMappingService.getSecondaryMuscles(exerciseName);
        return primaryMuscles.contains(muscle) || secondaryMuscles.contains(muscle);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Calculate detailed muscle data
    final detailedMuscleData = _calculateDetailedMuscleData(allWorkouts, selectedFilter);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title
          Text('Muscle Heat Map', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Tap any muscle to see detailed breakdown',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode toggle chips
          Row(
            children: [
              _FilterChip(
                label: 'Training Load',
                isSelected: heatMapMode == HeatMapMode.trainingLoad,
                onTap: () => onModeChanged(HeatMapMode.trainingLoad),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Recovery',
                isSelected: heatMapMode == HeatMapMode.recovery,
                onTap: () => onModeChanged(HeatMapMode.recovery),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Time filter chips
          Row(
            children: [
              _FilterChip(
                label: 'Week',
                isSelected: selectedFilter == TimeFilter.weekly,
                onTap: () => onFilterChanged(TimeFilter.weekly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Month',
                isSelected: selectedFilter == TimeFilter.monthly,
                onTap: () => onFilterChanged(TimeFilter.monthly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '90 Days',
                isSelected: selectedFilter == TimeFilter.ninetyDays,
                onTap: () => onFilterChanged(TimeFilter.ninetyDays),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Detailed heat map visualization with tap support
          DetailedMuscleHeatMap(
            muscleData: detailedMuscleData,
            mode: heatMapMode,
            onMuscleTap: (muscle) {
              // Use ?? operator to ensure we always have valid data, even if muscle is missing
              final muscleData = detailedMuscleData[muscle] ?? DetailedMuscleData(
                muscle: muscle,
                load: 0.0,
                primarySets: 0,
                secondarySets: 0,
                totalVolume: 0.0,
                topExercises: [],
              );
              
              // Only navigate if there's actual training data
              if (muscleData.load > 0) {
                final recentWorkouts = _getWorkoutsForMuscle(muscle, allWorkouts, selectedFilter);
                final timeFilterLabel = selectedFilter == TimeFilter.weekly 
                    ? 'Week' 
                    : selectedFilter == TimeFilter.monthly 
                        ? 'Month' 
                        : '90 Days';
                
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MuscleDetailScreen(
                      muscle: muscle,
                      muscleData: muscleData,
                      recentWorkouts: recentWorkouts,
                      preferredUnit: provider.preferredUnit,
                      timeFilter: timeFilterLabel,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}


