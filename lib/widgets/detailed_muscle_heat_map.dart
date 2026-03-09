import 'package:flutter/material.dart';
import 'package:total_athlete/models/detailed_muscle.dart';
import 'package:total_athlete/theme.dart';

/// Heat map display mode
enum HeatMapMode {
  trainingLoad,    // Show total training load
  recovery,        // Show recovery status (inverse freshness)
}

/// Training intensity level for a detailed muscle region
enum MuscleIntensity {
  none,      // 0 sets
  low,       // 1-4 sets
  moderate,  // 5-9 sets
  onTarget,  // 10-14 sets
  high,      // 15+ sets
}

extension MuscleIntensityExtension on MuscleIntensity {
  Color getColor(bool isDark, {HeatMapMode mode = HeatMapMode.trainingLoad}) {
    if (mode == HeatMapMode.recovery) {
      // Recovery/Freshness mode - inverse color scheme
      switch (this) {
        case MuscleIntensity.none:
          return isDark 
              ? const Color(0xFF2A2A2A)  // Undertrained - dark/neutral
              : const Color(0xFFE0E0E0);
        case MuscleIntensity.low:
          return isDark 
              ? AppColors.darkSuccess.withValues(alpha: 0.6)  // Fresh/Ready - green
              : AppColors.lightSuccess.withValues(alpha: 0.6);
        case MuscleIntensity.moderate:
          return isDark 
              ? const Color(0xFF64B5F6)  // Neutral - blue
              : const Color(0xFF90CAF9);
        case MuscleIntensity.onTarget:
          return isDark 
              ? const Color(0xFFFFB74D)  // Worked - orange
              : const Color(0xFFFFCC80);
        case MuscleIntensity.high:
          return isDark 
              ? const Color(0xFFFF6B6B)  // Fatigued/Overworked - red
              : const Color(0xFFFF5252);
      }
    } else {
      // Training Load mode - original color scheme
      switch (this) {
        case MuscleIntensity.none:
          return isDark 
              ? const Color(0xFF2A2A2A) 
              : const Color(0xFFE0E0E0);
        case MuscleIntensity.low:
          return isDark 
              ? const Color(0xFF4A4A6A) 
              : const Color(0xFFB3C5E6);
        case MuscleIntensity.moderate:
          return isDark 
              ? const Color(0xFF6A7AA0) 
              : const Color(0xFF7B9FCC);
        case MuscleIntensity.onTarget:
          return isDark 
              ? AppColors.darkSuccess.withValues(alpha: 0.8)
              : AppColors.lightSuccess.withValues(alpha: 0.8);
        case MuscleIntensity.high:
          return isDark 
              ? const Color(0xFFFF6B6B) 
              : const Color(0xFFFF5252);
      }
    }
  }
  
  String getLabel(HeatMapMode mode) {
    if (mode == HeatMapMode.recovery) {
      // Recovery/Freshness labels
      switch (this) {
        case MuscleIntensity.none:
          return 'Undertrained';
        case MuscleIntensity.low:
          return 'Fresh';
        case MuscleIntensity.moderate:
          return 'Neutral';
        case MuscleIntensity.onTarget:
          return 'Worked';
        case MuscleIntensity.high:
          return 'Fatigued';
      }
    } else {
      // Training Load labels
      switch (this) {
        case MuscleIntensity.none:
          return 'None';
        case MuscleIntensity.low:
          return 'Low';
        case MuscleIntensity.moderate:
          return 'Moderate';
        case MuscleIntensity.onTarget:
          return 'On Target';
        case MuscleIntensity.high:
          return 'High';
      }
    }
  }
  
  // Legacy getter for backward compatibility
  String get label => getLabel(HeatMapMode.trainingLoad);
}

/// Detailed anatomical muscle heat map with front/back views
class DetailedMuscleHeatMap extends StatelessWidget {
  final Map<DetailedMuscle, DetailedMuscleData> muscleData;
  final Function(DetailedMuscle)? onMuscleTap;
  final HeatMapMode mode;
  
  const DetailedMuscleHeatMap({
    super.key,
    required this.muscleData,
    this.onMuscleTap,
    this.mode = HeatMapMode.trainingLoad,
  });
  
  MuscleIntensity _getIntensity(DetailedMuscle muscle) {
    // Use ?? operator to ensure we always get a value, defaulting to 0 load
    final data = muscleData[muscle];
    
    // Use decayed load for recovery mode, raw load for training mode
    final load = mode == HeatMapMode.recovery 
        ? (data?.decayedLoad ?? 0.0)
        : (data?.load ?? 0.0);
    
    if (load == 0) return MuscleIntensity.none;
    
    // Use weighted load to determine intensity
    // Adjusted thresholds for weighted contributions
    if (load >= 15) return MuscleIntensity.high;
    if (load >= 10) return MuscleIntensity.onTarget;
    if (load >= 5) return MuscleIntensity.moderate;
    return MuscleIntensity.low;
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Front and back body views
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Front view
            Expanded(
              child: Column(
                children: [
                  Text(
                    'FRONT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailedFrontBodyView(
                    getIntensity: _getIntensity,
                    isDark: isDark,
                    mode: mode,
                    onMuscleTap: onMuscleTap,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Back view
            Expanded(
              child: Column(
                children: [
                  Text(
                    'BACK',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailedBackBodyView(
                    getIntensity: _getIntensity,
                    isDark: isDark,
                    mode: mode,
                    onMuscleTap: onMuscleTap,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Legend
        _IntensityLegend(isDark: isDark, mode: mode),
      ],
    );
  }
}

/// Front body view with detailed muscle regions
class _DetailedFrontBodyView extends StatelessWidget {
  final MuscleIntensity Function(DetailedMuscle) getIntensity;
  final bool isDark;
  final HeatMapMode mode;
  final Function(DetailedMuscle)? onMuscleTap;
  
  const _DetailedFrontBodyView({
    required this.getIntensity,
    required this.isDark,
    required this.mode,
    this.onMuscleTap,
  });
  
  void _handleTap(TapDownDetails details, Size size) {
    if (onMuscleTap == null) return;
    
    final localPos = details.localPosition;
    final centerX = size.width / 2;
    
    // Simple hit detection for each muscle region
    // Upper Chest: center area, top
    if (localPos.dy >= 48 && localPos.dy <= 70 && 
        localPos.dx >= centerX - 30 && localPos.dx <= centerX + 30) {
      onMuscleTap!(DetailedMuscle.upperChest);
      return;
    }
    
    // Lower Chest: center area, below upper chest
    if (localPos.dy >= 72 && localPos.dy <= 96 && 
        localPos.dx >= centerX - 28 && localPos.dx <= centerX + 28) {
      onMuscleTap!(DetailedMuscle.lowerChest);
      return;
    }
    
    // Front/Side Delts: shoulders
    if (localPos.dy >= 38 && localPos.dy <= 56) {
      if (localPos.dx >= centerX - 50 && localPos.dx <= centerX - 24) {
        onMuscleTap!(DetailedMuscle.sideDelts);
        return;
      }
      if (localPos.dx >= centerX + 24 && localPos.dx <= centerX + 50) {
        onMuscleTap!(DetailedMuscle.sideDelts);
        return;
      }
    }
    
    // Biceps: upper arms
    if (localPos.dy >= 58 && localPos.dy <= 88) {
      if (localPos.dx >= centerX - 54 && localPos.dx <= centerX - 40) {
        onMuscleTap!(DetailedMuscle.biceps);
        return;
      }
      if (localPos.dx >= centerX + 40 && localPos.dx <= centerX + 54) {
        onMuscleTap!(DetailedMuscle.biceps);
        return;
      }
    }
    
    // Upper/Lower Abs: center torso
    if (localPos.dy >= 98 && localPos.dy <= 116 && 
        localPos.dx >= centerX - 20 && localPos.dx <= centerX + 20) {
      onMuscleTap!(DetailedMuscle.upperAbs);
      return;
    }
    if (localPos.dy >= 118 && localPos.dy <= 136 && 
        localPos.dx >= centerX - 18 && localPos.dx <= centerX + 18) {
      onMuscleTap!(DetailedMuscle.lowerAbs);
      return;
    }
    
    // Quads: upper legs
    if (localPos.dy >= 140 && localPos.dy <= 205) {
      if (localPos.dx >= centerX - 26 && localPos.dx <= centerX - 4) {
        onMuscleTap!(DetailedMuscle.quads);
        return;
      }
      if (localPos.dx >= centerX + 4 && localPos.dx <= centerX + 26) {
        onMuscleTap!(DetailedMuscle.quads);
        return;
      }
    }
    
    // Calves: lower legs
    if (localPos.dy >= 210 && localPos.dy <= 265) {
      if (localPos.dx >= centerX - 24 && localPos.dx <= centerX - 6) {
        onMuscleTap!(DetailedMuscle.calvesF);
        return;
      }
      if (localPos.dx >= centerX + 6 && localPos.dx <= centerX + 24) {
        onMuscleTap!(DetailedMuscle.calvesF);
        return;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details, const Size(140, 280)),
      child: CustomPaint(
        size: const Size(140, 280),
        painter: _DetailedFrontBodyPainter(
          upperChestColor: getIntensity(DetailedMuscle.upperChest).getColor(isDark, mode: mode),
          lowerChestColor: getIntensity(DetailedMuscle.lowerChest).getColor(isDark, mode: mode),
          frontDeltsColor: getIntensity(DetailedMuscle.frontDelts).getColor(isDark, mode: mode),
          sideDeltsColor: getIntensity(DetailedMuscle.sideDelts).getColor(isDark, mode: mode),
          bicepsColor: getIntensity(DetailedMuscle.biceps).getColor(isDark, mode: mode),
          forearmsColor: getIntensity(DetailedMuscle.forearms).getColor(isDark, mode: mode),
          upperAbsColor: getIntensity(DetailedMuscle.upperAbs).getColor(isDark, mode: mode),
          lowerAbsColor: getIntensity(DetailedMuscle.lowerAbs).getColor(isDark, mode: mode),
          obliquesColor: getIntensity(DetailedMuscle.obliques).getColor(isDark, mode: mode),
          quadsColor: getIntensity(DetailedMuscle.quads).getColor(isDark, mode: mode),
          adductorsColor: getIntensity(DetailedMuscle.adductors).getColor(isDark, mode: mode),
          calvesColor: getIntensity(DetailedMuscle.calvesF).getColor(isDark, mode: mode),
          onMuscleTap: onMuscleTap,
        ),
      ),
    );
  }
}

/// Back body view with detailed muscle regions
class _DetailedBackBodyView extends StatelessWidget {
  final MuscleIntensity Function(DetailedMuscle) getIntensity;
  final bool isDark;
  final HeatMapMode mode;
  final Function(DetailedMuscle)? onMuscleTap;
  
  const _DetailedBackBodyView({
    required this.getIntensity,
    required this.isDark,
    required this.mode,
    this.onMuscleTap,
  });
  
  void _handleTap(TapDownDetails details, Size size) {
    if (onMuscleTap == null) return;
    
    final localPos = details.localPosition;
    final centerX = size.width / 2;
    
    // Traps: upper center
    if (localPos.dy >= 35 && localPos.dy <= 48 && 
        localPos.dx >= centerX - 25 && localPos.dx <= centerX + 25) {
      onMuscleTap!(DetailedMuscle.traps);
      return;
    }
    
    // Rear Delts: shoulders back
    if (localPos.dy >= 40 && localPos.dy <= 56) {
      if (localPos.dx >= centerX - 48 && localPos.dx <= centerX - 32) {
        onMuscleTap!(DetailedMuscle.rearDelts);
        return;
      }
      if (localPos.dx >= centerX + 32 && localPos.dx <= centerX + 48) {
        onMuscleTap!(DetailedMuscle.rearDelts);
        return;
      }
    }
    
    // Triceps: back of arms
    if (localPos.dy >= 58 && localPos.dy <= 88) {
      if (localPos.dx >= centerX - 54 && localPos.dx <= centerX - 40) {
        onMuscleTap!(DetailedMuscle.triceps);
        return;
      }
      if (localPos.dx >= centerX + 40 && localPos.dx <= centerX + 54) {
        onMuscleTap!(DetailedMuscle.triceps);
        return;
      }
    }
    
    // Mid Back: mid-upper torso
    if (localPos.dy >= 50 && localPos.dy <= 78 && 
        localPos.dx >= centerX - 26 && localPos.dx <= centerX + 26) {
      onMuscleTap!(DetailedMuscle.midBack);
      return;
    }
    
    // Lats: sides of torso
    if (localPos.dy >= 80 && localPos.dy <= 110) {
      if (localPos.dx >= centerX - 38 && localPos.dx <= centerX - 24) {
        onMuscleTap!(DetailedMuscle.lats);
        return;
      }
      if (localPos.dx >= centerX + 24 && localPos.dx <= centerX + 38) {
        onMuscleTap!(DetailedMuscle.lats);
        return;
      }
    }
    
    // Lower Back: lower torso
    if (localPos.dy >= 80 && localPos.dy <= 118 && 
        localPos.dx >= centerX - 22 && localPos.dx <= centerX + 22) {
      onMuscleTap!(DetailedMuscle.lowerBackErectors);
      return;
    }
    
    // Glutes
    if (localPos.dy >= 122 && localPos.dy <= 146 && 
        localPos.dx >= centerX - 24 && localPos.dx <= centerX + 24) {
      onMuscleTap!(DetailedMuscle.glutes);
      return;
    }
    
    // Hamstrings: back of thighs
    if (localPos.dy >= 150 && localPos.dy <= 205) {
      if (localPos.dx >= centerX - 26 && localPos.dx <= centerX - 4) {
        onMuscleTap!(DetailedMuscle.hamstrings);
        return;
      }
      if (localPos.dx >= centerX + 4 && localPos.dx <= centerX + 26) {
        onMuscleTap!(DetailedMuscle.hamstrings);
        return;
      }
    }
    
    // Calves: lower legs
    if (localPos.dy >= 210 && localPos.dy <= 265) {
      if (localPos.dx >= centerX - 24 && localPos.dx <= centerX - 6) {
        onMuscleTap!(DetailedMuscle.calvesB);
        return;
      }
      if (localPos.dx >= centerX + 6 && localPos.dx <= centerX + 24) {
        onMuscleTap!(DetailedMuscle.calvesB);
        return;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details, const Size(140, 280)),
      child: CustomPaint(
        size: const Size(140, 280),
        painter: _DetailedBackBodyPainter(
          trapsColor: getIntensity(DetailedMuscle.traps).getColor(isDark, mode: mode),
          rearDeltsColor: getIntensity(DetailedMuscle.rearDelts).getColor(isDark, mode: mode),
          latsColor: getIntensity(DetailedMuscle.lats).getColor(isDark, mode: mode),
          midBackColor: getIntensity(DetailedMuscle.midBack).getColor(isDark, mode: mode),
          lowerBackErectorsColor: getIntensity(DetailedMuscle.lowerBackErectors).getColor(isDark, mode: mode),
          tricepsColor: getIntensity(DetailedMuscle.triceps).getColor(isDark, mode: mode),
          glutesColor: getIntensity(DetailedMuscle.glutes).getColor(isDark, mode: mode),
          hamstringsColor: getIntensity(DetailedMuscle.hamstrings).getColor(isDark, mode: mode),
          calvesColor: getIntensity(DetailedMuscle.calvesB).getColor(isDark, mode: mode),
          onMuscleTap: onMuscleTap,
        ),
      ),
    );
  }
}

/// Custom painter for detailed front body view
class _DetailedFrontBodyPainter extends CustomPainter {
  final Color upperChestColor;
  final Color lowerChestColor;
  final Color frontDeltsColor;
  final Color sideDeltsColor;
  final Color bicepsColor;
  final Color forearmsColor;
  final Color upperAbsColor;
  final Color lowerAbsColor;
  final Color obliquesColor;
  final Color quadsColor;
  final Color adductorsColor;
  final Color calvesColor;
  final Function(DetailedMuscle)? onMuscleTap;
  
  _DetailedFrontBodyPainter({
    required this.upperChestColor,
    required this.lowerChestColor,
    required this.frontDeltsColor,
    required this.sideDeltsColor,
    required this.bicepsColor,
    required this.forearmsColor,
    required this.upperAbsColor,
    required this.lowerAbsColor,
    required this.obliquesColor,
    required this.quadsColor,
    required this.adductorsColor,
    required this.calvesColor,
    this.onMuscleTap,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    // Head (circle)
    paint.color = Colors.grey.shade700;
    canvas.drawCircle(Offset(centerX, 20), 14, paint);
    
    // SHOULDERS
    // Side Delts (outer shoulders)
    paint.color = sideDeltsColor;
    // Left side delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 50, 38, 18, 18),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 50, 38, 18, 18),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    // Right side delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 32, 38, 18, 18),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 32, 38, 18, 18),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    
    // Front Delts (front of shoulders)
    paint.color = frontDeltsColor;
    // Left front delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 38, 40, 14, 16),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 38, 40, 14, 16),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    // Right front delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 24, 40, 14, 16),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 24, 40, 14, 16),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    
    // CHEST
    // Upper Chest
    paint.color = upperChestColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 30, 48, 60, 22),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 30, 48, 60, 22),
        const Radius.circular(10),
      ),
      strokePaint,
    );
    
    // Lower Chest
    paint.color = lowerChestColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 28, 72, 56, 24),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 28, 72, 56, 24),
        const Radius.circular(10),
      ),
      strokePaint,
    );
    
    // ARMS
    // Biceps
    paint.color = bicepsColor;
    // Left bicep
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 54, 58, 14, 30),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 54, 58, 14, 30),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    // Right bicep
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 40, 58, 14, 30),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 40, 58, 14, 30),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    
    // Forearms
    paint.color = forearmsColor;
    // Left forearm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 52, 90, 11, 35),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 52, 90, 11, 35),
        const Radius.circular(5),
      ),
      strokePaint,
    );
    // Right forearm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 41, 90, 11, 35),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 41, 90, 11, 35),
        const Radius.circular(5),
      ),
      strokePaint,
    );
    
    // CORE
    // Obliques (sides)
    paint.color = obliquesColor;
    // Left oblique
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 30, 98, 8, 32),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 30, 98, 8, 32),
        const Radius.circular(4),
      ),
      strokePaint,
    );
    // Right oblique
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 22, 98, 8, 32),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 22, 98, 8, 32),
        const Radius.circular(4),
      ),
      strokePaint,
    );
    
    // Upper Abs
    paint.color = upperAbsColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 98, 40, 18),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 98, 40, 18),
        const Radius.circular(6),
      ),
      strokePaint,
    );
    
    // Lower Abs
    paint.color = lowerAbsColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 18, 118, 36, 18),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 18, 118, 36, 18),
        const Radius.circular(6),
      ),
      strokePaint,
    );
    
    // LEGS
    // Quads (front thighs)
    paint.color = quadsColor;
    // Left quad
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 140, 22, 65),
        const Radius.circular(11),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 140, 22, 65),
        const Radius.circular(11),
      ),
      strokePaint,
    );
    // Right quad
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 4, 140, 22, 65),
        const Radius.circular(11),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 4, 140, 22, 65),
        const Radius.circular(11),
      ),
      strokePaint,
    );
    
    // Adductors (inner thighs - subtle)
    paint.color = adductorsColor;
    // Left adductor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 6, 145, 6, 50),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 6, 145, 6, 50),
        const Radius.circular(3),
      ),
      strokePaint,
    );
    // Right adductor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX, 145, 6, 50),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX, 145, 6, 50),
        const Radius.circular(3),
      ),
      strokePaint,
    );
    
    // Calves
    paint.color = calvesColor;
    // Left calf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 210, 18, 55),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 210, 18, 55),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    // Right calf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 6, 210, 18, 55),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 6, 210, 18, 55),
        const Radius.circular(9),
      ),
      strokePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for detailed back body view
class _DetailedBackBodyPainter extends CustomPainter {
  final Color trapsColor;
  final Color rearDeltsColor;
  final Color latsColor;
  final Color midBackColor;
  final Color lowerBackErectorsColor;
  final Color tricepsColor;
  final Color glutesColor;
  final Color hamstringsColor;
  final Color calvesColor;
  final Function(DetailedMuscle)? onMuscleTap;
  
  _DetailedBackBodyPainter({
    required this.trapsColor,
    required this.rearDeltsColor,
    required this.latsColor,
    required this.midBackColor,
    required this.lowerBackErectorsColor,
    required this.tricepsColor,
    required this.glutesColor,
    required this.hamstringsColor,
    required this.calvesColor,
    this.onMuscleTap,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    // Head (circle)
    paint.color = Colors.grey.shade700;
    canvas.drawCircle(Offset(centerX, 20), 14, paint);
    
    // SHOULDERS/UPPER BACK
    // Traps (upper trapezius - neck to shoulders)
    paint.color = trapsColor;
    final trapsPath = Path();
    trapsPath.moveTo(centerX, 35);
    trapsPath.lineTo(centerX - 25, 48);
    trapsPath.lineTo(centerX + 25, 48);
    trapsPath.close();
    canvas.drawPath(trapsPath, paint);
    canvas.drawPath(trapsPath, strokePaint);
    
    // Rear Delts (back of shoulders)
    paint.color = rearDeltsColor;
    // Left rear delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 48, 40, 16, 16),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 48, 40, 16, 16),
        const Radius.circular(8),
      ),
      strokePaint,
    );
    // Right rear delt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 32, 40, 16, 16),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 32, 40, 16, 16),
        const Radius.circular(8),
      ),
      strokePaint,
    );
    
    // ARMS
    // Triceps
    paint.color = tricepsColor;
    // Left tricep
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 54, 58, 14, 30),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 54, 58, 14, 30),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    // Right tricep
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 40, 58, 14, 30),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 40, 58, 14, 30),
        const Radius.circular(7),
      ),
      strokePaint,
    );
    
    // BACK MUSCLES
    // Mid Back (rhomboids, mid traps)
    paint.color = midBackColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 50, 52, 28),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 50, 52, 28),
        const Radius.circular(10),
      ),
      strokePaint,
    );
    
    // Lats (latissimus dorsi - wings)
    paint.color = latsColor;
    // Left lat
    final leftLatPath = Path();
    leftLatPath.moveTo(centerX - 30, 80);
    leftLatPath.lineTo(centerX - 38, 85);
    leftLatPath.lineTo(centerX - 36, 110);
    leftLatPath.lineTo(centerX - 24, 108);
    leftLatPath.close();
    canvas.drawPath(leftLatPath, paint);
    canvas.drawPath(leftLatPath, strokePaint);
    
    // Right lat
    final rightLatPath = Path();
    rightLatPath.moveTo(centerX + 30, 80);
    rightLatPath.lineTo(centerX + 38, 85);
    rightLatPath.lineTo(centerX + 36, 110);
    rightLatPath.lineTo(centerX + 24, 108);
    rightLatPath.close();
    canvas.drawPath(rightLatPath, paint);
    canvas.drawPath(rightLatPath, strokePaint);
    
    // Lower Back / Erectors
    paint.color = lowerBackErectorsColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 22, 80, 44, 38),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 22, 80, 44, 38),
        const Radius.circular(8),
      ),
      strokePaint,
    );
    
    // LOWER BODY
    // Glutes
    paint.color = glutesColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 122, 48, 24),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 122, 48, 24),
        const Radius.circular(10),
      ),
      strokePaint,
    );
    
    // Hamstrings
    paint.color = hamstringsColor;
    // Left hamstring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 150, 22, 55),
        const Radius.circular(11),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 26, 150, 22, 55),
        const Radius.circular(11),
      ),
      strokePaint,
    );
    // Right hamstring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 4, 150, 22, 55),
        const Radius.circular(11),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 4, 150, 22, 55),
        const Radius.circular(11),
      ),
      strokePaint,
    );
    
    // Calves
    paint.color = calvesColor;
    // Left calf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 210, 18, 55),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 24, 210, 18, 55),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    // Right calf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 6, 210, 18, 55),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 6, 210, 18, 55),
        const Radius.circular(9),
      ),
      strokePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Legend showing intensity levels and colors
class _IntensityLegend extends StatelessWidget {
  final bool isDark;
  final HeatMapMode mode;
  
  const _IntensityLegend({
    required this.isDark,
    required this.mode,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == HeatMapMode.recovery ? 'Recovery Status' : 'Training Load',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: MuscleIntensity.values.map((intensity) {
              return _LegendItem(
                color: intensity.getColor(isDark, mode: mode),
                label: intensity.getLabel(mode),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  
  const _LegendItem({
    required this.color,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
