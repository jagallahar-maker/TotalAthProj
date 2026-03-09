/// Detailed muscle regions for anatomical heat map
enum DetailedMuscle {
  // FRONT
  upperChest,
  lowerChest,
  frontDelts,
  sideDelts,
  biceps,
  forearms,
  upperAbs,
  lowerAbs,
  obliques,
  quads,
  adductors,
  calvesF,
  
  // BACK
  traps,
  rearDelts,
  lats,
  midBack,
  lowerBackErectors,
  triceps,
  glutes,
  hamstrings,
  calvesB,
}

extension DetailedMuscleExtension on DetailedMuscle {
  String get name {
    switch (this) {
      case DetailedMuscle.upperChest:
        return 'Upper Chest';
      case DetailedMuscle.lowerChest:
        return 'Lower Chest';
      case DetailedMuscle.frontDelts:
        return 'Front Delts';
      case DetailedMuscle.sideDelts:
        return 'Side Delts';
      case DetailedMuscle.biceps:
        return 'Biceps';
      case DetailedMuscle.forearms:
        return 'Forearms';
      case DetailedMuscle.upperAbs:
        return 'Upper Abs';
      case DetailedMuscle.lowerAbs:
        return 'Lower Abs';
      case DetailedMuscle.obliques:
        return 'Obliques';
      case DetailedMuscle.quads:
        return 'Quads';
      case DetailedMuscle.adductors:
        return 'Adductors';
      case DetailedMuscle.calvesF:
        return 'Calves';
      case DetailedMuscle.traps:
        return 'Traps';
      case DetailedMuscle.rearDelts:
        return 'Rear Delts';
      case DetailedMuscle.lats:
        return 'Lats';
      case DetailedMuscle.midBack:
        return 'Mid Back';
      case DetailedMuscle.lowerBackErectors:
        return 'Lower Back / Erectors';
      case DetailedMuscle.triceps:
        return 'Triceps';
      case DetailedMuscle.glutes:
        return 'Glutes';
      case DetailedMuscle.hamstrings:
        return 'Hamstrings';
      case DetailedMuscle.calvesB:
        return 'Calves';
    }
  }
  
  bool get isFront {
    return [
      DetailedMuscle.upperChest,
      DetailedMuscle.lowerChest,
      DetailedMuscle.frontDelts,
      DetailedMuscle.sideDelts,
      DetailedMuscle.biceps,
      DetailedMuscle.forearms,
      DetailedMuscle.upperAbs,
      DetailedMuscle.lowerAbs,
      DetailedMuscle.obliques,
      DetailedMuscle.quads,
      DetailedMuscle.adductors,
      DetailedMuscle.calvesF,
    ].contains(this);
  }
}

/// Data for a specific muscle region
class DetailedMuscleData {
  final DetailedMuscle muscle;
  final double load; // Weighted load (primary = 1.0, secondary = 0.5)
  final double decayedLoad; // Load with time-based decay applied
  final int primarySets;
  final int secondarySets;
  final double totalVolume;
  final List<String> topExercises; // Top 3 contributing exercises
  final Map<DateTime, double> dailyLoads; // Load by date for decay calculation
  
  const DetailedMuscleData({
    required this.muscle,
    required this.load,
    this.decayedLoad = 0.0,
    required this.primarySets,
    required this.secondarySets,
    required this.totalVolume,
    required this.topExercises,
    this.dailyLoads = const {},
  });
  
  int get totalSets => primarySets + secondarySets;
  
  DetailedMuscleData copyWith({
    double? load,
    double? decayedLoad,
    int? primarySets,
    int? secondarySets,
    double? totalVolume,
    List<String>? topExercises,
    Map<DateTime, double>? dailyLoads,
  }) {
    return DetailedMuscleData(
      muscle: muscle,
      load: load ?? this.load,
      decayedLoad: decayedLoad ?? this.decayedLoad,
      primarySets: primarySets ?? this.primarySets,
      secondarySets: secondarySets ?? this.secondarySets,
      totalVolume: totalVolume ?? this.totalVolume,
      topExercises: topExercises ?? this.topExercises,
      dailyLoads: dailyLoads ?? this.dailyLoads,
    );
  }
}
