import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/bodyweight_log.dart';
import 'package:total_athlete/services/workout_service.dart';
import 'package:total_athlete/services/bodyweight_service.dart';
import 'package:total_athlete/services/exercise_service.dart';

class SpreadsheetImportService {
  // Singleton pattern
  static final SpreadsheetImportService _instance = SpreadsheetImportService._internal();

  factory SpreadsheetImportService() {
    return _instance;
  }

  SpreadsheetImportService._internal();

  final _uuid = const Uuid();
  final WorkoutService _workoutService = WorkoutService();
  final BodyweightService _bodyweightService = BodyweightService();
  final ExerciseService _exerciseService = ExerciseService();

  static const String _importHistoryKey = 'import_history';

  /// Parse spreadsheet file and return sheet info for selection
  Future<SpreadsheetInfo> parseSpreadsheetFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final extension = filePath.split('.').last.toLowerCase();
      
      debugPrint('=== SPREADSHEET IMPORT DEBUG ===');
      debugPrint('File name: $fileName');
      debugPrint('File path: $filePath');
      debugPrint('File extension: $extension');
      
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $filePath');
      }
      
      final bytes = await file.readAsBytes();
      debugPrint('File size: ${bytes.length} bytes');
      
      // Detect actual file type by examining file content
      final detectedType = _detectFileType(bytes, extension);
      debugPrint('Detected file type: $detectedType');
      
      if (detectedType == 'csv') {
        debugPrint('Using CSV parser');
        // CSV files only have one sheet
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);
        debugPrint('CSV rows parsed: ${rows.length}');
        
        return SpreadsheetInfo(
          sheets: [
            SheetInfo(
              name: 'Sheet1',
              index: 0,
              rowCount: rows.length,
              columnCount: rows.isNotEmpty ? rows.first.length : 0,
              headers: rows.isNotEmpty ? rows.first.map((e) => e.toString()).toList() : [],
            ),
          ],
          filePath: filePath,
          fileType: SpreadsheetFileType.csv,
        );
      } else if (detectedType == 'xlsx') {
        debugPrint('Using XLSX parser');
        // Excel files
        final excel = Excel.decodeBytes(bytes);
        final sheets = <SheetInfo>[];
        
        debugPrint('Excel sheets found: ${excel.tables.keys.length}');
        
        int index = 0;
        for (var tableName in excel.tables.keys) {
          final table = excel.tables[tableName];
          if (table == null || table.rows.isEmpty) continue;
          
          final headers = table.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
          
          debugPrint('Sheet "$tableName": ${table.rows.length} rows, ${headers.length} columns');
          
          sheets.add(SheetInfo(
            name: tableName,
            index: index,
            rowCount: table.rows.length,
            columnCount: headers.length,
            headers: headers,
          ));
          index++;
        }
        
        return SpreadsheetInfo(
          sheets: sheets,
          filePath: filePath,
          fileType: SpreadsheetFileType.xlsx,
        );
      } else {
        throw Exception(
          'Unsupported file type detected.\n\n'
          'File: $fileName\n'
          'Extension: .$extension\n'
          'Detected type: $detectedType\n\n'
          'Expected: .csv or .xlsx\n\n'
          'Please ensure you are selecting a valid CSV or Excel file.'
        );
      }
    } catch (e) {
      debugPrint('Error parsing spreadsheet file: $e');
      rethrow;
    }
  }
  
  /// Detect file type by examining file content (magic bytes)
  String _detectFileType(List<int> bytes, String extension) {
    if (bytes.isEmpty) return 'unknown';
    
    // Check for Excel file (ZIP signature: PK)
    // XLSX files are ZIP archives
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      debugPrint('File signature: ZIP archive (likely XLSX)');
      return 'xlsx';
    }
    
    // Check for XML/ODS signature (<?xml)
    if (bytes.length >= 5 && 
        bytes[0] == 0x3C && bytes[1] == 0x3F && 
        bytes[2] == 0x78 && bytes[3] == 0x6D && bytes[4] == 0x6C) {
      debugPrint('File signature: XML (possibly ODS or XML Spreadsheet)');
      return 'unsupported_xml';
    }
    
    // Check if file appears to be text-based (CSV)
    // CSV files should be plain text
    try {
      // Try to decode as UTF-8 text
      final text = String.fromCharCodes(bytes.take(1000));
      // Check if it contains typical CSV delimiters
      if (text.contains(',') || text.contains('\t') || text.contains(';')) {
        debugPrint('File appears to be text-based (CSV-like)');
        return 'csv';
      }
    } catch (e) {
      debugPrint('File does not appear to be text-based');
    }
    
    // Fallback to extension-based detection
    debugPrint('Using extension-based detection as fallback');
    if (extension == 'csv') return 'csv';
    if (extension == 'xlsx') return 'xlsx';
    
    return 'unknown';
  }

  /// Parse selected sheets and return import preview
  Future<ImportPreview> parseSelectedSheets(
    SpreadsheetInfo info,
    List<int> selectedSheetIndices,
  ) async {
    try {
      final allWorkouts = <ImportedWorkout>[];
      final allBodyweightLogs = <ImportedBodyweightLog>[];

      for (var sheetIndex in selectedSheetIndices) {
        final sheet = info.sheets[sheetIndex];
        final rows = await _getSheetRows(info, sheetIndex);
        
        if (rows.isEmpty) continue;

        // Detect format by examining headers
        final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
        
        if (_isWorkoutFormat(headers)) {
          final preview = await _parseWorkoutRows(rows);
          allWorkouts.addAll(preview.workouts);
        } else if (_isBodyweightFormat(headers)) {
          final preview = await _parseBodyweightRows(rows);
          allBodyweightLogs.addAll(preview.bodyweightLogs);
        }
      }

      // Sort by date
      allWorkouts.sort((a, b) => a.date.compareTo(b.date));
      allBodyweightLogs.sort((a, b) => a.date.compareTo(b.date));

      return ImportPreview(
        workouts: allWorkouts,
        bodyweightLogs: allBodyweightLogs,
        totalWorkouts: allWorkouts.length,
        totalSets: allWorkouts.fold(0, (sum, w) => sum + w.setCount),
        totalBodyweightLogs: allBodyweightLogs.length,
        dateRange: _getDateRange(allWorkouts, allBodyweightLogs),
      );
    } catch (e) {
      debugPrint('Error parsing selected sheets: $e');
      rethrow;
    }
  }

  Future<List<List<dynamic>>> _getSheetRows(SpreadsheetInfo info, int sheetIndex) async {
    final file = File(info.filePath);
    
    if (info.fileType == SpreadsheetFileType.csv) {
      final content = await file.readAsString();
      return const CsvToListConverter().convert(content);
    } else if (info.fileType == SpreadsheetFileType.xlsx) {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final tableName = excel.tables.keys.elementAt(sheetIndex);
      final table = excel.tables[tableName];
      if (table == null) return [];
      
      return table.rows.map((row) => 
        row.map((cell) => cell?.value).toList()
      ).toList();
    }
    
    return [];
  }

  /// Parse CSV content and return import preview (legacy method for backward compatibility)
  Future<ImportPreview> parseCSV(String csvContent) async {
    try {
      // Parse CSV
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Detect format by examining headers
      final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      
      if (_isWorkoutFormat(headers)) {
        return _parseWorkoutRows(rows);
      } else if (_isBodyweightFormat(headers)) {
        return _parseBodyweightRows(rows);
      } else {
        throw Exception('Unrecognized CSV format. Expected workout or bodyweight data.');
      }
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
      rethrow;
    }
  }

  bool _isWorkoutFormat(List<String> headers) {
    // Check if headers contain workout-related columns
    final workoutColumns = ['date', 'workout', 'exercise', 'set', 'weight', 'reps'];
    return workoutColumns.every((col) => headers.any((h) => h.contains(col)));
  }

  bool _isBodyweightFormat(List<String> headers) {
    // Check if headers contain bodyweight-related columns
    final bodyweightColumns = ['date', 'weight', 'bodyweight'];
    return headers.any((h) => bodyweightColumns.any((col) => h.contains(col)));
  }

  Future<ImportPreview> _parseWorkoutRows(List<List<dynamic>> rows) async {
    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1).toList();

    // Find column indices
    final dateIdx = _findColumnIndex(headers, ['date']);
    final workoutIdx = _findColumnIndex(headers, ['workout', 'split', 'title', 'name']);
    final exerciseIdx = _findColumnIndex(headers, ['exercise']);
    final setIdx = _findColumnIndex(headers, ['set', 'set number', 'set #']);
    final weightIdx = _findColumnIndex(headers, ['weight']);
    final repsIdx = _findColumnIndex(headers, ['reps', 'repetitions']);
    final completedIdx = _findColumnIndex(headers, ['completed', 'status']);
    final volumeIdx = _findColumnIndex(headers, ['volume']);

    if (dateIdx == -1 || exerciseIdx == -1 || weightIdx == -1 || repsIdx == -1) {
      throw Exception('Missing required columns: date, exercise, weight, reps');
    }

    // Load existing exercises for matching
    final existingExercises = await _exerciseService.getAllExercises();

    // Group rows by date and workout
    final Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};

    for (var row in dataRows) {
      if (row.isEmpty || row.length <= dateIdx) continue;

      final dateStr = row[dateIdx]?.toString().trim() ?? '';
      if (dateStr.isEmpty) continue;

      final workoutName = workoutIdx != -1 ? (row[workoutIdx]?.toString().trim() ?? 'Workout') : 'Workout';
      final exerciseName = row[exerciseIdx]?.toString().trim() ?? '';
      if (exerciseName.isEmpty) continue;

      final setNumber = setIdx != -1 ? _parseInt(row[setIdx]) : 1;
      final weight = _parseDouble(row[weightIdx]);
      final reps = _parseInt(row[repsIdx]);
      final isCompleted = completedIdx != -1 ? _parseBool(row[completedIdx]) : true;

      if (weight <= 0 || reps <= 0) continue;

      final date = _parseDate(dateStr);
      final dateKey = date.toIso8601String().split('T')[0];

      groupedData.putIfAbsent(dateKey, () => {});
      groupedData[dateKey]!.putIfAbsent(workoutName, () => []);
      
      groupedData[dateKey]![workoutName]!.add({
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'isCompleted': isCompleted,
        'date': date,
      });
    }

    // Convert grouped data to workouts
    final List<ImportedWorkout> importedWorkouts = [];

    for (var dateEntry in groupedData.entries) {
      for (var workoutEntry in dateEntry.value.entries) {
        final workoutName = workoutEntry.key;
        final sets = workoutEntry.value;
        
        // Group sets by exercise
        final Map<String, List<Map<String, dynamic>>> exerciseSets = {};
        for (var set in sets) {
          final exerciseName = set['exerciseName'] as String;
          exerciseSets.putIfAbsent(exerciseName, () => []);
          exerciseSets[exerciseName]!.add(set);
        }

        // Create workout exercises
        final List<WorkoutExercise> exercises = [];
        for (var exerciseEntry in exerciseSets.entries) {
          final exerciseName = exerciseEntry.key;
          final exerciseSetsData = exerciseEntry.value;

          // Find or create exercise
          Exercise? exercise = _findExerciseByName(existingExercises, exerciseName);
          if (exercise == null) {
            // Create a default exercise if not found
            exercise = Exercise(
              id: _uuid.v4(),
              name: exerciseName,
              primaryMuscleGroup: MuscleGroup.chest, // Default
              equipment: EquipmentType.barbell, // Default
              calorieCategory: CalorieCategory.compoundUpperBody, // Default
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }

          // Sort sets by set number
          exerciseSetsData.sort((a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int));

          // Create workout sets
          final List<WorkoutSet> workoutSets = [];
          for (var setData in exerciseSetsData) {
            final setDate = setData['date'] as DateTime;
            workoutSets.add(WorkoutSet(
              id: _uuid.v4(),
              setNumber: setData['setNumber'] as int,
              weight: setData['weight'] as double,
              unit: 'kg', // Default to kg for imported data
              reps: setData['reps'] as int,
              isCompleted: setData['isCompleted'] as bool,
              completedAt: setData['isCompleted'] as bool ? setDate : null,
              createdAt: setDate,
              updatedAt: setDate,
            ));
          }

          exercises.add(WorkoutExercise(
            id: _uuid.v4(),
            exercise: exercise,
            sets: workoutSets,
            createdAt: exerciseSetsData.first['date'] as DateTime,
            updatedAt: exerciseSetsData.first['date'] as DateTime,
          ));
        }

        final workoutDate = sets.first['date'] as DateTime;
        importedWorkouts.add(ImportedWorkout(
          name: workoutName,
          date: workoutDate,
          exercises: exercises,
          exerciseCount: exercises.length,
          setCount: sets.length,
        ));
      }
    }

    // Sort by date
    importedWorkouts.sort((a, b) => a.date.compareTo(b.date));

    return ImportPreview(
      workouts: importedWorkouts,
      bodyweightLogs: [],
      totalWorkouts: importedWorkouts.length,
      totalSets: importedWorkouts.fold(0, (sum, w) => sum + w.setCount),
      dateRange: importedWorkouts.isEmpty 
          ? null 
          : '${_formatDate(importedWorkouts.first.date)} - ${_formatDate(importedWorkouts.last.date)}',
    );
  }

  Future<ImportPreview> _parseBodyweightRows(List<List<dynamic>> rows) async {
    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1).toList();

    final dateIdx = _findColumnIndex(headers, ['date']);
    final weightIdx = _findColumnIndex(headers, ['weight', 'bodyweight', 'bw']);
    final notesIdx = _findColumnIndex(headers, ['notes', 'note', 'comment']);

    if (dateIdx == -1 || weightIdx == -1) {
      throw Exception('Missing required columns: date, weight');
    }

    final List<ImportedBodyweightLog> logs = [];

    for (var row in dataRows) {
      if (row.isEmpty || row.length <= dateIdx) continue;

      final dateStr = row[dateIdx]?.toString().trim() ?? '';
      if (dateStr.isEmpty) continue;

      final weight = _parseDouble(row[weightIdx]);
      if (weight <= 0) continue;

      final notes = notesIdx != -1 ? row[notesIdx]?.toString().trim() : null;
      final date = _parseDate(dateStr);

      logs.add(ImportedBodyweightLog(
        date: date,
        weight: weight,
        notes: notes,
      ));
    }

    // Sort by date
    logs.sort((a, b) => a.date.compareTo(b.date));

    return ImportPreview(
      workouts: [],
      bodyweightLogs: logs,
      totalBodyweightLogs: logs.length,
      dateRange: logs.isEmpty 
          ? null 
          : '${_formatDate(logs.first.date)} - ${_formatDate(logs.last.date)}',
    );
  }

  /// Import workouts and bodyweight logs into the app
  Future<ImportResult> importData(ImportPreview preview, String userId) async {
    try {
      // Check for duplicates
      final existingWorkouts = await _workoutService.getWorkoutsByUserId(userId);
      final existingBodyweightLogs = await _bodyweightService.getLogsByUserId(userId);

      // Track import history
      final importId = _uuid.v4();
      final importDate = DateTime.now();

      int importedWorkouts = 0;
      int skippedWorkouts = 0;
      int importedBodyweight = 0;
      int skippedBodyweight = 0;

      // Import workouts
      for (var importedWorkout in preview.workouts) {
        // Check for duplicate (same date and name)
        final isDuplicate = existingWorkouts.any((w) =>
          w.name == importedWorkout.name &&
          _isSameDay(w.startTime, importedWorkout.date)
        );

        if (isDuplicate) {
          skippedWorkouts++;
          continue;
        }

        // Create workout
        final workout = Workout(
          id: _uuid.v4(),
          userId: userId,
          name: importedWorkout.name,
          exercises: importedWorkout.exercises,
          startTime: importedWorkout.date,
          endTime: importedWorkout.date.add(const Duration(hours: 1)), // Estimate
          isCompleted: true,
          createdAt: importedWorkout.date,
          updatedAt: importedWorkout.date,
        );

        await _workoutService.addWorkout(workout);
        importedWorkouts++;
      }

      // Import bodyweight logs
      for (var log in preview.bodyweightLogs) {
        // Check for duplicate (same date)
        final isDuplicate = existingBodyweightLogs.any((bw) =>
          _isSameDay(bw.logDate, log.date)
        );

        if (isDuplicate) {
          skippedBodyweight++;
          continue;
        }

        final bodyweightLog = BodyweightLog(
          id: _uuid.v4(),
          userId: userId,
          weight: log.weight,
          unit: 'kg', // Default to kg for imported data
          logDate: log.date,
          notes: log.notes,
          createdAt: log.date,
          updatedAt: log.date,
        );

        await _bodyweightService.addLog(bodyweightLog);
        importedBodyweight++;
      }

      // Save import history
      await _saveImportHistory(ImportHistoryEntry(
        id: importId,
        date: importDate,
        workoutsImported: importedWorkouts,
        bodyweightLogsImported: importedBodyweight,
      ));

      return ImportResult(
        success: true,
        importedWorkouts: importedWorkouts,
        skippedWorkouts: skippedWorkouts,
        importedBodyweightLogs: importedBodyweight,
        skippedBodyweightLogs: skippedBodyweight,
      );
    } catch (e) {
      debugPrint('Error importing data: $e');
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _saveImportHistory(ImportHistoryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_importHistoryKey);
      
      final List<Map<String, dynamic>> history = historyJson != null
          ? (json.decode(historyJson) as List).cast<Map<String, dynamic>>()
          : [];
      
      history.add({
        'id': entry.id,
        'date': entry.date.toIso8601String(),
        'workoutsImported': entry.workoutsImported,
        'bodyweightLogsImported': entry.bodyweightLogsImported,
      });
      
      await prefs.setString(_importHistoryKey, json.encode(history));
    } catch (e) {
      debugPrint('Error saving import history: $e');
    }
  }

  // Helper methods
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (var name in possibleNames) {
      final idx = headers.indexWhere((h) => h.contains(name));
      if (idx != -1) return idx;
    }
    return -1;
  }

  Exercise? _findExerciseByName(List<Exercise> exercises, String name) {
    final normalizedName = name.toLowerCase().trim();
    try {
      return exercises.firstWhere(
        (e) => e.name.toLowerCase().trim() == normalizedName
      );
    } catch (e) {
      return null;
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    final str = value.toString().toLowerCase().trim();
    return str == 'true' || str == 'yes' || str == '1' || str == 'completed';
  }

  DateTime _parseDate(String dateStr) {
    // Try multiple date formats
    try {
      // ISO format: 2024-01-15
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // US format: 01/15/2024 or 1/15/2024
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (e) {
        // Ignore
      }
      
      try {
        // UK format: 15/01/2024
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (e) {
        // Ignore
      }
    }
    
    // Default to today if parsing fails
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _getDateRange(List<ImportedWorkout> workouts, List<ImportedBodyweightLog> logs) {
    final dates = <DateTime>[];
    dates.addAll(workouts.map((w) => w.date));
    dates.addAll(logs.map((l) => l.date));
    
    if (dates.isEmpty) return null;
    
    dates.sort();
    return '${_formatDate(dates.first)} - ${_formatDate(dates.last)}';
  }
}

// Spreadsheet file info models
enum SpreadsheetFileType { csv, xlsx }

class SpreadsheetInfo {
  final List<SheetInfo> sheets;
  final String filePath;
  final SpreadsheetFileType fileType;

  SpreadsheetInfo({
    required this.sheets,
    required this.filePath,
    required this.fileType,
  });
}

class SheetInfo {
  final String name;
  final int index;
  final int rowCount;
  final int columnCount;
  final List<String> headers;

  SheetInfo({
    required this.name,
    required this.index,
    required this.rowCount,
    required this.columnCount,
    required this.headers,
  });

  bool get isWorkoutFormat {
    final lowercaseHeaders = headers.map((h) => h.toLowerCase().trim()).toList();
    final workoutColumns = ['date', 'workout', 'exercise', 'set', 'weight', 'reps'];
    return workoutColumns.every((col) => lowercaseHeaders.any((h) => h.contains(col)));
  }

  bool get isBodyweightFormat {
    final lowercaseHeaders = headers.map((h) => h.toLowerCase().trim()).toList();
    final bodyweightColumns = ['date', 'weight', 'bodyweight'];
    return lowercaseHeaders.any((h) => bodyweightColumns.any((col) => h.contains(col)));
  }

  String get formatType {
    if (isWorkoutFormat) return 'Workout Data';
    if (isBodyweightFormat) return 'Bodyweight Data';
    return 'Unknown Format';
  }
}

// Data models for import
class ImportPreview {
  final List<ImportedWorkout> workouts;
  final List<ImportedBodyweightLog> bodyweightLogs;
  final int totalWorkouts;
  final int totalSets;
  final int totalBodyweightLogs;
  final String? dateRange;

  ImportPreview({
    required this.workouts,
    required this.bodyweightLogs,
    this.totalWorkouts = 0,
    this.totalSets = 0,
    this.totalBodyweightLogs = 0,
    this.dateRange,
  });
}

class ImportedWorkout {
  final String name;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  final int exerciseCount;
  final int setCount;

  ImportedWorkout({
    required this.name,
    required this.date,
    required this.exercises,
    required this.exerciseCount,
    required this.setCount,
  });
}

class ImportedBodyweightLog {
  final DateTime date;
  final double weight;
  final String? notes;

  ImportedBodyweightLog({
    required this.date,
    required this.weight,
    this.notes,
  });
}

class ImportResult {
  final bool success;
  final int importedWorkouts;
  final int skippedWorkouts;
  final int importedBodyweightLogs;
  final int skippedBodyweightLogs;
  final String? error;

  ImportResult({
    required this.success,
    this.importedWorkouts = 0,
    this.skippedWorkouts = 0,
    this.importedBodyweightLogs = 0,
    this.skippedBodyweightLogs = 0,
    this.error,
  });
}

class ImportHistoryEntry {
  final String id;
  final DateTime date;
  final int workoutsImported;
  final int bodyweightLogsImported;

  ImportHistoryEntry({
    required this.id,
    required this.date,
    required this.workoutsImported,
    required this.bodyweightLogsImported,
  });
}
