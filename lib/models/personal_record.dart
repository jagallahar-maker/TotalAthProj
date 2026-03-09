class PersonalRecord {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final String unit; // 'kg' or 'lb' - the unit this weight was entered in
  final int reps;
  final double estimatedOneRepMax; // Always stored in kg for consistent comparison
  final DateTime achievedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.unit,
    required this.reps,
    required this.estimatedOneRepMax,
    required this.achievedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  static double calculateOneRepMax(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'weight': weight,
    'unit': unit,
    'reps': reps,
    'estimatedOneRepMax': estimatedOneRepMax,
    'achievedDate': achievedDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
    id: json['id'] as String,
    userId: json['userId'] as String,
    exerciseId: json['exerciseId'] as String,
    exerciseName: json['exerciseName'] as String,
    weight: (json['weight'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'kg', // Default to kg for backwards compatibility
    reps: json['reps'] as int,
    estimatedOneRepMax: (json['estimatedOneRepMax'] as num).toDouble(),
    achievedDate: DateTime.parse(json['achievedDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  PersonalRecord copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    double? weight,
    String? unit,
    int? reps,
    double? estimatedOneRepMax,
    DateTime? achievedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PersonalRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    weight: weight ?? this.weight,
    unit: unit ?? this.unit,
    reps: reps ?? this.reps,
    estimatedOneRepMax: estimatedOneRepMax ?? this.estimatedOneRepMax,
    achievedDate: achievedDate ?? this.achievedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
