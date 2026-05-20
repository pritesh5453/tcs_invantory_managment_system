import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EmployeeRecordsScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final DateTime fromDate;
  final DateTime toDate;

  const EmployeeRecordsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<EmployeeRecordsScreen> createState() => _EmployeeRecordsScreenState();
}

class _EmployeeRecordsScreenState extends State<EmployeeRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _orderRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final from = DateFormat('yyyy-MM-dd').format(widget.fromDate);
      final to = DateFormat('yyyy-MM-dd').format(widget.toDate);

      final response = await Dio().get(
        'https://dashboard.theceramicstudio.in/api/dashboard/attendance-dashboard',
        queryParameters: {
          'employeeId': widget.employeeId,
          'from': from,
          'to': to,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        setState(() {
          _attendanceRecords = List<Map<String, dynamic>>.from(
            data['attendance'],
          );
          _orderRecords = List<Map<String, dynamic>>.from(data['orders']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // ================= EXPORT ATTENDANCE TO EXCEL =================
  Future<void> _exportAttendanceToExcel() async {
    if (_attendanceRecords.isEmpty) {
      _showSnackBar('No attendance records to export', Colors.orange);
      return;
    }

    try {
      final excelFile = Excel.createExcel();

      // Get default sheet name
      String sheetName = excelFile.getDefaultSheet()!;

      // Rename default sheet
      excelFile.rename(sheetName, "Attendance");

      sheetName = "Attendance";

      final Sheet sheet = excelFile[sheetName];

      final headers = ['Date', 'Punch In', 'Punch Out', 'Verified'];

      // Header row
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Data rows
      for (var record in _attendanceRecords) {
        final date = _formatDate(record['attendance_date']);

        final punchIn = record['punch_in'] ?? '--';

        final punchOut = record['punch_out'] ?? '--';

        final verified = record['is_verified'] == 1 ? 'Yes' : 'No';

        sheet.appendRow([
          TextCellValue(date),
          TextCellValue(punchIn),
          TextCellValue(punchOut),
          TextCellValue(verified),
        ]);
      }

      // Column width
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final bytes = excelFile.save();

      if (bytes == null) {
        throw Exception('Excel generation failed');
      }

      final dir = await getExternalStorageDirectory();

      if (dir == null) {
        throw Exception('Cannot access storage');
      }

      final fileName = 'Attendance_${widget.employeeName}.xlsx';

      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);

      await file.writeAsBytes(bytes);

      _showFileOptions(filePath, fileName);
    } catch (e) {
      _showSnackBar('Export failed: $e', Colors.red);
    }
  }

  // ================= EXPORT ORDERS TO EXCEL =================
  Future<void> _exportOrdersToExcel() async {
    if (_orderRecords.isEmpty) {
      _showSnackBar('No order records to export', Colors.orange);
      return;
    }

    try {
      final excelFile = Excel.createExcel();

      // Get default sheet
      String sheetName = excelFile.getDefaultSheet()!;

      // Rename default sheet
      excelFile.rename(sheetName, "Orders");

      sheetName = "Orders";

      // Get sheet
      final Sheet sheet = excelFile[sheetName];

      final headers = [
        'Quotation ID',
        'Client Name',
        'Grand Total (₹)',
        'Paid Amount (₹)',
        'Due Amount (₹)',
        'Status',
        'Date',
      ];

      // Header row
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Data rows
      for (var order in _orderRecords) {
        final grandTotal =
            double.tryParse(order['grandTotal']?.toString() ?? '0') ?? 0;

        final paidAmount =
            double.tryParse(order['paid_amount']?.toString() ?? '0') ?? 0;

        final dueAmount =
            double.tryParse(order['due_amount']?.toString() ?? '0') ?? 0;

        sheet.appendRow([
          TextCellValue('#${order['quotationId']}'),
          TextCellValue(order['clientName'] ?? ''),
          TextCellValue(grandTotal.toStringAsFixed(2)),
          TextCellValue(paidAmount.toStringAsFixed(2)),
          TextCellValue(dueAmount.toStringAsFixed(2)),
          TextCellValue(
            dueAmount > 0
                ? 'Pending'
                : (grandTotal == paidAmount ? 'Settled' : 'Partial'),
          ),
          TextCellValue(_formatDate(order['createdAt'])),
        ]);
      }

      print(excelFile.tables.keys);

      // Column width
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final dir = await getExternalStorageDirectory();

      if (dir == null) {
        throw Exception('Cannot access storage');
      }

      final fileName =
          'Orders_${widget.employeeName}_${DateFormat('yyyy-MM-dd').format(widget.fromDate)}_to_${DateFormat('yyyy-MM-dd').format(widget.toDate)}.xlsx';

      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);

      final bytes = excelFile.save();

      if (bytes == null) {
        throw Exception('Excel generation failed');
      }

      await file.writeAsBytes(bytes);

      _showFileOptions(filePath, fileName);
    } catch (e) {
      _showSnackBar('Export failed: $e', Colors.red);
    }
  }

  void _showFileOptions(String filePath, String fileName) {
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
                'Excel Exported',
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
                        _showSnackBar('Could not open file', Colors.orange);
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
                      ], text: 'Report');
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '${widget.employeeName}\'s Records',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFA54A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Attendance Records'), Tab(text: 'Orders')],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFA54A)),
                    SizedBox(height: 16),
                    Text('Loading records...'),
                  ],
                ),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA54A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [_buildAttendanceTab(), _buildOrdersTab()],
              ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryChip(
                label: 'Total Days',
                value: _attendanceRecords.length.toString(),
                color: Colors.blue,
              ),
              _buildSummaryChip(
                label: 'Present',
                value: _attendanceRecords.length.toString(),
                color: Colors.green,
              ),
              _buildSummaryChip(label: 'Absent', value: '0', color: Colors.red),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _exportAttendanceToExcel,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) => const Color(0xFFFFF3E0),
                    ),
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    headingRowHeight: 50,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Punch In',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Punch Out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Verified',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        _attendanceRecords.map((record) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(_formatDate(record['attendance_date'])),
                              ),
                              DataCell(Text(record['punch_in'] ?? '--')),
                              DataCell(Text(record['punch_out'] ?? '--')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record['is_verified'] == 1 ? 'Yes' : 'No',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_orderRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No order records found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    double totalGrand = 0;
    double totalPaid = 0;
    double totalDue = 0;
    for (var order in _orderRecords) {
      totalGrand +=
          double.tryParse(order['grandTotal']?.toString() ?? '0') ?? 0;
      totalPaid +=
          double.tryParse(order['paid_amount']?.toString() ?? '0') ?? 0;
      totalDue += double.tryParse(order['due_amount']?.toString() ?? '0') ?? 0;
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryChip(
                label: 'Total Orders',
                value: _orderRecords.length.toString(),
                color: Colors.blue,
              ),
              _buildSummaryChip(
                label: 'Total Amount',
                value: '₹${totalGrand.toStringAsFixed(0)}',
                color: Colors.purple,
              ),
              _buildSummaryChip(
                label: 'Due Amount',
                value: '₹${totalDue.toStringAsFixed(0)}',
                color: Colors.red,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _exportOrdersToExcel,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) => const Color(0xFFFFF3E0),
                    ),
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 50,
                    headingRowHeight: 50,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Quotation ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Client Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Grand Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Paid',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Due',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        _orderRecords.map((order) {
                          final grandTotal =
                              double.tryParse(
                                order['grandTotal']?.toString() ?? '0',
                              ) ??
                              0;
                          final paidAmount =
                              double.tryParse(
                                order['paid_amount']?.toString() ?? '0',
                              ) ??
                              0;
                          final dueAmount =
                              double.tryParse(
                                order['due_amount']?.toString() ?? '0',
                              ) ??
                              0;
                          final status =
                              dueAmount > 0
                                  ? 'Pending'
                                  : (grandTotal == paidAmount
                                      ? 'Settled'
                                      : 'Partial');
                          final statusColor =
                              dueAmount > 0 ? Colors.red : Colors.green;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '#${order['quotationId']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  order['clientName'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text('₹${grandTotal.toStringAsFixed(2)}'),
                              ),
                              DataCell(
                                Text('₹${paidAmount.toStringAsFixed(2)}'),
                              ),
                              DataCell(
                                Text(
                                  '₹${dueAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color:
                                        dueAmount > 0
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(_formatDate(order['createdAt']))),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
