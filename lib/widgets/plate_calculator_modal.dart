import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/utils/unit_conversion.dart';
import 'package:total_athlete/models/exercise.dart';

class PlateCalculatorModal extends StatefulWidget {
  final double targetWeight;
  final EquipmentType equipmentType;

  const PlateCalculatorModal({
    super.key,
    required this.targetWeight,
    this.equipmentType = EquipmentType.barbell,
  });

  @override
  State<PlateCalculatorModal> createState() => _PlateCalculatorModalState();
}

class _PlateCalculatorModalState extends State<PlateCalculatorModal> {
  // Default bar weights in kg and lb
  static const double kgBarbellWeight = 20.0;
  static const double lbBarbellWeight = 45.0;

  // Available plates
  static const List<double> kgPlates = [25, 20, 15, 10, 5, 2.5, 1.25];
  static const List<double> lbPlates = [45, 35, 25, 10, 5, 2.5];

  late bool _isKg;
  late double _targetWeight;
  late double _barWeight;
  late TextEditingController _barWeightController;
  bool _isEditingBarWeight = false;

  @override
  void initState() {
    super.initState();
    // Initialize with user's preferred unit
    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;
    _isKg = provider.preferredUnit == 'kg';
    
    // Convert target weight from storage (kg) to display unit
    _targetWeight = UnitConversion.toDisplayUnit(widget.targetWeight, provider.preferredUnit);
    
    // Set default bar weight based on equipment type
    if (widget.equipmentType == EquipmentType.smithMachine && user != null) {
      _barWeight = _isKg ? user.smithMachineBarWeightKg : user.smithMachineBarWeightLb;
    } else {
      _barWeight = _isKg ? kgBarbellWeight : lbBarbellWeight;
    }
    
    _barWeightController = TextEditingController(text: _barWeight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _barWeightController.dispose();
    super.dispose();
  }

  void _toggleUnit() {
    setState(() {
      _isKg = !_isKg;
      if (_isKg) {
        // Convert lb to kg
        _targetWeight = _targetWeight * 0.453592;
        _barWeight = _barWeight * 0.453592;
      } else {
        // Convert kg to lb
        _targetWeight = _targetWeight / 0.453592;
        _barWeight = _barWeight / 0.453592;
      }
      _barWeightController.text = _barWeight.toStringAsFixed(1);
    });
  }

  void _updateBarWeight(String value) {
    final newWeight = double.tryParse(value);
    if (newWeight != null && newWeight >= 0) {
      setState(() {
        _barWeight = newWeight;
      });
    }
  }

  Map<double, int> _calculatePlates() {
    final availablePlates = _isKg ? kgPlates : lbPlates;
    
    // Calculate weight to distribute per side
    double weightPerSide = (_targetWeight - _barWeight) / 2;
    
    if (weightPerSide <= 0) {
      return {};
    }

    Map<double, int> platesNeeded = {};
    
    // Greedy algorithm to find plate combination
    for (double plate in availablePlates) {
      int count = (weightPerSide / plate).floor();
      if (count > 0) {
        platesNeeded[plate] = count;
        weightPerSide -= plate * count;
      }
    }

    return platesNeeded;
  }

  double _getActualWeight() {
    final plates = _calculatePlates();
    double platesWeight = 0;
    plates.forEach((plate, count) {
      platesWeight += plate * count * 2; // Both sides
    });
    return _barWeight + platesWeight;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plates = _calculatePlates();
    final actualWeight = _getActualWeight();
    final weightDifference = (_targetWeight - actualWeight).abs();
    final isExactMatch = weightDifference < 0.1;

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: AppSpacing.paddingLg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Plate Calculator',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Target weight display
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? AppColors.darkPrimary.withValues(alpha: 0.15) : AppColors.lightPrimary.withValues(alpha: 0.1),
                          isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.lightPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Target Weight',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _targetWeight.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isKg ? 'kg' : 'lb',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _toggleUnit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text('Switch to ${_isKg ? 'LB' : 'KG'}'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bar weight (editable)
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.equipmentType == EquipmentType.smithMachine 
                                  ? 'Smith Machine Bar'
                                  : 'Bar Weight',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _barWeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    borderSide: BorderSide(
                                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    borderSide: BorderSide(
                                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    borderSide: BorderSide(
                                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: _updateBarWeight,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isKg ? 'kg' : 'lb',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Weight per side
                  _buildInfoRow(
                    context,
                    isDark,
                    'Weight Per Side',
                    '${((_targetWeight - _barWeight) / 2).toStringAsFixed(1)} ${_isKg ? 'kg' : 'lb'}',
                    Icons.balance_rounded,
                  ),

                  const SizedBox(height: 24),

                  // Plates needed header
                  Row(
                    children: [
                      Icon(
                        Icons.view_list_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Plates Per Side',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Plates list or empty state
                  if (plates.isEmpty)
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bar only - no additional plates needed',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...plates.entries.map((entry) => _buildPlateRow(
                      context,
                      isDark,
                      entry.key,
                      entry.value,
                    )),

                  const SizedBox(height: 24),

                  // Actual weight achieved
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: isExactMatch
                          ? (isDark ? AppColors.darkSuccess.withValues(alpha: 0.15) : AppColors.lightSuccess.withValues(alpha: 0.1))
                          : (isDark ? AppColors.darkAccent.withValues(alpha: 0.15) : AppColors.lightAccent.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isExactMatch
                            ? (isDark ? AppColors.darkSuccess.withValues(alpha: 0.3) : AppColors.lightSuccess.withValues(alpha: 0.3))
                            : (isDark ? AppColors.darkAccent.withValues(alpha: 0.3) : AppColors.lightAccent.withValues(alpha: 0.3)),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Actual Weight',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${actualWeight.toStringAsFixed(1)} ${_isKg ? 'kg' : 'lb'}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isExactMatch
                                        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                                        : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                                  ),
                                ),
                                if (isExactMatch) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        if (!isExactMatch) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Closest loadable weight (${weightDifference.toStringAsFixed(1)} ${_isKg ? 'kg' : 'lb'} ${actualWeight < _targetWeight ? 'under' : 'over'})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, bool isDark, String label, String value, IconData icon) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateRow(BuildContext context, bool isDark, double plate, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: Row(
        children: [
          // Plate weight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.2) : AppColors.lightPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${plate.toStringAsFixed(plate % 1 == 0 ? 0 : 2)} ${_isKg ? 'kg' : 'lb'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Multiply symbol
          Icon(
            Icons.close_rounded,
            size: 16,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(width: 12),
          // Count
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Visual plate indicators
          Row(
            children: List.generate(
              count.clamp(0, 5), // Show max 5 visual indicators
              (index) => Container(
                margin: const EdgeInsets.only(left: 4),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          if (count > 5)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '+${count - 5}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
