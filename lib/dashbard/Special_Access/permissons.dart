import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EmployeeRolePermissionScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const EmployeeRolePermissionScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeRolePermissionScreen> createState() =>
      _EmployeeRolePermissionScreenState();
}

class _EmployeeRolePermissionScreenState
    extends State<EmployeeRolePermissionScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        // "Authorization": "Bearer YOUR_TOKEN",
      },
    ),
  );

  bool isLoading = false;
  bool isSaving = false;

  /// All permissions map (dynamic)
  Map<String, bool> permissions = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployeePermissions();
  }

  /// ================= FETCH PERMISSIONS =================
  Future<void> _fetchEmployeePermissions() async {
    setState(() => isLoading = true);

    try {
      final response = await dio.get(
        "/roles/get-employee-roles/${widget.employeeId}",
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final Map<String, dynamic> perms = response.data['permissions'] ?? {};

        permissions = perms.map(
          (key, value) => MapEntry(key, value == true),
        );
      }
    } catch (_) {}
    finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= SAVE PERMISSIONS =================
  Future<void> _savePermissions() async {
    setState(() => isSaving = true);

    try {
      final body = {
        "employeeId": widget.employeeId.toString(),
        "permissions": permissions,
      };

      final response = await dio.post(
        "/roles/save-employee-roles",
        data: body,
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSnackbar("Permissions updated successfully", isError: false);
      } else {
        _showSnackbar(response.data['message'] ?? "Failed to save permissions");
      }
    } catch (_) {
      _showSnackbar("Network error");
    } finally {
      setState(() => isSaving = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Permissions - ${widget.employeeName}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissions.isEmpty
              ? const Center(child: Text("No permissions found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: permissions.keys.map((key) {
                          return CheckboxListTile(
                            title: Text(
                              key,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: permissions[key],
                            onChanged: (val) {
                              setState(() {
                                permissions[key] = val ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    /// SAVE BUTTON
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _savePermissions,
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Save Permissions"),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showSnackbar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
