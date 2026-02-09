import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  List<dynamic> employees = [];
  int? selectedEmployeeId;
  String selectedEmployeeName = "";

  DateTime selectedMonth = DateTime.now();

  bool isLoading = false;

  int daysPresent = 0;
  String avgHours = "0";
  List<dynamic> records = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  /// ================= EMPLOYEES =================
  Future<void> _fetchEmployees() async {
    try {
      final res = await dio.get("/employees/list");
      if (res.data['success'] == true) {
        setState(() {
          employees = res.data['employees'];
          if (employees.isNotEmpty) {
            selectedEmployeeId = employees.first['id'];
            selectedEmployeeName = employees.first['name'];
            _loadAttendance();
          }
        });
      }
    } catch (_) {}
  }

  /// ================= LOAD ATTENDANCE =================
  Future<void> _loadAttendance() async {
    if (selectedEmployeeId == null) return;

    setState(() => isLoading = true);

    final monthStr = DateFormat("yyyy-MM").format(selectedMonth);

    try {
      final summaryRes = await dio.get(
        "/employees/attendance-summary/$selectedEmployeeId?month=$monthStr",
      );

      final recordRes = await dio.get(
        "/employees/$selectedEmployeeId?month=$monthStr",
      );

      setState(() {
        daysPresent = summaryRes.data['daysPresent'] ?? 0;
        avgHours = summaryRes.data['avgHours'] ?? "0";
        records = recordRes.data['records'] ?? [];
      });
    } catch (_) {}

    setState(() => isLoading = false);
  }

  /// ================= MONTH PICKER (MONTH ONLY) =================
  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "Select Month",
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadAttendance();
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Attendance • ${DateFormat("MMMM yyyy").format(selectedMonth)}",
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  /// TOP CONTROLS
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedEmployeeId,
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
                              final emp = employees.firstWhere(
                                (e) => e['id'] == val,
                              );
                              setState(() {
                                selectedEmployeeId = val;
                                selectedEmployeeName = emp['name'];
                              });
                              _loadAttendance();
                            },
                            decoration: const InputDecoration(
                              labelText: "Employee",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _pickMonth,
                        ),
                      ],
                    ),
                  ),

                  /// SUMMARY CARDS (HORIZONTAL)
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _summaryCard(
                          title: "Days Present",
                          value: daysPresent.toString(),
                          icon: Icons.event_available,
                          color: Colors.green,
                        ),
                        _summaryCard(
                          title: "Avg Hours",
                          value:
                              "${double.tryParse(avgHours)?.toStringAsFixed(1) ?? "0.0"} h",
                          icon: Icons.schedule,
                          color: Colors.orange,
                        ),
                        _summaryCard(
                          title: "Employee",
                          value: selectedEmployeeName,
                          icon: Icons.person,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// ATTENDANCE LIST
                  Expanded(
                    child:
                        records.isEmpty
                            ? const Center(child: Text("No attendance records"))
                            : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: records.length,
                              itemBuilder: (_, i) {
                                final r = records[i];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      DateFormat(
                                        "dd MMM yyyy",
                                      ).format(DateTime.parse(r['date'])),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          /// PUNCH IN (LEFT)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.login,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(r['punchIn'] ?? "--"),
                                            ],
                                          ),

                                          const Spacer(), // 🔥 pushes punch-out to right
                                          /// PUNCH OUT (RIGHT)
                                          Row(
                                            children: [
                                              Text(r['punchOut'] ?? "--"),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.logout,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  /// ================= SUMMARY CARD =================
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
