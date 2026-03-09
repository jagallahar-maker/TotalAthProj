import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/nav.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/utils/unit_conversion.dart';
import 'package:total_athlete/widgets/plate_calculator_modal.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class LogExerciseScreen extends StatefulWidget {
final String workoutId;
final String? exerciseIndex;

const LogExerciseScreen({super.key, required this.workoutId, this.exerciseIndex});

@override
State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
Workout? _workout;
WorkoutExercise? _currentExercise;
int _currentExerciseIndex = -1;

// Search and filter state
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
MuscleGroup? _selectedMuscleFilter;

// Rest timer state
bool _isResting = false;
int _restSecondsRemaining = 90;
Timer? _restTimer;
final int _defaultRestSeconds = 90;

// Previous performance state
WorkoutExercise? _previousPerformance;
DateTime? _lastWorkoutDate;
WorkoutSet? _bestSetEver;

// Progression suggestion state
Map<String, dynamic>? _progressionSuggestion;

// Last workout expanded state
bool _isLastWorkoutExpanded = false;

// Helper getter for preferred unit
String get preferredUnit {
final provider = Provider.of<AppProvider>(context, listen: false);
return provider.preferredUnit;
}

@override
void initState() {
super.initState();
_loadWorkout();
_searchController.addListener(() {
setState(() {
_searchQuery = _searchController.text.toLowerCase();
});
});
}

@override
void dispose() {
_searchController.dispose();
_restTimer?.cancel();
super.dispose();
}

void _startRestTimer() {
_restTimer?.cancel();
setState(() {
_isResting = true;
_restSecondsRemaining = _defaultRestSeconds;
});

_restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
setState(() {
if (_restSecondsRemaining > 0) {
_restSecondsRemaining--;
} else {
_stopRestTimer();
}
});
});
}

void _stopRestTimer() {
_restTimer?.cancel();
setState(() {
_isResting = false;
_restSecondsRemaining = _defaultRestSeconds;
});
}

void _resetRestTimer() {
_restTimer?.cancel();
setState(() {
_restSecondsRemaining = _defaultRestSeconds;
});
_startRestTimer();
}

Future<void> _loadWorkout() async {
final provider = Provider.of<AppProvider>(context, listen: false);
final workouts = provider.workouts;
final workout = workouts.firstWhere((w) => w.id == widget.workoutId);
setState(() {
_workout = workout;
// If exerciseIndex is provided, use it; otherwise default to first exercise
if (widget.exerciseIndex != null) {
final index = int.tryParse(widget.exerciseIndex!) ?? -1;
if (index >= 0 && index < workout.exercises.length) {
_currentExerciseIndex = index;
_currentExercise = workout.exercises[index];
}
} else if (workout.exercises.isNotEmpty) {
_currentExerciseIndex = 0;
_currentExercise = workout.exercises[0];
}
});

// Log screen to Crashlytics
final crashlytics = CrashlyticsService();
await crashlytics.logScreen('LogExercise');
if (_currentExercise != null) {
await crashlytics.setCustomKey('current_exercise', _currentExercise!.exercise.name);
}

// Load previous performance for the current exercise if it exists
if (_currentExercise != null) {
await _loadPreviousPerformance(_currentExercise!.exercise.id);
}
}

Future<void> _loadPreviousPerformance(String exerciseId) async {
final provider = Provider.of<AppProvider>(context, listen: false);
final userId = _workout?.userId ?? 'user_1';

// Get exercise history to find the date
final history = await provider.workoutService.getExerciseHistory(userId, exerciseId);

// Get best set ever
final bestSet = await provider.workoutService.getBestSetEver(userId, exerciseId);

// Get progression suggestion
final suggestion = await provider.workoutService.getProgressionSuggestion(userId, exerciseId);

if (history.isNotEmpty) {
final lastEntry = history.first;
final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(userId, exerciseId);
setState(() {
_previousPerformance = lastOccurrence;
_lastWorkoutDate = lastEntry['date'] as DateTime;
_bestSetEver = bestSet;
_progressionSuggestion = suggestion;
});
} else {
setState(() {
_previousPerformance = null;
_lastWorkoutDate = null;
_bestSetEver = null;
_progressionSuggestion = null;
});
}
}

Future<void> _saveWorkout() async {
if (_workout == null) return;
final provider = Provider.of<AppProvider>(context, listen: false);

try {
// Update the current exercise in the workout
if (_currentExercise != null && _currentExerciseIndex >= 0) {
final updatedExercises = List<WorkoutExercise>.from(_workout!.exercises);
updatedExercises[_currentExerciseIndex] = _currentExercise!;
_workout = _workout!.copyWith(
exercises: updatedExercises,
updatedAt: DateTime.now(),
);
}

await provider.updateWorkout(_workout!);
} catch (e, stackTrace) {
// Log error to Crashlytics
await CrashlyticsService().recordError(
e,
stackTrace,
reason: 'Failed to save workout in LogExerciseScreen',
);
rethrow;
}
}

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;

if (_workout == null) {
return Scaffold(
backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
body: Center(child: CircularProgressIndicator(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
);
}

if (_currentExercise == null) {
return _buildExerciseSelection();
}

return _buildWorkoutSession();
}

Widget _buildWorkoutSession() {
final isDark = Theme.of(context).brightness == Brightness.dark;

return Scaffold(
backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
body: SafeArea(
child: Column(
children: [
// Header
Container(
padding: AppSpacing.paddingLg,
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
IconButton(
icon: const Icon(Icons.arrow_back_rounded),
onPressed: () async {
await _saveWorkout();
if (context.mounted) {
context.pop();
}
},
),
Expanded(
child: Column(
children: [
_isResting ? _buildRestTimerDisplay(isDark) : _buildWorkoutTimerDisplay(isDark),
const SizedBox(height: 6),
WorkoutDatePicker(
selectedDate: _workout!.startTime,
onDateChanged: (date) {
setState(() {
_workout = _workout!.copyWith(
startTime: date,
updatedAt: DateTime.now(),
);
});
_saveWorkout();
},
isDark: isDark,
),
],
),
),
TextButton(
onPressed: () => _finishWorkout(),
child: Text(
'Finish',
style: TextStyle(
color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
),
],
),
// Rest timer controls
if (_isResting) _buildRestTimerControls(isDark),
const SizedBox(height: 16),
Text(
_currentExercise!.exercise.name,
style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Row(
children: [
Icon(Icons.museum_rounded, size: 16, color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
const SizedBox(width: 4),
Text(
FormatUtils.formatMuscleGroup(_currentExercise!.exercise.primaryMuscleGroup.name),
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
),
],
),
if (_currentExercise!.sets.isNotEmpty) ...[
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildStatItem(context, 'Completed Sets', '${_currentExercise!.completedSets}/${_currentExercise!.sets.length}'),
Container(width: 1, height: 24, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
_buildStatItem(context, 'Volume', FormatUtils.formatWeight(_currentExercise!.totalVolume, preferredUnit)),
],
),
),
],
],
),
),
// Sets List
Expanded(
child: SingleChildScrollView(
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Previous Performance Section
if (_previousPerformance != null) _buildPreviousPerformance(isDark),
..._currentExercise!.sets.asMap().entries.map((entry) => EditableSetRow(
index: entry.key + 1,
workoutSet: entry.value,
exercise: _currentExercise!.exercise,
onUpdate: (updatedSet) => _updateSet(entry.key, updatedSet),
onDelete: () => _deleteSet(entry.key),
onToggleComplete: () => _toggleSetComplete(entry.key),
)),
const SizedBox(height: 16),
OutlinedButton.icon(
onPressed: _addEmptySet,
icon: const Icon(Icons.add_rounded),
label: const Text('Add Set'),
style: OutlinedButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
side: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
),
),
const SizedBox(height: 24),
],
),
),
),
// Quick Add Panel
_buildQuickAddPanel(),
],
),
),
);
}

Widget _buildWorkoutTimerDisplay(bool isDark) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
borderRadius: BorderRadius.circular(AppRadius.full),
),
child: Text(
FormatUtils.formatDuration(_workout!.duration),
style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
),
);
}

Widget _buildRestTimerDisplay(bool isDark) {
final minutes = _restSecondsRemaining ~/ 60;
final seconds = _restSecondsRemaining % 60;
final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
isDark ? AppColors.darkPrimary.withValues(alpha: 0.7) : AppColors.lightPrimary.withValues(alpha: 0.7),
],
),
borderRadius: BorderRadius.circular(AppRadius.full),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.timer_rounded,
size: 18,
color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
),
const SizedBox(width: 6),
Text(
'REST $timeString',
style: Theme.of(context).textTheme.labelLarge?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
),
),
],
),
);
}

Widget _buildRestTimerControls(bool isDark) {
return Padding(
padding: const EdgeInsets.only(top: 12),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_buildRestControlButton(
icon: Icons.replay_rounded,
label: 'Reset',
onPressed: _resetRestTimer,
isDark: isDark,
),
const SizedBox(width: 12),
_buildRestControlButton(
icon: Icons.skip_next_rounded,
label: 'Skip',
onPressed: _stopRestTimer,
isDark: isDark,
),
],
),
);
}

Widget _buildRestControlButton({
required IconData icon,
required String label,
required VoidCallback onPressed,
required bool isDark,
}) {
return OutlinedButton.icon(
onPressed: onPressed,
icon: Icon(icon, size: 16),
label: Text(label),
style: OutlinedButton.styleFrom(
foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
minimumSize: Size.zero,
),
);
}

Widget _buildStatItem(BuildContext context, String label, String value) {
final isDark = Theme.of(context).brightness == Brightness.dark;
return Column(
children: [
Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
const SizedBox(height: 4),
Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
],
);
}

Widget _buildPreviousPerformance(bool isDark) {
if (_previousPerformance == null) return const SizedBox.shrink();

// Calculate best estimated 1RM from last workout
final provider = Provider.of<AppProvider>(context, listen: false);
final bestE1RM = provider.workoutService.getBestOneRepMax(_previousPerformance!.sets);

final hasMoreSets = _previousPerformance!.sets.length > 3;

return Column(
children: [
// Last Workout Section
InkWell(
onTap: hasMoreSets ? () {
setState(() {
_isLastWorkoutExpanded = !_isLastWorkoutExpanded;
});
} : null,
borderRadius: BorderRadius.circular(AppRadius.lg),
child: Container(
margin: const EdgeInsets.only(bottom: 12),
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
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Icon(
Icons.history_rounded,
size: 18,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
const SizedBox(width: 6),
Text(
'Last Workout',
style: Theme.of(context).textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
if (_lastWorkoutDate != null)
Text(
FormatUtils.formatDate(_lastWorkoutDate!),
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Sets',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 4),
Text(
'${_previousPerformance!.sets.length}',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
),
),
const SizedBox(width: 8),
Expanded(
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Volume',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 4),
Text(
FormatUtils.formatWeight(_previousPerformance!.totalVolume, preferredUnit),
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
),
),
const SizedBox(width: 8),
Expanded(
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Est. 1RM',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 4),
Text(
FormatUtils.formatWeight(bestE1RM, preferredUnit),
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
),
),
],
),
const SizedBox(height: 12),
// Show either first 3 sets or all sets based on expanded state
...(_isLastWorkoutExpanded
? _previousPerformance!.sets
: _previousPerformance!.sets.take(3).toList()
).asMap().entries.map((entry) => Padding(
padding: const EdgeInsets.symmetric(vertical: 2),
child: Row(
children: [
Container(
width: 24,
height: 24,
decoration: BoxDecoration(
color: isDark ? AppColors.darkSuccess.withValues(alpha: 0.2) : AppColors.lightSuccess.withValues(alpha: 0.2),
borderRadius: BorderRadius.circular(6),
),
alignment: Alignment.center,
child: Text(
'${entry.key + 1}',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
),
),
),
const SizedBox(width: 12),
Text(
'${FormatUtils.formatWeight(entry.value.weight, preferredUnit, storedUnit: entry.value.unit)} × ${entry.value.reps} reps',
style: Theme.of(context).textTheme.bodyMedium,
),
const Spacer(),
Text(
FormatUtils.formatWeight(entry.value.weight * entry.value.reps, preferredUnit, storedUnit: entry.value.unit),
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
)),
// Show/hide all sets button
if (hasMoreSets)
Padding(
padding: const EdgeInsets.only(top: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
_isLastWorkoutExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
size: 18,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
const SizedBox(width: 4),
Text(
_isLastWorkoutExpanded
? 'Show Less'
: 'Show All ${_previousPerformance!.sets.length} Sets',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
fontWeight: FontWeight.bold,
),
),
],
),
),
],
),
),
),

// Best Set Ever Section
if (_bestSetEver != null) _buildBestSetEver(isDark),

// Progression Suggestion Section
if (_progressionSuggestion != null) _buildProgressionSuggestion(isDark),

// View Full Progress Link
InkWell(
onTap: () {
context.push(
'${AppRoutes.exerciseProgress}/${_currentExercise!.exercise.id}?name=${Uri.encodeComponent(_currentExercise!.exercise.name)}',
);
},
child: Container(
margin: const EdgeInsets.only(bottom: 16),
padding: const EdgeInsets.symmetric(vertical: 12),
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.lightPrimary.withValues(alpha: 0.3)),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'View Full Progress',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
fontWeight: FontWeight.bold,
),
),
const SizedBox(width: 4),
Icon(
Icons.arrow_forward_rounded,
size: 18,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
],
),
),
),
],
);
}

Widget _buildBestSetEver(bool isDark) {
if (_bestSetEver == null) return const SizedBox.shrink();

final provider = Provider.of<AppProvider>(context, listen: false);
final bestE1RM = provider.workoutService.calculateOneRepMax(_bestSetEver!.weight, _bestSetEver!.reps);

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
isDark ? AppColors.darkPrimary.withValues(alpha: 0.15) : AppColors.lightPrimary.withValues(alpha: 0.1),
isDark ? AppColors.darkSurface : AppColors.lightSurface,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(
color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.lightPrimary.withValues(alpha: 0.3),
width: 1.5,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(6),
decoration: BoxDecoration(
color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.lightPrimary.withValues(alpha: 0.2),
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Icon(
Icons.emoji_events_rounded,
size: 18,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
const SizedBox(width: 8),
Text(
'Best Set Ever',
style: Theme.of(context).textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
],
),
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Column(
children: [
Text(
'Weight × Reps',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 6),
Text(
'${FormatUtils.formatWeight(_bestSetEver!.weight, preferredUnit, storedUnit: _bestSetEver!.unit)} × ${_bestSetEver!.reps}',
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
],
),
Container(
width: 1,
height: 40,
color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
),
Column(
children: [
Text(
'Est. 1RM',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 6),
Text(
FormatUtils.formatWeight(bestE1RM, preferredUnit),
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
],
),
),
],
),
);
}

Widget _buildProgressionSuggestion(bool isDark) {
if (_progressionSuggestion == null) return const SizedBox.shrink();

final suggestedWeight = _progressionSuggestion!['suggestedWeight'] as double;
final reason = _progressionSuggestion!['reason'] as String;
final lastWeight = _progressionSuggestion!['lastWeight'] as double;

// Determine if weight should increase, stay same, or decrease
bool isIncrease = suggestedWeight > lastWeight;
bool isDecrease = suggestedWeight < lastWeight;

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
isDark
? (isIncrease ? AppColors.darkSuccess.withValues(alpha: 0.15) : AppColors.darkAccent.withValues(alpha: 0.15))
: (isIncrease ? AppColors.lightSuccess.withValues(alpha: 0.1) : AppColors.lightAccent.withValues(alpha: 0.1)),
isDark ? AppColors.darkSurface : AppColors.lightSurface,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(
color: isDark
? (isIncrease ? AppColors.darkSuccess.withValues(alpha: 0.3) : AppColors.darkAccent.withValues(alpha: 0.3))
: (isIncrease ? AppColors.lightSuccess.withValues(alpha: 0.3) : AppColors.lightAccent.withValues(alpha: 0.3)),
width: 1.5,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(6),
decoration: BoxDecoration(
color: isDark
? (isIncrease ? AppColors.darkSuccess.withValues(alpha: 0.2) : AppColors.darkAccent.withValues(alpha: 0.2))
: (isIncrease ? AppColors.lightSuccess.withValues(alpha: 0.2) : AppColors.lightAccent.withValues(alpha: 0.2)),
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Icon(
isIncrease
? Icons.trending_up_rounded
: isDecrease
? Icons.trending_down_rounded
: Icons.trending_flat_rounded,
size: 18,
color: isDark
? (isIncrease ? AppColors.darkSuccess : AppColors.darkAccent)
: (isIncrease ? AppColors.lightSuccess : AppColors.lightAccent),
),
),
const SizedBox(width: 8),
Text(
'Next Session',
style: Theme.of(context).textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 12),
// Suggested weight display
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'Use',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(width: 8),
Text(
FormatUtils.formatWeight(suggestedWeight, preferredUnit),
style: Theme.of(context).textTheme.headlineSmall?.copyWith(
fontWeight: FontWeight.bold,
color: isDark
? (isIncrease ? AppColors.darkSuccess : AppColors.darkPrimaryText)
: (isIncrease ? AppColors.lightSuccess : AppColors.lightPrimaryText),
),
),
if (isIncrease) ...[
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: isDark ? AppColors.darkSuccess.withValues(alpha: 0.2) : AppColors.lightSuccess.withValues(alpha: 0.2),
borderRadius: BorderRadius.circular(AppRadius.sm),
),
child: Text(
'+${FormatUtils.formatWeight(suggestedWeight - lastWeight, preferredUnit)}',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
),
),
),
],
],
),
),
const SizedBox(height: 12),
// Reason text
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.lightbulb_outline_rounded,
size: 16,
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
const SizedBox(width: 6),
Expanded(
child: Text(
reason,
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontStyle: FontStyle.italic,
),
),
),
],
),
],
),
);
}

Widget _buildQuickAddPanel() {
final isDark = Theme.of(context).brightness == Brightness.dark;

// Get last set values or defaults
final lastSet = _currentExercise!.sets.isNotEmpty ? _currentExercise!.sets.last : null;
final defaultWeight = lastSet?.weight ?? 60.0; // This is in kg (storage unit)
final defaultReps = lastSet?.reps ?? 10;

// Convert weight to display unit for showing in the button
final displayWeight = UnitConversion.toDisplayUnit(defaultWeight, preferredUnit);

return Container(
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.15),
blurRadius: 16,
offset: const Offset(0, -4),
),
],
border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
),
padding: AppSpacing.paddingLg,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
ElevatedButton(
onPressed: () => _quickAddSet(defaultWeight, defaultReps),
style: ElevatedButton.styleFrom(
minimumSize: const Size(double.infinity, 64),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
elevation: 4,
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.check_circle_rounded, size: 28, color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary),
const SizedBox(width: 12),
Text(
'ADD SET: ${displayWeight.toInt()} $preferredUnit × $defaultReps',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
color: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
),
),
],
),
),
],
),
);
}

Widget _buildExerciseSelection() {
final provider = Provider.of<AppProvider>(context);
final isDark = Theme.of(context).brightness == Brightness.dark;

// Filter exercises based on search and muscle group
final filteredExercises = provider.exercises.where((exercise) {
final matchesSearch = _searchQuery.isEmpty ||
exercise.name.toLowerCase().contains(_searchQuery);
final matchesMuscleFilter = _selectedMuscleFilter == null ||
exercise.primaryMuscleGroup == _selectedMuscleFilter;
return matchesSearch && matchesMuscleFilter;
}).toList();

return Scaffold(
backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
appBar: AppBar(
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Add Exercise'),
if (_workout!.exercises.isNotEmpty)
Text(
'${_workout!.exercises.length} exercise${_workout!.exercises.length == 1 ? '' : 's'} added',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
),
],
),
leading: IconButton(
icon: const Icon(Icons.arrow_back_rounded),
onPressed: () async {
await _saveWorkout();
if (context.mounted) {
context.pop();
}
},
),
),
body: Column(
children: [
// Workout Summary
if (_workout!.exercises.isNotEmpty)
Container(
margin: AppSpacing.paddingLg,
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildWorkoutStat(context, Icons.fitness_center_rounded, 'Exercises', '${_workout!.exercises.length}'),
Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
_buildWorkoutStat(context, Icons.format_list_numbered_rounded, 'Sets', '${_workout!.completedSets}'),
Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
_buildWorkoutStat(context, Icons.monitor_weight_rounded, 'Volume', FormatUtils.formatWeight(_workout!.totalVolume, preferredUnit)),
],
),
const SizedBox(height: 12),
Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
const SizedBox(height: 8),
..._workout!.exercises.map((ex) => Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Icon(Icons.check_circle, size: 16, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
const SizedBox(width: 8),
Expanded(
child: Text(
ex.exercise.name,
style: Theme.of(context).textTheme.bodyMedium,
),
),
Text(
'${ex.completedSets}/${ex.sets.length} sets',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
),
],
),
)),
],
),
),
// Search Bar
Container(
margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
child: TextField(
controller: _searchController,
style: Theme.of(context).textTheme.bodyMedium,
decoration: InputDecoration(
hintText: 'Search exercises...',
hintStyle: TextStyle(color: isDark ? AppColors.darkHint : AppColors.lightHint),
prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkHint : AppColors.lightHint),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
icon: Icon(Icons.clear_rounded, color: isDark ? AppColors.darkHint : AppColors.lightHint),
onPressed: () {
_searchController.clear();
},
)
: null,
filled: true,
fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
borderSide: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
borderSide: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, width: 2),
),
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
),
),
),
// Muscle Group Filters
SizedBox(
height: 50,
child: ListView(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 16),
children: [
_buildMuscleFilterChip('All', null, isDark),
...MuscleGroup.values.map((muscle) =>
_buildMuscleFilterChip(FormatUtils.formatMuscleGroup(muscle.name), muscle, isDark)
),
],
),
),
const SizedBox(height: 8),
// Exercise List
Expanded(
child: filteredExercises.isEmpty
? Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.search_off_rounded,
size: 64,
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
const SizedBox(height: 16),
Text(
'No exercises found',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
const SizedBox(height: 8),
Text(
'Try a different search or filter',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
],
),
)
: ListView.builder(
padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
itemCount: filteredExercises.length,
itemBuilder: (context, index) {
final exercise = filteredExercises[index];
return GestureDetector(
onTap: () => _selectExercise(exercise),
child: Container(
margin: const EdgeInsets.only(bottom: 12),
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
child: Row(
children: [
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Icon(
Icons.fitness_center_rounded,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
exercise.name,
style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
),
Text(
FormatUtils.formatMuscleGroup(exercise.primaryMuscleGroup.name),
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
),
],
),
),
Icon(
Icons.add_circle_rounded,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
size: 32,
),
],
),
),
);
},
),
),
],
),
);
}

Widget _buildMuscleFilterChip(String label, MuscleGroup? muscle, bool isDark) {
final isSelected = _selectedMuscleFilter == muscle;

return Padding(
padding: const EdgeInsets.only(right: 8),
child: FilterChip(
label: Text(label),
selected: isSelected,
onSelected: (selected) {
setState(() {
_selectedMuscleFilter = muscle;
});
},
labelStyle: TextStyle(
color: isSelected
? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary)
: (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
),
backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
selectedColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
checkmarkColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
side: BorderSide(
color: isSelected
? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
: (isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
showCheckmark: true,
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
),
);
}

Widget _buildWorkoutStat(BuildContext context, IconData icon, String label, String value) {
final isDark = Theme.of(context).brightness == Brightness.dark;
return Column(
children: [
Icon(icon, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
const SizedBox(height: 4),
Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
],
);
}

void _selectExercise(Exercise exercise) async {
final provider = Provider.of<AppProvider>(context, listen: false);

// Try to get the last time this exercise was logged with completed sets
final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(
_workout!.userId,
exercise.id,
);

// Load previous performance with date
await _loadPreviousPerformance(exercise.id);

// Auto-generate sets based on history or defaults
List<WorkoutSet> initialSets = [];

if (lastOccurrence != null && lastOccurrence.sets.isNotEmpty) {
// Use previous workout's completed sets as template
for (int i = 0; i < lastOccurrence.sets.length; i++) {
final previousSet = lastOccurrence.sets[i];
// Only use sets that were actually completed with valid data
if (previousSet.isCompleted && previousSet.weight > 0 && previousSet.reps > 0) {
initialSets.add(WorkoutSet(
id: const Uuid().v4(),
setNumber: i + 1,
weight: previousSet.weight,
unit: previousSet.unit, // Preserve unit from previous set
reps: previousSet.reps,
isCompleted: false, // Start uncompleted
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
));
}
}
}

// If no valid history found, create 3 default sets
if (initialSets.isEmpty) {
for (int i = 0; i < 3; i++) {
initialSets.add(WorkoutSet(
id: const Uuid().v4(),
setNumber: i + 1,
weight: 60.0,
unit: preferredUnit, // Use user's preferred unit
reps: 10,
isCompleted: false, // Start uncompleted
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
));
}
}

final workoutExercise = WorkoutExercise(
id: const Uuid().v4(),
exercise: exercise,
sets: initialSets,
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
);

setState(() {
_workout = _workout!.copyWith(
exercises: [..._workout!.exercises, workoutExercise],
);
_currentExerciseIndex = _workout!.exercises.length - 1;
_currentExercise = workoutExercise;
});

await _saveWorkout();
}

void _showExerciseSelection() async {
await _saveWorkout();
setState(() {
_currentExercise = null;
_currentExerciseIndex = -1;
});
}

void _quickAddSet(double weight, int reps) {
final newSet = WorkoutSet(
id: const Uuid().v4(),
setNumber: _currentExercise!.sets.length + 1,
weight: weight,
unit: preferredUnit, // Use current preferred unit
reps: reps,
isCompleted: true,
completedAt: DateTime.now(),
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
);

setState(() {
_currentExercise = _currentExercise!.copyWith(
sets: [..._currentExercise!.sets, newSet],
updatedAt: DateTime.now(),
);
});

_saveWorkout();

// Start rest timer after quick adding a completed set
_startRestTimer();
}

void _addEmptySet() {
// Auto-fill new set with previous set's weight, reps, and unit
final lastSet = _currentExercise!.sets.isNotEmpty ? _currentExercise!.sets.last : null;
final newSet = WorkoutSet(
id: const Uuid().v4(),
setNumber: _currentExercise!.sets.length + 1,
weight: lastSet?.weight ?? 60.0,
unit: lastSet?.unit ?? preferredUnit, // Use last set's unit or preferred unit
reps: lastSet?.reps ?? 10,
isCompleted: false, // Starts uncompleted until user marks it done
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
);

setState(() {
_currentExercise = _currentExercise!.copyWith(
sets: [..._currentExercise!.sets, newSet],
updatedAt: DateTime.now(),
);
});

_saveWorkout();
}

void _updateSet(int index, WorkoutSet updatedSet) {
final sets = List<WorkoutSet>.from(_currentExercise!.sets);
sets[index] = updatedSet;
setState(() {
_currentExercise = _currentExercise!.copyWith(
sets: sets,
updatedAt: DateTime.now(),
);
});
_saveWorkout();
}

void _deleteSet(int index) {
final sets = List<WorkoutSet>.from(_currentExercise!.sets);
sets.removeAt(index);
// Renumber sets
for (int i = 0; i < sets.length; i++) {
sets[i] = sets[i].copyWith(setNumber: i + 1);
}
setState(() {
_currentExercise = _currentExercise!.copyWith(
sets: sets,
updatedAt: DateTime.now(),
);
});
_saveWorkout();
}

void _toggleSetComplete(int index) async {
final sets = List<WorkoutSet>.from(_currentExercise!.sets);
final set = sets[index];
final wasCompleted = set.isCompleted;

sets[index] = set.copyWith(
isCompleted: !set.isCompleted,
completedAt: !set.isCompleted ? DateTime.now() : null,
updatedAt: DateTime.now(),
);
setState(() {
_currentExercise = _currentExercise!.copyWith(
sets: sets,
updatedAt: DateTime.now(),
);
});
await _saveWorkout();

// Start rest timer when a set is newly completed
if (!wasCompleted && sets[index].isCompleted) {
_startRestTimer();

// Check if all sets are now completed
final allSetsCompleted = sets.every((s) => s.isCompleted);
if (allSetsCompleted && mounted) {
// Show completion message
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('${_currentExercise!.exercise.name} completed!'),
backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.lightSuccess,
duration: const Duration(seconds: 2),
),
);

// Wait a moment then navigate back to overview
await Future.delayed(const Duration(milliseconds: 1500));
if (mounted) {
context.pop();
}
}
}
}

void _finishWorkout() async {
if (_workout == null) return;

final provider = Provider.of<AppProvider>(context, listen: false);

// Save current exercise state
if (_currentExercise != null && _currentExerciseIndex >= 0) {
final updatedExercises = List<WorkoutExercise>.from(_workout!.exercises);
updatedExercises[_currentExerciseIndex] = _currentExercise!;
_workout = _workout!.copyWith(exercises: updatedExercises);
}

// Filter out exercises with no completed sets
final exercisesWithCompletedSets = _workout!.exercises.where((ex) {
return ex.sets.any((set) => set.isCompleted);
}).map((ex) {
// For each exercise, keep only completed sets
final completedSets = ex.sets.where((set) => set.isCompleted).toList();
return ex.copyWith(sets: completedSets);
}).toList();

// Check if there are any completed sets
final hasCompletedSets = exercisesWithCompletedSets.isNotEmpty;

if (!hasCompletedSets) {
// No completed sets - show discard confirmation
_showExitConfirmation(hasCompletedSets: false);
return;
}

// Has completed sets - show save/discard confirmation
_showExitConfirmation(hasCompletedSets: true, exercisesWithCompletedSets: exercisesWithCompletedSets);
}

void _showExitConfirmation({
required bool hasCompletedSets,
List<WorkoutExercise>? exercisesWithCompletedSets,
}) {
final isDark = Theme.of(context).brightness == Brightness.dark;

showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (context) => Container(
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
),
padding: AppSpacing.paddingLg,
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Handle bar
Center(
child: Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
borderRadius: BorderRadius.circular(2),
),
),
),

// Icon and Title
Icon(
hasCompletedSets ? Icons.save_rounded : Icons.warning_rounded,
size: 48,
color: hasCompletedSets
? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
: (isDark ? AppColors.darkError : AppColors.lightError),
),
const SizedBox(height: 16),
Text(
hasCompletedSets ? 'Finish Workout?' : 'No Sets Completed',
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
Text(
hasCompletedSets
? 'You have completed sets. Would you like to save this workout?'
: 'No sets completed. Discard this workout?',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 24),

// Buttons
if (hasCompletedSets) ...[
// Continue Workout Button
OutlinedButton(
onPressed: () => Navigator.of(context).pop(),
style: OutlinedButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
child: Text(
'Continue Workout',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.w600,
),
),
),
const SizedBox(height: 12),

// Save Workout Button
ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
_saveAndFinishWorkout(exercisesWithCompletedSets!);
},
style: ElevatedButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
),
child: const Text(
'Save Workout',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
const SizedBox(height: 12),

// Discard Workout Button
TextButton(
onPressed: () {
Navigator.of(context).pop();
_discardWorkout();
},
style: TextButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
),
child: Text(
'Discard Workout',
style: TextStyle(
color: isDark ? AppColors.darkError : AppColors.lightError,
fontWeight: FontWeight.w600,
),
),
),
] else ...[
// Cancel Button
OutlinedButton(
onPressed: () => Navigator.of(context).pop(),
style: OutlinedButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
child: Text(
'Cancel',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.w600,
),
),
),
const SizedBox(height: 12),

// Discard Workout Button
ElevatedButton(
onPressed: () {
Navigator.of(context).pop();
_discardWorkout();
},
style: ElevatedButton.styleFrom(
minimumSize: const Size(double.infinity, 56),
backgroundColor: isDark ? AppColors.darkError : AppColors.lightError,
foregroundColor: Colors.white,
),
child: const Text(
'Discard Workout',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
],

const SizedBox(height: 8),
],
),
),
);
}

Future<void> _saveAndFinishWorkout(List<WorkoutExercise> exercisesWithCompletedSets) async {
if (_workout == null) return;

final provider = Provider.of<AppProvider>(context, listen: false);

final completedWorkout = _workout!.copyWith(
exercises: exercisesWithCompletedSets,
isCompleted: true,
endTime: DateTime.now(),
updatedAt: DateTime.now(),
);

await provider.updateWorkout(completedWorkout);

if (mounted) {
context.go('/');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Workout completed! ${completedWorkout.totalVolume.toInt()} kg total volume'),
backgroundColor: Colors.green,
),
);
}
}

Future<void> _discardWorkout() async {
if (_workout == null) return;

final provider = Provider.of<AppProvider>(context, listen: false);

// Remove the workout from the provider without saving
await provider.deleteWorkout(_workout!.id);

if (mounted) {
context.go('/');
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Workout discarded'),
backgroundColor: Colors.grey,
),
);
}
}
}

class EditableSetRow extends StatefulWidget {
final int index;
final WorkoutSet workoutSet;
final Exercise exercise;
final Function(WorkoutSet) onUpdate;
final VoidCallback onDelete;
final VoidCallback onToggleComplete;

const EditableSetRow({
super.key,
required this.index,
required this.workoutSet,
required this.exercise,
required this.onUpdate,
required this.onDelete,
required this.onToggleComplete,
});

@override
State<EditableSetRow> createState() => _EditableSetRowState();
}

class _EditableSetRowState extends State<EditableSetRow> {
late TextEditingController _weightController;
late TextEditingController _repsController;
bool _isEditing = false;

// Helper getter for preferred unit
String get preferredUnit {
final provider = Provider.of<AppProvider>(context, listen: false);
return provider.preferredUnit;
}

@override
void initState() {
super.initState();
// Convert from stored unit to display unit if needed
final displayWeight = UnitConversion.getDisplayWeight(
widget.workoutSet.weight,
widget.workoutSet.unit,
preferredUnit
);
_weightController = TextEditingController(text: displayWeight.toInt().toString());
_repsController = TextEditingController(text: widget.workoutSet.reps.toString());
}

@override
void dispose() {
_weightController.dispose();
_repsController.dispose();
super.dispose();
}

@override
void didUpdateWidget(EditableSetRow oldWidget) {
super.didUpdateWidget(oldWidget);
if (oldWidget.workoutSet != widget.workoutSet) {
// Convert from stored unit to display unit if needed
final displayWeight = UnitConversion.getDisplayWeight(
widget.workoutSet.weight,
widget.workoutSet.unit,
preferredUnit
);
_weightController.text = displayWeight.toInt().toString();
_repsController.text = widget.workoutSet.reps.toString();
}
}

void _saveChanges() {
final enteredWeight = double.tryParse(_weightController.text);
final reps = int.tryParse(_repsController.text) ?? widget.workoutSet.reps;

// Store weight exactly as entered in the current preferred unit
final weight = enteredWeight ?? widget.workoutSet.weight;

widget.onUpdate(widget.workoutSet.copyWith(
weight: weight,
unit: preferredUnit, // Store in the unit the user is currently using
reps: reps,
updatedAt: DateTime.now(),
));

setState(() => _isEditing = false);
}

void _showPlateCalculator(BuildContext context) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (context) => PlateCalculatorModal(
targetWeight: widget.workoutSet.weight,
equipmentType: widget.exercise.equipment,
),
);
}

@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final isCompleted = widget.workoutSet.isCompleted;

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.md),
border: Border.all(
color: isCompleted
? (isDark ? AppColors.darkSuccess.withValues(alpha: 0.3) : AppColors.lightSuccess.withValues(alpha: 0.3))
: (isDark ? AppColors.darkDivider : AppColors.lightDivider),
width: isCompleted ? 2 : 1,
),
),
child: Row(
children: [
// Set Number
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: isCompleted
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkBackground : AppColors.lightBackground),
shape: BoxShape.circle,
),
child: Center(
child: Text(
'${widget.index}',
style: TextStyle(
fontWeight: FontWeight.bold,
color: isCompleted
? Colors.white
: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
),
),
),
),
const SizedBox(width: 16),
// Weight Input with Plate Calculator
Expanded(
flex: 3,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
preferredUnit.toUpperCase(),
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
const SizedBox(height: 4),
Row(
children: [
Expanded(
child: _isEditing
? TextField(
controller: _weightController,
keyboardType: TextInputType.number,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
decoration: InputDecoration(
isDense: true,
contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
),
autofocus: true,
onSubmitted: (_) => _saveChanges(),
)
: GestureDetector(
onTap: () => setState(() => _isEditing = true),
child: Row(
children: [
Text(
UnitConversion.getDisplayWeight(widget.workoutSet.weight, widget.workoutSet.unit, preferredUnit).toInt().toString(),
style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(width: 4),
Icon(Icons.edit_rounded, size: 14, color: isDark ? AppColors.darkHint : AppColors.lightHint),
],
),
),
),
const SizedBox(width: 4),
InkWell(
onTap: () => _showPlateCalculator(context),
borderRadius: BorderRadius.circular(AppRadius.sm),
child: Padding(
padding: const EdgeInsets.all(4),
child: Icon(
Icons.calculate_outlined,
size: 20,
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
),
],
),
],
),
),
const SizedBox(width: 16),
// Reps Input
Expanded(
flex: 3,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'REPS',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
const SizedBox(height: 4),
_isEditing
? TextField(
controller: _repsController,
keyboardType: TextInputType.number,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
decoration: InputDecoration(
isDense: true,
contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
),
onSubmitted: (_) => _saveChanges(),
)
: GestureDetector(
onTap: () => setState(() => _isEditing = true),
child: Row(
children: [
Text(
widget.workoutSet.reps.toString(),
style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(width: 4),
Icon(Icons.edit_rounded, size: 14, color: isDark ? AppColors.darkHint : AppColors.lightHint),
],
),
),
],
),
),
// Actions
if (_isEditing) ...[
IconButton(
onPressed: _saveChanges,
icon: Icon(Icons.check_rounded, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
),
] else ...[
IconButton(
onPressed: widget.onDelete,
icon: Icon(Icons.delete_outline_rounded, color: isDark ? AppColors.darkError : AppColors.lightError, size: 20),
),
IconButton(
onPressed: widget.onToggleComplete,
icon: Icon(
isCompleted ? Icons.check_circle_rounded : Icons.panorama_fish_eye_rounded,
color: isCompleted
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
size: 28,
),
),
],
],
),
);
}
}
