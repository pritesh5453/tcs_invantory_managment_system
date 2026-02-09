import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class AdvanceAnalyticsScreen extends StatefulWidget {
  const AdvanceAnalyticsScreen({super.key});

  @override
  State<AdvanceAnalyticsScreen> createState() => _AdvanceAnalyticsScreenState();
}

class _AdvanceAnalyticsScreenState extends State<AdvanceAnalyticsScreen> {
  /// ================= MONTHS & YEARS =================
  final List<Map<String, dynamic>> months = [
    {"name": "Jan", "value": 1},
    {"name": "Feb", "value": 2},
    {"name": "Mar", "value": 3},
    {"name": "Apr", "value": 4},
    {"name": "May", "value": 5},
    {"name": "Jun", "value": 6},
    {"name": "Jul", "value": 7},
    {"name": "Aug", "value": 8},
    {"name": "Sep", "value": 9},
    {"name": "Oct", "value": 10},
    {"name": "Nov", "value": 11},
    {"name": "Dec", "value": 12},
  ];

  final List<int> years = [2024, 2025, 2026, 2027];

  /// ================= REPORT STATES =================
  final Map<String, int?> selectedMonth = {
    "customer": null,
    "quotation": null,
    "purchase": null,
    "payment": null,
  };

  final Map<String, int?> selectedYear = {
    "customer": null,
    "quotation": null,
    "purchase": null,
    "payment": null,
  };

  /// ================= EMPLOYEE ATTENDANCE =================
  final TextEditingController employeeController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  List<Map<String, dynamic>> employees = [];
  int? selectedEmployeeId;

  /// ================= DATE PICKER =================
  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.year}";

      setState(() {
        if (isFrom) {
          fromDate = picked;
          fromDateController.text = formatted;
        } else {
          toDate = picked;
          toDateController.text = formatted;
        }
      });
    }
  }

  /// ================= FORMAT DATE FOR API =================
  String _formatApiDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  /// ================= FETCH EMPLOYEES =================
  Future<void> _fetchEmployees(String query) async {
    if (query.isEmpty) {
      setState(() => employees = []);
      return;
    }

    try {
      final res = await Dio().get(
        "https://dashboarduat.theceramicstudio.in/api/employees/list",
        queryParameters: {"search": query},
      );

      final List list = res.data["employees"];

      setState(() {
        employees =
            list
                .map<Map<String, dynamic>>(
                  (e) => {"id": e["id"], "name": e["name"]},
                )
                .toList();
      });
    } catch (e) {
      debugPrint("EMPLOYEE API ERROR: $e");
    }
  }

  /// ================= DOWNLOAD EMPLOYEE ATTENDANCE =================
  Future<void> _downloadEmployeeAttendance() async {
    if (selectedEmployeeId == null || fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Employee, From & To Date"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await Permission.storage.request();

      final from = _formatApiDate(fromDate!);
      final to = _formatApiDate(toDate!);

      final response = await Dio(
        BaseOptions(responseType: ResponseType.bytes),
      ).get(
        "https://dashboarduat.theceramicstudio.in/api/dashboard/records",
        queryParameters: {
          "employeeId": selectedEmployeeId,
          "from": from,
          "to": to,
        },
      );

      final dir = Directory("/storage/emulated/0/Download");
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final path =
          "${dir.path}/Employee_Attendance_${selectedEmployeeId}_$from\_to_$to.xlsx";

      await File(path).writeAsBytes(response.data, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded: $path"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("ATTENDANCE DOWNLOAD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance download failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= DOWNLOAD REPORT EXCEL =================
  Future<void> _downloadExcel({
    required String key,
    required String url,
    required String fileName,
  }) async {
    if (selectedMonth[key] == null || selectedYear[key] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Month & Year"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await Permission.storage.request();

      final res = await Dio(BaseOptions(responseType: ResponseType.bytes)).get(
        url,
        queryParameters: {
          "month": selectedMonth[key],
          "year": selectedYear[key],
        },
      );

      final dir = Directory("/storage/emulated/0/Download");
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final path =
          "${dir.path}/${fileName}_${selectedMonth[key]}_${selectedYear[key]}.xlsx";

      await File(path).writeAsBytes(res.data, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded: $path"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _employeeAttendanceCard(),
                    const SizedBox(height: 12),

                    _analyticsCard(
                      keyName: "customer",
                      title: "Customer Register",
                      url:
                          "https://dashboarduat.theceramicstudio.in/api/dashboard/customers/export",
                      fileName: "Customer_Register",
                    ),
                    _analyticsCard(
                      keyName: "quotation",
                      title: "Quotation Data",
                      url:
                          "https://dashboarduat.theceramicstudio.in/api/dashboard/quotations/export",
                      fileName: "Quotation_Data",
                    ),
                    _analyticsCard(
                      keyName: "purchase",
                      title: "Purchase Records",
                      url:
                          "https://dashboarduat.theceramicstudio.in/api/dashboard/purchases/export",
                      fileName: "Purchase_Records",
                    ),
                    _analyticsCard(
                      keyName: "payment",
                      title: "Payment Report",
                      url:
                          "https://dashboarduat.theceramicstudio.in/api/dashboard/api/payments/export",
                      fileName: "Payment_Report",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= EMPLOYEE ATTENDANCE CARD =================
  Widget _employeeAttendanceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Employee Attendance"),
          const SizedBox(height: 10),

          TextField(
            controller: employeeController,
            onChanged: _fetchEmployees,
            decoration: InputDecoration(
              hintText: "Employee Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: selectedEmployeeId,
            hint: const Text("Select Employee"),
            items:
                employees
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e["id"],
                        child: Text(e["name"]),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => selectedEmployeeId = v),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fromDateController,
                  readOnly: true,
                  onTap: () => _pickDate(isFrom: true),
                  decoration: InputDecoration(
                    hintText: "From Date",
                    suffixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: toDateController,
                  readOnly: true,
                  onTap: () => _pickDate(isFrom: false),
                  decoration: InputDecoration(
                    hintText: "To Date",
                    suffixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA54A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _downloadEmployeeAttendance,
              child: const Text("Download Excel"),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= ANALYTICS CARD =================
  Widget _analyticsCard({
    required String keyName,
    required String title,
    required String url,
    required String fileName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(title),
            const SizedBox(height: 10),
            Row(
              children: [
                _pill(
                  DropdownButton<int>(
                    value: selectedMonth[keyName],
                    hint: const Text("Month"),
                    underline: const SizedBox(),
                    items:
                        months
                            .map(
                              (m) => DropdownMenuItem<int>(
                                value: m["value"],
                                child: Text(m["name"]),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (v) => setState(() => selectedMonth[keyName] = v),
                  ),
                ),
                const SizedBox(width: 8),
                _pill(
                  DropdownButton<int>(
                    value: selectedYear[keyName],
                    hint: const Text("Year"),
                    underline: const SizedBox(),
                    items:
                        years
                            .map(
                              (y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => selectedYear[keyName] = v),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFFFF8C2B)),
                  onPressed:
                      () => _downloadExcel(
                        key: keyName,
                        url: url,
                        fileName: fileName,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= COMMON UI =================
  Widget _topBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
    decoration: const BoxDecoration(
      color: Color(0xFFFFA54A),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(26),
        bottomRight: Radius.circular(26),
      ),
    ),
  );

  Widget _pill(Widget child) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFFFA54A)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: child,
  );

  Widget _title(String text) => Row(
    children: [
      const Icon(Icons.groups, size: 20),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}
