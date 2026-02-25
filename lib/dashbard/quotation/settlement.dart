import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class QuotationSettlementScreen extends StatefulWidget {
  final int quotationId;
  final double dueAmount;

  const QuotationSettlementScreen({
    super.key,
    required this.quotationId,
    required this.dueAmount,
    required Map<dynamic, dynamic> quotationData,
  });

  @override
  State<QuotationSettlementScreen> createState() =>
      _QuotationSettlementScreenState();
}

class _QuotationSettlementScreenState extends State<QuotationSettlementScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  // ─── Settlement Form Controllers ─────────────────────────────
  String? selectedMethod;
  String billingType = "Billing";
  bool loading = false;
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController remarkCtrl = TextEditingController();

  // ─── Payment History ─────────────────────────────────────────
  List<dynamic> _payments = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    remarkCtrl.dispose();
    super.dispose();
  }

  // ─── Fetch Payment History ───────────────────────────────────
  Future<void> _fetchPayments() async {
    setState(() => _loadingHistory = true);
    try {
      final response = await dio.get(
        "/Quotation/payment-history/${widget.quotationId}",
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _payments = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Payment history error: $e");
    } finally {
      setState(() => _loadingHistory = false);
    }
  }

  // ─── Save Payment ────────────────────────────────────────────
  Future<void> savePayment() async {
    if (selectedMethod == null) {
      _toast("Please select payment method");
      return;
    }

    if (amountCtrl.text.trim().isEmpty) {
      _toast("Please enter amount");
      return;
    }

    setState(() => loading = true);

    final body = {
      "quotation_id": widget.quotationId,
      "amount": amountCtrl.text.trim(),
      "paymentType": selectedMethod,
      "remark": remarkCtrl.text.trim(),
      "billingType": billingType,
    };

    try {
      final res = await dio.post("/payment/request", data: body);

      if (res.data['success'] == true) {
        // Refresh payment history and clear form
        await _fetchPayments();
        amountCtrl.clear();
        remarkCtrl.clear();
        setState(() {
          selectedMethod = null;
          billingType = "Billing";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Payment saved"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _toast(res.data['message'] ?? "Payment failed");
      }
    } catch (e) {
      debugPrint("PAYMENT ERROR: $e");
      _toast("Payment failed");
    } finally {
      setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Settlement & History"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Settlement Card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.credit_card, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Settlement",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Amount Boxes
                  Row(
                    children: [
                      _amountBox(
                        title: "Paid Amount",
                        value: "₹ 0.00",
                        valueColor: Colors.black,
                      ),
                      const SizedBox(width: 12),
                      _amountBox(
                        title: "Due Amount",
                        value: "₹ ${widget.dueAmount.toStringAsFixed(2)}",
                        valueColor: Colors.deepOrange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Payment Method
                  const Text(
                    "Payment Method",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Select Method"),
                    value: selectedMethod,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "UPI", child: Text("UPI")),
                      DropdownMenuItem(
                        value: "Bank",
                        child: Text("Bank Transfer"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedMethod = value);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Amount
                  const Text(
                    "Amount",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Enter amount"),
                  ),

                  const SizedBox(height: 14),

                  // Remark
                  const Text(
                    "Remark",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: remarkCtrl,
                    decoration: _inputDecoration("e.g. Received by hand"),
                  ),

                  const SizedBox(height: 16),

                  // Transaction Type
                  const Text(
                    "Transaction Type",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _billingChip("Billing"),
                      const SizedBox(width: 8),
                      _billingChip("Non-Bill"),
                      const SizedBox(width: 8),
                      _billingChip("None"),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: loading ? null : savePayment,
                      child:
                          loading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                "SAVE PAYMENT",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Payment History ─────────────────────────────────
            const Text(
              "Payment History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_payments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text("No payment history found"),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _payments.length,
                itemBuilder: (ctx, i) {
                  final p = _payments[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "₹${double.parse(p['amount'].toString()).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      p['status'] == 'approved'
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  p['status']?.toString().toUpperCase() ??
                                      'UNKNOWN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        p['status'] == 'approved'
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildHistoryRow("Type", p['payment_type'] ?? '-'),
                          _buildHistoryRow(
                            "Billing Type",
                            p['billingType'] ?? '-',
                          ),
                          _buildHistoryRow("Remark", p['remark'] ?? '-'),
                          _buildHistoryRow(
                            "Date",
                            _formatDate(p['created_at'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _billingChip(String type) {
    final bool selected = billingType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => billingType = type);
        },
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            type,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.blue : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountBox({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }

  Widget _buildHistoryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
