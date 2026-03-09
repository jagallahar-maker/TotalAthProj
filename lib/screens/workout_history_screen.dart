import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen view
    CrashlyticsService().logScreen('WorkoutHistory');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    // Only show completed workouts with at least one completed set
    final completedWorkouts = provider.workouts
        .where((w) => w.isCompleted && w.completedSets > 0)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final recentWorkouts = completedWorkouts.take(7).toList();

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
                      Text('Workout History', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Track your consistency', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ),
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Volume Trend', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Last 7 Days', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 160, child: VolumeBarChart(workouts: recentWorkouts.reversed.toList())),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(label: 'All Workouts', selected: true),
                    const SizedBox(width: 8),
                    FilterChip(label: 'Push', selected: false),
                    const SizedBox(width: 8),
                    FilterChip(label: 'Pull', selected: false),
                    const SizedBox(width: 8),
                    FilterChip(label: 'Legs', selected: false),
                    const SizedBox(width: 8),
                    FilterChip(label: 'Upper Body', selected: false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...completedWorkouts.take(10).map((workout) => WorkoutCard(workout: workout)),
              TextButton(
                onPressed: () {},
                child: Text('Load Older Workouts', style: TextStyle(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/start-workout'),
        icon: const Icon(Icons.add),
        label: const Text('New Workout'),
      ),
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const FilterChip({super.key, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: selected ? Colors.transparent : (isDark ? AppColors.darkDivider : AppColors.lightDivider)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary) : null)),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final Workout workout;

  const WorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    return GestureDetector(
      onTap: () => context.push('/workout-details/${workout.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(FormatUtils.formatDate(workout.startTime), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(FormatUtils.formatVolume(workout.totalVolume, preferredUnit), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exercises', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
                        Text('${workout.exercises.length}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sets', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
                        Text('${workout.completedSets}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Load Score', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
                        Text(
                          workout.loadScore > 0 ? workout.loadScore.toStringAsFixed(0) : '--',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Color(int.parse(LoadScoreCalculator.getLoadScoreColor(workout.loadScore, isDark).replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: workout.exercises.take(4).map((e) => ExerciseMiniTag(name: e.exercise.name)).toList(),
          ),
        ],
      ),
      ),
    );
  }
}

class ExerciseMiniTag extends StatelessWidget {
  final String name;

  const ExerciseMiniTag({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(name, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
    );
  }
}

class VolumeBarChart extends StatelessWidget {
  final List<Workout> workouts;

  const VolumeBarChart({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < 7; i++) {
      final volume = i < workouts.length ? workouts[i].totalVolume / 1000 : 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: volume, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(labels[value.toInt()], style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
