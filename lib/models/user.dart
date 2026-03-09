class User {
  final String id;
  final String name;
  final String email;
  final double? currentWeight; // Always stored in kg, converted for display
  final double? goalWeight; // Always stored in kg, converted for display
  final String? avatarInitials;
  final String preferredUnit; // 'kg' or 'lb' - display preference only
  final double smithMachineBarWeightKg; // Smith machine bar weight in kg
  final double smithMachineBarWeightLb; // Smith machine bar weight in lb
  final double? heightCm; // Height in centimeters
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.currentWeight,
    this.goalWeight,
    this.avatarInitials,
    this.preferredUnit = 'kg', // Default to kg
    this.smithMachineBarWeightKg = 15.0, // Default smith machine bar weight in kg
    this.smithMachineBarWeightLb = 33.0, // Default smith machine bar weight in lb
    this.heightCm,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'currentWeight': currentWeight,
    'goalWeight': goalWeight,
    'avatarInitials': avatarInitials,
    'preferredUnit': preferredUnit,
    'smithMachineBarWeightKg': smithMachineBarWeightKg,
    'smithMachineBarWeightLb': smithMachineBarWeightLb,
    'heightCm': heightCm,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    currentWeight: json['currentWeight'] as double?,
    goalWeight: json['goalWeight'] as double?,
    avatarInitials: json['avatarInitials'] as String?,
    preferredUnit: json['preferredUnit'] as String? ?? 'kg',
    smithMachineBarWeightKg: json['smithMachineBarWeightKg'] as double? ?? 15.0,
    smithMachineBarWeightLb: json['smithMachineBarWeightLb'] as double? ?? 33.0,
    heightCm: json['heightCm'] as double?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  User copyWith({
    String? id,
    String? name,
    String? email,
    double? currentWeight,
    double? goalWeight,
    String? avatarInitials,
    String? preferredUnit,
    double? smithMachineBarWeightKg,
    double? smithMachineBarWeightLb,
    double? heightCm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    currentWeight: currentWeight ?? this.currentWeight,
    goalWeight: goalWeight ?? this.goalWeight,
    avatarInitials: avatarInitials ?? this.avatarInitials,
    preferredUnit: preferredUnit ?? this.preferredUnit,
    smithMachineBarWeightKg: smithMachineBarWeightKg ?? this.smithMachineBarWeightKg,
    smithMachineBarWeightLb: smithMachineBarWeightLb ?? this.smithMachineBarWeightLb,
    heightCm: heightCm ?? this.heightCm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
