class BodyweightLog {
  final String id;
  final String userId;
  final double weight;
  final String unit; // 'kg' or 'lb' - the unit this weight was entered in
  final DateTime logDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BodyweightLog({
    required this.id,
    required this.userId,
    required this.weight,
    required this.unit,
    required this.logDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'weight': weight,
    'unit': unit,
    'logDate': logDate.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BodyweightLog.fromJson(Map<String, dynamic> json) => BodyweightLog(
    id: json['id'] as String,
    userId: json['userId'] as String,
    weight: (json['weight'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'kg', // Default to kg for backwards compatibility
    logDate: DateTime.parse(json['logDate'] as String),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  BodyweightLog copyWith({
    String? id,
    String? userId,
    double? weight,
    String? unit,
    DateTime? logDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BodyweightLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    weight: weight ?? this.weight,
    unit: unit ?? this.unit,
    logDate: logDate ?? this.logDate,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
