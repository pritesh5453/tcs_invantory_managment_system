import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/Special_Access/permissons.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {
        "Accept": "application/json",
        // "Authorization": "Bearer YOUR_TOKEN",
      },
    ),
  );

  final TextEditingController searchCtrl = TextEditingController();

  bool isLoading = false;
  List<dynamic> employees = [];
  List<dynamic> filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  /// ================= FETCH EMPLOYEES =================
  Future<void> _fetchEmployees() async {
    setState(() => isLoading = true);

    try {
      final response = await dio.get(
        "/employees/list",
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        employees = response.data['employees'] ?? [];
        filteredEmployees = employees;
      }
    } catch (_) {
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= SEARCH FILTER =================
  void _onSearch(String value) {
    setState(() {
      filteredEmployees =
          employees.where((emp) {
            final name = (emp['name'] ?? "").toString().toLowerCase();
            final email = (emp['email'] ?? "").toString().toLowerCase();
            final query = value.toLowerCase();

            return name.contains(query) || email.contains(query);
          }).toList();
    });
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employees")),
      body: Column(
        children: [
          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Search by name or email",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          /// LIST
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredEmployees.isEmpty
                    ? const Center(child: Text("No employees found"))
                    : ListView.separated(
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];

                        return ListTile(
                          title: Text(
                            emp['name'] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(emp['email'] ?? ""),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EmployeeRolePermissionScreen(
                                      employeeId: emp['id'],
                                      employeeName: emp['name'],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
