import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/bodyweight_log.dart';
import 'package:total_athlete/models/personal_record.dart';
import 'package:total_athlete/models/user.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

/// Service to migrate incorrectly stored weight data
/// 
/// This service detects and fixes weights that were saved in pounds
/// but stored as if they were kilograms (missing the lb to kg conversion).
class WeightMigrationService {
  static const String _migrationKey = 'weight_migration_v1_completed';
  static const String _goalWeightMigrationKey = 'goal_weight_migration_v1_completed';
  static const String _workoutsKey = 'workouts';
  static const String _bodyweightLogsKey = 'bodyweight_logs';
  static const String _personalRecordsKey = 'personal_records';
  static const String _userKey = 'current_user';
  
  /// Run the migration if it hasn't been run before
  static Future<void> runMigrationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // TEMPORARILY DISABLED: Migration is causing crashes due to storage format incompatibility
      // Mark as completed to skip migration
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;
      if (!migrationCompleted) {
        print('⚠️ Skipping weight migration (disabled due to storage format changes)');
        await prefs.setBool(_migrationKey, true);
        return;
      }
      
      // Run goal weight migration
      final goalWeightMigrationCompleted = prefs.getBool(_goalWeightMigrationKey) ?? false;
      if (!goalWeightMigrationCompleted) {
        print('🔄 Running goal weight migration...');
        await _migrateUserGoalWeight();
        await prefs.setBool(_goalWeightMigrationKey, true);
        print('✅ Goal weight migration completed');
      }
      
      /*
      if (!migrationCompleted) {
        print('🔄 Running weight data migration...');
        await _migrateWorkoutWeights();
        await _migrateBodyweightLogs();
        await _migratePersonalRecords();
        await prefs.setBool(_migrationKey, true);
        print('✅ Weight data migration completed');
      }
      */
    } catch (e) {
      print('⚠️ Migration failed but continuing: $e');
      // Don't block app initialization if migration fails
    }
  }
  
  /// Migrate user's goalWeight and currentWeight to ensure they're stored in kg
  /// 
  /// Detects if weights appear to be stored in pounds and converts them to kg
  static Future<void> _migrateUserGoalWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData == null) {
        print('   No user data to migrate');
        return;
      }
      
      final userMap = json.decode(userData) as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      
      bool needsUpdate = false;
      double? migratedGoalWeight = user.goalWeight;
      double? migratedCurrentWeight = user.currentWeight;
      
      // More sophisticated detection: Check if values look like they're stored in pounds
      // Case 1: Value > 200 (obviously too heavy for kg)
      // Case 2: User's preferred unit is lb AND goalWeight seems unreasonable as kg
      //         (e.g., 200 kg would be 440 lb, which is a very uncommon goal)
      // Case 3: GoalWeight is a nice round number in lb range (100-400) and preferredUnit is lb
      
      if (user.goalWeight != null) {
        final shouldMigrate = _looksLikePoundsStoredAsKg(user.goalWeight!) ||
            (user.preferredUnit == 'lb' && user.goalWeight! >= 100 && user.goalWeight! <= 400);
        
        if (shouldMigrate) {
          print('   Detected goalWeight stored in pounds: ${user.goalWeight} lb');
          migratedGoalWeight = UnitConversion.toStorageUnit(user.goalWeight!, 'lb');
          print('   Converted to kg: $migratedGoalWeight kg');
          needsUpdate = true;
        }
      }
      
      // Check if currentWeight looks like it's stored in pounds
      // Only migrate currentWeight if it's > 200 to avoid false positives
      if (user.currentWeight != null && _looksLikePoundsStoredAsKg(user.currentWeight!)) {
        print('   Detected currentWeight stored in pounds: ${user.currentWeight} lb');
        migratedCurrentWeight = UnitConversion.toStorageUnit(user.currentWeight!, 'lb');
        print('   Converted to kg: $migratedCurrentWeight kg');
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        final updatedUser = user.copyWith(
          goalWeight: migratedGoalWeight,
          currentWeight: migratedCurrentWeight,
          updatedAt: DateTime.now(),
        );
        
        await prefs.setString(_userKey, json.encode(updatedUser.toJson()));
        print('   ✅ User weight data migrated successfully');
      } else {
        print('   No migration needed for user weight data');
      }
    } catch (e) {
      print('   ⚠️ Error migrating user goal weight: $e');
    }
  }
  
  /// Detect if a weight value looks like it was incorrectly stored
  /// 
  /// Heuristic: If a weight in "kg" is > 200, it's likely actually in pounds
  /// (since 200+ kg is 440+ lbs, which is very uncommon for most exercises)
  static bool _looksLikePoundsStoredAsKg(double weightInKg) {
    return weightInKg > 200.0;
  }
  
  /// Load data with fallback for old format (getStringList) and new format (getString)
  static Future<List<dynamic>?> _loadDataWithFallback(SharedPreferences prefs, String key) async {
    // Try new format first (getString with JSON)
    try {
      final stringData = prefs.getString(key);
      if (stringData != null) {
        return json.decode(stringData) as List<dynamic>;
      }
    } catch (e) {
      print('   Error loading new format from $key: $e');
    }
    
    // Try old format (getStringList)
    try {
      final stringListData = prefs.getStringList(key);
      if (stringListData != null && stringListData.isNotEmpty) {
        // Convert old format to new format
        final jsonList = stringListData.map((str) => json.decode(str)).toList();
        // Save in new format
        await prefs.setString(key, json.encode(jsonList));
        print('   Migrated $key from old format to new format');
        return jsonList;
      }
    } catch (e) {
      print('   Error loading old format from $key: $e');
    }
    
    return null;
  }
  
  /// Migrate workout weights
  static Future<void> _migrateWorkoutWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = await _loadDataWithFallback(prefs, _workoutsKey);
      
      // If no data exists, nothing to migrate
      if (jsonList == null || jsonList.isEmpty) {
        return;
      }
      
      int fixedCount = 0;
      final updatedWorkouts = jsonList.map((json) {
        try {
          final workoutMap = json as Map<String, dynamic>;
          final workout = Workout.fromJson(workoutMap);
          
          // Check and fix each exercise's sets
          final updatedExercises = workout.exercises.map((exercise) {
            final updatedSets = exercise.sets.map((set) {
              // If weight looks like pounds stored as kg, convert it
              if (_looksLikePoundsStoredAsKg(set.weight)) {
                fixedCount++;
                // Convert from pounds to kg (the weight value is actually in pounds)
                final correctWeightInKg = UnitConversion.toStorageUnit(set.weight, 'lb');
                return set.copyWith(weight: correctWeightInKg);
              }
              return set;
            }).toList();
            
            return exercise.copyWith(sets: updatedSets);
          }).toList();
          
          final updatedWorkout = workout.copyWith(exercises: updatedExercises);
          return updatedWorkout.toJson();
        } catch (e) {
          print('   Skipping corrupted workout during migration: $e');
          return json;
        }
      }).toList();
      
      if (fixedCount > 0) {
        await prefs.setString(_workoutsKey, json.encode(updatedWorkouts));
        print('   Fixed $fixedCount workout sets');
      }
    } catch (e) {
      print('   Error migrating workouts: $e');
    }
  }
  
  /// Migrate bodyweight logs
  static Future<void> _migrateBodyweightLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = await _loadDataWithFallback(prefs, _bodyweightLogsKey);
      
      // If no data exists, nothing to migrate
      if (jsonList == null || jsonList.isEmpty) {
        return;
      }
      
      int fixedCount = 0;
      final updatedLogs = jsonList.map((json) {
        try {
          final logMap = json as Map<String, dynamic>;
          final log = BodyweightLog.fromJson(logMap);
          
          // If weight looks like pounds stored as kg, convert it
          if (_looksLikePoundsStoredAsKg(log.weight)) {
            fixedCount++;
            final correctWeightInKg = UnitConversion.toStorageUnit(log.weight, 'lb');
            final updatedLog = log.copyWith(weight: correctWeightInKg);
            return updatedLog.toJson();
          }
          
          return json;
        } catch (e) {
          print('   Skipping corrupted log during migration: $e');
          return json;
        }
      }).toList();
      
      if (fixedCount > 0) {
        await prefs.setString(_bodyweightLogsKey, json.encode(updatedLogs));
        print('   Fixed $fixedCount bodyweight logs');
      }
    } catch (e) {
      print('   Error migrating bodyweight logs: $e');
    }
  }
  
  /// Migrate personal records
  static Future<void> _migratePersonalRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = await _loadDataWithFallback(prefs, _personalRecordsKey);
      
      // If no data exists, nothing to migrate
      if (jsonList == null || jsonList.isEmpty) {
        return;
      }
      
      int fixedCount = 0;
      final updatedPRs = jsonList.map((json) {
        try {
          final prMap = json as Map<String, dynamic>;
          final pr = PersonalRecord.fromJson(prMap);
          
          // If weight looks like pounds stored as kg, convert it
          if (_looksLikePoundsStoredAsKg(pr.weight)) {
            fixedCount++;
            final correctWeightInKg = UnitConversion.toStorageUnit(pr.weight, 'lb');
            final updatedPR = pr.copyWith(weight: correctWeightInKg);
            return updatedPR.toJson();
          }
          
          return json;
        } catch (e) {
          print('   Skipping corrupted PR during migration: $e');
          return json;
        }
      }).toList();
      
      if (fixedCount > 0) {
        await prefs.setString(_personalRecordsKey, json.encode(updatedPRs));
        print('   Fixed $fixedCount personal records');
      }
    } catch (e) {
      print('   Error migrating personal records: $e');
    }
  }
  
  /// Force run the migration again (for testing)
  static Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    await runMigrationIfNeeded();
  }
}
