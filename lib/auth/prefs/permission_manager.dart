// utils/permission_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PermissionManager {
  static Map<String, bool> _permissions = {};

  /// Load permissions from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsString = prefs.getString("permissions") ?? "{}";

    final Map<String, dynamic> decoded = json.decode(permissionsString);

    _permissions = decoded.map((key, value) => MapEntry(key, value == true));
  }

  /// Check specific permission
  static bool hasPermission(String permissionKey) {
    return _permissions[permissionKey] == true;
  }

  /// Check if user has ANY permission of a module
  static bool hasAnyPermission(String moduleName) {
    return _permissions.keys.any(
      (key) => key.startsWith(moduleName) && _permissions[key] == true,
    );
  }

  static Map<String, bool> get allPermissions => _permissions;

  /// Update permissions at login
  static void updatePermissions(Map<String, dynamic> newPermissions) {
    _permissions = newPermissions.map(
      (key, value) => MapEntry(key, value == true),
    );
  }
}
