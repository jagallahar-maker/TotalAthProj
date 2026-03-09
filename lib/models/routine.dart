import 'package:total_athlete/models/exercise.dart';

class Routine {
  final String id;
  final String userId;
  final String name;
  final List<String> exerciseIds; // List of exercise IDs in the routine
  final List<MuscleGroup> targetMuscleGroups;
  final int estimatedDurationMinutes;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.exerciseIds,
    required this.targetMuscleGroups,
    required this.estimatedDurationMinutes,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get exerciseCount => exerciseIds.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'exerciseIds': exerciseIds,
    'targetMuscleGroups': targetMuscleGroups.map((m) => m.toString().split('.').last).toList(),
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    exerciseIds: List<String>.from(json['exerciseIds'] as List),
    targetMuscleGroups: (json['targetMuscleGroups'] as List)
        .map((m) => MuscleGroup.values.firstWhere((e) => e.toString().split('.').last == m))
        .toList(),
    estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Routine copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? exerciseIds,
    List<MuscleGroup>? targetMuscleGroups,
    int? estimatedDurationMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Routine(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    exerciseIds: exerciseIds ?? this.exerciseIds,
    targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
    estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
