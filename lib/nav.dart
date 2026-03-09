import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/screens/dashboard_screen.dart';
import 'package:total_athlete/screens/start_workout_screen.dart';
import 'package:total_athlete/screens/workout_session_screen.dart';
import 'package:total_athlete/screens/log_exercise_screen.dart';
import 'package:total_athlete/screens/workout_history_screen.dart';
import 'package:total_athlete/screens/workout_details_screen.dart';
import 'package:total_athlete/screens/progress_analytics_screen.dart';
import 'package:total_athlete/screens/bodyweight_tracker_screen.dart';
import 'package:total_athlete/screens/exercise_progress_screen.dart';
import 'package:total_athlete/screens/settings_screen.dart';
import 'package:total_athlete/screens/spreadsheet_import_screen.dart';
import 'package:total_athlete/screens/programs_screen.dart';
import 'package:total_athlete/models/training_program.dart';
import 'package:total_athlete/widgets/bottom_nav.dart';

// Import ProgramDetailScreen which is defined in programs_screen.dart
// This is already included via the programs_screen import above

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => BottomNavScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage(child: WorkoutHistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.progress,
            name: 'progress',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProgressAnalyticsScreen()),
          ),
          GoRoute(
            path: AppRoutes.bodyweight,
            name: 'bodyweight',
            pageBuilder: (context, state) => const NoTransitionPage(child: BodyweightTrackerScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.startWorkout,
        name: 'start-workout',
        pageBuilder: (context, state) => const MaterialPage(child: StartWorkoutScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.workoutSession}/:workoutId',
        name: 'workout-session',
        pageBuilder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          return MaterialPage(child: WorkoutSessionScreen(workoutId: workoutId));
        },
      ),
      GoRoute(
        path: '${AppRoutes.logExercise}/:workoutId',
        name: 'log-exercise',
        pageBuilder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          final exerciseIndex = state.uri.queryParameters['exerciseIndex'];
          return MaterialPage(child: LogExerciseScreen(workoutId: workoutId, exerciseIndex: exerciseIndex));
        },
      ),
      GoRoute(
        path: '${AppRoutes.workoutDetails}/:workoutId',
        name: 'workout-details',
        pageBuilder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          return MaterialPage(child: WorkoutDetailsScreen(workoutId: workoutId));
        },
      ),
      GoRoute(
        path: '${AppRoutes.exerciseProgress}/:exerciseId',
        name: 'exercise-progress',
        pageBuilder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          final exerciseName = state.uri.queryParameters['name'] ?? 'Exercise';
          return MaterialPage(
            child: ExerciseProgressScreen(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.spreadsheetImport,
        name: 'spreadsheet-import',
        pageBuilder: (context, state) => const MaterialPage(child: SpreadsheetImportScreen()),
      ),
      GoRoute(
        path: AppRoutes.programs,
        name: 'programs',
        pageBuilder: (context, state) => const MaterialPage(child: ProgramsScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.programDetail}/:programId',
        name: 'program-detail',
        pageBuilder: (context, state) {
          final program = state.extra as TrainingProgram;
          return MaterialPage(child: ProgramDetailScreen(program: program));
        },
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String history = '/history';
  static const String progress = '/progress';
  static const String bodyweight = '/bodyweight';
  static const String startWorkout = '/start-workout';
  static const String workoutSession = '/workout-session';
  static const String logExercise = '/log-exercise';
  static const String workoutDetails = '/workout-details';
  static const String exerciseProgress = '/exercise-progress';
  static const String settings = '/settings';
  static const String spreadsheetImport = '/spreadsheet-import';
  static const String programs = '/programs';
  static const String programDetail = '/program-detail';
}
