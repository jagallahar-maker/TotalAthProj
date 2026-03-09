import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:total_athlete/models/user.dart';

class UserService {
  static const String _storageKey = 'current_user';

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      
      if (data == null) {
        final defaultUser = _getDefaultUser();
        await saveUser(defaultUser);
        return defaultUser;
      }
      
      return User.fromJson(json.decode(data) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load user: $e');
      return _getDefaultUser();
    }
  }

  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(user.toJson());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save user: $e');
    }
  }

  Future<void> updateUser(User user) async {
    await saveUser(user.copyWith(updatedAt: DateTime.now()));
  }

  User _getDefaultUser() {
    final now = DateTime.now();
    return User(
      id: 'user_1',
      name: 'Justin',
      email: 'j.a.gallahar@gmail.com',
      currentWeight: 84.2,
      goalWeight: 80.0,
      avatarInitials: 'JG',
      createdAt: now,
      updatedAt: now,
    );
  }
}
