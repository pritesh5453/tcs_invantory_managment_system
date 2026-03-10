import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// ================= PAYMENT HISTORY DIALOG =================
class PaymentHistoryDialog extends StatefulWidget {
  final int quotationId;
  const PaymentHistoryDialog({super.key, required this.quotationId});

  @override
  State<PaymentHistoryDialog> createState() => _PaymentHistoryDialogState();
}

class _PaymentHistoryDialogState extends State<PaymentHistoryDialog> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      final response = await _dio.get(
        "/Quotation/payment-history/${widget.quotationId}",
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _payments = response.data['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Payment history error: $e");
      setState(() => _loading = false);
    }
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Payment History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_payments.isEmpty)
              const Expanded(
                child: Center(child: Text("No payment history found")),
              )
            else
              Expanded(
                child: ListView.builder(
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
                            _buildRow("Type", p['payment_type'] ?? '-'),
                            // Custom row for Billing Type with colored dot
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 80,
                                    child: Text(
                                      "Billing Type:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _getBillingDotColor(
                                              p['billingType']?.toString() ??
                                                  '',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            p['billingType'] ?? '-',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildRow("Remark", p['remark'] ?? '-'),
                            _buildRow(
                              "Date",
                              _formatDate(p['created_at'] ?? ''),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
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

  Color _getBillingDotColor(String billingType) {
    // Case-insensitive check for "Non-Billing"
    if (billingType.toLowerCase() == 'non-billing') {
      return Colors.blue;
    }
    // Default to red for "Billing" or any other value
    return Colors.red;
  }
}
