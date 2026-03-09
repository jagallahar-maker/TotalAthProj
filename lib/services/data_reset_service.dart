import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DataResetService {
  /// Clears ALL user-generated and derived data while preserving app structure and templates
  /// This includes workout history, bodyweight logs, PRs, draft workouts, goals, and analytics
  Future<bool> resetAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      debugPrint('🔄 Starting complete data reset...');
      
      // 1. Clear workout history and sets
      await prefs.setString('workouts', '[]');
      debugPrint('   ✓ Workouts cleared');
      
      // 2. Clear draft/active workouts
      await prefs.remove('current_workout');
      debugPrint('   ✓ Draft workout cleared');
      
      // 3. Clear bodyweight logs
      await prefs.setString('bodyweight_logs', '[]');
      debugPrint('   ✓ Bodyweight logs cleared');
      
      // 4. Clear personal records
      await prefs.setString('personal_records', '[]');
      debugPrint('   ✓ Personal records cleared');
      
      // 5. Clear user bodyweight goals (reset user to default without goals)
      final currentUserData = prefs.getString('current_user');
      if (currentUserData != null) {
        try {
          final userData = json.decode(currentUserData) as Map<String, dynamic>;
          // Remove bodyweight goal data from user
          userData['currentWeight'] = null;
          userData['goalWeight'] = null;
          userData['updatedAt'] = DateTime.now().toIso8601String();
          await prefs.setString('current_user', json.encode(userData));
          debugPrint('   ✓ User bodyweight goals cleared');
        } catch (e) {
          debugPrint('   ⚠️ Failed to clear user goals: $e');
        }
      }
      
      // 6. Clear any cached analytics or computed data
      await prefs.remove('cached_analytics');
      await prefs.remove('exercise_stats');
      await prefs.remove('strength_trend');
      await prefs.remove('volume_trend');
      await prefs.remove('muscle_group_stats');
      debugPrint('   ✓ Cached analytics cleared');
      
      debugPrint('✅ COMPLETE DATA RESET SUCCESSFUL');
      debugPrint('   📊 Exercise database: preserved');
      debugPrint('   📋 Routine templates: preserved');
      return true;
    } catch (e) {
      debugPrint('❌ Data reset failed: $e');
      return false;
    }
  }
  
  /// Get comprehensive data counts for debugging
  Future<Map<String, int>> getDataCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int workoutCount = 0;
      int bodyweightCount = 0;
      int prCount = 0;
      bool hasDraft = false;
      bool hasGoals = false;
      
      // Count workouts
      final workoutsData = prefs.getString('workouts');
      if (workoutsData != null) {
        try {
          final workoutsList = json.decode(workoutsData) as List;
          workoutCount = workoutsList.length;
        } catch (e) {
          debugPrint('Error parsing workouts: $e');
        }
      }
      
      // Count bodyweight logs
      final bodyweightData = prefs.getString('bodyweight_logs');
      if (bodyweightData != null) {
        try {
          final bodyweightList = json.decode(bodyweightData) as List;
          bodyweightCount = bodyweightList.length;
        } catch (e) {
          debugPrint('Error parsing bodyweight logs: $e');
        }
      }
      
      // Count personal records
      final prData = prefs.getString('personal_records');
      if (prData != null) {
        try {
          final prList = json.decode(prData) as List;
          prCount = prList.length;
        } catch (e) {
          debugPrint('Error parsing personal records: $e');
        }
      }
      
      // Check for draft
      hasDraft = prefs.containsKey('current_workout');
      
      // Check for user goals
      final userData = prefs.getString('current_user');
      if (userData != null) {
        try {
          final userMap = json.decode(userData) as Map<String, dynamic>;
          hasGoals = userMap['currentWeight'] != null && userMap['goalWeight'] != null;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }
      
      return {
        'workouts': workoutCount,
        'bodyweight_logs': bodyweightCount,
        'personal_records': prCount,
        'draft_workouts': hasDraft ? 1 : 0,
        'user_goals': hasGoals ? 1 : 0,
      };
    } catch (e) {
      debugPrint('Failed to get data counts: $e');
      return {
        'workouts': -1,
        'bodyweight_logs': -1,
        'personal_records': -1,
        'draft_workouts': -1,
        'user_goals': -1,
      };
    }
  }
  
  /// Verify that data was cleared successfully
  Future<Map<String, bool>> verifyReset() async {
    try {
      final counts = await getDataCounts();
      
      return {
        'workouts_cleared': counts['workouts'] == 0,
        'bodyweight_cleared': counts['bodyweight_logs'] == 0,
        'prs_cleared': counts['personal_records'] == 0,
        'draft_cleared': counts['draft_workouts'] == 0,
        'goals_cleared': counts['user_goals'] == 0,
      };
    } catch (e) {
      debugPrint('Verification failed: $e');
      return {};
    }
  }
}
