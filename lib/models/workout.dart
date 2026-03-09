import 'package:total_athlete/models/user.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/utils/calorie_calculator.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';

class Workout {
  final String id;
  final String userId;
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.exercises,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Total volume from all completed sets only
  double get totalVolume => exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);

  // Total count of all sets (completed and incomplete)
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  // Total count of completed sets with valid data
  int get completedSets => exercises.fold(0, (sum, ex) => sum + ex.completedSets);

  /// Calculate estimated calories burned using advanced algorithm
  /// Optionally provide user bodyweight in kg for more accurate estimates
  double getCaloriesBurned({double? userBodyweightKg}) {
    return CalorieCalculator.calculateWorkoutCalories(this, userBodyweightKg: userBodyweightKg);
  }

  /// Legacy getter for backwards compatibility
  /// Uses simplified calculation without bodyweight
  double get caloriesBurned => getCaloriesBurned();

  /// Calculate Load Score - combines volume and intensity for better training stress metric
  double get loadScore => LoadScoreCalculator.calculateWorkoutLoadScore(this);

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'isCompleted': isCompleted,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    exercises: (json['exercises'] as List).map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>)).toList(),
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    isCompleted: json['isCompleted'] as bool? ?? false,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    List<WorkoutExercise>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Workout(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    exercises: exercises ?? this.exercises,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    isCompleted: isCompleted ?? this.isCompleted,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
