import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SettlementScreen extends StatefulWidget {
  final int quotationId;
  final double dueAmount;

  const SettlementScreen({
    super.key,
    required this.quotationId,
    required this.dueAmount,
    required Map<String, dynamic> quotationData,
  });

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  String? selectedMethod;
  String billingType = "Billing"; // ✅ default
  bool loading = false;

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController remarkCtrl = TextEditingController();

  /// ================= SAVE PAYMENT =================
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
      "billingType": billingType, // ✅ dynamic
    };

    try {
      final res = await dio.post("/payment/request", data: body);

      if (res.data['success'] == true) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("PAYMENT ERROR: $e");
      _toast("Payment failed");
    }

    setState(() => loading = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
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

                /// AMOUNT BOXES
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

                /// PAYMENT METHOD
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

                /// AMOUNT
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

                /// REMARK
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

                /// TRANSACTION TYPE
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

                /// SAVE BUTTON
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
        ),
      ),
    );
  }

  /// ================= BILLING CHIP =================
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

  /// ================= AMOUNT BOX =================
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

  /// ================= INPUT DECORATION =================
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
}
