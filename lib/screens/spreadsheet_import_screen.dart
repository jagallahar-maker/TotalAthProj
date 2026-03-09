import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/services/spreadsheet_import_service.dart';
import 'package:total_athlete/theme.dart';

class SpreadsheetImportScreen extends StatefulWidget {
  const SpreadsheetImportScreen({super.key});

  @override
  State<SpreadsheetImportScreen> createState() => _SpreadsheetImportScreenState();
}

class _SpreadsheetImportScreenState extends State<SpreadsheetImportScreen> {
  final SpreadsheetImportService _importService = SpreadsheetImportService();
  
  bool _isLoading = false;
  String? _errorMessage;
  ImportPreview? _preview;
  SpreadsheetInfo? _spreadsheetInfo;
  Set<int> _selectedSheetIndices = {};
  Map<String, String>? _fileDebugInfo;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _preview = null;
        _spreadsheetInfo = null;
        _selectedSheetIndices.clear();
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      
      // Collect debug information
      final debugInfo = <String, String>{
        'File name': file.name,
        'Extension': file.extension ?? 'none',
        'Size': '${file.size} bytes',
        'Path': file.path ?? 'null',
      };
      
      // Debug file information
      print('=== FILE PICKER RESULT ===');
      debugInfo.forEach((key, value) => print('$key: $value'));
      
      if (file.path == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not read file path. This may happen with cloud-stored files. '
                         'Please download the file to your device first and try again.';
          _fileDebugInfo = debugInfo;
        });
        return;
      }

      // Parse spreadsheet file to get sheet info
      final info = await _importService.parseSpreadsheetFile(file.path!);

      setState(() {
        _spreadsheetInfo = info;
        _isLoading = false;
        _fileDebugInfo = debugInfo;
        
        // Auto-select all sheets by default
        _selectedSheetIndices = Set.from(
          List.generate(info.sheets.length, (i) => i)
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _generatePreview() async {
    if (_spreadsheetInfo == null || _selectedSheetIndices.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _importService.parseSelectedSheets(
        _spreadsheetInfo!,
        _selectedSheetIndices.toList(),
      );

      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_preview == null) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;
    
    if (user == null) {
      setState(() => _errorMessage = 'User not found');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _importService.importData(_preview!, user.id);

      if (result.success) {
        // Refresh data
        await provider.loadWorkouts();
        await provider.loadBodyweightLogs();

        if (!mounted) return;

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.importedWorkouts > 0)
                  Text('✓ Imported ${result.importedWorkouts} workout${result.importedWorkouts == 1 ? '' : 's'}'),
                if (result.skippedWorkouts > 0)
                  Text('⊘ Skipped ${result.skippedWorkouts} duplicate workout${result.skippedWorkouts == 1 ? '' : 's'}'),
                if (result.importedBodyweightLogs > 0)
                  Text('✓ Imported ${result.importedBodyweightLogs} bodyweight log${result.importedBodyweightLogs == 1 ? '' : 's'}'),
                if (result.skippedBodyweightLogs > 0)
                  Text('⊘ Skipped ${result.skippedBodyweightLogs} duplicate log${result.skippedBodyweightLogs == 1 ? '' : 's'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close import screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _errorMessage = result.error);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetImport() {
    setState(() {
      _preview = null;
      _spreadsheetInfo = null;
      _selectedSheetIndices.clear();
      _errorMessage = null;
      _fileDebugInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'Import Spreadsheet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions card
                  _buildInstructionsCard(isDark),
                  
                  const SizedBox(height: 24),

                  // File picker button
                  if (_spreadsheetInfo == null && _preview == null) ...[
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Select Spreadsheet File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                          if (_fileDebugInfo != null) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              'Debug Information:',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._fileDebugInfo!.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ],
                  
                  // Debug info (success case)
                  if (_fileDebugInfo != null && _errorMessage == null && _spreadsheetInfo != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bug_report_outlined,
                                size: 16,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'File Debug Info',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._fileDebugInfo!.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // Sheet selection
                  if (_spreadsheetInfo != null && _preview == null) ...[
                    _buildSheetSelectionCard(isDark),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetImport,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedSheetIndices.isEmpty ? null : _generatePreview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Generate Preview'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Preview
                  if (_preview != null) ...[
                    _buildPreviewCard(isDark),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetImport,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmImport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Import Data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                'Supported File Formats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirement('✓ CSV (.csv)', isDark),
          _buildRequirement('✓ Excel (.xlsx)', isDark),
          const SizedBox(height: 16),
          Text(
            'Workout Data Format:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirement('Required: Date, Exercise, Weight, Reps', isDark),
          _buildRequirement('Optional: Workout, Set, Completed, Volume', isDark),
          const SizedBox(height: 12),
          Text(
            'Bodyweight Data Format:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirement('Required: Date, Weight', isDark),
          _buildRequirement('Optional: Notes', isDark),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Tip: For multi-sheet files, you can select which sheets to import',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetSelectionCard(bool isDark) {
    final info = _spreadsheetInfo!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select Sheets to Import',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSheetIndices.length == info.sheets.length) {
                      _selectedSheetIndices.clear();
                    } else {
                      _selectedSheetIndices = Set.from(
                        List.generate(info.sheets.length, (i) => i)
                      );
                    }
                  });
                },
                child: Text(
                  _selectedSheetIndices.length == info.sheets.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // File info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Type: ${info.fileType.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
                Text(
                  'Total Sheets: ${info.sheets.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sheet list
          ...info.sheets.map((sheet) => _buildSheetTile(sheet, isDark)),
        ],
      ),
    );
  }

  Widget _buildSheetTile(SheetInfo sheet, bool isDark) {
    final isSelected = _selectedSheetIndices.contains(sheet.index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedSheetIndices.add(sheet.index);
            } else {
              _selectedSheetIndices.remove(sheet.index);
            }
          });
        },
        title: Text(
          sheet.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${sheet.rowCount} rows × ${sheet.columnCount} columns',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sheet.isWorkoutFormat || sheet.isBodyweightFormat
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sheet.formatType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: sheet.isWorkoutFormat || sheet.isBodyweightFormat
                      ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildRequirement(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    final preview = _preview!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                'Import Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary stats
          if (preview.workouts.isNotEmpty) ...[
            _buildStatRow('Workouts', preview.totalWorkouts.toString(), Icons.fitness_center, isDark),
            _buildStatRow('Total Sets', preview.totalSets.toString(), Icons.format_list_numbered, isDark),
            _buildStatRow('Exercises per Workout', 
              (preview.totalSets / preview.totalWorkouts).toStringAsFixed(1), 
              Icons.toc, isDark),
          ],
          
          if (preview.bodyweightLogs.isNotEmpty) ...[
            _buildStatRow('Bodyweight Logs', preview.totalBodyweightLogs.toString(), Icons.monitor_weight, isDark),
          ],

          if (preview.dateRange != null) ...[
            const SizedBox(height: 8),
            _buildStatRow('Date Range', preview.dateRange!, Icons.date_range, isDark),
          ],

          const SizedBox(height: 16),

          // Sample data preview
          if (preview.workouts.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Sample Workouts (first 3):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...preview.workouts.take(3).map((workout) => _buildWorkoutPreview(workout, isDark)),
          ],

          if (preview.bodyweightLogs.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Sample Bodyweight Logs (first 3):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...preview.bodyweightLogs.take(3).map((log) => _buildBodyweightPreview(log, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreview(ImportedWorkout workout, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workout.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(workout.date)} • ${workout.exerciseCount} exercises • ${workout.setCount} sets',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 8),
          ...workout.exercises.take(2).map((ex) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              '• ${ex.exercise.name} (${ex.sets.length} sets)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          )),
          if (workout.exercises.length > 2)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '... and ${workout.exercises.length - 2} more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyweightPreview(ImportedBodyweightLog log, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDate(log.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ),
          Text(
            '${log.weight.toStringAsFixed(1)} kg',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
