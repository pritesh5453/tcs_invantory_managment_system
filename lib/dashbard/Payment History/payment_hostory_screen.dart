import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final Dio _dio = Dio();
  final ScrollController _horizontalScrollController = ScrollController();

  // Controllers for filters
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool isLoading = true;
  List<dynamic> allPayments = [];
  List<dynamic> filteredPayments = [];
  String selectedTab = "Billing";
  int totalRecords = 0;

  @override
  void initState() {
    super.initState();
    // Optional default value (matches image hint)
    _partyController.text = '';
    fetchPaymentHistory();
  }

  @override
  void dispose() {
    _partyController.dispose();
    _dateController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// 🔥 API CALL with optional query parameters
  Future<void> fetchPaymentHistory({String? partyName, String? date}) async {
    setState(() => isLoading = true);

    try {
      final queryParams = <String, dynamic>{};
      if (partyName != null && partyName.isNotEmpty) {
        queryParams['partyName'] = partyName;
      }
      if (date != null && date.isNotEmpty) {
        // API expects YYYY-MM-DD, but we store/display DD-MM-YYYY
        // Convert if necessary (assuming we pass the formatted date)
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        "https://dashboard.theceramicstudio.in/api/payment/history",
        queryParameters: queryParams,
        options: Options(headers: {"Accept": "application/json"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        allPayments = response.data['data'];
      } else {
        allPayments = [];
      }
    } catch (e) {
      debugPrint("Dio Error: $e");
      allPayments = [];
    }

    applyFilter();
    setState(() => isLoading = false);
  }

  /// 🔍 FILTER by selected tab (Billing / Non-Billing)
  void applyFilter() {
    filteredPayments =
        allPayments.where((e) => e['billingType'] == selectedTab).toList();
    totalRecords = filteredPayments.length;
  }

  /// 🔍 SEARCH action – calls API with current filter values
  void _performSearch() {
    // Date from controller is in DD-MM-YYYY format, convert to YYYY-MM-DD for API
    String? apiDate;
    if (_dateController.text.isNotEmpty) {
      // Simple conversion – assumes valid DD-MM-YYYY
      final parts = _dateController.text.split('-');
      if (parts.length == 3) {
        apiDate = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }
    fetchPaymentHistory(partyName: _partyController.text, date: apiDate);
  }

  /// 📅 Show date picker and update controller (DD-MM-YYYY)
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.year}";
      setState(() => _dateController.text = formatted);
    }
  }

  /// 📏 Dynamic table height
  double _getTableHeight() {
    const headerHeight = 48.0;
    const rowHeight = 56.0;
    const padding = 32.0;
    return headerHeight + (filteredPayments.length * rowHeight) + padding;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if keyboard is open
        if (FocusScope.of(context).hasFocus) {
          // Dismiss keyboard and prevent back navigation
          FocusScope.of(context).unfocus();
          return false;
        }
        // Otherwise, navigate to home and clear stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );
        return false; // Must return false to prevent default pop
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Financial Ledger",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Categorized transaction history",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 🔍 FILTER SECTION (image style)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // TOTAL RECORDS
                    Row(
                      children: [
                        const Text(
                          "TOTAL RECORDS",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$totalRecords",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // PARTY NAME ROW
                    Row(
                      children: [
                        const Text(
                          "PARTY NAME",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _partyController,
                            decoration: InputDecoration(
                              hintText: "Enter party name",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DATE FILTER + SEARCH BUTTONS
                    Row(
                      children: [
                        const Text(
                          "FILTER BY DATE",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _dateController,
                                decoration: InputDecoration(
                                  hintText: "dd-mm-yyyy",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Search button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _performSearch,
                            icon: const Icon(Icons.search, color: Colors.white),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Link button (optional, as per image)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // child: IconButton(
                          //   onPressed: () {
                          //     // You can implement link sharing if needed
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       const SnackBar(
                          //         content: Text("Link button pressed"),
                          //       ),
                          //     );
                          //   },
                          //   // icon: const Icon(Icons.link, color: Colors.grey),
                          //   constraints: const BoxConstraints(
                          //     minWidth: 40,
                          //     minHeight: 40,
                          //   ),
                          // ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔘 TABS (Billing / Non-Billing)
              Row(
                children: [
                  _buildTab("Billing", Colors.red),
                  _buildTab("Non-Billing", Colors.blue),
                ],
              ),

              const SizedBox(height: 20),

              // 💳 TABLE
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 8,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: _getTableHeight(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  36,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.blueAccent.withOpacity(0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(
                                        0.10,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: DataTable(
                                  headingRowHeight: 48,
                                  dataRowHeight: 56,
                                  headingRowColor: MaterialStateProperty.all(
                                    Colors.blueAccent.withOpacity(0.06),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("ID")),
                                    DataColumn(label: Text("Quotation ID")),
                                    DataColumn(label: Text("Party Name")),
                                    DataColumn(label: Text("Party Number")),
                                    DataColumn(label: Text("Date")),
                                    DataColumn(label: Text("Payment Type")),
                                    DataColumn(label: Text("Remark")),
                                    DataColumn(label: Text("Status")),
                                    DataColumn(label: Text("Amount")),
                                  ],
                                  rows:
                                      filteredPayments.map((e) {
                                        return _paymentRow(
                                          id: "#${e['id']}",
                                          quotation: "#${e['quotation_id']}",
                                          name: e['clientName'],
                                          // projectName: e["projectName"],   // ← REMOVE THIS LINE
                                          number: e['contactNo'],
                                          date:
                                              e['created_at'].toString().split(
                                                "T",
                                              )[0],
                                          type: e['payment_type'],
                                          remark: e['remark'],
                                          approved: e['status'] == "approved",
                                          amount:
                                              "₹${double.parse(e['amount']).toStringAsFixed(0)}",
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔘 Tab button with label and color
  /// 🔘 Tab button without label (just colored)
  Widget _buildTab(String title, Color baseColor) {
    final isActive = selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
          applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 14),
        width: 100, // fixed width
        height: 40, // fixed height
        decoration: BoxDecoration(
          color: isActive ? baseColor : baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: baseColor, width: 1.5),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 8),
                  ]
                  : null,
        ),
        // No child – just a colored box
      ),
    );
  }

  /// 💰 Payment row (unchanged)
  static DataRow _paymentRow({
    required String id,
    required String quotation,
    required String name,
    required String number,
    required String date,
    required String type,
    required String remark,
    required bool approved,
    required String amount,
  }) {
    return DataRow(
      cells: [
        DataCell(Text(id)),
        DataCell(Text(quotation)),
        DataCell(Text(name)),
        DataCell(Text(number)),
        DataCell(Text(date)),
        DataCell(Text(type)),
        DataCell(Text(remark)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: approved ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              approved ? "APPROVED" : "REJECTED",
              style: TextStyle(
                color: approved ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
