import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout_set.dart';

class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Only sum volume from completed sets with valid data
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);

  // Count only completed sets with valid weight and reps > 0
  int get completedSets => sets.where((set) => 
    set.isCompleted && set.weight > 0 && set.reps > 0
  ).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise.toJson(),
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
    id: json['id'] as String,
    exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
    sets: (json['sets'] as List).map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>)).toList(),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  WorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    List<WorkoutSet>? sets,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkoutExercise(
    id: id ?? this.id,
    exercise: exercise ?? this.exercise,
    sets: sets ?? this.sets,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
