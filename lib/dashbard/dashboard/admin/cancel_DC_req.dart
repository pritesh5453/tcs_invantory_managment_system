import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// ================= MODEL =================
class CancelledChallan {
  final int id;
  final int deliveryChallanId;
  final int quotationId;
  final String seriesNumber;
  final String client;
  final String contact;
  final String employeeName;
  final String grandTotalAmount;
  final String cancelRemark;
  final String status;

  CancelledChallan({
    required this.id,
    required this.deliveryChallanId,
    required this.quotationId,
    required this.seriesNumber,
    required this.client,
    required this.contact,
    required this.employeeName,
    required this.grandTotalAmount,
    required this.cancelRemark,
    required this.status,
  });

  factory CancelledChallan.fromJson(Map<String, dynamic> json) {
    return CancelledChallan(
      id: json['id'] ?? 0,
      deliveryChallanId: json['deliveryChallanId'] ?? 0,
      quotationId: json['quotationId'] ?? 0,
      seriesNumber: json['seriesNumber'] ?? '',
      client: json['client'] ?? '',
      contact: json['contact'] ?? '',
      employeeName: json['employeeName'] ?? '',
      grandTotalAmount: json['grandTotalAmount'] ?? '0',
      cancelRemark: json['cancelRemark'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}

// ================= API SERVICE =================
class CancelledChallanApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in/api/dashboard',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<List<CancelledChallan>> fetchCancelledChallans() async {
    try {
      final response = await _dio.get('/cancelled-delivery-challans');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => CancelledChallan.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load cancelled challans');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<void> updateChallanStatus(int id, String newStatus) async {
    try {
      await _dio.put(
        '/cancelled-delivery-challan-status/$id',
        data: {'status': newStatus},
      );
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}

// ================= SCREEN UI =================
class CancelledChallansScreen extends StatefulWidget {
  const CancelledChallansScreen({super.key});

  @override
  State<CancelledChallansScreen> createState() =>
      _CancelledChallansScreenState();
}

class _CancelledChallansScreenState extends State<CancelledChallansScreen> {
  final CancelledChallanApi _api = CancelledChallanApi();
  List<CancelledChallan> _challans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChallans();
  }

  Future<void> _fetchChallans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchCancelledChallans();
      setState(() {
        _challans = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(CancelledChallan challan, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Action'),
            content: Text(
              'Are you sure you want to ${newStatus.toLowerCase()} this cancellation request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(newStatus),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      await _api.updateChallanStatus(challan.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchChallans(); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Cancel Delivery Challans',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFA9C42),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChallans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchChallans,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'Cancellation Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _challans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) =>
                              _buildRequestCard(_challans[index]),
                    ),
                    if (_challans.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('No cancellation requests found'),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard() {
    final pendingCount = _challans.where((c) => c.status == 'Pending').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFA9C42), const Color(0xFFF57C00)],
        ), // removed const
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pending Approvals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pendingCount.toString(),
              style: const TextStyle(
                color: Color(0xFFFA9C42),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CancelledChallan challan) {
    final bool isPending = challan.status == 'Pending';
    final Color statusColor =
        challan.status == 'Approved'
            ? Colors.green
            : challan.status == 'Rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'CH-${challan.seriesNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        challan.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.person, 'Client', challan.client),
                _infoRow(Icons.badge, 'Employee', challan.employeeName),
                _infoRow(Icons.phone, 'Contact', challan.contact),
                _infoRow(
                  Icons.currency_rupee,
                  'Amount',
                  '₹${challan.grandTotalAmount}',
                ),
                _infoRow(
                  Icons.comment,
                  'Remark',
                  challan.cancelRemark.isEmpty ? '-' : challan.cancelRemark,
                ),
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFA9C42).withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(challan, 'Approved'),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(challan, 'Rejected'),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                      ), // fixed icon name
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
