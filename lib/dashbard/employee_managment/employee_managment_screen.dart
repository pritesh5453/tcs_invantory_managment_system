import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/add_employee.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/edit_employee.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class EmployeeManagmentScreen extends StatefulWidget {
  const EmployeeManagmentScreen({super.key});

  @override
  State<EmployeeManagmentScreen> createState() =>
      _EmployeeManagmentScreenState();
}

class _EmployeeManagmentScreenState extends State<EmployeeManagmentScreen> {
  File? aadharImage;
  final ImagePicker picker = ImagePicker();
  late bool canAddEmployee;
  late bool canEditEmployee;
  late bool canDeleteEmployee;

  final Dio dio = Dio();
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int limit = 10;

  List<Employee> employees = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    debugPrint("ALL PERMISSIONS => ${PermissionManager.allPermissions}");
    canAddEmployee = PermissionManager.hasPermission(
      "Employee Registration_Add",
    );

    canEditEmployee = PermissionManager.hasPermission(
      "Employee Registration_Edit",
    );

    canDeleteEmployee = PermissionManager.hasPermission(
      "Employee Registration_Delete",
    );

    fetchEmployees();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        !isLoading &&
        hasMoreData) {
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> fetchEmployees({String? search, bool reset = true}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
        employees = [];
      });
    }

    try {
      final Map<String, dynamic> queryParams = {
        "page": currentPage,
        "limit": limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams["search"] = search;
      }

      final response = await dio.get(
        "https://dashboard.theceramicstudio.in/api/employees/list",
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List list = response.data['employees'];
        final pagination = response.data['pagination'] ?? {};
        final totalPages = pagination['totalPages'] ?? 1;

        final newEmployees = list.map((e) => Employee.fromJson(e)).toList();

        setState(() {
          if (reset) {
            employees = newEmployees;
          } else {
            employees.addAll(newEmployees);
          }
          hasMoreData = currentPage < totalPages;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Dio Error: $e");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!hasMoreData || isLoadingMore || isLoading) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    await fetchEmployees(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      reset: false,
    );
  }

  // Debounced search function
  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
          currentPage = 1;
        });
        fetchEmployees(search: value, reset: true);
      }
    });
  }

  // Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      currentPage = 1;
    });
    fetchEmployees(reset: true);
  }

  Future<void> showDeleteDialog(BuildContext context, int employeeId) async {
    if (!canDeleteEmployee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have permission to delete employee."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        "https://dashboard.theceramicstudio.in/api/employees/delete/$employeeId",
      );

      debugPrint("📥 DELETE RESPONSE => ${response.data}");

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data["success"] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data["message"])));

        // ✅ list refresh after delete
        setState(() {
          isLoading = true;
          currentPage = 1;
        });
        await fetchEmployees(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          reset: true,
        );
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );

        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              /// ---------------- APP BAR WITH SEARCH ----------------
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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: "Search by name or phone...",
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon:
                                          _searchQuery.isNotEmpty
                                              ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear,
                                                  size: 16,
                                                ),
                                                onPressed: _clearSearch,
                                              )
                                              : null,
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap:
                              canAddEmployee
                                  ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const AddEmployeeScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      setState(() {
                                        currentPage = 1;
                                      });
                                      await fetchEmployees(
                                        search:
                                            _searchQuery.isNotEmpty
                                                ? _searchQuery
                                                : null,
                                        reset: true,
                                      );
                                    }
                                  }
                                  : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You don't have permission to add employee. Please contact support.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                          child: Opacity(
                            opacity: canAddEmployee ? 1 : 0.4,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// ---------------- LIST WITH PAGINATION ----------------
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    debugPrint("🔄 PULL TO REFRESH TRIGGERED");
                    setState(() {
                      isLoading = true;
                      currentPage = 1;
                    });
                    await fetchEmployees(
                      search: _searchQuery.isNotEmpty ? _searchQuery : null,
                      reset: true,
                    );
                  },
                  child:
                      isLoading && employees.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : employees.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: employees.length + (hasMoreData ? 1 : 0),
                            itemBuilder: (_, index) {
                              if (index == employees.length) {
                                // Show loading indicator at bottom
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child:
                                        isLoadingMore
                                            ? const CircularProgressIndicator()
                                            : const SizedBox.shrink(),
                                  ),
                                );
                              }

                              return EmployeeCard(
                                employee: employees[index],
                                onDelete:
                                    () => showDeleteDialog(
                                      context,
                                      employees[index].id,
                                    ),
                                canEditEmployee: canEditEmployee,
                                canDeleteEmployee: canDeleteEmployee,
                              );
                            },
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "No employees found for '$_searchQuery'"
                : "No employees found",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: _clearSearch,
              child: const Text("Clear Search"),
            ),
        ],
      ),
    );
  }
}

/// =======================================================
/// EMPLOYEE MODEL (UPDATED with all fields from API)
/// =======================================================
class Employee {
  final int id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String commission;
  final String birthdate;
  final String salary;
  final String expense;
  final String advance;
  final String? aadharPhoto;
  final String? pancardPhoto;
  final String? profilePhoto;
  final bool isActive;
  final String? createdAt;
  final String? fcmToken;
  final String? aadharUrl;
  final String? pancardUrl;
  final String? profileUrl;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.commission,
    required this.birthdate,
    required this.salary,
    required this.expense,
    required this.advance,
    this.aadharPhoto,
    this.pancardPhoto,
    this.profilePhoto,
    required this.isActive,
    this.createdAt,
    this.fcmToken,
    this.aadharUrl,
    this.pancardUrl,
    this.profileUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final parsedId = json['employee_id'] ?? json['id'];

    return Employee(
      id:
          parsedId is int
              ? parsedId
              : int.tryParse(parsedId?.toString() ?? '') ?? -1,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      commission: json['commission']?.toString() ?? '0',
      birthdate: json['birthdate']?.toString() ?? '',
      salary: json['salary']?.toString() ?? '0',
      expense: json['expense']?.toString() ?? '0',
      advance: json['advance']?.toString() ?? '0',
      aadharPhoto: json['aadhar_photo']?.toString(),
      pancardPhoto: json['pancard_photo']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      isActive: json['status'] == 'active',
      createdAt: json['createdAt']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      aadharUrl: json['aadhar_url']?.toString(),
      pancardUrl: json['pancard_url']?.toString(),
      profileUrl: json['profile_url']?.toString(),
    );
  }

  // Convert to Map for edit popup
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'commission': commission,
      'birthdate': birthdate,
      'salary': salary,
      'expense': expense,
      'advance': advance,
      'aadhar_photo': aadharPhoto,
      'pancard_photo': pancardPhoto,
      'profile_photo': profilePhoto,
      'status': isActive ? 'active' : 'blocked',
      'createdAt': createdAt,
      'fcmToken': fcmToken,
      'aadhar_url': aadharUrl,
      'pancard_url': pancardUrl,
      'profile_url': profileUrl,
    };
  }
}

/// =======================================================
/// EMPLOYEE CARD (UI SAME - no changes)
/// =======================================================
class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onDelete;
  final bool canEditEmployee;
  final bool canDeleteEmployee;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onDelete,
    required this.canEditEmployee,
    required this.canDeleteEmployee,
  });

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
                child: Opacity(
                  opacity: canEditEmployee ? 1 : 0.4,
                  child: OutlinedButton.icon(
                    onPressed:
                        canEditEmployee
                            ? () async {
                              debugPrint(
                                "🆔 EDIT CLICKED ID => ${employee.id}",
                              );

                              // 🔥 Send ALL employee data to edit popup
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditEmployeePopup(
                                        employeeData: employee.toMap(),
                                      ),
                                ),
                              );

                              // Refresh after edit
                              final state =
                                  context
                                      .findAncestorStateOfType<
                                        _EmployeeManagmentScreenState
                                      >();
                              if (state != null) {
                                state.setState(() {
                                  state.currentPage = 1;
                                });
                                await state.fetchEmployees(
                                  search:
                                      state._searchQuery.isNotEmpty
                                          ? state._searchQuery
                                          : null,
                                  reset: true,
                                );
                              }
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to edit employee.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: canDeleteEmployee ? 1 : 0.4,
                  child: OutlinedButton.icon(
                    onPressed:
                        canDeleteEmployee
                            ? onDelete
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to delete employee.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
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
      "https://dashboard.theceramicstudio.in/api/employees/status/$employeeId",
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
      if (state != null) {
        state.setState(() {
          state.isLoading = true;
          state.currentPage = 1;
        });
        await state.fetchEmployees(reset: true);
      }
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
/// HELPER (SAME)
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
