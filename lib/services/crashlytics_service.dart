import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase Crashlytics integration
/// Provides context logging and error reporting for Total Athlete
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  /// Initialize Crashlytics (call after Firebase.initializeApp())
  Future<void> initialize() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Enable crash collection in release mode
      // In debug mode, you can still test crashes manually
      await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      _isInitialized = true;
      
      // Set initial app context
      await setCustomKey('environment', kDebugMode ? 'development' : kReleaseMode ? 'production' : 'beta');
      await setCustomKey('platform', defaultTargetPlatform.toString());
      
      if (kDebugMode) {
        print('✅ Crashlytics initialized (collection disabled in debug mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Crashlytics initialization failed: $e');
      }
    }
  }

  /// Check if Crashlytics is ready
  bool get isInitialized => _isInitialized;

  /// Set a custom key-value pair for crash context
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized || _crashlytics == null) return;
    
    try {
      await _crashlytics!.setCustomKey(key, value.toString());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to set custom key $key: $e');
      }
    }
  }

  /// Set user identifier (for tracking issues per user)
  Future<void> setUserIdentifier(String userId) async {
    if (!_isInitialized || _crashlytics == null) return;
    
    try {
      await _crashlytics!.setUserIdentifier(userId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to set user identifier: $e');
      }
    }
  }

  /// Log the current screen/route
  Future<void> logScreen(String screenName) async {
    await setCustomKey('current_screen', screenName);
    await log('Screen: $screenName');
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    if (!_isInitialized || _crashlytics == null) return;
    
    try {
      await _crashlytics!.log(message);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to log message: $e');
      }
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_isInitialized || _crashlytics == null) return;
    
    try {
      await _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      
      if (kDebugMode) {
        print('🔴 Crashlytics recorded error: $exception');
        if (reason != null) print('   Reason: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to record error: $e');
      }
    }
  }

  /// Force a crash (for testing only - use in developer tools)
  void testCrash() {
    if (_crashlytics == null) {
      throw Exception('Crashlytics not initialized - cannot test crash');
    }
    
    // This will cause an immediate crash to test Crashlytics
    _crashlytics!.crash();
  }

  /// Log workout context
  Future<void> setWorkoutContext({
    String? workoutId,
    String? workoutName,
    String? routineName,
    String? programName,
    int? exerciseCount,
  }) async {
    if (workoutId != null) await setCustomKey('active_workout_id', workoutId);
    if (workoutName != null) await setCustomKey('active_workout_name', workoutName);
    if (routineName != null) await setCustomKey('active_routine', routineName);
    if (programName != null) await setCustomKey('active_program', programName);
    if (exerciseCount != null) await setCustomKey('exercise_count', exerciseCount);
  }

  /// Clear workout context (when workout ends)
  Future<void> clearWorkoutContext() async {
    await setCustomKey('active_workout_id', 'none');
    await setCustomKey('active_workout_name', 'none');
    await setCustomKey('active_routine', 'none');
    await setCustomKey('active_program', 'none');
  }

  /// Log unit preference context
  Future<void> setUnitPreference(String unit) async {
    await setCustomKey('unit_preference', unit);
  }

  /// Log app version
  Future<void> setAppVersion(String version, String buildNumber) async {
    await setCustomKey('app_version', version);
    await setCustomKey('build_number', buildNumber);
  }
}
