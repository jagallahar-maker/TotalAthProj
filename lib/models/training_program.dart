enum ProgramGoal {
  strength,
  hypertrophy,
  cut,
  bulk,
  generalFitness,
}

class TrainingProgram {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final ProgramGoal? goal;
  final List<String> routineIds; // Ordered list of routine IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingProgram({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.goal,
    required this.routineIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'description': description,
    'goal': goal?.toString().split('.').last,
    'routineIds': routineIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TrainingProgram.fromJson(Map<String, dynamic> json) => TrainingProgram(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    goal: json['goal'] != null 
      ? ProgramGoal.values.firstWhere((e) => e.toString().split('.').last == json['goal'])
      : null,
    routineIds: List<String>.from(json['routineIds'] as List),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  TrainingProgram copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    ProgramGoal? goal,
    List<String>? routineIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TrainingProgram(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description ?? this.description,
    goal: goal ?? this.goal,
    routineIds: routineIds ?? this.routineIds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
