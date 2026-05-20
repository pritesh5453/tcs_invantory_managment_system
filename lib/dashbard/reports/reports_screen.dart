import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/reports/employee_records_scree.dart';

// ================= Modal Bottom Sheet for Employee Selection =================
class EmployeeSelectionBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onEmployeeSelected;
  final int? initialEmployeeId;
  final String? initialEmployeeName;

  const EmployeeSelectionBottomSheet({
    super.key,
    required this.onEmployeeSelected,
    this.initialEmployeeId,
    this.initialEmployeeName,
  });

  @override
  State<EmployeeSelectionBottomSheet> createState() =>
      _EmployeeSelectionBottomSheetState();
}

class _EmployeeSelectionBottomSheetState
    extends State<EmployeeSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  List<Map<String, dynamic>> _employees = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text;
    _currentPage = 1;
    _employees.clear();
    _fetchEmployees();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _fetchEmployees(isLoadMore: true);
    }
  }

  Future<void> _fetchEmployees({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/employees/list',
        queryParameters: {
          'page': _currentPage,
          'search': _searchQuery,
          'limit': 20,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['employees'];
        final pagination = response.data['pagination'];

        final newEmployees =
            data
                .map<Map<String, dynamic>>(
                  (e) => {'id': e['id'], 'name': e['name']},
                )
                .toList();

        setState(() {
          if (isLoadMore) {
            _employees.addAll(newEmployees);
          } else {
            _employees = newEmployees;
          }
          _totalPages = pagination['totalPages'] ?? 1;
          _currentPage = pagination['currentPage'] ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (!isLoadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employees: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Employee List
          Expanded(
            child:
                _isLoading && _employees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _employees.isEmpty
                    ? const Center(child: Text('No employees found'))
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _employees.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _employees.length) {
                          if (_isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                        final employee = _employees[index];
                        final isSelected =
                            widget.initialEmployeeId == employee['id'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.person,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(employee['name']),
                          trailing:
                              isSelected
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                          onTap: () {
                            widget.onEmployeeSelected(employee);
                            Navigator.pop(context);
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

  late List<int> _years;

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
  int? selectedEmployeeId;
  String _selectedEmployeeName = '';

  // ================= DELIVERY CHALLAN REPORT =================
  final TextEditingController dcEmployeeController = TextEditingController();
  final TextEditingController dcFromDateController = TextEditingController();
  final TextEditingController dcToDateController = TextEditingController();

  DateTime? dcFromDate;
  DateTime? dcToDate;
  int? dcSelectedEmployeeId;
  String _dcSelectedEmployeeName = '';

  Map<String, dynamic> _attendanceSummary = {
    "present": 0,
    "absent": 0,
    "totalDays": 0,
  };
  bool _isLoadingAttendance = false;
  bool _isDownloadingReport = false;

  @override
  void initState() {
    super.initState();
    _initYears();
  }

  void _initYears() {
    final now = DateTime.now();
    final currentYear = now.year;
    const startYear = 2024;
    final endYear = currentYear + 2;
    _years = List.generate(
      endYear - startYear + 1,
      (index) => startYear + index,
    );
  }

  // ================= DATE PICKER =================
  Future<void> _pickDate({
    required bool isFrom,
    required TextEditingController controller,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.year}";
      controller.text = formatted;
      onDateSelected(picked);
    }
  }

  String _formatApiDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // ================= EMPLOYEE MODAL =================
  void _showEmployeeSelectionModal({
    required String title,
    required int? currentId,
    required String currentName,
    required Function(Map<String, dynamic>) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EmployeeSelectionBottomSheet(
            onEmployeeSelected: (employee) {
              onSelected(employee);
            },
            initialEmployeeId: currentId,
            initialEmployeeName: currentName,
          ),
    );
  }

  // ================= ATTENDANCE SUMMARY =================
  Future<void> _fetchAttendanceSummary() async {
    if (selectedEmployeeId == null || fromDate == null || toDate == null) {
      setState(() {
        _attendanceSummary = {"present": 0, "absent": 0, "totalDays": 0};
      });
      return;
    }
    setState(() => _isLoadingAttendance = true);
    try {
      final from = _formatApiDate(fromDate!);
      final to = _formatApiDate(toDate!);
      final response = await Dio().get(
        "https://dashboard.theceramicstudio.in/api/dashboard/attendance-dashboard",
        queryParameters: {
          "employeeId": selectedEmployeeId,
          "from": from,
          "to": to,
        },
      );
      final data = response.data;
      if (data["success"] == true) {
        setState(() {
          _attendanceSummary = {
            "present": data["summary"]["present"] ?? 0,
            "absent": data["summary"]["absent"] ?? 0,
            "totalDays": data["summary"]["totalDays"] ?? 0,
          };
        });
      } else {
        setState(() {
          _attendanceSummary = {"present": 0, "absent": 0, "totalDays": 0};
        });
      }
    } catch (e) {
      debugPrint("ATTENDANCE SUMMARY ERROR: $e");
      setState(() {
        _attendanceSummary = {"present": 0, "absent": 0, "totalDays": 0};
      });
    } finally {
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  // ================= FILE HANDLING =================
  void _showExcelOptions(String filePath, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Excel Downloaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to do?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.visibility,
                    label: 'Open',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await OpenFilex.open(filePath);
                      if (result.type != ResultType.done) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Could not open file: ${result.message}",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Share.shareXFiles([
                        XFile(filePath),
                      ], text: 'Analytics Report');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.orange),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  // ================= DOWNLOAD ATTENDANCE =================
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
      final from = _formatApiDate(fromDate!);
      final to = _formatApiDate(toDate!);
      final response = await Dio(
        BaseOptions(responseType: ResponseType.bytes),
      ).get(
        "https://dashboard.theceramicstudio.in/api/dashboard/records",
        queryParameters: {
          "employeeId": selectedEmployeeId,
          "from": from,
          "to": to,
        },
      );
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Cannot access external storage");
      final path =
          "${dir.path}/Employee_Attendance_${selectedEmployeeId}_$from\_to_$to.xlsx";
      await File(path).writeAsBytes(response.data, flush: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded: $path"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _showExcelOptions(path, "Employee_Attendance_$selectedEmployeeId");
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

  // ================= DOWNLOAD DELIVERY CHALLAN REPORT =================
  Future<void> _downloadDeliveryChallanReport() async {
    // Only from and to dates are mandatory now
    if (dcFromDate == null || dcToDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select From Date & To Date"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDownloadingReport = true);
    try {
      final from = _formatApiDate(dcFromDate!);
      final to = _formatApiDate(dcToDate!);

      // Build query parameters
      final queryParams = {"fromDate": from, "toDate": to};
      // Add employeeId only if selected
      if (dcSelectedEmployeeId != null) {
        queryParams["employeeId"] = dcSelectedEmployeeId as String;
      }

      final response = await Dio(
        BaseOptions(responseType: ResponseType.bytes),
      ).get(
        "https://dashboard.theceramicstudio.in/api/dashboard/delivery-challan",
        queryParameters: queryParams,
      );

      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Cannot access external storage");

      final employeePart =
          dcSelectedEmployeeId != null
              ? "${_dcSelectedEmployeeName.replaceAll(' ', '_')}_"
              : "All_Employees_";
      final fileName = "Delivery_Challan_${employeePart}${from}_to_$to.xlsx";
      final filePath = "${dir.path}/$fileName";

      await File(filePath).writeAsBytes(response.data, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded: $filePath"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _showExcelOptions(filePath, fileName);
    } catch (e) {
      debugPrint("DELIVERY CHALLAN DOWNLOAD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery Challan download failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingReport = false);
    }
  }

  // ================= OTHER DOWNLOADS =================
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
      final res = await Dio(BaseOptions(responseType: ResponseType.bytes)).get(
        url,
        queryParameters: {
          "month": selectedMonth[key],
          "year": selectedYear[key],
        },
      );
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Cannot access external storage");
      final path =
          "${dir.path}/${fileName}_${selectedMonth[key]}_${selectedYear[key]}.xlsx";
      await File(path).writeAsBytes(res.data, flush: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded: $path"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _showExcelOptions(path, fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI BUILD =================
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
                      _deliveryChallanReportCard(), // NEW CARD
                      const SizedBox(height: 12),
                      _analyticsCard(
                        keyName: "customer",
                        title: "Customer Register",
                        url:
                            "https://dashboard.theceramicstudio.in/api/dashboard/customers/export",
                        fileName: "Customer_Register",
                      ),
                      _analyticsCard(
                        keyName: "quotation",
                        title: "Quotation Data",
                        url:
                            "https://dashboard.theceramicstudio.in/api/dashboard/quotations/export",
                        fileName: "Quotation_Data",
                      ),
                      _analyticsCard(
                        keyName: "purchase",
                        title: "Purchase Records",
                        url:
                            "https://dashboard.theceramicstudio.in/api/dashboard/purchases/export",
                        fileName: "Purchase_Records",
                      ),
                      _analyticsCard(
                        keyName: "payment",
                        title: "Payment Report",
                        url:
                            "https://dashboard.theceramicstudio.in/api/dashboard/api/payments/export",
                        fileName: "Payment_Report",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= EMPLOYEE ATTENDANCE CARD =================
  Widget _employeeAttendanceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Employee Attendance"),
          const SizedBox(height: 10),

          // Employee Selection (Modal)
          InkWell(
            onTap: () {
              _showEmployeeSelectionModal(
                title: "Select Employee",
                currentId: selectedEmployeeId,
                currentName: _selectedEmployeeName,
                onSelected: (employee) {
                  setState(() {
                    selectedEmployeeId = employee['id'];
                    _selectedEmployeeName = employee['name'];
                    employeeController.text = employee['name'];
                  });
                  _fetchAttendanceSummary();
                },
              );
            },
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: "Select Employee",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _selectedEmployeeName.isEmpty
                    ? "Select Employee"
                    : _selectedEmployeeName,
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
                  onTap:
                      () => _pickDate(
                        isFrom: true,
                        controller: fromDateController,
                        date: fromDate,
                        onDateSelected: (picked) {
                          fromDate = picked;
                          _fetchAttendanceSummary();
                        },
                      ),
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
                  onTap:
                      () => _pickDate(
                        isFrom: false,
                        controller: toDateController,
                        date: toDate,
                        onDateSelected: (picked) {
                          toDate = picked;
                          _fetchAttendanceSummary();
                        },
                      ),
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

          if (_isLoadingAttendance)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryPill(
                    label: "Present",
                    value: _attendanceSummary["present"],
                    color: Colors.green,
                  ),
                  _summaryPill(
                    label: "Absent",
                    value: _attendanceSummary["absent"],
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA54A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _downloadEmployeeAttendance,
                  child: const Text("Export Attendance"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFA54A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    if (selectedEmployeeId == null ||
                        fromDate == null ||
                        toDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select employee and date range",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EmployeeRecordsScreen(
                              employeeId: selectedEmployeeId!,
                              employeeName: _selectedEmployeeName,
                              fromDate: fromDate!,
                              toDate: toDate!,
                            ),
                      ),
                    );
                  },
                  child: const Text("View Records"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= NEW: DELIVERY CHALLAN REPORT CARD =================
  Widget _deliveryChallanReportCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt, color: Color(0xFFFFA54A), size: 20),
              const SizedBox(width: 6),
              const Text(
                "Delivery Challan Report",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Employee Selection (Optional) with clear button
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    _showEmployeeSelectionModal(
                      title: "Select Employee (Optional)",
                      currentId: dcSelectedEmployeeId,
                      currentName: _dcSelectedEmployeeName,
                      onSelected: (employee) {
                        setState(() {
                          dcSelectedEmployeeId = employee['id'];
                          _dcSelectedEmployeeName = employee['name'];
                          dcEmployeeController.text = employee['name'];
                        });
                      },
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: "Select Employee (Optional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _dcSelectedEmployeeName.isEmpty
                          ? "Select Employee (Optional)"
                          : _dcSelectedEmployeeName,
                    ),
                  ),
                ),
              ),
              if (_dcSelectedEmployeeName.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      dcSelectedEmployeeId = null;
                      _dcSelectedEmployeeName = '';
                      dcEmployeeController.clear();
                    });
                  },
                  tooltip: 'Clear Employee',
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dcFromDateController,
                  readOnly: true,
                  onTap:
                      () => _pickDate(
                        isFrom: true,
                        controller: dcFromDateController,
                        date: dcFromDate,
                        onDateSelected: (picked) => dcFromDate = picked,
                      ),
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
                  controller: dcToDateController,
                  readOnly: true,
                  onTap:
                      () => _pickDate(
                        isFrom: false,
                        controller: dcToDateController,
                        date: dcToDate,
                        onDateSelected: (picked) => dcToDate = picked,
                      ),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed:
                  _isDownloadingReport ? null : _downloadDeliveryChallanReport,
              child:
                  _isDownloadingReport
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Download Report"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ANALYTICS CARD =================
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
                        months.map((m) {
                          return DropdownMenuItem<int>(
                            value: m["value"],
                            child: Text(m["name"]),
                          );
                        }).toList(),
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
                        _years.map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text(y.toString()),
                          );
                        }).toList(),
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

  // ================= COMMON UI =================
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

  Widget _summaryPill({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
