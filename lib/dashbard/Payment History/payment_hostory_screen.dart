import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final Dio _dio = Dio();
  final ScrollController _horizontalScrollController = ScrollController();

  bool isLoading = true;

  List<dynamic> allPayments = [];
  List<dynamic> filteredPayments = [];

  String selectedTab = "Billing";

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  /// 🔥 API CALL
  Future<void> fetchPaymentHistory() async {
    try {
      final response = await _dio.get(
        "https://dashboarduat.theceramicstudio.in/api/payment/history",
        options: Options(headers: {"Accept": "application/json"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        allPayments = response.data['data'];
        applyFilter();
      }
    } catch (e) {
      debugPrint("Dio Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// 🔍 FILTER
  void applyFilter() {
    filteredPayments =
        allPayments.where((e) => e['billingType'] == selectedTab).toList();
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
    return Scaffold(
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

            /// 🔘 TABS WITH SHADOW
            Row(
              children: [
                _tabButton("Billing"),
                _tabButton("Non-Billing"),
                _tabButton("Other"),
              ],
            ),

            const SizedBox(height: 20),

            /// 💳 TABLE
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
                      constraints: BoxConstraints(minHeight: _getTableHeight()),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 36),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.10),
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
                                  number: e['contactNo'],
                                  date:
                                      e['created_at'].toString().split("T")[0],
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
          ],
        ),
      ),
    );
  }

  /// 🔘 TAB BUTTON WITH SHADOW
  Widget _tabButton(String title) {
    final isActive = selectedTab == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
          applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive
                    ? Colors.blueAccent.withOpacity(0.6)
                    : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isActive
                      ? Colors.blueAccent.withOpacity(0.30)
                      : Colors.black.withOpacity(0.08),
              blurRadius: isActive ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isActive ? Colors.blueAccent : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// 💰 PAYMENT ROW
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
