import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class PaymentRequestsPage extends StatefulWidget {
  const PaymentRequestsPage({super.key});

  @override
  State<PaymentRequestsPage> createState() => _PaymentRequestsPageState();
}

class _PaymentRequestsPageState extends State<PaymentRequestsPage> {
  final Dio dio = Dio();

  bool loading = false;
  List requests = [];

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  /// ================= API CALLS =================

  /// 1️⃣ Get Pending Requests
  Future<void> fetchPendingRequests() async {
    setState(() => loading = true);

    try {
      final response = await dio.get(
        'https://dashboard.theceramicstudio.in/api/payment/pending',
      );

      if (response.data['success'] == true) {
        setState(() {
          requests = response.data['requests'];
        });
      }
    } catch (e) {
      _showSnack('Failed to load payment requests');
    }

    setState(() => loading = false);
  }

  /// 2️⃣ Update Request Status (Approve / Reject)
  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      final response = await dio.put(
        'https://dashboard.theceramicstudio.in/api/payment/update-status',
        data: {
          "requestId": requestId,
          "status": status.trim().toLowerCase(), // approved / rejected
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.data['success'] == true) {
        _showSnack(response.data['message']);
        fetchPendingRequests(); // refresh list
      } else {
        _showSnack('Update failed');
      }
    } on DioException catch (e) {
      print('DIO ERROR DATA: ${e.response?.data}');
      print('STATUS CODE: ${e.response?.statusCode}');

      String msg = 'Something went wrong';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response!.data['message'];
      } else if (e.response?.statusCode == 404) {
        msg = 'API not found / wrong method';
      }
      _showSnack(msg);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Payment Requests'),
        backgroundColor: Colors.orange,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : RefreshIndicator(
                onRefresh: fetchPendingRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _requestCard(requests[index]);
                  },
                ),
              ),
    );
  }

  /// ================= CARD =================

  Widget _requestCard(Map request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Client Name
          Text(
            request['client_name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          _infoRow('Amount', '₹ ${request['amount']}'),
          _infoRow('Payment Type', request['payment_type']),
          _infoRow('Billing Type', request['billingType']),
          _infoRow('Remark', request['remark'] ?? '-'),
          _infoRow('Amount Collector', request['employee_name'] ?? '-'),

          const SizedBox(height: 12),

          /// STATUS CHIP
          Align(
            alignment: Alignment.centerLeft,
            child: _statusChip(request['status']),
          ),

          const SizedBox(height: 14),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      () => updateRequestStatus(
                        requestId: request['id'],
                        status: 'approved',
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('APPROVE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      () => updateRequestStatus(
                        requestId: request['id'],
                        status: 'rejected',
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('REJECT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
