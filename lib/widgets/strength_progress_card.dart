import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:go_router/go_router.dart';

/// Time filter options for strength progress
enum StrengthTimeFilter {
sevenDays,
thirtyDays,
ninetyDays,
allTime,
}

/// Data model for tracking a single exercise's strength progress
class ExerciseStrengthData {
final Exercise exercise;
final WorkoutSet? bestSet;
final double estimatedOneRepMax;
final WorkoutSet? highestVolumeSet;
final double thirtyDayChange; // Percentage change
final List<StrengthDataPoint> dataPoints;
final bool hasEnoughData;

const ExerciseStrengthData({
required this.exercise,
this.bestSet,
required this.estimatedOneRepMax,
this.highestVolumeSet,
required this.thirtyDayChange,
required this.dataPoints,
required this.hasEnoughData,
});
}

/// Individual data point for strength progression over time
class StrengthDataPoint {
final DateTime date;
final double estimatedOneRepMax;
final WorkoutSet bestSetOfDay;
final double totalVolume;

const StrengthDataPoint({
required this.date,
required this.estimatedOneRepMax,
required this.bestSetOfDay,
required this.totalVolume,
});
}

class StrengthProgressCard extends StatefulWidget {
final List<ExerciseStrengthData> exerciseData;
final String preferredUnit;

const StrengthProgressCard({
super.key,
required this.exerciseData,
required this.preferredUnit,
});

@override
State<StrengthProgressCard> createState() => _StrengthProgressCardState();
}

class _StrengthProgressCardState extends State<StrengthProgressCard> {
StrengthTimeFilter _selectedFilter = StrengthTimeFilter.thirtyDays;

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

// Filter to only exercises with enough data
final validExercises = widget.exerciseData.where((e) => e.hasEnoughData).toList();

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
children: [
Icon(
Icons.trending_up_rounded,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
size: 24,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Strength Progress',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'Track your major lifts over time',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
),
],
),
const SizedBox(height: 16),

// Time filter chips
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_buildFilterChip(context, isDark, '7 Days', StrengthTimeFilter.sevenDays),
const SizedBox(width: 8),
_buildFilterChip(context, isDark, '30 Days', StrengthTimeFilter.thirtyDays),
const SizedBox(width: 8),
_buildFilterChip(context, isDark, '90 Days', StrengthTimeFilter.ninetyDays),
const SizedBox(width: 8),
_buildFilterChip(context, isDark, 'All Time', StrengthTimeFilter.allTime),
],
),
),
const SizedBox(height: 20),

// Content
if (validExercises.isEmpty)
_buildEmptyState(context, isDark)
else
...validExercises.map((data) => Padding(
padding: const EdgeInsets.only(bottom: 16.0),
child: _StrengthExerciseRow(
data: data,
preferredUnit: widget.preferredUnit,
timeFilter: _selectedFilter,
),
)),
],
),
);
}

Widget _buildFilterChip(BuildContext context, bool isDark, String label, StrengthTimeFilter filter) {
final isSelected = _selectedFilter == filter;

return GestureDetector(
onTap: () {
setState(() {
_selectedFilter = filter;
});
},
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

Widget _buildEmptyState(BuildContext context, bool isDark) {
return Container(
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(
color: (isDark ? AppColors.darkDivider : AppColors.lightDivider).withValues(alpha: 0.5),
),
),
child: Column(
children: [
Icon(
Icons.show_chart_rounded,
size: 48,
color: (isDark ? AppColors.darkHint : AppColors.lightHint).withValues(alpha: 0.5),
),
const SizedBox(height: 16),
Text(
'Complete more workouts to unlock strength trends',
textAlign: TextAlign.center,
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
height: 1.5,
),
),
const SizedBox(height: 8),
Text(
'Log at least 2 workouts with major lifts to see progress',
textAlign: TextAlign.center,
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
height: 1.4,
),
),
],
),
);
}
}

class _StrengthExerciseRow extends StatelessWidget {
final ExerciseStrengthData data;
final String preferredUnit;
final StrengthTimeFilter timeFilter;

const _StrengthExerciseRow({
required this.data,
required this.preferredUnit,
required this.timeFilter,
});

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

// Filter data points based on time filter
final filteredDataPoints = _filterDataPoints(data.dataPoints, timeFilter);

// Calculate change based on filtered data
double change = 0.0;
if (filteredDataPoints.length >= 2) {
final oldest = filteredDataPoints.first.estimatedOneRepMax;
final newest = filteredDataPoints.last.estimatedOneRepMax;
if (oldest > 0) {
change = ((newest - oldest) / oldest) * 100;
}
}

// Format the best set
final bestSetText = data.bestSet != null
? '${FormatUtils.formatWeight(data.bestSet!.weight, preferredUnit, storedUnit: data.bestSet!.unit)} × ${data.bestSet!.reps}'
: '--';

// Format the estimated 1RM
final e1rmText = data.estimatedOneRepMax > 0
? FormatUtils.formatWeight(data.estimatedOneRepMax, preferredUnit, storedUnit: 'kg')
: '--';

// Format the change
final changeText = change.abs() >= 0.1
? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'
: '--';

final changeColor = change >= 0
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError);

return GestureDetector(
onTap: () {
// Navigate to exercise progress detail
context.push(
'/exercise-progress/${data.exercise.id}?name=${Uri.encodeComponent(data.exercise.name)}',
);
},
child: Container(
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(
color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
),
),
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Exercise name and trend indicator
Row(
children: [
Expanded(
child: Text(
data.exercise.name,
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.w600,
),
),
),
Icon(
change >= 0
? Icons.trending_up_rounded
: Icons.trending_down_rounded,
color: changeColor,
size: 20,
),
const SizedBox(width: 4),
Text(
changeText,
style: Theme.of(context).textTheme.labelMedium?.copyWith(
color: changeColor,
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 12),

// Stats row
Row(
children: [
Expanded(
child: _StatChip(
label: 'Best Set',
value: bestSetText,
),
),
const SizedBox(width: 8),
Expanded(
child: _StatChip(
label: 'Est. 1RM',
value: e1rmText,
),
),
],
),
const SizedBox(height: 12),

// Mini trend chart
SizedBox(
height: 60,
child: _MiniTrendChart(
dataPoints: filteredDataPoints,
isDark: isDark,
),
),
],
),
),
);
}

List<StrengthDataPoint> _filterDataPoints(List<StrengthDataPoint> dataPoints, StrengthTimeFilter filter) {
if (filter == StrengthTimeFilter.allTime) {
return dataPoints;
}

final days = filter == StrengthTimeFilter.sevenDays
? 7
: filter == StrengthTimeFilter.thirtyDays
? 30
: 90;

final cutoff = DateTime.now().subtract(Duration(days: days));
return dataPoints.where((dp) => dp.date.isAfter(cutoff)).toList();
}
}

class _StatChip extends StatelessWidget {
final String label;
final String value;

const _StatChip({
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;

return Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.md),
border: Border.all(
color: (isDark ? AppColors.darkDivider : AppColors.lightDivider).withValues(alpha: 0.5),
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
const SizedBox(height: 4),
Text(
value,
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
);
}
}

class _MiniTrendChart extends StatelessWidget {
final List<StrengthDataPoint> dataPoints;
final bool isDark;

const _MiniTrendChart({
required this.dataPoints,
required this.isDark,
});

@override
Widget build(BuildContext context) {
if (dataPoints.isEmpty) {
return Center(
child: Text(
'No data',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
);
}

// Convert data points to chart spots
final spots = <FlSpot>[];
for (int i = 0; i < dataPoints.length; i++) {
spots.add(FlSpot(i.toDouble(), dataPoints[i].estimatedOneRepMax));
}

// Find min and max for Y axis
final yValues = spots.map((s) => s.y).toList();
final minY = yValues.reduce((a, b) => a < b ? a : b);
final maxY = yValues.reduce((a, b) => a > b ? a : b);
final padding = (maxY - minY) * 0.1;

return LineChart(
LineChartData(
gridData: const FlGridData(show: false),
titlesData: const FlTitlesData(show: false),
borderData: FlBorderData(show: false),
minY: minY - padding,
maxY: maxY + padding,
lineBarsData: [
LineChartBarData(
spots: spots,
isCurved: true,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
barWidth: 2,
isStrokeCapRound: true,
dotData: FlDotData(
show: true,
getDotPainter: (spot, percent, barData, index) {
return FlDotCirclePainter(
radius: 3,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
strokeWidth: 1,
strokeColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
);
},
),
belowBarData: BarAreaData(
show: true,
color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
.withValues(alpha: 0.1),
),
),
],
lineTouchData: const LineTouchData(enabled: false),
),
);
}
}
