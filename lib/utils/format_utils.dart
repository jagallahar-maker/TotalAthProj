import 'package:intl/intl.dart';

import 'package:total_athlete/utils/unit_conversion.dart';

class FormatUtils {
  /// Format weight with unit conversion
  /// If storedUnit is provided, converts from stored unit to display unit
  /// Otherwise assumes weight is already in the correct unit (for backwards compatibility)
  static String formatWeight(double weight, String displayUnit, {String? storedUnit}) {
    final displayWeight = storedUnit != null 
      ? UnitConversion.getDisplayWeight(weight, storedUnit, displayUnit)
      : weight; // Backwards compatibility - assume already in correct unit
    return '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} $displayUnit';
  }

  /// Format volume with unit conversion
  /// If storedUnit is provided, converts from stored unit to display unit
  static String formatVolume(double volume, String displayUnit, {String? storedUnit}) {
    final displayVolume = storedUnit != null
      ? UnitConversion.getDisplayWeight(volume, storedUnit, displayUnit)
      : volume; // Backwards compatibility
    return '${(displayVolume / 1000).toStringAsFixed(1)}k $displayUnit';
  }

  static String formatCalories(double calories) => '${calories.toStringAsFixed(0)} kcal';

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)}, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  static String formatTime(DateTime time) => DateFormat('hh:mm a').format(time);

  static String formatDateWithTime(DateTime dateTime) => '${formatDate(dateTime)}, ${formatTime(dateTime)}';

  static String formatMuscleGroup(String group) {
    return group[0].toUpperCase() + group.substring(1);
  }

  static String formatEquipment(String equipment) {
    return equipment[0].toUpperCase() + equipment.substring(1);
  }
}
