enum MuscleGroup {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
}

enum EquipmentType {
  barbell,
  dumbbell,
  smithMachine,
  machine,
  cable,
  bodyweight,
  other,
}

enum CalorieCategory {
  compoundLowerBody,
  compoundUpperBody,
  isolation,
  bodyweightCore,
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup primaryMuscleGroup;
  final List<MuscleGroup> secondaryMuscleGroups;
  final EquipmentType equipment;
  final CalorieCategory calorieCategory;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    required this.equipment,
    required this.calorieCategory,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryMuscleGroup': primaryMuscleGroup.name,
    'secondaryMuscleGroups': secondaryMuscleGroups.map((e) => e.name).toList(),
    'equipment': equipment.name,
    'calorieCategory': calorieCategory.name,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    primaryMuscleGroup: MuscleGroup.values.firstWhere((e) => e.name == json['primaryMuscleGroup']),
    secondaryMuscleGroups: (json['secondaryMuscleGroups'] as List?)?.map((e) => MuscleGroup.values.firstWhere((mg) => mg.name == e)).toList() ?? [],
    equipment: EquipmentType.values.firstWhere((e) => e.name == json['equipment']),
    calorieCategory: json['calorieCategory'] != null 
      ? CalorieCategory.values.firstWhere((e) => e.name == json['calorieCategory'])
      : CalorieCategory.isolation, // Default for backward compatibility
    imageUrl: json['imageUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Exercise copyWith({
    String? id,
    String? name,
    MuscleGroup? primaryMuscleGroup,
    List<MuscleGroup>? secondaryMuscleGroups,
    EquipmentType? equipment,
    CalorieCategory? calorieCategory,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
    secondaryMuscleGroups: secondaryMuscleGroups ?? this.secondaryMuscleGroups,
    equipment: equipment ?? this.equipment,
    calorieCategory: calorieCategory ?? this.calorieCategory,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
