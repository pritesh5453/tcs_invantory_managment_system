import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_todo.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/empdash/punch_in.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/services/dashboardapi.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/services/punchInService.dart';
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

  // Services
  final PunchAttendanceService _punchService = PunchAttendanceService();
  final DashboardApiService _apiService = DashboardApiService();

  // Current date
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadEmployeeData();

      // ✅ FIX: Check for 0 instead of null (int can't be null)
      if (employeeId == 0) {
        setState(() => isLoading = false);
        return;
      }

      await Future.wait([
        _fetchTasks(),
        _fetchDashboardStats(),
        _fetchAttendanceSummary(),
        _loadNotifications(),
      ]);
    } catch (e) {
      print("💥 ERROR in initialization: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final loadedId = prefs.getInt("userId");
      final loadedName = prefs.getString("userName");
      final loadedEmail = prefs.getString("userEmail");
      final loadedPhone = prefs.getString("userPhone");

      if (loadedId == null || loadedId == 0) {
        print("❌ USER ID NOT FOUND OR INVALID IN PREFS");
        return;
      }

      if (!mounted) return;

      setState(() {
        employeeId = loadedId;
        employeeName = loadedName ?? "Employee Name";
        employeeEmail = loadedEmail ?? "email@example.com";
        employeePhone = loadedPhone ?? "0000000000";
        empId = loadedId.toString();
      });

      print("✅ EMPLOYEE ID LOADED => $employeeId");
    } catch (e) {
      print("💥 Error loading employee data: $e");
    }
  }

  Future<void> _fetchTasks() async {
    final fetchedTasks = await _apiService.fetchTasks(employeeId);
    if (fetchedTasks != null) {
      setState(() => tasks = fetchedTasks);
    }
  }

  Future<void> _fetchDashboardStats() async {
    final stats = await _apiService.fetchDashboardStats(employeeId);
    if (stats != null) {
      setState(() {
        customerCount = stats['customers'] ?? 0;
        quotationCount = stats['quotations'] ?? 0;
      });
    }
  }

  Future<void> _fetchAttendanceSummary() async {
    final attendance = await _apiService.fetchAttendanceSummary(employeeId);
    if (attendance != null) {
      setState(() {
        daysPresent = attendance['daysPresent'] ?? 0;
        avgHours = attendance['avgHours']?.toString() ?? "0";
      });
    }
  }

  Future<void> _updateTaskStatus(int taskId, String status) async {
    try {
      final success = await _apiService.updateTaskStatus(
        taskId,
        status,
        remarkController.text.trim(),
      );

      if (success) {
        _showSnackBar("✅ Task updated successfully");
        await _fetchTasks();
        remarkController.clear();

        setState(() {
          showCompleteTask = false;
          selectedTask = null;
          selectedStatus = "done";
        });
      } else {
        _showSnackBar("❌ Failed to update task");
      }
    } catch (e) {
      _showSnackBar("❌ Error updating task");
    }
  }

  Future<void> _loadNotifications() async {
    final fetchedNotifications = await _apiService.fetchNotifications(
      role: 'Employee',
      employeeId: employeeId,
    );
    if (fetchedNotifications != null) {
      setState(() => notifications = fetchedNotifications);
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
            if (showCompleteTask) _taskCompletionOverlay(),
            if (isLoading) _loadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    return Column(
      children: [
        _headerSection(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _userCard(),
                const SizedBox(height: 16),
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

  Widget _headerSection() {
    return Container(
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
          _todoButton(),
          _walletButton(),
          _notificationIcon(),
        ],
      ),
    );
  }

  Widget _todoButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: _navigateToTodoPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xffFFA34D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.task_alt, size: 16),
        label: const Text(
          "Todo",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _walletButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: _navigateToWalletPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.account_balance_wallet, size: 16),
        label: const Text(
          "Wallet",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _notificationIcon() {
    return Stack(
      children: [
        IconButton(
          onPressed: _showNotificationsDialog,
          icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
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
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          // ✅ FIX: Use employeeId != 0 and wrap in SizedBox with fixed width
          SizedBox(
            width: 180,
            child:
                employeeId != 0
                    ? PunchAttendanceWidget(
                      employeeId: employeeId,
                      onPunchSuccess: _fetchAttendanceSummary,
                      showSnackBar: _showSnackBar,
                    )
                    : const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
          ),
        ],
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
          _taskHeader(),
          const SizedBox(height: 10),
          if (tasks.isEmpty) _noTasksMessage() else ..._buildTaskList(),
        ],
      ),
    );
  }

  Widget _taskHeader() {
    return Container(
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
    );
  }

  Widget _noTasksMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text("No tasks assigned", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  List<Widget> _buildTaskList() {
    List<Widget> taskWidgets = [];
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final isCompleted = task['status'] == 'done';
      taskWidgets.add(_taskRow(task: task, isCompleted: isCompleted));
      if (i < tasks.length - 1) taskWidgets.add(_taskDivider());
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
              child: isCompleted ? _completedBadge() : _markAsDoneButton(task),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.check_circle, size: 16, color: Colors.green),
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
    );
  }

  Widget _markAsDoneButton(Map<String, dynamic> task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }

  Widget _taskDivider() {
    return Divider(color: Colors.grey.withOpacity(0.25), height: 1);
  }

  Widget _taskCompletionOverlay() {
    return Stack(
      children: [
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
        Center(child: _completeTaskCard()),
      ],
    );
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
          _taskCompletionHeader(),
          const SizedBox(height: 12),
          _statusDropdown(),
          const SizedBox(height: 12),
          const Text(
            "Please provide a brief remark on what was done",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          _remarkTextField(),
          const SizedBox(height: 16),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _taskCompletionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_note, color: Colors.orange, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Complete Task - ${selectedTask?['title'] ?? ''}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }

  Widget _statusDropdown() {
    return Container(
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
          setState(() => selectedStatus = newValue ?? "done");
        },
      ),
    );
  }

  Widget _remarkTextField() {
    return Container(
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
    );
  }

  Widget _saveButton() {
    return Align(
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        ),
        child: const Text("Save"),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(child: CircularProgressIndicator()),
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
