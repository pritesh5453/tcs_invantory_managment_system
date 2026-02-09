import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_todo.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/wallet.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final int userId;
  final String role;
  final String userName;
  const EmployeeDashboardScreen({
    super.key,
    required this.userId,
    required this.role,
    required this.userName,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool showCompleteTask = false;
  bool isLoading = true;
  bool isPunchLoading = false;

  // Punch Status Variables
  String? punchStatus;

  // Employee Data
  int employeeId = 0;
  String employeeName = "";
  String employeeEmail = "";
  String employeePhone = "";
  String empId = "";

  // API Data
  List<dynamic> tasks = [];
  int customerCount = 0;
  int quotationCount = 0;
  int daysPresent = 0;
  String avgHours = "0";
  List<dynamic> notifications = [];

  // Selected task for completion
  Map<String, dynamic>? selectedTask;
  TextEditingController remarkController = TextEditingController();
  String selectedStatus = "done";

  // Dio instance
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboarduat.theceramicstudio.in',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Current date
  String currentDate = "";

  @override
  void initState() {
    super.initState();

    // Set current date
    currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    // Initialize data
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Step 1: Load employee data
      await _loadEmployeeData();

      if (employeeId == 0) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Step 2: Load all data in parallel
      await Future.wait([
        _fetchPunchStatus(),
        _fetchTasks(),
        _fetchDashboardStats(),
        _fetchAttendanceSummary(),
        _loadNotifications(),
      ]);
    } catch (e) {
      print("💥 ERROR in initialization: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPunchStatus() async {
    try {
      final response = await _dio.get('/api/employees/status/$employeeId');

      if (response.statusCode == 200) {
        final data = response.data;
        String? extractedStatus;

        if (data is Map && data['status'] != null) {
          extractedStatus = data['status'].toString();
        } else if (data is Map && data['data'] != null && data['data'] is Map) {
          final nestedData = data['data'] as Map;
          if (nestedData['status'] != null) {
            extractedStatus = nestedData['status'].toString();
          }
        } else if (data is Map && data['message'] != null) {
          final message = data['message'].toString().toLowerCase();
          if (message.contains('punched in')) {
            extractedStatus = "IN";
          } else if (message.contains('punched out') ||
              message.contains('completed')) {
            extractedStatus = "COMPLETED";
          }
        } else if (data is String) {
          extractedStatus = data;
        }

        setState(() {
          punchStatus = extractedStatus?.toUpperCase().trim() ?? "READY";
        });
      } else {
        setState(() {
          punchStatus = "READY";
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _tryAlternativeStatusEndpoints();
      } else {
        setState(() {
          punchStatus = "READY";
        });
      }
    } catch (e) {
      setState(() {
        punchStatus = "READY";
      });
    }
  }

  Future<void> _tryAlternativeStatusEndpoints() async {
    final endpoints = [
      '/api/attendance/status/$employeeId',
      '/api/employees/$employeeId/punch-status',
      '/api/attendance/today/$employeeId',
    ];

    for (var endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map && data['status'] != null) {
            setState(() {
              punchStatus = data['status'].toString().toUpperCase().trim();
            });
            return;
          }
        }
      } catch (e) {
        continue;
      }
    }

    setState(() {
      punchStatus = "READY";
    });
  }

  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final loadedId = prefs.getInt("userId") ?? 0;
      final loadedName = prefs.getString("userName") ?? "Employee Name";

      setState(() {
        employeeId = loadedId;
        employeeName = loadedName;
        employeeEmail = prefs.getString("userEmail") ?? "email@example.com";
        employeePhone = prefs.getString("userPhone") ?? "0000000000";
        empId = loadedId.toString();
      });
    } catch (e) {
      print("💥 Error loading employee data: $e");
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await _dio.get('/api/tasks/employee/$employeeId');
      if (response.statusCode == 200) {
        setState(() {
          tasks = response.data['tasks'] ?? [];
        });
      }
    } catch (e) {
      print("💥 Error fetching tasks: $e");
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await _dio.get(
        '/api/users/employee-dashboard/$employeeId',
      );
      if (response.statusCode == 200) {
        setState(() {
          customerCount = response.data['counts']['customers'] ?? 0;
          quotationCount = response.data['counts']['quotations'] ?? 0;
        });
      }
    } catch (e) {
      print("💥 Error fetching dashboard stats: $e");
    }
  }

  Future<void> _fetchAttendanceSummary() async {
    try {
      final response = await _dio.get(
        '/api/employees/attendance-summary/$employeeId',
      );
      if (response.statusCode == 200) {
        setState(() {
          daysPresent = response.data['daysPresent'] ?? 0;
          avgHours = response.data['avgHours']?.toString() ?? "0";
        });
      }
    } catch (e) {
      print("💥 Error fetching attendance: $e");
    }
  }

  Future<void> _punchIn() async {
    try {
      setState(() {
        isPunchLoading = true;
      });

      final response = await _dio.post(
        '/api/employees/punch-in',
        data: {"employeeId": employeeId, "image": null},
      );

      if (response.statusCode == 200) {
        _showSnackBar("✅ Punch In successful");
        await _fetchPunchStatus();
        await _fetchAttendanceSummary();
      } else {
        _showSnackBar("❌ Failed to Punch In");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = "Failed to Punch In";

        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? "Already punched in";
        }

        if (errorMessage.toLowerCase().contains('already punched in')) {
          _showSnackBar("✅ You are already punched in for today");
          setState(() {
            punchStatus = "IN";
          });
          await _fetchAttendanceSummary();
        } else {
          _showSnackBar("❌ $errorMessage");
        }
      } else {
        _showSnackBar("❌ Failed to Punch In");
      }
    } catch (e) {
      _showSnackBar("❌ Punch In failed");
    } finally {
      setState(() {
        isPunchLoading = false;
      });
    }
  }

  Future<void> _punchOut() async {
    try {
      setState(() {
        isPunchLoading = true;
      });

      final response = await _dio.post(
        '/api/employees/punch-out',
        data: {"employeeId": employeeId, "image": null},
      );

      if (response.statusCode == 200) {
        _showSnackBar("✅ Punch Out successful");
        await _fetchPunchStatus();
        await _fetchAttendanceSummary();
      } else {
        _showSnackBar("❌ Failed to Punch Out");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = "Failed to Punch Out";

        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? "Punch out error";
        }

        if (errorMessage.toLowerCase().contains('already punched out') ||
            errorMessage.toLowerCase().contains('not punched in')) {
          _showSnackBar("✅ You are already punched out for today");
          setState(() {
            punchStatus = "COMPLETED";
          });
          await _fetchAttendanceSummary();
        } else {
          _showSnackBar("❌ $errorMessage");
        }
      } else if (e.response?.statusCode == 404) {
        _showSnackBar("❌ Punch Out Error: Endpoint not found");
      } else {
        _showSnackBar("❌ Failed to Punch Out");
      }
    } catch (e) {
      _showSnackBar("❌ Punch Out failed");
    } finally {
      setState(() {
        isPunchLoading = false;
      });
    }
  }

  Future<void> _updateTaskStatus(int taskId, String status) async {
    try {
      debugPrint("🟡 UPDATE TASK START");
      //https://dashboarduat.theceramicstudio.in/api/tasks/update/9
      //https://dashboarduat.theceramicstudio.in
      final response = await _dio.put(
        '/api/tasks/update/$taskId',
        data: {
          "status": status.toLowerCase() == "done" ? "Done" : "Pending",
          "remark": remarkController.text.trim(),
        },
      );

      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("DATA   : ${response.data}");

      if (response.statusCode == 200 && response.data["success"] == true) {
        _showSnackBar("✅ Task updated successfully");

        await _fetchTasks();
        remarkController.clear();

        setState(() {
          showCompleteTask = false;
          selectedTask = null;
          selectedStatus = "done";
        });
      }
    } on DioException catch (e) {
      debugPrint("❌ DIO ERROR");
      debugPrint("Status : ${e.response?.statusCode}");
      debugPrint("Data   : ${e.response?.data}");
      _showSnackBar("❌ Failed to update task");
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _dio.get(
        '/api/users/GetNotification',
        queryParameters: {
          'role': 'Employee',
          'employeeId': employeeId,
          'page': 1,
          'limit': 10,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      print("💥 Error fetching notifications: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Navigate to Todo Page
  void _navigateToTodoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TodoPage(userId: widget.userId, role: widget.role),
      ),
    );
  }

  // Navigate to Wallet Page
  void _navigateToWalletPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WalletScreen(
              userName: widget.userName,
              userId: widget.userId.toString(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            _dashboardBody(),

            if (showCompleteTask)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showCompleteTask = false;
                      selectedTask = null;
                      remarkController.clear();
                      selectedStatus = "done";
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

            if (showCompleteTask) Center(child: _completeTaskCard()),

            // Only one loader for initial loading
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    return Column(
      children: [
        // Header with Todo and Wallet buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xffFFA34D),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              // Title on the left
              const Expanded(
                child: Text(
                  "Employee Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Todo Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _navigateToTodoPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xffFFA34D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: const Text(
                    "Todo",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Wallet Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _navigateToWalletPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: const Text(
                    "Wallet",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Notifications Icon with Badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      _showNotificationsDialog();
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (notifications.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notifications.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _userCard(),

                const SizedBox(height: 16),

                // Daily Workspace
                _dailyWorkspace(),

                const SizedBox(height: 16),

                _statsRow(),

                const SizedBox(height: 16),

                _taskCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employeeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("EMP ID : $empId", style: const TextStyle(fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(employeeEmail, style: const TextStyle(fontSize: 12)),
              Text(employeePhone, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailyWorkspace() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daily Workspace",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  "Today is $currentDate",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Punch buttons logic
          Builder(
            builder: (context) {
              // Show loader on punch button if punch is loading
              if (isPunchLoading) {
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              // If punch status is null (still loading or error)
              if (punchStatus == null) {
                return ElevatedButton(
                  onPressed: () async {
                    await _fetchPunchStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Refresh",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                );
              }

              // Process the punch status
              String status = punchStatus!.toUpperCase().trim();

              // COMPLETED status
              if (status == "COMPLETED" ||
                  status == "DONE" ||
                  status == "OUT" ||
                  status.contains("COMPLETE") ||
                  status.contains("OUT")) {
                return _workFinishedBadge();
              }
              // IN status (already punched in)
              else if (status == "IN" ||
                  status.contains("IN") ||
                  status == "PUNCHED_IN") {
                return Row(
                  children: [
                    _punchButton(
                      text: "Punch In",
                      color: Colors.grey,
                      icon: Icons.check_circle,
                      onTap: null,
                      disabled: true,
                    ),
                    const SizedBox(width: 10),
                    _punchButton(
                      text: "Punch Out",
                      color: const Color(0xffE62828),
                      icon: Icons.check_circle,
                      onTap: _punchOut,
                      disabled: false,
                    ),
                  ],
                );
              }
              // READY or any other status
              else {
                return Row(
                  children: [
                    _punchButton(
                      text: "Punch In",
                      color: const Color(0xff2ED11B),
                      icon: Icons.check_circle,
                      onTap: _punchIn,
                      disabled: false,
                    ),
                    const SizedBox(width: 10),
                    _punchButton(
                      text: "Punch Out",
                      color: Colors.grey,
                      icon: Icons.check_circle,
                      onTap: null,
                      disabled: true,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _workFinishedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 6),
          Text("Work Finished for Today", style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _punchButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
    required bool disabled,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow:
                disabled
                    ? []
                    : [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statCard("CUSTOMERS", customerCount.toString()),
        _statCard("QUOTATIONS", quotationCount.toString()),
        _statCard("ATTENDANCE", "$daysPresent Days\nAvg: ${avgHours}h"),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard() {
    final pendingTasks =
        tasks.where((task) => task['status'] == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "My Assigned Tasks",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFE7C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text("Pending: ", style: TextStyle(fontSize: 10)),
                    Text(
                      "$pendingTasks",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffFFF6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "TASK DETAILS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DATE ASSIGNED",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "ACTION",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No tasks assigned",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._buildTaskList(),
        ],
      ),
    );
  }

  List<Widget> _buildTaskList() {
    List<Widget> taskWidgets = [];

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final isCompleted = task['status'] == 'done';

      taskWidgets.add(_taskRow(task: task, isCompleted: isCompleted));

      if (i < tasks.length - 1) {
        taskWidgets.add(_taskDivider());
      }
    }

    return taskWidgets;
  }

  Widget _taskRow({
    required Map<String, dynamic> task,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? "Task",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"${task['description'] ?? "No description"}"',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              _formatDate(task['created_at'] ?? ""),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  isCompleted
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "COMPLETED",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              selectedTask = task;
                              selectedStatus = task['status'] ?? 'pending';
                              showCompleteTask = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Mark as Done",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskDivider() {
    return Divider(color: Colors.grey.withOpacity(0.25), height: 1);
  }

  Widget _completeTaskCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Complete Task - ${selectedTask?['title'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showCompleteTask = false;
                    selectedTask = null;
                    remarkController.clear();
                    selectedStatus = "done";
                  });
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "done", child: Text("Done")),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedStatus = newValue ?? "done";
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Please provide a brief remark on what was done",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: remarkController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Type your remark here...",
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (remarkController.text.isEmpty) {
                  _showSnackBar("Please enter a remark");
                  return;
                }
                if (selectedTask != null) {
                  _updateTaskStatus(selectedTask!['id'], selectedStatus);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
              ),
              child: const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Notifications"),
          content:
              notifications.isEmpty
                  ? const Text("No notifications")
                  : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          title: Text(notification['title'] ?? 'Notification'),
                          subtitle: Text(notification['message'] ?? ''),
                          trailing: Text(
                            _formatDate(notification['createdAt'] ?? ''),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
