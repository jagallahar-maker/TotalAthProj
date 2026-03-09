import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';

/// Time filter options for Load Score trends
enum LoadScoreTimeFilter { week, month, ninetyDays }

class LoadScoreTrendCard extends StatefulWidget {
  final List<Workout> workouts;
  
  const LoadScoreTrendCard({
    super.key,
    required this.workouts,
  });

  @override
  State<LoadScoreTrendCard> createState() => _LoadScoreTrendCardState();
}

class _LoadScoreTrendCardState extends State<LoadScoreTrendCard> {
  LoadScoreTimeFilter _selectedFilter = LoadScoreTimeFilter.week;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate data based on selected filter
    final days = _getDaysForFilter(_selectedFilter);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredWorkouts = widget.workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Calculate average Load Score
    final avgLoadScore = LoadScoreCalculator.calculateAverageLoadScore(filteredWorkouts);
    final loadScoreLabel = LoadScoreCalculator.getLoadScoreLabel(avgLoadScore);
    
    // Calculate trend
    final trend = LoadScoreCalculator.calculateLoadScoreTrend(
      allWorkouts: widget.workouts,
      days: days,
    );
    
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
                    'Load Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Training stress metric',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(int.parse(LoadScoreCalculator.getLoadScoreColor(avgLoadScore, isDark).replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  loadScoreLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filter chips
          Row(
            children: [
              _FilterChip(
                label: '7 Days',
                isSelected: _selectedFilter == LoadScoreTimeFilter.week,
                onTap: () => setState(() => _selectedFilter = LoadScoreTimeFilter.week),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '30 Days',
                isSelected: _selectedFilter == LoadScoreTimeFilter.month,
                onTap: () => setState(() => _selectedFilter = LoadScoreTimeFilter.month),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '90 Days',
                isSelected: _selectedFilter == LoadScoreTimeFilter.ninetyDays,
                onTap: () => setState(() => _selectedFilter = LoadScoreTimeFilter.ninetyDays),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Avg Score',
                  value: avgLoadScore > 0 ? avgLoadScore.toStringAsFixed(0) : '--',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Trend',
                  value: trend.abs() >= 0.1 
                      ? '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%'
                      : '--',
                  isDark: isDark,
                  isPositive: trend >= 0,
                  showTrend: trend.abs() >= 0.1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Workouts',
                  value: filteredWorkouts.length.toString(),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          
          // Chart
          if (filteredWorkouts.length >= 2) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: _LoadScoreChart(
                workouts: filteredWorkouts,
                isDark: isDark,
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Complete at least 2 workouts to see Load Score trend',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkHint : AppColors.lightHint,
                  ),
                ),
              ),
            ),
          ],
          
          // Info section
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Load Score combines volume and intensity to measure total training stress. Higher scores indicate harder workouts.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  int _getDaysForFilter(LoadScoreTimeFilter filter) {
    switch (filter) {
      case LoadScoreTimeFilter.week:
        return 7;
      case LoadScoreTimeFilter.month:
        return 30;
      case LoadScoreTimeFilter.ninetyDays:
        return 90;
    }
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool? isPositive;
  final bool showTrend;

  const _StatBox({
    required this.label,
    required this.value,
    required this.isDark,
    this.isPositive,
    this.showTrend = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (showTrend && isPositive != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    isPositive! ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositive!
                        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                        : (isDark ? AppColors.darkError : AppColors.lightError),
                  ),
                ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: showTrend && isPositive != null
                        ? (isPositive!
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : (isDark ? AppColors.darkError : AppColors.lightError))
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadScoreChart extends StatelessWidget {
  final List<Workout> workouts;
  final bool isDark;

  const _LoadScoreChart({
    required this.workouts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Prepare data points
    final spots = <FlSpot>[];
    
    for (int i = 0; i < workouts.length; i++) {
      final loadScore = workouts[i].loadScore;
      spots.add(FlSpot(i.toDouble(), loadScore));
    }
    
    // Find min and max for Y axis
    final scores = spots.map((s) => s.y).toList();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    
    // Add padding to Y axis
    final yPadding = (maxScore - minScore) * 0.2;
    final yMin = (minScore - yPadding).clamp(0.0, double.infinity).toDouble();
    final yMax = maxScore + yPadding;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: (isDark ? AppColors.darkDivider : AppColors.lightDivider).withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (yMax - yMin) / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: workouts.length > 10 ? (workouts.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= workouts.length) return const SizedBox.shrink();
                
                final workout = workouts[index];
                final day = workout.startTime.day;
                final month = workout.startTime.month;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '$month/$day',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (workouts.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
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
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => isDark ? AppColors.darkBackground : AppColors.lightBackground,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final workout = workouts[spot.x.toInt()];
                final date = '${workout.startTime.month}/${workout.startTime.day}';
                final score = spot.y.toStringAsFixed(0);
                final label = LoadScoreCalculator.getLoadScoreLabel(spot.y);
                
                return LineTooltipItem(
                  '$date\n$score ($label)',
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
