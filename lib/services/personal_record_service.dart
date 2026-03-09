import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/personal_record.dart';

class PersonalRecordService {
  static const String _storageKey = 'personal_records';
  final _uuid = const Uuid();

  Future<List<PersonalRecord>> getAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      // Start with empty PRs - they will be auto-detected from workout data
      if (data == null) {
        await _saveRecords([]);
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final records = jsonList.map((json) {
        try {
          return PersonalRecord.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted PR entry: $e');
          return null;
        }
      }).whereType<PersonalRecord>().toList();
      
      if (records.isEmpty && jsonList.isNotEmpty) {
        await prefs.setString(_storageKey, json.encode([]));
      }
      
      return records;
    } catch (e) {
      debugPrint('Failed to load personal records: $e');
      return [];
    }
  }

  Future<List<PersonalRecord>> getRecordsByUserId(String userId) async {
    final records = await getAllRecords();
    return records.where((r) => r.userId == userId).toList()..sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
  }

  Future<List<PersonalRecord>> getRecentRecords(String userId, {int limit = 5}) async {
    final records = await getRecordsByUserId(userId);
    return records.take(limit).toList();
  }

  Future<PersonalRecord?> getRecordForExercise(String userId, String exerciseId) async {
    final records = await getRecordsByUserId(userId);
    try {
      return records.firstWhere((r) => r.exerciseId == exerciseId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addRecord(PersonalRecord record) async {
    final records = await getAllRecords();
    records.add(record);
    await _saveRecords(records);
  }

  Future<void> updateRecord(PersonalRecord record) async {
    final records = await getAllRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _saveRecords(records);
    }
  }

  Future<void> deleteRecord(String id) async {
    final records = await getAllRecords();
    records.removeWhere((r) => r.id == id);
    await _saveRecords(records);
  }
  
  Future<void> clearAllRecords(String userId) async {
    final records = await getAllRecords();
    records.removeWhere((r) => r.userId == userId);
    await _saveRecords(records);
    debugPrint('🗑️ Cleared all PRs for user: $userId');
  }

  Future<void> _saveRecords(List<PersonalRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save personal records: $e');
    }
  }
}
