# Spreadsheet Import Guide

## Overview
This tool allows you to import historical workout data from CSV spreadsheets into Total Athlete.

## Accessing the Import Tool
1. Open the app
2. Navigate to **Settings** screen
3. Scroll to **Developer Tools** section
4. Tap **Import from Spreadsheet**

## CSV Format Requirements

### Workout Data Format

**Required columns:**
- `Date` - Workout date (YYYY-MM-DD or MM/DD/YYYY format)
- `Exercise` - Exercise name (e.g., "Bench Press", "Squat")
- `Weight` - Weight lifted in kg or lb
- `Reps` - Number of repetitions

**Optional columns:**
- `Workout` or `Split` - Workout name/split (e.g., "Push Day", "Leg Day")
- `Set` or `Set Number` - Set number (defaults to 1 if not provided)
- `Completed` - Set completion status (true/false, yes/no, 1/0)
- `Volume` - Total volume (calculated automatically if not provided)

**Example CSV:**
```csv
Date,Workout,Exercise,Set,Weight,Reps,Completed
2024-01-15,Push Day,Bench Press,1,80,8,true
2024-01-15,Push Day,Bench Press,2,80,7,true
2024-01-15,Push Day,Bench Press,3,80,6,true
2024-01-15,Push Day,Incline Bench Press,1,60,10,true
2024-01-15,Push Day,Incline Bench Press,2,60,9,true
```

### Bodyweight Data Format

**Required columns:**
- `Date` - Log date (YYYY-MM-DD or MM/DD/YYYY format)
- `Weight` or `Bodyweight` - Bodyweight in kg or lb

**Optional columns:**
- `Notes` - Any notes about the log

**Example CSV:**
```csv
Date,Weight,Notes
2024-01-15,84.2,Morning weigh-in
2024-01-16,84.3,
2024-01-17,84.0,After workout
```

## Import Process

1. **Select CSV File**
   - Tap "Select CSV File" button
   - Choose your CSV file from device storage

2. **Preview Data**
   - Review the import preview
   - Check the number of workouts, sets, and date range
   - View sample data to confirm correct parsing

3. **Confirm Import**
   - Tap "Import Data" to confirm
   - Wait for import to complete

4. **View Results**
   - See summary of imported and skipped items
   - Duplicate workouts (same date & name) are automatically skipped

## Exercise Matching

- The importer will attempt to match exercise names to existing exercises in your database
- If an exercise is not found, a default exercise will be created
- Exercise names are case-insensitive and matched exactly

## Duplicate Prevention

- **Workouts:** Duplicates are detected by matching workout name and date
- **Bodyweight Logs:** Duplicates are detected by matching date
- Duplicate entries are automatically skipped during import

## Tips

1. **Date Formats:** Use YYYY-MM-DD format for best compatibility (e.g., 2024-01-15)
2. **Column Headers:** Column names are flexible - the importer looks for keywords (e.g., "weight", "reps")
3. **Data Validation:** Invalid rows (missing required data, weight/reps <= 0) are automatically skipped
4. **Backup First:** Consider exporting your current data before importing large datasets

## Troubleshooting

**Import fails with "Unrecognized CSV format"**
- Ensure your CSV has the required columns (Date, Exercise, Weight, Reps for workouts)
- Check that column headers contain the correct keywords

**Some rows are skipped**
- Check that all required fields have valid values
- Ensure weight and reps are greater than 0
- Verify date format is correct

**Exercises not matching correctly**
- Exercise names must match exactly (case-insensitive)
- Add exercises to your database first, then import workouts

**Import takes a long time**
- Large CSV files may take several seconds to process
- Be patient and wait for the success dialog

## Example CSV Templates

### Minimal Workout CSV
```csv
Date,Exercise,Weight,Reps
2024-01-15,Bench Press,80,8
2024-01-15,Bench Press,80,7
2024-01-15,Squat,120,5
```

### Complete Workout CSV
```csv
Date,Workout,Exercise,Set,Weight,Reps,Completed
2024-01-15,Push Day,Bench Press,1,80,8,true
2024-01-15,Push Day,Bench Press,2,80,7,true
2024-01-15,Push Day,Bench Press,3,80,6,true
```

### Bodyweight CSV
```csv
Date,Weight,Notes
2024-01-15,84.2,Morning
2024-01-16,84.3,
2024-01-17,84.0,After workout
```
