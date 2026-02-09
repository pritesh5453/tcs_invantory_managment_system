import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final Dio dio = Dio();

  /// Controllers
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController instructionController = TextEditingController();

  /// Employees
  List employees = [];
  int? selectedEmployeeId;

  /// Tasks
  List tasks = [];

  bool loadingEmployees = false;
  bool assigningTask = false;
  bool loadingTasks = false;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    fetchTasks();
  }

  /// ================= API CALLS =================

  /// 1️⃣ Employees List API
  Future<void> fetchEmployees() async {
    setState(() => loadingEmployees = true);

    try {
      final response = await dio.get(
        'https://dashboarduat.theceramicstudio.in/api/employees/list',
      );

      if (response.data['success'] == true) {
        setState(() {
          employees = response.data['employees'];
        });
      }
    } catch (e) {
      _showSnack('Failed to load employees');
    }

    setState(() => loadingEmployees = false);
  }

  /// 2️⃣ Assign Task API
  Future<void> assignTask() async {
    if (selectedEmployeeId == null ||
        taskTitleController.text.isEmpty ||
        instructionController.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    setState(() => assigningTask = true);

    try {
      final response = await dio.post(
        'https://dashboarduat.theceramicstudio.in/api/tasks/assign',
        data: {
          "employeeId": selectedEmployeeId.toString(),
          "title": taskTitleController.text,
          "description": instructionController.text,
        },
      );

      if (response.data['success'] == true) {
        _showSnack('Task assigned successfully');

        taskTitleController.clear();
        instructionController.clear();
        selectedEmployeeId = null;

        fetchTasks();
      }
    } catch (e) {
      _showSnack('Task assignment failed');
    }

    setState(() => assigningTask = false);
  }

  /// 3️⃣ Task List API
  Future<void> fetchTasks() async {
    setState(() => loadingTasks = true);

    try {
      final response = await dio.get(
        'https://dashboarduat.theceramicstudio.in/api/tasks/all',
      );

      if (response.data['success'] == true) {
        setState(() {
          tasks = response.data['tasks'];
        });
      }
    } catch (e) {
      _showSnack('Failed to load tasks');
    }

    setState(() => loadingTasks = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Assign Task'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ASSIGN TASK
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow('Assign New Task'),
                  const SizedBox(height: 16),

                  isMobile
                      ? Column(
                        children: [
                          _employeeDropdown(),
                          const SizedBox(height: 16),
                          _taskHeadline(),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(child: _employeeDropdown()),
                          const SizedBox(width: 16),
                          Expanded(child: _taskHeadline()),
                        ],
                      ),

                  const SizedBox(height: 16),
                  _instructionBox(),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: _assignButton(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// TASK LIST
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Tasks Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: fetchTasks,
                        child: const Text('REFRESH'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  loadingTasks
                      ? const Center(child: CircularProgressIndicator())
                      : isMobile
                      ? Column(
                        children: tasks.map((e) => _mobileTaskCard(e)).toList(),
                      )
                      : Column(
                        children: [
                          _tableHeader(),
                          const Divider(),
                          ...tasks.map((e) => _taskRow(e)).toList(),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= WIDGETS =================

  Widget _employeeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('SELECT EMPLOYEE'),
        loadingEmployees
            ? const LinearProgressIndicator()
            : DropdownButtonFormField<int>(
              value: selectedEmployeeId,
              hint: const Text('Choose Employee'),
              items:
                  employees
                      .map<DropdownMenuItem<int>>(
                        (e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['name']),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() => selectedEmployeeId = val);
              },
              decoration: _inputDecoration(),
            ),
      ],
    );
  }

  Widget _taskHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TASK HEADLINE'),
        TextFormField(
          controller: taskTitleController,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _instructionBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('SPECIFIC INSTRUCTIONS'),
        TextFormField(
          controller: instructionController,
          maxLines: 4,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _assignButton() {
    return ElevatedButton.icon(
      onPressed: assigningTask ? null : assignTask,
      icon:
          assigningTask
              ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : const Icon(Icons.send, size: 16),
      label: const Text('ASSIGN TASK'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// ================= TASK UI =================

  Widget _taskRow(task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(task['empName'])),
          Expanded(flex: 2, child: Text(task['title'])),
          Expanded(child: _statusChip(task['status'])),
          Expanded(child: Text(task['remark'] == null ? 'No remark' : 'View')),
          const Icon(Icons.delete_outline, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _mobileTaskCard(task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task['empName'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(task['title']),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip(task['status']),
              const Spacer(),
              Text(task['remark'] == null ? 'No remark' : 'View'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.orange, fontSize: 12),
      ),
    );
  }

  /// ================= COMMON =================

  Widget _tableHeader() {
    return const Row(
      children: [
        Expanded(flex: 2, child: Text('EMPLOYEE')),
        Expanded(flex: 2, child: Text('TASK')),
        Expanded(child: Text('STATUS')),
        Expanded(child: Text('REMARK')),
        SizedBox(width: 24),
      ],
    );
  }

  Widget _titleRow(String title) {
    return Row(
      children: [
        Icon(Icons.send, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xffF9FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
