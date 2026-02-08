// utils/permission_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PermissionManager {
  static Map<String, bool> _permissions = {};
  static String _role = "";

  /// Load permissions from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final permissionsString = prefs.getString("permissions") ?? "{}";
    final roleString = prefs.getString("role") ?? "";

    final Map<String, dynamic> decoded = json.decode(permissionsString);

    _permissions = decoded.map((key, value) => MapEntry(key, value == true));
    _role = roleString;
  }

  /// 🔥 SET ROLE (call after login)
  static void setRole(String role) async {
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);
  }

  /// 🔥 ADMIN / SUPERADMIN = ALL ACCESS
  static bool hasPermission(String permissionKey) {
    if (_role == "admin" || _role == "superadmin") {
      return true;
    }
    return _permissions[permissionKey] == true;
  }

  /// Check if user has ANY permission of a module
  static bool hasAnyPermission(String moduleName) {
    if (_role == "admin" || _role == "superadmin") {
      return true;
    }

    return _permissions.keys.any(
      (key) => key.startsWith(moduleName) && _permissions[key] == true,
    );
  }

  static Map<String, bool> get allPermissions => _permissions;
  static String get role => _role;

  /// Update permissions at login
  static void updatePermissions(Map<String, dynamic> newPermissions) async {
    _permissions = newPermissions.map(
      (key, value) => MapEntry(key, value == true),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("permissions", json.encode(newPermissions));
  }

  /// Clear on logout
  static Future<void> clear() async {
    _permissions.clear();
    _role = "";
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
