import 'package:flutter/material.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/theme.dart';

/// Represents training intensity level for a muscle group
enum TrainingIntensity {
  untrained,  // 0% of target
  low,        // 1-49% of target
  moderate,   // 50-99% of target
  onTarget,   // 100-149% of target
  high,       // 150%+ of target
}

/// Heat map visualization of muscle training volume
class MuscleHeatMap extends StatelessWidget {
  final Map<MuscleGroup, int> muscleGroupSets;
  final Map<MuscleGroup, int> weeklyTargets;
  final bool showWeeklyTargets;

  const MuscleHeatMap({
    super.key,
    required this.muscleGroupSets,
    required this.weeklyTargets,
    this.showWeeklyTargets = true,
  });

  TrainingIntensity _getIntensity(MuscleGroup muscle) {
    final sets = muscleGroupSets[muscle] ?? 0;
    if (sets == 0) return TrainingIntensity.untrained;
    
    if (!showWeeklyTargets) {
      // For monthly/90d views, use absolute thresholds
      if (sets >= 60) return TrainingIntensity.high;
      if (sets >= 40) return TrainingIntensity.onTarget;
      if (sets >= 20) return TrainingIntensity.moderate;
      return TrainingIntensity.low;
    }
    
    final target = weeklyTargets[muscle] ?? 12;
    final percentage = (sets / target) * 100;
    
    if (percentage >= 150) return TrainingIntensity.high;
    if (percentage >= 100) return TrainingIntensity.onTarget;
    if (percentage >= 50) return TrainingIntensity.moderate;
    return TrainingIntensity.low;
  }

  Color _getIntensityColor(TrainingIntensity intensity, bool isDark) {
    switch (intensity) {
      case TrainingIntensity.untrained:
        return isDark 
            ? const Color(0xFF2A2A2A) 
            : const Color(0xFFE0E0E0);
      case TrainingIntensity.low:
        return isDark 
            ? const Color(0xFF4A4A6A) 
            : const Color(0xFFB3C5E6);
      case TrainingIntensity.moderate:
        return isDark 
            ? const Color(0xFF6A7AA0) 
            : const Color(0xFF7B9FCC);
      case TrainingIntensity.onTarget:
        return isDark 
            ? AppColors.darkSuccess.withValues(alpha: 0.8)
            : AppColors.lightSuccess.withValues(alpha: 0.8);
      case TrainingIntensity.high:
        return isDark 
            ? const Color(0xFFFF6B6B) 
            : const Color(0xFFFF5252);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Front and back body views
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  _FrontBodyView(
                    chestIntensity: _getIntensity(MuscleGroup.chest),
                    shouldersIntensity: _getIntensity(MuscleGroup.shoulders),
                    armsIntensity: _getIntensity(MuscleGroup.arms),
                    coreIntensity: _getIntensity(MuscleGroup.core),
                    legsIntensity: _getIntensity(MuscleGroup.legs),
                    getColor: (intensity) => _getIntensityColor(intensity, isDark),
                  ),
                ],
              ),
            ),
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
                  _BackBodyView(
                    backIntensity: _getIntensity(MuscleGroup.back),
                    shouldersIntensity: _getIntensity(MuscleGroup.shoulders),
                    armsIntensity: _getIntensity(MuscleGroup.arms),
                    legsIntensity: _getIntensity(MuscleGroup.legs),
                    getColor: (intensity) => _getIntensityColor(intensity, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Legend
        _HeatMapLegend(
          isDark: isDark,
          getColor: (intensity) => _getIntensityColor(intensity, isDark),
        ),
      ],
    );
  }
}

/// Front body view showing chest, shoulders, arms, core, legs
class _FrontBodyView extends StatelessWidget {
  final TrainingIntensity chestIntensity;
  final TrainingIntensity shouldersIntensity;
  final TrainingIntensity armsIntensity;
  final TrainingIntensity coreIntensity;
  final TrainingIntensity legsIntensity;
  final Color Function(TrainingIntensity) getColor;

  const _FrontBodyView({
    required this.chestIntensity,
    required this.shouldersIntensity,
    required this.armsIntensity,
    required this.coreIntensity,
    required this.legsIntensity,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 220),
      painter: _FrontBodyPainter(
        chestColor: getColor(chestIntensity),
        shouldersColor: getColor(shouldersIntensity),
        armsColor: getColor(armsIntensity),
        coreColor: getColor(coreIntensity),
        legsColor: getColor(legsIntensity),
      ),
    );
  }
}

/// Back body view showing back, shoulders, arms, legs
class _BackBodyView extends StatelessWidget {
  final TrainingIntensity backIntensity;
  final TrainingIntensity shouldersIntensity;
  final TrainingIntensity armsIntensity;
  final TrainingIntensity legsIntensity;
  final Color Function(TrainingIntensity) getColor;

  const _BackBodyView({
    required this.backIntensity,
    required this.shouldersIntensity,
    required this.armsIntensity,
    required this.legsIntensity,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 220),
      painter: _BackBodyPainter(
        backColor: getColor(backIntensity),
        shouldersColor: getColor(shouldersIntensity),
        armsColor: getColor(armsIntensity),
        legsColor: getColor(legsIntensity),
      ),
    );
  }
}

/// Custom painter for front body view
class _FrontBodyPainter extends CustomPainter {
  final Color chestColor;
  final Color shouldersColor;
  final Color armsColor;
  final Color coreColor;
  final Color legsColor;

  _FrontBodyPainter({
    required this.chestColor,
    required this.shouldersColor,
    required this.armsColor,
    required this.coreColor,
    required this.legsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Head (circle)
    paint.color = Colors.grey.shade700;
    canvas.drawCircle(Offset(centerX, 20), 12, paint);

    // Shoulders (rounded rectangles)
    paint.color = shouldersColor;
    final shoulderWidth = 20.0;
    final shoulderHeight = 15.0;
    
    // Left shoulder
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 35, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 35, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      strokePaint,
    );
    
    // Right shoulder
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 15, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 15, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      strokePaint,
    );

    // Arms
    paint.color = armsColor;
    
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 45, 52, 12, 50),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 45, 52, 12, 50),
        const Radius.circular(6),
      ),
      strokePaint,
    );
    
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 33, 52, 12, 50),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 33, 52, 12, 50),
        const Radius.circular(6),
      ),
      strokePaint,
    );

    // Chest (torso upper section)
    paint.color = chestColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 25, 45, 50, 35),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 25, 45, 50, 35),
        const Radius.circular(10),
      ),
      strokePaint,
    );

    // Core (torso lower section)
    paint.color = coreColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 22, 82, 44, 30),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 22, 82, 44, 30),
        const Radius.circular(8),
      ),
      strokePaint,
    );

    // Legs
    paint.color = legsColor;
    
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 115, 18, 95),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 115, 18, 95),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, 115, 18, 95),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, 115, 18, 95),
        const Radius.circular(9),
      ),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for back body view
class _BackBodyPainter extends CustomPainter {
  final Color backColor;
  final Color shouldersColor;
  final Color armsColor;
  final Color legsColor;

  _BackBodyPainter({
    required this.backColor,
    required this.shouldersColor,
    required this.armsColor,
    required this.legsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Head (circle)
    paint.color = Colors.grey.shade700;
    canvas.drawCircle(Offset(centerX, 20), 12, paint);

    // Shoulders (back view - upper trapezius area)
    paint.color = shouldersColor;
    final shoulderWidth = 20.0;
    final shoulderHeight = 15.0;
    
    // Left shoulder
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 35, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 35, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      strokePaint,
    );
    
    // Right shoulder
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 15, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 15, 35, shoulderWidth, shoulderHeight),
        const Radius.circular(8),
      ),
      strokePaint,
    );

    // Arms (back of arms - triceps)
    paint.color = armsColor;
    
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 45, 52, 12, 50),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 45, 52, 12, 50),
        const Radius.circular(6),
      ),
      strokePaint,
    );
    
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 33, 52, 12, 50),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 33, 52, 12, 50),
        const Radius.circular(6),
      ),
      strokePaint,
    );

    // Back (entire torso)
    paint.color = backColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 25, 45, 50, 67),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 25, 45, 50, 67),
        const Radius.circular(10),
      ),
      strokePaint,
    );

    // Legs (hamstrings/glutes)
    paint.color = legsColor;
    
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 115, 18, 95),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 20, 115, 18, 95),
        const Radius.circular(9),
      ),
      strokePaint,
    );
    
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, 115, 18, 95),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, 115, 18, 95),
        const Radius.circular(9),
      ),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Legend showing intensity levels and colors
class _HeatMapLegend extends StatelessWidget {
  final bool isDark;
  final Color Function(TrainingIntensity) getColor;

  const _HeatMapLegend({
    required this.isDark,
    required this.getColor,
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
            'Training Load',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(
                color: getColor(TrainingIntensity.untrained),
                label: 'None',
              ),
              _LegendItem(
                color: getColor(TrainingIntensity.low),
                label: 'Low',
              ),
              _LegendItem(
                color: getColor(TrainingIntensity.moderate),
                label: 'Moderate',
              ),
              _LegendItem(
                color: getColor(TrainingIntensity.onTarget),
                label: 'On Target',
              ),
              _LegendItem(
                color: getColor(TrainingIntensity.high),
                label: 'High',
              ),
            ],
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
