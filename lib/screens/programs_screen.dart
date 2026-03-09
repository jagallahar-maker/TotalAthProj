import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/models/training_program.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/nav.dart';

// Shared UUID instance for generating IDs
final _uuid = Uuid();

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programs = provider.programs;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Programs',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organize your training routines',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showCreateProgramDialog(context, provider),
                    icon: Icon(Icons.add_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: programs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 64,
                          color: isDark ? AppColors.darkHint : AppColors.lightHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No programs yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first training program',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: programs.length,
                    itemBuilder: (context, index) {
                      final program = programs[index];
                      return ProgramCard(
                        program: program,
                        onTap: () => _navigateToProgramDetail(context, program),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Program',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a starter template or create from scratch',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ProgramTypeCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Starter Program',
                      subtitle: 'Use a template',
                      onTap: () {
                        Navigator.pop(context);
                        _showStarterProgramsDialog(context, provider);
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ProgramTypeCard(
                      icon: Icons.edit_rounded,
                      title: 'Custom Program',
                      subtitle: 'Build from scratch',
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomProgramDialog(context, provider);
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStarterProgramsDialog(BuildContext context, AppProvider provider) {
    final starters = provider.trainingProgramService.getStarterPrograms();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Starter Programs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: starters.length,
                  itemBuilder: (context, index) {
                    final starter = starters[index];
                    return StarterProgramCard(
                      starter: starter,
                      onTap: () async {
                        Navigator.pop(context);
                        await _createProgramFromStarter(context, provider, starter);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomProgramDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    ProgramGoal? selectedGoal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Custom Program',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Program Name',
                      hintText: 'e.g., PPL Split, 5x5 Strength',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What is this program for?',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProgramGoal>(
                    value: selectedGoal,
                    decoration: const InputDecoration(
                      labelText: 'Goal (Optional)',
                    ),
                    items: ProgramGoal.values.map((goal) {
                      return DropdownMenuItem(
                        value: goal,
                        child: Text(_goalToString(goal)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedGoal = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a program name')),
                        );
                        return;
                      }

                      final program = TrainingProgram(
                        id: _uuid.v4(),
                        userId: provider.currentUser?.id ?? 'user_1',
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isNotEmpty 
                          ? descriptionController.text.trim() 
                          : null,
                        goal: selectedGoal,
                        routineIds: [],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await provider.addProgram(program);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _navigateToProgramDetail(context, program);
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                    child: const Text('Create Program'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createProgramFromStarter(BuildContext context, AppProvider provider, dynamic starter) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating program...')),
        );
      }

      final result = await provider.trainingProgramService.createProgramFromStarter(
        userId: provider.currentUser?.id ?? 'user_1',
        starter: starter,
        exercises: provider.exercises,
      );

      // Add routines first
      for (final routine in result.routines) {
        await provider.addRoutine(routine);
      }

      // Then add the program
      await provider.addProgram(result.program);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "${result.program.name}" with ${result.routines.length} routines')),
        );
        _navigateToProgramDetail(context, result.program);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating program: $e')),
        );
      }
    }
  }

  void _navigateToProgramDetail(BuildContext context, TrainingProgram program) {
    context.push('${AppRoutes.programDetail}/${program.id}', extra: program);
  }

  String _goalToString(ProgramGoal goal) {
    switch (goal) {
      case ProgramGoal.strength:
        return 'Strength';
      case ProgramGoal.hypertrophy:
        return 'Hypertrophy';
      case ProgramGoal.cut:
        return 'Cut';
      case ProgramGoal.bulk:
        return 'Bulk';
      case ProgramGoal.generalFitness:
        return 'General Fitness';
    }
  }
}

class ProgramCard extends StatelessWidget {
  final TrainingProgram program;
  final VoidCallback onTap;

  const ProgramCard({super.key, required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routines = program.routineIds
        .map((id) => provider.routines.where((r) => r.id == id).firstOrNull)
        .whereType<Routine>()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (program.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            program.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (program.goal != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getGoalColor(program.goal!, isDark).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        _goalToString(program.goal!),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getGoalColor(program.goal!, isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${routines.length} ${routines.length == 1 ? 'routine' : 'routines'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGoalColor(ProgramGoal goal, bool isDark) {
    switch (goal) {
      case ProgramGoal.strength:
        return isDark ? AppColors.darkError : AppColors.lightError;
      case ProgramGoal.hypertrophy:
        return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
      case ProgramGoal.cut:
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case ProgramGoal.bulk:
        return Colors.orange;
      case ProgramGoal.generalFitness:
        return Colors.blue;
    }
  }

  String _goalToString(ProgramGoal goal) {
    switch (goal) {
      case ProgramGoal.strength:
        return 'Strength';
      case ProgramGoal.hypertrophy:
        return 'Hypertrophy';
      case ProgramGoal.cut:
        return 'Cut';
      case ProgramGoal.bulk:
        return 'Bulk';
      case ProgramGoal.generalFitness:
        return 'Fitness';
    }
  }
}

class ProgramDetailScreen extends StatelessWidget {
  final TrainingProgram program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get the latest version of the program from the provider
    final currentProgram = provider.programs.firstWhere(
      (p) => p.id == program.id,
      orElse: () => program,
    );
    
    final routines = currentProgram.routineIds
        .map((id) => provider.routines.where((r) => r.id == id).firstOrNull)
        .whereType<Routine>()
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(currentProgram.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditProgramDialog(context, provider, currentProgram),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _confirmDeleteProgram(context, provider, currentProgram),
          ),
        ],
      ),
      body: Column(
        children: [
          if (currentProgram.description != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ),
                child: Text(
                  currentProgram.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Routines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showAddRoutineDialog(context, provider, currentProgram),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Routine'),
                ),
              ],
            ),
          ),
          Expanded(
            child: routines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkHint : AppColors.lightHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No routines in this program',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: routines.length,
                    onReorder: (oldIndex, newIndex) => _reorderRoutines(context, provider, currentProgram, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return RoutineListItem(
                        key: ValueKey(routine.id),
                        routine: routine,
                        onRemove: () => _removeRoutine(context, provider, currentProgram, routine.id),
                        onStart: () => _startWorkoutFromRoutine(context, routine),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditProgramDialog(BuildContext context, AppProvider provider, TrainingProgram currentProgram) {
    final nameController = TextEditingController(text: currentProgram.name);
    final descriptionController = TextEditingController(text: currentProgram.description ?? '');
    ProgramGoal? selectedGoal = currentProgram.goal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Program',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Program Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProgramGoal>(
                    value: selectedGoal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: ProgramGoal.values.map((goal) {
                      return DropdownMenuItem(
                        value: goal,
                        child: Text(_goalToString(goal)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedGoal = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final updated = currentProgram.copyWith(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isNotEmpty 
                          ? descriptionController.text.trim() 
                          : null,
                        goal: selectedGoal,
                        updatedAt: DateTime.now(),
                      );
                      await provider.updateProgram(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProgram(BuildContext context, AppProvider provider, TrainingProgram currentProgram) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Are you sure you want to delete "${currentProgram.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteProgram(currentProgram.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showAddRoutineDialog(BuildContext context, AppProvider provider, TrainingProgram currentProgram) {
    final availableRoutines = provider.routines
        .where((r) => !currentProgram.routineIds.contains(r.id))
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Routine',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (availableRoutines.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No available routines',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkHint : AppColors.lightHint,
                    ),
                  ),
                )
              else
                ...availableRoutines.map((routine) {
                  return ListTile(
                    title: Text(routine.name),
                    subtitle: Text('${routine.exerciseCount} exercises'),
                    onTap: () async {
                      final updated = currentProgram.copyWith(
                        routineIds: [...currentProgram.routineIds, routine.id],
                        updatedAt: DateTime.now(),
                      );
                      await provider.updateProgram(updated);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _removeRoutine(BuildContext context, AppProvider provider, TrainingProgram currentProgram, String routineId) async {
    final updated = currentProgram.copyWith(
      routineIds: currentProgram.routineIds.where((id) => id != routineId).toList(),
      updatedAt: DateTime.now(),
    );
    await provider.updateProgram(updated);
  }

  void _reorderRoutines(BuildContext context, AppProvider provider, TrainingProgram currentProgram, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final routineIds = List<String>.from(currentProgram.routineIds);
    final item = routineIds.removeAt(oldIndex);
    routineIds.insert(newIndex, item);

    final updated = currentProgram.copyWith(
      routineIds: routineIds,
      updatedAt: DateTime.now(),
    );
    await provider.updateProgram(updated);
  }

  void _startWorkoutFromRoutine(BuildContext context, Routine routine) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final userId = provider.currentUser?.id ?? 'user_1';
    
    // Get all exercises in the routine
    final exercisesInRoutine = provider.exercises
        .where((e) => routine.exerciseIds.contains(e.id))
        .toList();

    // Create workout exercises with auto-generated sets from history
    final workoutExercises = <WorkoutExercise>[];
    final preferredUnit = provider.preferredUnit;
    
    for (final exercise in exercisesInRoutine) {
      // Get last occurrence of this exercise
      final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(userId, exercise.id);
      
      List<WorkoutSet> sets;
      if (lastOccurrence != null && lastOccurrence.sets.isNotEmpty) {
        // Use previous workout's sets as template (but mark as not completed)
        sets = lastOccurrence.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final previousSet = entry.value;
          return WorkoutSet(
            id: _uuid.v4(),
            setNumber: index + 1,
            weight: previousSet.weight,
            unit: previousSet.unit, // Preserve unit from previous set
            reps: previousSet.reps,
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } else {
        // No history - create 3 default sets using user's preferred unit
        sets = List.generate(3, (index) => WorkoutSet(
          id: _uuid.v4(),
          setNumber: index + 1,
          weight: 60.0,
          unit: preferredUnit, // Use user's preferred unit
          reps: 10,
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      workoutExercises.add(WorkoutExercise(
        id: _uuid.v4(),
        exercise: exercise,
        sets: sets,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // Create the workout
    final workout = Workout(
      id: _uuid.v4(),
      userId: userId,
      name: routine.name,
      exercises: workoutExercises,
      startTime: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await provider.addWorkout(workout);
    
    if (context.mounted) {
      context.push('/workout-session/${workout.id}');
    }
  }

  String _goalToString(ProgramGoal goal) {
    switch (goal) {
      case ProgramGoal.strength:
        return 'Strength';
      case ProgramGoal.hypertrophy:
        return 'Hypertrophy';
      case ProgramGoal.cut:
        return 'Cut';
      case ProgramGoal.bulk:
        return 'Bulk';
      case ProgramGoal.generalFitness:
        return 'General Fitness';
    }
  }
}

class RoutineListItem extends StatelessWidget {
  final Routine routine;
  final VoidCallback onRemove;
  final VoidCallback onStart;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.onRemove,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle_rounded,
          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
        ),
        title: Text(
          routine.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${routine.exerciseCount} exercises'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: onStart,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: onRemove,
              color: isDark ? AppColors.darkError : AppColors.lightError,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ProgramTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class StarterProgramCard extends StatelessWidget {
  final dynamic starter;
  final VoidCallback onTap;

  const StarterProgramCard({
    super.key,
    required this.starter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          starter.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          starter.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getGoalColor(starter.goal, isDark).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      _goalToString(starter.goal),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getGoalColor(starter.goal, isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${starter.routineTemplates.length} routines included',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGoalColor(ProgramGoal goal, bool isDark) {
    switch (goal) {
      case ProgramGoal.strength:
        return isDark ? AppColors.darkError : AppColors.lightError;
      case ProgramGoal.hypertrophy:
        return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
      case ProgramGoal.cut:
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case ProgramGoal.bulk:
        return Colors.orange;
      case ProgramGoal.generalFitness:
        return Colors.blue;
    }
  }

  String _goalToString(ProgramGoal goal) {
    switch (goal) {
      case ProgramGoal.strength:
        return 'Strength';
      case ProgramGoal.hypertrophy:
        return 'Hypertrophy';
      case ProgramGoal.cut:
        return 'Cut';
      case ProgramGoal.bulk:
        return 'Bulk';
      case ProgramGoal.generalFitness:
        return 'Fitness';
    }
  }
}
