import 'package:total_athlete/models/detailed_muscle.dart';

/// Maps exercise names to their weighted muscle contributions
/// Each exercise can target multiple muscles with different intensity weights (0.0 to 1.0)
class MuscleMappingService {
  
  /// Get the weighted muscle contributions for an exercise
  /// Returns a map of DetailedMuscle -> contribution weight (0.0 to 1.0)
  static Map<DetailedMuscle, double> getMuscleContributions(String exerciseName) {
    return _muscleContributionMap[exerciseName.toLowerCase()] ?? {};
  }
  
  /// Legacy method: Get primary muscles (contribution >= 0.8)
  /// Kept for backward compatibility
  static List<DetailedMuscle> getPrimaryMuscles(String exerciseName) {
    final contributions = getMuscleContributions(exerciseName);
    return contributions.entries
        .where((e) => e.value >= 0.8)
        .map((e) => e.key)
        .toList();
  }
  
  /// Legacy method: Get secondary muscles (0.2 <= contribution < 0.8)
  /// Kept for backward compatibility
  static List<DetailedMuscle> getSecondaryMuscles(String exerciseName) {
    final contributions = getMuscleContributions(exerciseName);
    return contributions.entries
        .where((e) => e.value >= 0.2 && e.value < 0.8)
        .map((e) => e.key)
        .toList();
  }
  
  // Weighted muscle contribution mappings
  // Each exercise maps to muscles with contribution weights from 0.0 to 1.0
  static final Map<String, Map<DetailedMuscle, double>> _muscleContributionMap = {
    // ===== LEG EXERCISES =====
    'back squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.9,
      DetailedMuscle.lowerBackErectors: 0.5,
      DetailedMuscle.adductors: 0.4,
      DetailedMuscle.hamstrings: 0.3,
      DetailedMuscle.upperAbs: 0.3,
      DetailedMuscle.lowerAbs: 0.3,
    },
    
    'front squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.7,
      DetailedMuscle.lowerBackErectors: 0.4,
      DetailedMuscle.upperAbs: 0.5,
      DetailedMuscle.lowerAbs: 0.5,
    },
    
    'leg press': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.5,
      DetailedMuscle.hamstrings: 0.2,
      DetailedMuscle.adductors: 0.2,
    },
    
    'hack squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.6,
      DetailedMuscle.hamstrings: 0.2,
    },
    
    'leg extension': {
      DetailedMuscle.quads: 1.0,
    },
    
    'bulgarian split squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.hamstrings: 0.4,
    },
    
    'walking lunge': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.7,
      DetailedMuscle.hamstrings: 0.3,
    },
    
    'dumbbell lunge': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.7,
      DetailedMuscle.hamstrings: 0.3,
    },
    
    'smith machine squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.lowerBackErectors: 0.4,
      DetailedMuscle.hamstrings: 0.3,
    },
    
    'smith machine split squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.7,
      DetailedMuscle.hamstrings: 0.3,
    },
    
    'goblet squat': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.6,
      DetailedMuscle.upperAbs: 0.3,
      DetailedMuscle.lowerAbs: 0.3,
    },
    
    'dumbbell step-up': {
      DetailedMuscle.quads: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.hamstrings: 0.3,
    },
    
    'romanian deadlift': {
      DetailedMuscle.hamstrings: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.lowerBackErectors: 0.5,
      DetailedMuscle.forearms: 0.2,
    },
    
    'dumbbell romanian deadlift': {
      DetailedMuscle.hamstrings: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.lowerBackErectors: 0.5,
      DetailedMuscle.forearms: 0.2,
    },
    
    'smith machine romanian deadlift': {
      DetailedMuscle.hamstrings: 1.0,
      DetailedMuscle.glutes: 0.8,
      DetailedMuscle.lowerBackErectors: 0.4,
    },
    
    'seated leg curl': {
      DetailedMuscle.hamstrings: 1.0,
      DetailedMuscle.calvesB: 0.2,
    },
    
    'lying leg curl': {
      DetailedMuscle.hamstrings: 1.0,
      DetailedMuscle.calvesB: 0.2,
    },
    
    'smith machine hip thrust': {
      DetailedMuscle.glutes: 1.0,
      DetailedMuscle.hamstrings: 0.4,
    },
    
    'standing calf raise': {
      DetailedMuscle.calvesF: 1.0,
      DetailedMuscle.calvesB: 1.0,
    },
    
    'seated calf raise': {
      DetailedMuscle.calvesF: 1.0,
      DetailedMuscle.calvesB: 1.0,
    },
    
    'smith machine calf raises': {
      DetailedMuscle.calvesF: 1.0,
      DetailedMuscle.calvesB: 1.0,
    },
    
    // ===== CHEST EXERCISES =====
    'barbell bench press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.45,
      DetailedMuscle.triceps: 0.55,
      DetailedMuscle.upperChest: 0.3,
    },
    
    'dumbbell bench press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.45,
      DetailedMuscle.triceps: 0.5,
      DetailedMuscle.upperChest: 0.3,
    },
    
    'incline dumbbell press': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.55,
      DetailedMuscle.triceps: 0.4,
      DetailedMuscle.lowerChest: 0.2,
    },
    
    'incline machine press': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.5,
      DetailedMuscle.triceps: 0.4,
    },
    
    'decline dumbbell press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.3,
      DetailedMuscle.triceps: 0.5,
    },
    
    'smith machine bench press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.45,
      DetailedMuscle.triceps: 0.55,
    },
    
    'smith machine incline press': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.55,
      DetailedMuscle.triceps: 0.4,
    },
    
    'smith machine decline press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.3,
      DetailedMuscle.triceps: 0.5,
    },
    
    'hammer strength bench press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.4,
      DetailedMuscle.triceps: 0.5,
    },
    
    'hammer strength incline press': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.5,
      DetailedMuscle.triceps: 0.4,
    },
    
    'hammer strength decline press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.3,
      DetailedMuscle.triceps: 0.5,
    },
    
    'machine chest press': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.4,
      DetailedMuscle.triceps: 0.5,
    },
    
    'dumbbell fly': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.2,
      DetailedMuscle.upperChest: 0.3,
    },
    
    'incline dumbbell fly': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.25,
      DetailedMuscle.lowerChest: 0.2,
    },
    
    'cable fly': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.15,
    },
    
    'low cable fly': {
      DetailedMuscle.upperChest: 1.0,
      DetailedMuscle.frontDelts: 0.2,
    },
    
    'high cable fly': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.frontDelts: 0.15,
    },
    
    'pec deck': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.upperChest: 0.4,
      DetailedMuscle.frontDelts: 0.15,
    },
    
    // ===== SHOULDER EXERCISES =====
    'barbell overhead press': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.sideDelts: 0.5,
      DetailedMuscle.triceps: 0.6,
      DetailedMuscle.upperChest: 0.15,
      DetailedMuscle.upperAbs: 0.2,
      DetailedMuscle.lowerAbs: 0.2,
    },
    
    'dumbbell shoulder press': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.sideDelts: 0.6,
      DetailedMuscle.triceps: 0.5,
      DetailedMuscle.upperChest: 0.15,
    },
    
    'arnold press': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.sideDelts: 0.7,
      DetailedMuscle.triceps: 0.5,
      DetailedMuscle.upperChest: 0.2,
    },
    
    'machine shoulder press': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.sideDelts: 0.5,
      DetailedMuscle.triceps: 0.5,
    },
    
    'smith machine shoulder press': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.sideDelts: 0.5,
      DetailedMuscle.triceps: 0.5,
    },
    
    'dumbbell lateral raise': {
      DetailedMuscle.sideDelts: 1.0,
      DetailedMuscle.traps: 0.15,
    },
    
    'cable lateral raise': {
      DetailedMuscle.sideDelts: 1.0,
      DetailedMuscle.traps: 0.15,
    },
    
    'cable front raise': {
      DetailedMuscle.frontDelts: 1.0,
      DetailedMuscle.upperChest: 0.2,
    },
    
    'face pulls': {
      DetailedMuscle.rearDelts: 1.0,
      DetailedMuscle.midBack: 0.5,
      DetailedMuscle.traps: 0.4,
    },
    
    'rear delt fly': {
      DetailedMuscle.rearDelts: 1.0,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.traps: 0.2,
    },
    
    'reverse pec deck': {
      DetailedMuscle.rearDelts: 1.0,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.traps: 0.2,
    },
    
    'smith machine shrugs': {
      DetailedMuscle.traps: 1.0,
      DetailedMuscle.midBack: 0.3,
    },
    
    // ===== BACK EXERCISES =====
    'deadlift': {
      DetailedMuscle.glutes: 1.0,
      DetailedMuscle.hamstrings: 0.8,
      DetailedMuscle.lowerBackErectors: 0.8,
      DetailedMuscle.traps: 0.5,
      DetailedMuscle.forearms: 0.4,
      DetailedMuscle.lats: 0.3,
      DetailedMuscle.quads: 0.2,
    },
    
    'pull-ups': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.biceps: 0.45,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.rearDelts: 0.2,
      DetailedMuscle.forearms: 0.2,
    },
    
    'weighted pull-ups': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.biceps: 0.45,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.rearDelts: 0.2,
      DetailedMuscle.forearms: 0.25,
    },
    
    'chin-ups': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.biceps: 0.6,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.forearms: 0.2,
    },
    
    'weighted chin-ups': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.biceps: 0.6,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.forearms: 0.25,
    },
    
    'lat pulldown': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.biceps: 0.4,
      DetailedMuscle.midBack: 0.3,
      DetailedMuscle.rearDelts: 0.2,
    },
    
    'barbell bent over row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.8,
      DetailedMuscle.rearDelts: 0.45,
      DetailedMuscle.biceps: 0.35,
      DetailedMuscle.lowerBackErectors: 0.25,
      DetailedMuscle.forearms: 0.2,
    },
    
    'one arm dumbbell row': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.midBack: 0.7,
      DetailedMuscle.biceps: 0.35,
      DetailedMuscle.rearDelts: 0.3,
      DetailedMuscle.forearms: 0.2,
    },
    
    't bar row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.7,
      DetailedMuscle.rearDelts: 0.4,
      DetailedMuscle.biceps: 0.3,
      DetailedMuscle.lowerBackErectors: 0.3,
    },
    
    'seated cable row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.7,
      DetailedMuscle.rearDelts: 0.35,
      DetailedMuscle.biceps: 0.3,
    },
    
    'chest supported row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.6,
      DetailedMuscle.rearDelts: 0.35,
      DetailedMuscle.biceps: 0.3,
    },
    
    'machine row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.6,
      DetailedMuscle.biceps: 0.3,
      DetailedMuscle.rearDelts: 0.3,
    },
    
    'hammer strength row': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.midBack: 0.8,
      DetailedMuscle.rearDelts: 0.4,
      DetailedMuscle.biceps: 0.3,
    },
    
    'hammer strength high row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.traps: 0.6,
      DetailedMuscle.rearDelts: 0.4,
      DetailedMuscle.biceps: 0.3,
    },
    
    'smith machine row': {
      DetailedMuscle.midBack: 1.0,
      DetailedMuscle.lats: 0.75,
      DetailedMuscle.rearDelts: 0.35,
      DetailedMuscle.biceps: 0.3,
    },
    
    'straight arm pulldown': {
      DetailedMuscle.lats: 1.0,
      DetailedMuscle.triceps: 0.3,
      DetailedMuscle.lowerChest: 0.2,
    },
    
    // ===== ARM EXERCISES =====
    'barbell curl': {
      DetailedMuscle.biceps: 1.0,
      DetailedMuscle.forearms: 0.35,
    },
    
    'ez bar curl': {
      DetailedMuscle.biceps: 1.0,
      DetailedMuscle.forearms: 0.3,
    },
    
    'hammer curls': {
      DetailedMuscle.biceps: 0.75,
      DetailedMuscle.forearms: 0.75,
    },
    
    'incline dumbbell curl': {
      DetailedMuscle.biceps: 1.0,
      DetailedMuscle.forearms: 0.25,
    },
    
    'cable curl': {
      DetailedMuscle.biceps: 1.0,
      DetailedMuscle.forearms: 0.3,
    },
    
    'rope hammer curl': {
      DetailedMuscle.biceps: 0.8,
      DetailedMuscle.forearms: 0.8,
    },
    
    'bench dips': {
      DetailedMuscle.triceps: 1.0,
      DetailedMuscle.lowerChest: 0.25,
      DetailedMuscle.frontDelts: 0.2,
    },
    
    'chest dips': {
      DetailedMuscle.lowerChest: 1.0,
      DetailedMuscle.triceps: 0.8,
      DetailedMuscle.frontDelts: 0.3,
    },
    
    'ez bar skull crusher': {
      DetailedMuscle.triceps: 1.0,
    },
    
    'tricep pushdown': {
      DetailedMuscle.triceps: 1.0,
    },
    
    'rope pushdown': {
      DetailedMuscle.triceps: 1.0,
    },
    
    'overhead cable tricep extension': {
      DetailedMuscle.triceps: 1.0,
    },
    
    'smith machine close grip press': {
      DetailedMuscle.triceps: 1.0,
      DetailedMuscle.lowerChest: 0.4,
      DetailedMuscle.frontDelts: 0.2,
    },
    
    // ===== CORE EXERCISES =====
    'plank': {
      DetailedMuscle.upperAbs: 0.8,
      DetailedMuscle.lowerAbs: 0.7,
      DetailedMuscle.obliques: 0.5,
      DetailedMuscle.lowerBackErectors: 0.2,
    },
    
    'weighted plank': {
      DetailedMuscle.upperAbs: 1.0,
      DetailedMuscle.lowerAbs: 0.9,
      DetailedMuscle.obliques: 0.6,
      DetailedMuscle.lowerBackErectors: 0.3,
    },
    
    'ab wheel rollout': {
      DetailedMuscle.upperAbs: 1.0,
      DetailedMuscle.lowerAbs: 0.8,
      DetailedMuscle.obliques: 0.4,
      DetailedMuscle.frontDelts: 0.2,
      DetailedMuscle.lowerBackErectors: 0.2,
    },
    
    'hanging leg raise': {
      DetailedMuscle.lowerAbs: 1.0,
      DetailedMuscle.upperAbs: 0.5,
      DetailedMuscle.forearms: 0.3,
    },
    
    'cable crunch': {
      DetailedMuscle.upperAbs: 1.0,
      DetailedMuscle.lowerAbs: 0.4,
    },
    
    'russian twist': {
      DetailedMuscle.obliques: 1.0,
      DetailedMuscle.upperAbs: 0.4,
      DetailedMuscle.lowerAbs: 0.3,
    },
  };
}
