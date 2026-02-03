// utils/permission_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PermissionManager {
  static Map<String, bool> _permissions = {};
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsString = prefs.getString("permissions") ?? "{}";
    _permissions = Map<String, bool>.from(json.decode(permissionsString));
  }
  
  static bool hasViewPermission(String moduleName) {
    // Module name se permission key generate karo
    final viewPermissionKey = "${moduleName}_View";
    return _permissions[viewPermissionKey] ?? false;
  }
  
  static bool hasAnyPermission(String moduleName) {
    // Check karo kisi bhi permission ka (Add, Edit, View, Delete)
    final permissionKeys = [
      "${moduleName}_Add",
      "${moduleName}_Edit", 
      "${moduleName}_View",
      "${moduleName}_Delete",
    ];
    
    return permissionKeys.any((key) => _permissions[key] ?? false);
  }
  
  static Map<String, bool> get allPermissions => _permissions;
  
  static void updatePermissions(Map<String, dynamic> newPermissions) {
    _permissions = Map<String, bool>.from(newPermissions);
  }
}