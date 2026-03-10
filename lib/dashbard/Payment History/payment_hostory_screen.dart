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
  final ScrollController _verticalScrollController = ScrollController();

  // Controllers for filters
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  bool isLoading = true;
  List<dynamic> allPayments = [];
  List<dynamic> filteredPayments = [];
  String selectedTab = "Billing";
  int totalRecords = 0;

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  @override
  void dispose() {
    _partyController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// 🔥 API CALL with optional query parameters (partyName, fromDate, toDate)
  Future<void> fetchPaymentHistory({
    String? partyName,
    String? fromDate,
    String? toDate,
  }) async {
    setState(() => isLoading = true);

    try {
      final queryParams = <String, dynamic>{};
      if (partyName != null && partyName.isNotEmpty) {
        queryParams['partyName'] = partyName;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate; // API expects YYYY-MM-DD
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
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
    // Convert date from DD-MM-YYYY to YYYY-MM-DD for API
    String? fromApiDate;
    if (_fromDateController.text.isNotEmpty) {
      final parts = _fromDateController.text.split('-');
      if (parts.length == 3) {
        fromApiDate = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }
    String? toApiDate;
    if (_toDateController.text.isNotEmpty) {
      final parts = _toDateController.text.split('-');
      if (parts.length == 3) {
        toApiDate = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }

    fetchPaymentHistory(
      partyName: _partyController.text,
      fromDate: fromApiDate,
      toDate: toApiDate,
    );
  }

  /// 📅 Show date picker and update the given controller (DD-MM-YYYY)
  Future<void> _selectDate(TextEditingController controller) async {
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
      setState(() => controller.text = formatted);
    }
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
        return false;
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
          padding: const EdgeInsets.all(12), // reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Categorized transaction history",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // 🔍 FILTER SECTION – more compact
              Container(
                padding: const EdgeInsets.all(12), // reduced from 16
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$totalRecords",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // PARTY NAME ROW
                    Row(
                      children: [
                        const Text(
                          "PARTY NAME",
                          style: TextStyle(
                            fontSize: 12,
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
                                horizontal: 10,
                                vertical: 8, // reduced
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // FROM DATE
                    Row(
                      children: [
                        const Text(
                          "FROM",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(_fromDateController),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _fromDateController,
                                decoration: InputDecoration(
                                  hintText: "dd-mm-yyyy",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TO DATE + SEARCH BUTTONS
                    Row(
                      children: [
                        const Text(
                          "TO",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(_toDateController),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _toDateController,
                                decoration: InputDecoration(
                                  hintText: "dd-mm-yyyy",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
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
                        // Search button – smaller
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            onPressed: _performSearch,
                            icon: const Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.white,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Link button (optional)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          // child: IconButton(...) if needed
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔘 TABS (colored boxes)
              Row(
                children: [
                  _buildTab("Billing", Colors.red),
                  _buildTab("Non-Billing", Colors.blue),
                ],
              ),

              const SizedBox(height: 16),

              // 💳 TABLE – now with proper vertical + horizontal scrolling
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(8),
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _horizontalScrollController,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  10,
                                  24,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blueAccent.withOpacity(0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(
                                        0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: DataTable(
                                  headingRowHeight: 42,
                                  dataRowHeight: 48,
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

  /// 🔘 Tab button – just a colored box without label
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
        margin: const EdgeInsets.only(right: 12),
        width: 80, // slightly smaller
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? baseColor : baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: baseColor, width: 1.5),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 6),
                  ]
                  : null,
        ),
      ),
    );
  }

  /// 💰 Payment row
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
        DataCell(Text(id, style: const TextStyle(fontSize: 13))),
        DataCell(Text(quotation, style: const TextStyle(fontSize: 13))),
        DataCell(Text(name, style: const TextStyle(fontSize: 13))),
        DataCell(Text(number, style: const TextStyle(fontSize: 13))),
        DataCell(Text(date, style: const TextStyle(fontSize: 13))),
        DataCell(Text(type, style: const TextStyle(fontSize: 13))),
        DataCell(
          Text(
            remark,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: approved ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              approved ? "APPROVED" : "REJECTED",
              style: TextStyle(
                color: approved ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
