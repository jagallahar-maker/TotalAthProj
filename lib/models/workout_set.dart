class WorkoutSet {
  final String id;
  final int setNumber;
  final double weight;
  final String unit; // 'kg' or 'lb' - the unit this weight was entered in
  final int reps;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.unit,
    required this.reps,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Only count volume if set is completed and has valid weight/reps > 0
  double get volume {
    if (!isCompleted || weight <= 0 || reps <= 0) return 0;
    return weight * reps;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'setNumber': setNumber,
    'weight': weight,
    'unit': unit,
    'reps': reps,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    id: json['id'] as String,
    setNumber: json['setNumber'] as int,
    weight: (json['weight'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'kg', // Default to kg for backwards compatibility
    reps: json['reps'] as int,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  WorkoutSet copyWith({
    String? id,
    int? setNumber,
    double? weight,
    String? unit,
    int? reps,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkoutSet(
    id: id ?? this.id,
    setNumber: setNumber ?? this.setNumber,
    weight: weight ?? this.weight,
    unit: unit ?? this.unit,
    reps: reps ?? this.reps,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
