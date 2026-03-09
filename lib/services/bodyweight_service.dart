import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/models/bodyweight_log.dart';

class BodyweightService {
  static const String _storageKey = 'bodyweight_logs';
  final _uuid = const Uuid();

  Future<List<BodyweightLog>> getAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      // Only populate sample data on first run (when key doesn't exist)
      // If data exists but is empty array, keep it empty (user reset)
      if (data == null) {
        final sampleData = _getSampleLogs();
        await _saveLogs(sampleData);
        return sampleData;
      }
      
      final List<dynamic> jsonList = json.decode(data);
      final logs = jsonList.map((json) {
        try {
          return BodyweightLog.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Skipping corrupted bodyweight log entry: $e');
          return null;
        }
      }).whereType<BodyweightLog>().toList();
      
      if (logs.isEmpty && jsonList.isNotEmpty) {
        await prefs.setString(_storageKey, json.encode([]));
      }
      
      return logs;
    } catch (e) {
      debugPrint('Failed to load bodyweight logs: $e');
      return [];
    }
  }

  Future<List<BodyweightLog>> getLogsByUserId(String userId) async {
    final logs = await getAllLogs();
    return logs.where((l) => l.userId == userId).toList()..sort((a, b) => b.logDate.compareTo(a.logDate));
  }

  Future<List<BodyweightLog>> getRecentLogs(String userId, {int days = 30}) async {
    final logs = await getLogsByUserId(userId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return logs.where((l) => l.logDate.isAfter(cutoffDate)).toList();
  }

  Future<BodyweightLog?> getLatestLog(String userId) async {
    final logs = await getLogsByUserId(userId);
    return logs.isEmpty ? null : logs.first;
  }

  Future<void> addLog(BodyweightLog log) async {
    final logs = await getAllLogs();
    logs.add(log);
    await _saveLogs(logs);
  }

  Future<void> updateLog(BodyweightLog log) async {
    final logs = await getAllLogs();
    final index = logs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      logs[index] = log;
      await _saveLogs(logs);
    }
  }

  Future<void> deleteLog(String id) async {
    final logs = await getAllLogs();
    logs.removeWhere((l) => l.id == id);
    await _saveLogs(logs);
  }

  Future<void> _saveLogs(List<BodyweightLog> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(logs.map((l) => l.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save bodyweight logs: $e');
    }
  }

  List<BodyweightLog> _getSampleLogs() {
    final now = DateTime.now();
    final userId = 'user_1';
    
    return [
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.2, unit: 'kg', logDate: now, createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.3, unit: 'kg', logDate: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.5, unit: 'kg', logDate: now.subtract(const Duration(days: 2)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.0, unit: 'kg', logDate: now.subtract(const Duration(days: 3)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.3, unit: 'kg', logDate: now.subtract(const Duration(days: 4)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 85.0, unit: 'kg', logDate: now.subtract(const Duration(days: 5)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 84.8, unit: 'kg', logDate: now.subtract(const Duration(days: 6)), createdAt: now, updatedAt: now),
      BodyweightLog(id: _uuid.v4(), userId: userId, weight: 85.1, unit: 'kg', logDate: now.subtract(const Duration(days: 7)), createdAt: now, updatedAt: now),
    ];
  }
}
