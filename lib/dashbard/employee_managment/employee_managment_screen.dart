import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/add_employee.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/edit_employee.dart';

class EmployeeManagmentScreen extends StatefulWidget {
  const EmployeeManagmentScreen({super.key});

  @override
  State<EmployeeManagmentScreen> createState() =>
      _EmployeeManagmentScreenState();
}

class _EmployeeManagmentScreenState extends State<EmployeeManagmentScreen> {
  File? aadharImage;
  final ImagePicker picker = ImagePicker();

  final Dio dio = Dio();
  bool isLoading = true;
  List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await dio.get(
        "https://dashboarduat.theceramicstudio.in/api/employees/list",
      );

      if (response.statusCode == 200) {
        final List list = response.data['employees'];
        employees = list.map((e) => Employee.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Dio Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> showDeleteDialog(BuildContext context, int employeeId) async {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Employee"),
            content: const Text(
              "Are you sure you want to delete this employee?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(context);
                  await deleteEmployee(employeeId);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  Future<void> deleteEmployee(int employeeId) async {
    debugPrint("🗑️ DELETE CLICKED ID => $employeeId");

    if (employeeId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid Employee ID")));
      return;
    }

    try {
      final response = await dio.delete(
        "https://dashboarduat.theceramicstudio.in/api/employees/delete/$employeeId",
      );

      debugPrint("📥 DELETE RESPONSE => ${response.data}");

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data["success"] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data["message"])));

        // ✅ list refresh after delete
        setState(() => isLoading = true);
        await fetchEmployees();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete employee")),
        );
      }
    } catch (e) {
      debugPrint("❌ DELETE ERROR => $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            /// ---------------- APP BAR ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, size: 20, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                "Search..",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEmployeeScreen(),
                            ),
                          );

                          // ✅ optional: employee add hone ke baad list refresh
                          if (result == true) {
                            fetchEmployees();
                          }
                        },
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// ---------------- LIST ----------------
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  debugPrint("🔄 PULL TO REFRESH TRIGGERED");
                  setState(() => isLoading = true);
                  await fetchEmployees();
                },
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: employees.length,
                          itemBuilder: (_, index) {
                            return EmployeeCard(
                              employee: employees[index],
                              onDelete:
                                  () => showDeleteDialog(
                                    context,
                                    employees[index].id,
                                  ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// EMPLOYEE MODEL
/// =======================================================
class Employee {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String salary;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.salary,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final parsedId = json['employee_id'] ?? json['id'];

    return Employee(
      id:
          parsedId is int
              ? parsedId
              : int.tryParse(parsedId?.toString() ?? '') ??
                  -1, // ✅ SAFE FALLBACK
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      salary: json['salary']?.toString() ?? '0',
      isActive: json['status'] == 'active',
    );
  }
}

/// =======================================================
/// EMPLOYEE CARD
/// =======================================================
class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onDelete;

  const EmployeeCard({super.key, required this.employee, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = employee.isActive ? Colors.green : Colors.red;
    final statusText = employee.isActive ? "Active" : "Blocked";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "toggle") {
                    toggleEmployeeStatus(
                      context,
                      employee.id,
                      employee.isActive,
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<String>(
                        value: "toggle",
                        child: Row(
                          children: [
                            Icon(
                              employee.isActive
                                  ? Icons.block
                                  : Icons.check_circle,
                              color:
                                  employee.isActive ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              employee.isActive ? "Block" : "Unblock",
                              style: TextStyle(
                                color:
                                    employee.isActive
                                        ? Colors.red
                                        : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _infoColumn(
                  "Name",
                  employee.name,
                  "Salary",
                  "₹${employee.salary}",
                  isStrike: !employee.isActive,
                ),
              ),
              Expanded(
                child: _infoColumn(
                  "Mobile Number",
                  employee.phone,
                  "Email Address",
                  employee.email,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint("🆔 EDIT CLICKED ID => ${employee.id}");

                    final employeeModel = EmployeeModel(
                      id: employee.id, // ✅ DYNAMIC ID (FIXED)
                      firstName:
                          employee.name.split(' ').isNotEmpty
                              ? employee.name.split(' ').first
                              : '',
                      lastName:
                          employee.name.split(' ').length > 1
                              ? employee.name.split(' ').sublist(1).join(' ')
                              : '',
                      mobile: employee.phone,
                      email: employee.email,
                      dob: '',
                      password: '',
                      expense: '0',
                      salary: employee.salary,
                      commission: '0',
                      isActive: employee.isActive,
                    );

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditEmployeePopup(employee: employeeModel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> toggleEmployeeStatus(
  BuildContext context,
  int employeeId,
  bool isCurrentlyActive,
) async {
  final dio = Dio();

  final newStatus = isCurrentlyActive ? "blocked" : "active";

  debugPrint("🔁 STATUS API HIT");
  debugPrint("🆔 ID => $employeeId");
  debugPrint("📤 NEW STATUS => $newStatus");

  try {
    final response = await dio.patch(
      "https://dashboarduat.theceramicstudio.in/api/employees/status/$employeeId",
      data: {
        "status": newStatus, // ✅ SIMPLE MAP (JSON)
      },
      options: Options(
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        validateStatus: (_) => true, // 🔥 Dio exception avoid
      ),
    );

    debugPrint("📥 STATUS CODE => ${response.statusCode}");
    debugPrint("📥 STATUS RESPONSE => ${response.data}");

    if (response.statusCode == 200 &&
        response.data is Map &&
        response.data["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.data["message"])));

      // 🔁 refresh list
      final state =
          context.findAncestorStateOfType<_EmployeeManagmentScreenState>();
      state?.setState(() => state.isLoading = true);
      await state?.fetchEmployees();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update status")));
    }
  } catch (e) {
    debugPrint("❌ STATUS ERROR => $e");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Status update failed")));
  }
}

/// =======================================================
/// HELPER
/// =======================================================
Widget _infoColumn(
  String title1,
  String value1,
  String title2,
  String value2, {
  bool isStrike = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(
        value1,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: isStrike ? TextDecoration.lineThrough : null,
        ),
      ),
      const SizedBox(height: 8),
      Text(title2, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value2, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}
