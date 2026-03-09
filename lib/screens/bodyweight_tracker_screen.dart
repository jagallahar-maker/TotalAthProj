import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/utils/unit_conversion.dart';
import 'package:total_athlete/models/bodyweight_log.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class BodyweightTrackerScreen extends StatefulWidget {
  const BodyweightTrackerScreen({super.key});

  @override
  State<BodyweightTrackerScreen> createState() => _BodyweightTrackerScreenState();
}

class _BodyweightTrackerScreenState extends State<BodyweightTrackerScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen view
    CrashlyticsService().logScreen('BodyweightTracker');
  }

  /// Calculates goal progress as a decimal from 0.0 to 1.0
  /// 
  /// Formula: (startWeight - currentWeight) / (startWeight - goalWeight)
  /// 
  /// Example:
  /// - Start: 212 lb
  /// - Current: 206 lb  
  /// - Goal: 200 lb
  /// - Progress: (212 - 206) / (212 - 200) = 6 / 12 = 0.5 (50%)
  static double _calculateGoalProgress({
    required double startWeight,
    required double currentWeight,
    required double goalWeight,
  }) {
    final totalChange = startWeight - goalWeight;
    final progressChange = startWeight - currentWeight;

    if (totalChange == 0) return 0;

    final progress = progressChange / totalChange;

    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final logs = provider.bodyweightLogs;
    final recentLogs = logs.take(5).toList();
    // currentWeight and goalWeight are stored in kg internally
    final currentWeightKg = user?.currentWeight;
    final goalWeightKg = user?.goalWeight;
    final weightLeftKg = (currentWeightKg != null && goalWeightKg != null) ? currentWeightKg - goalWeightKg : 0.0;
    
    // Calculate goal progress using the earliest recorded weight in the entire database
    double progress = 0.0;
    if (currentWeightKg != null && goalWeightKg != null && logs.isNotEmpty) {
      // Get ALL logs from provider (not filtered by chart range)
      final allLogs = provider.bodyweightLogs;
      
      // Sort all logs by date to find the first (oldest) weight entry across entire history
      final sortedLogs = allLogs.toList()..sort((a, b) => a.logDate.compareTo(b.logDate));
      // First log weight is already stored in kg
      final startWeightKg = sortedLogs.first.weight;
      
      // Calculate progress using the exact formula (all values in kg)
      progress = _calculateGoalProgress(
        startWeight: startWeightKg,
        currentWeight: currentWeightKg,
        goalWeight: goalWeightKg,
      ) * 100; // Convert to percentage
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bodyweight', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Track your physique progress', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showWeightSettingsDialog(context, provider),
                    icon: Icon(Icons.settings_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: StatCard(
                    label: 'Current',
                    value: currentWeightKg != null ? FormatUtils.formatWeight(currentWeightKg, preferredUnit, storedUnit: 'kg') : '--',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    label: 'Goal',
                    value: goalWeightKg != null ? FormatUtils.formatWeight(goalWeightKg, preferredUnit, storedUnit: 'kg') : '--',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    label: 'Left',
                    value: (currentWeightKg != null && goalWeightKg != null) ? FormatUtils.formatWeight(weightLeftKg, preferredUnit, storedUnit: 'kg') : '--',
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _buildSecondaryMetricsRow(context, provider, isDark),
              const SizedBox(height: 24),
              _buildWeightTrendCard(context, provider, isDark),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showLogWeightDialog(context, provider, user?.id ?? 'user_1'),
                icon: const Icon(Icons.add_rounded),
                label: const Text("Log Weight"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () {}, child: Text('View All', style: TextStyle(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary))),
                ],
              ),
              const SizedBox(height: 8),
              if (recentLogs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No weight logs yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkHint : AppColors.lightHint,
                      ),
                    ),
                  ),
                )
              else
                ...recentLogs.map((log) {
                  final previousLog = logs.indexOf(log) < logs.length - 1 ? logs[logs.indexOf(log) + 1] : null;
                  final diff = previousLog != null ? log.weight - previousLog.weight : 0.0;
                  final trend = diff > 0 ? 'up' : 'down';
                  return LogItem(date: FormatUtils.formatDate(log.logDate), time: FormatUtils.formatTime(log.logDate), weight: log.weight, unit: log.unit, diff: diff.abs(), trend: trend);
                }),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ),
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Goal Progress', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${progress.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress / 100, minHeight: 8, backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, borderRadius: BorderRadius.circular(AppRadius.full)),
                    const SizedBox(height: 16),
                    if (currentWeightKg != null && goalWeightKg != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current: ${FormatUtils.formatWeight(currentWeightKg, preferredUnit, storedUnit: 'kg')}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                          Text('Target: ${FormatUtils.formatWeight(goalWeightKg, preferredUnit, storedUnit: 'kg')}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          'Set your weight goals to track progress',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryMetricsRow(BuildContext context, AppProvider provider, bool isDark) {
    final logs = provider.bodyweightLogs;
    final preferredUnit = provider.preferredUnit;
    // currentWeight is stored in kg internally
    final currentWeightKg = provider.currentUser?.currentWeight;
    
    // Calculate 7-day average weight (all weights already stored in kg)
    double? sevenDayAverageKg;
    final recentLogs = logs.take(7).toList();
    if (recentLogs.length >= 3) {
      final sumKg = recentLogs.fold<double>(0.0, (sum, log) => sum + log.weight);
      sevenDayAverageKg = sumKg / recentLogs.length; // Result in kg
    }
    
    // Calculate change since start (all values in kg)
    double? changeSinceStartKg;
    if (logs.isNotEmpty && currentWeightKg != null) {
      final sortedAllLogs = logs.toList()..sort((a, b) => a.logDate.compareTo(b.logDate));
      final firstLog = sortedAllLogs.first;
      final startWeightKg = firstLog.weight; // Already stored in kg
      changeSinceStartKg = currentWeightKg - startWeightKg;
    }
    
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: '7-Day Avg',
            value: sevenDayAverageKg != null 
              ? FormatUtils.formatWeight(sevenDayAverageKg, preferredUnit, storedUnit: 'kg')
              : '--',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Change',
            value: changeSinceStartKg != null 
              ? '${changeSinceStartKg > 0 ? '+' : ''}${FormatUtils.formatWeight(changeSinceStartKg.abs(), preferredUnit, storedUnit: 'kg')}'
              : '--',
            valueColor: changeSinceStartKg != null
              ? (changeSinceStartKg < 0 
                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                : (isDark ? AppColors.darkError : AppColors.lightError))
              : null,
          ),
        ),
      ],
    );
  }

  void _showLogWeightDialog(BuildContext context, AppProvider provider, String userId) {
    final preferredUnit = provider.preferredUnit;
    final latestLog = provider.bodyweightLogs.isNotEmpty ? provider.bodyweightLogs.first : null;
    final currentWeight = provider.currentUser?.currentWeight;
    // Normalize latest log weight to kg before using
    final defaultWeightKg = latestLog != null 
      ? UnitConversion.toKg(latestLog.weight, latestLog.unit)
      : (currentWeight ?? 0.0);
    final defaultWeightDisplay = UnitConversion.toDisplayUnit(defaultWeightKg, preferredUnit);
    final weightController = TextEditingController(text: defaultWeightDisplay > 0 ? defaultWeightDisplay.toStringAsFixed(1) : '');
    
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Log Weight', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Weight ($preferredUnit)', hintText: 'Enter your weight'),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(FormatUtils.formatDate(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time (Optional)'),
                      child: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final enteredWeight = double.tryParse(weightController.text);
                      if (enteredWeight == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid weight')),
                          );
                        }
                        return;
                      }
                      
                      // Validate weight range (80-600 lb or equivalent in kg)
                      final minWeightKg = 36.0; // ~80 lb
                      final maxWeightKg = 272.0; // ~600 lb
                      final enteredWeightKg = UnitConversion.toKg(enteredWeight, preferredUnit);
                      
                      if (enteredWeightKg < minWeightKg || enteredWeightKg > maxWeightKg) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Weight must be between ${FormatUtils.formatWeight(minWeightKg, preferredUnit)} and ${FormatUtils.formatWeight(maxWeightKg, preferredUnit)}')),
                          );
                        }
                        return;
                      }
                      
                      // Check for large weight changes (>10 lb or ~4.5 kg)
                      final recentLogs = provider.bodyweightLogs;
                      if (recentLogs.isNotEmpty) {
                        // Normalize previous weight to kg for comparison
                        final latestLog = recentLogs.first;
                        final latestWeightKg = UnitConversion.toKg(latestLog.weight, latestLog.unit);
                        final diff = (enteredWeightKg - latestWeightKg).abs();
                        final thresholdKg = 4.5; // ~10 lb
                        
                        if (diff > thresholdKg) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Large Weight Change'),
                              content: Text('This entry differs by ${FormatUtils.formatWeight(diff, preferredUnit)} from your previous weight. Are you sure this is correct?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed != true) return;
                        }
                      }
                      
                      final logDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      
                      final log = BodyweightLog(
                        id: const Uuid().v4(),
                        userId: userId,
                        weight: enteredWeightKg,
                        unit: 'kg', // Always store in kg internally
                        logDate: logDateTime,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await provider.addBodyweightLog(log);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeightTrendCard(BuildContext context, AppProvider provider, bool isDark) {
    final logs = provider.bodyweightLogs;
    final preferredUnit = provider.preferredUnit;
    // currentWeight and goalWeight are stored in kg internally
    final currentWeightKg = provider.currentUser?.currentWeight;
    final goalWeightKg = provider.currentUser?.goalWeight;
    
    // Get visible logs (last 30 days - matching the chart range)
    final visibleLogs = logs.take(30).toList();
    
    double? rateOfChangeKg;
    String? goalEta;
    bool insufficientData = visibleLogs.length < 3;
    
    if (!insufficientData) {
      // Sort by date
      final sortedLogs = visibleLogs.toList()..sort((a, b) => a.logDate.compareTo(b.logDate));
      
      // Calculate linear regression (best fit line) to find slope
      // Formula: slope = (n * Σ(xy) - Σx * Σy) / (n * Σ(x²) - (Σx)²)
      final n = sortedLogs.length;
      final firstDate = sortedLogs.first.logDate;
      
      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;
      
      for (int i = 0; i < sortedLogs.length; i++) {
        // x = days since first entry (actual time difference)
        final x = sortedLogs[i].logDate.difference(firstDate).inDays.toDouble();
        // Weight is already stored in kg
        final y = sortedLogs[i].weight;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }
      
      final denominator = (n * sumX2 - sumX * sumX);
      
      if (denominator != 0) {
        // Slope is weight change per day in kg
        final slopePerDay = (n * sumXY - sumX * sumY) / denominator;
        
        // Convert to kg/week
        rateOfChangeKg = slopePerDay * 7;
        
        // Calculate goal ETA if goal weight exists
        if (goalWeightKg != null && currentWeightKg != null && rateOfChangeKg.abs() > 0.01) {
          final weightRemainingKg = currentWeightKg - goalWeightKg;
          final weeksToGoal = weightRemainingKg / rateOfChangeKg;
          
          // Only show ETA if moving in the right direction
          final movingTowardGoal = (weightRemainingKg > 0 && rateOfChangeKg < 0) || (weightRemainingKg < 0 && rateOfChangeKg > 0);
          
          if (movingTowardGoal && weeksToGoal > 0 && weeksToGoal < 104) { // Less than 2 years
            final etaDate = DateTime.now().add(Duration(days: (weeksToGoal * 7).round()));
            goalEta = FormatUtils.formatDate(etaDate);
          }
        }
      }
    }
    
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
              Text('Weight Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text('Last 30 Days', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: logs.isEmpty
              ? Center(
                  child: Text(
                    'No weight logs yet.\nLog your first weight to see trends!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkHint : AppColors.lightHint,
                    ),
                  ),
                )
              : WeightTrendChart(logs: logs.take(30).toList(), goalWeightKg: goalWeightKg),
          ),
          if (rateOfChangeKg != null || goalEta != null || insufficientData) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate of Change',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (insufficientData)
                        Text(
                          'Not enough data',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        )
                      else if (rateOfChangeKg != null)
                        Row(
                          children: [
                            Icon(
                              rateOfChangeKg > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 16,
                              color: rateOfChangeKg > 0 
                                ? (isDark ? AppColors.darkError : AppColors.lightError)
                                : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${UnitConversion.toDisplayUnit(rateOfChangeKg.abs(), preferredUnit).toStringAsFixed(1)} $preferredUnit / week',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: rateOfChangeKg > 0 
                                    ? (isDark ? AppColors.darkError : AppColors.lightError)
                                    : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal ETA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (goalEta != null)
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                goalEta,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          insufficientData ? 'Not enough data' : '--',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showWeightSettingsDialog(BuildContext context, AppProvider provider) {
    final user = provider.currentUser;
    final preferredUnit = provider.preferredUnit;
    final goalWeightController = TextEditingController(
      text: user?.goalWeight != null ? UnitConversion.toDisplayUnit(user!.goalWeight!, preferredUnit).toStringAsFixed(1) : '',
    );
    
    // Height handling
    final heightCm = user?.heightCm ?? 0.0;
    final heightFeet = (heightCm / 2.54 / 12).floor();
    final heightInches = ((heightCm / 2.54) % 12).round();
    
    final heightFeetController = TextEditingController(text: heightCm > 0 ? heightFeet.toString() : '');
    final heightInchesController = TextEditingController(text: heightCm > 0 ? heightInches.toString() : '');
    final heightCmController = TextEditingController(text: heightCm > 0 ? heightCm.toStringAsFixed(0) : '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Weight Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: goalWeightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Goal Weight ($preferredUnit)', hintText: 'Enter your target weight'),
              ),
              const SizedBox(height: 16),
              if (preferredUnit == 'lb') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightFeetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Feet', hintText: 'ft'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: heightInchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Inches', hintText: 'in'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: heightCmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)', hintText: 'Enter your height'),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (user != null) {
                    final goalWeightInput = double.tryParse(goalWeightController.text);
                    // Convert goal weight to kg for storage
                    final goalWeightKg = goalWeightInput != null 
                      ? UnitConversion.toKg(goalWeightInput, preferredUnit)
                      : null;
                    
                    double? heightInCm;
                    if (preferredUnit == 'lb') {
                      final feet = int.tryParse(heightFeetController.text) ?? 0;
                      final inches = int.tryParse(heightInchesController.text) ?? 0;
                      if (feet > 0 || inches > 0) {
                        heightInCm = (feet * 12 + inches) * 2.54;
                      }
                    } else {
                      heightInCm = double.tryParse(heightCmController.text);
                    }
                    
                    final updatedUser = user.copyWith(
                      goalWeight: goalWeightKg,
                      heightCm: heightInCm,
                      updatedAt: DateTime.now(),
                    );
                    await provider.updateUser(updatedUser);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatCard({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      padding: AppSpacing.paddingMd,
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class LogItem extends StatelessWidget {
  final String date;
  final String time;
  final double weight;
  final String unit;
  final double diff;
  final String trend;

  const LogItem({super.key, required this.date, required this.time, required this.weight, required this.unit, required this.diff, required this.trend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(FormatUtils.formatWeight(weight, preferredUnit, storedUnit: unit), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                ],
              ),
              if (diff > 0)
                Row(
                  children: [
                    Icon(trend == 'up' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: trend == 'up' ? (isDark ? AppColors.darkError : AppColors.lightError) : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)),
                    const SizedBox(width: 4),
                    Text('${diff.toStringAsFixed(1)} $preferredUnit', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: trend == 'up' ? (isDark ? AppColors.darkError : AppColors.lightError) : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeightTrendChart extends StatelessWidget {
  final List<BodyweightLog> logs;
  final double? goalWeightKg; // Goal weight stored in kg

  const WeightTrendChart({super.key, required this.logs, this.goalWeightKg});

  List<FlSpot> _calculateMovingAverage(List<BodyweightLog> logs, int windowSize) {
    if (logs.length < windowSize) return [];
    
    final sortedLogs = logs.toList()..sort((a, b) => a.logDate.compareTo(b.logDate));
    final movingAvgSpots = <FlSpot>[];
    
    for (int i = 0; i < sortedLogs.length; i++) {
      if (i < windowSize - 1) continue;
      
      double sumKg = 0;
      for (int j = 0; j < windowSize; j++) {
        // Weights are already stored in kg
        sumKg += sortedLogs[i - j].weight;
      }
      final avg = sumKg / windowSize;
      movingAvgSpots.add(FlSpot(i.toDouble(), avg));
    }
    
    return movingAvgSpots;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final preferredUnit = provider.preferredUnit;
    
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No weight data',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
          ),
        ),
      );
    }
    
    // Sort logs by date for proper chart display
    final sortedLogs = logs.toList()..sort((a, b) => a.logDate.compareTo(b.logDate));
    
    // Raw weight spots - weights are already stored in kg
    final rawSpots = sortedLogs.asMap().entries.map((e) => 
      FlSpot(e.key.toDouble(), e.value.weight)
    ).toList();
    
    // 7-day moving average spots
    final movingAvgSpots = _calculateMovingAverage(sortedLogs, 7);
    
    // Find min/max for better chart scaling (weights already in kg)
    final weightsKg = sortedLogs.map((log) => log.weight).toList();
    final minWeight = weightsKg.reduce((a, b) => a < b ? a : b);
    final maxWeight = weightsKg.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange > 0 ? weightRange * 0.1 : 5.0;
    
    // Calculate goal range if goal weight is set
    double? goalRangeMin;
    double? goalRangeMax;
    if (goalWeightKg != null) {
      final rangeDelta = 2.27; // ~5 lb in kg
      goalRangeMin = goalWeightKg! - rangeDelta;
      goalRangeMax = goalWeightKg! + rangeDelta;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minWeight - padding,
        maxY: maxWeight + padding,
        // Goal range shading
        extraLinesData: goalWeightKg != null && goalRangeMin != null && goalRangeMax != null
          ? ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: goalWeightKg!,
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ],
            )
          : null,
        lineBarsData: [
          // Goal range band (if goal is set)
          if (goalWeightKg != null && goalRangeMin != null && goalRangeMax != null)
            LineChartBarData(
              spots: [
                FlSpot(0, goalRangeMin),
                FlSpot(sortedLogs.length - 1, goalRangeMin),
              ],
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.08),
                cutOffY: goalRangeMax,
                applyCutOffY: true,
              ),
            ),
          // Raw weight data (monotone cubic interpolation, dots visible)
          LineChartBarData(
            spots: rawSpots,
            isCurved: true,
            curveSmoothness: 0.25, // Low distortion smoothing
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.6),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.08),
            ),
          ),
          // 7-day moving average (smooth trend line)
          if (movingAvgSpots.isNotEmpty)
            LineChartBarData(
              spots: movingAvgSpots,
              isCurved: true,
              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}
