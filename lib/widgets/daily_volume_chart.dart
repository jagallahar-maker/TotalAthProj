import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

enum VolumeChartFilter { sevenDays, thirtyDays, ninetyDays }

class DailyVolumeChartCard extends StatefulWidget {
final List<Workout> workouts;
final String preferredUnit;

const DailyVolumeChartCard({
super.key,
required this.workouts,
required this.preferredUnit,
});

@override
State<DailyVolumeChartCard> createState() => _DailyVolumeChartCardState();
}

class WeightUnit {
}

class _DailyVolumeChartCardState extends State<DailyVolumeChartCard> {
VolumeChartFilter _selectedFilter = VolumeChartFilter.sevenDays;
int? _touchedIndex;

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final dailyData = _getDailyVolumeData();

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
// Header with title and filter
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Daily Training Volume',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'Total weight lifted per day',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
),
],
),
const SizedBox(height: 12),
// Filter chips
Row(
mainAxisAlignment: MainAxisAlignment.start,
children: [
_buildFilterChip(
context,
'Last 7 Days',
VolumeChartFilter.sevenDays,
isDark,
),
const SizedBox(width: 8),
_buildFilterChip(
context,
'Last 30 Days',
VolumeChartFilter.thirtyDays,
isDark,
),
const SizedBox(width: 8),
_buildFilterChip(
context,
'90 Days',
VolumeChartFilter.ninetyDays,
isDark,
),
],
),
const SizedBox(height: 24),
// Chart
ConstrainedBox(
constraints: const BoxConstraints(
minHeight: 200,
maxHeight: 240,
),
child: dailyData.isEmpty
? _buildEmptyState(context, isDark)
: _buildChart(context, isDark, dailyData),
),
// Legend/summary
if (dailyData.isNotEmpty) ...[
const SizedBox(height: 16),
_buildSummary(context, isDark, dailyData),
],
],
),
);
}

Widget _buildFilterChip(
BuildContext context,
String label,
VolumeChartFilter filter,
bool isDark,
) {
final isSelected = _selectedFilter == filter;
return GestureDetector(
onTap: () {
setState(() {
_selectedFilter = filter;
_touchedIndex = null;
});
},
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isSelected
? Colors.white
: (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
),
),
),
);
}

Widget _buildEmptyState(BuildContext context, bool isDark) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.bar_chart_rounded,
size: 48,
color: isDark
? AppColors.darkSecondaryText.withValues(alpha: 0.3)
: AppColors.lightSecondaryText.withValues(alpha: 0.3),
),
const SizedBox(height: 12),
Text(
'No workout data',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 4),
Text(
'Complete workouts to see your volume trend',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
);
}

Widget _buildChart(BuildContext context, bool isDark, List<DailyVolumeData> data) {
final maxVolume = data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);
final maxY = maxVolume > 0 ? (maxVolume * 1.15) : 1000.0; // Add 15% padding

return BarChart(
BarChartData(
maxY: maxY,
minY: 0,
gridData: FlGridData(
show: true,
drawVerticalLine: false,
horizontalInterval: maxY / 4,
getDrawingHorizontalLine: (value) {
return FlLine(
color: isDark
? AppColors.darkDivider.withValues(alpha: 0.3)
: AppColors.lightDivider.withValues(alpha: 0.5),
strokeWidth: 1,
);
},
),
titlesData: FlTitlesData(
leftTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 50,
getTitlesWidget: (value, meta) {
if (value == meta.max || value == 0) {
return const SizedBox.shrink();
}
return Padding(
padding: const EdgeInsets.only(right: 8.0),
child: Text(
_formatVolumeShort(value),
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontSize: 10,
),
textAlign: TextAlign.right,
),
);
},
),
),
rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
getTitlesWidget: (value, meta) {
final index = value.toInt();
if (index >= 0 && index < data.length) {
return Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Text(
data[index].label,
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontSize: 10,
),
),
);
}
return const SizedBox.shrink();
},
),
),
),
borderData: FlBorderData(show: false),
barGroups: data.asMap().entries.map((entry) {
final index = entry.key;
final item = entry.value;
final isTouched = _touchedIndex == index;

return BarChartGroupData(
x: index,
barRods: [
BarChartRodData(
toY: item.volume,
color: item.workoutCount > 0
? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
: (isDark
? AppColors.darkDivider.withValues(alpha: 0.3)
: AppColors.lightDivider.withValues(alpha: 0.5)),
width: isTouched ? 20 : 16,
borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
),
],
);
}).toList(),
barTouchData: BarTouchData(
enabled: true,
touchCallback: (FlTouchEvent event, barTouchResponse) {
setState(() {
if (!event.isInterestedForInteractions ||
barTouchResponse == null ||
barTouchResponse.spot == null) {
_touchedIndex = null;
return;
}
_touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
});
},
touchTooltipData: BarTouchTooltipData(
getTooltipColor: (group) => isDark
? AppColors.darkBackground.withValues(alpha: 0.95)
: AppColors.lightBackground.withValues(alpha: 0.95),
tooltipPadding: const EdgeInsets.all(12),
tooltipMargin: 8,
tooltipRoundedRadius: AppRadius.md,
getTooltipItem: (group, groupIndex, rod, rodIndex) {
final item = data[groupIndex];
if (item.workoutCount == 0) {
return BarTooltipItem(
'Rest Day\n${item.dateLabel}',
TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.bold,
fontSize: 12,
),
);
}

return BarTooltipItem(
'${item.dateLabel}\n',
TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.bold,
fontSize: 12,
),
children: [
TextSpan(
text: FormatUtils.formatVolume(item.volume, widget.preferredUnit),
style: TextStyle(
color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
TextSpan(
text: '\n${item.workoutCount} workout${item.workoutCount > 1 ? 's' : ''}',
style: TextStyle(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontSize: 11,
),
),
],
);
},
),
),
),
);
}

Widget _buildSummary(BuildContext context, bool isDark, List<DailyVolumeData> data) {
final totalVolume = data.fold<double>(0, (sum, d) => sum + d.volume);
final totalWorkouts = data.fold<int>(0, (sum, d) => sum + d.workoutCount);
final daysWithWorkouts = data.where((d) => d.workoutCount > 0).length;
final avgVolumePerWorkout = totalWorkouts > 0 ? totalVolume / totalWorkouts : 0.0;

return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildSummaryItem(
context,
isDark,
'Total Volume',
FormatUtils.formatVolume(totalVolume, widget.preferredUnit),
),
_buildSummaryDivider(isDark),
_buildSummaryItem(
context,
isDark,
'Workouts',
totalWorkouts.toString(),
),
_buildSummaryDivider(isDark),
_buildSummaryItem(
context,
isDark,
'Training Days',
daysWithWorkouts.toString(),
),
_buildSummaryDivider(isDark),
_buildSummaryItem(
context,
isDark,
'Avg/Workout',
FormatUtils.formatVolume(avgVolumePerWorkout, widget.preferredUnit),
),
],
),
);
}

Widget _buildSummaryItem(BuildContext context, bool isDark, String label, String value) {
return Column(
children: [
Text(
value,
style: Theme.of(context).textTheme.labelLarge?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
),
),
const SizedBox(height: 2),
Text(
label,
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontSize: 9,
),
),
],
);
}

Widget _buildSummaryDivider(bool isDark) {
return Container(
width: 1,
height: 30,
color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
);
}

List<DailyVolumeData> _getDailyVolumeData() {
final now = DateTime.now();
final days = _selectedFilter == VolumeChartFilter.sevenDays
? 7
: _selectedFilter == VolumeChartFilter.thirtyDays
? 30
: 90;

// Filter workouts within the time range
final filteredWorkouts = widget.workouts.where((w) {
final diff = now.difference(w.startTime).inDays;
return diff >= 0 && diff < days;
}).toList();

// Group workouts by date
final Map<String, List<Workout>> workoutsByDate = {};
for (var workout in filteredWorkouts) {
final dateKey = _getDateKey(workout.startTime);
workoutsByDate.putIfAbsent(dateKey, () => []).add(workout);
}

// Create data points for each day
final List<DailyVolumeData> data = [];
for (int i = days - 1; i >= 0; i--) {
final date = now.subtract(Duration(days: i));
final dateKey = _getDateKey(date);
final dayWorkouts = workoutsByDate[dateKey] ?? [];

final totalVolume = dayWorkouts.fold<double>(
0,
(sum, w) => sum + w.totalVolume,
);

data.add(DailyVolumeData(
date: date,
volume: totalVolume,
workoutCount: dayWorkouts.length,
label: _getDateLabel(date, i, days),
dateLabel: _getFullDateLabel(date),
));
}

return data;
}

String _getDateKey(DateTime date) {
return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _getDateLabel(DateTime date, int daysAgo, int totalDays) {
if (totalDays <= 7) {
// For 7-day view, show day abbreviation
const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
return days[date.weekday - 1];
} else if (totalDays <= 30) {
// For 30-day view, show date
return '${date.day}';
} else {
// For 90-day view, show month/day for every 7th day or start/end
if (daysAgo % 7 == 0 || daysAgo == 0 || daysAgo == totalDays - 1) {
return '${date.month}/${date.day}';
}
return '';
}
}

String _getFullDateLabel(DateTime date) {
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String _formatVolumeShort(double volumeKg) {
// Volume is already in kg (stored unit), convert to display unit if needed
final volume = UnitConversion.convert(volumeKg, 'kg', widget.preferredUnit);
if (volume >= 1000) {
return '${(volume / 1000).toStringAsFixed(0)}k';
}
return volume.toStringAsFixed(0);
}
}

class DailyVolumeData {
final DateTime date;
final double volume;
final int workoutCount;
final String label;
final String dateLabel;

const DailyVolumeData({
required this.date,
required this.volume,
required this.workoutCount,
required this.label,
required this.dateLabel,
});
}
