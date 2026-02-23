import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class CommissionPage extends StatefulWidget {
  final int architectId;

  const CommissionPage({super.key, required this.architectId});

  @override
  State<CommissionPage> createState() => _CommissionPageState();
}

class _CommissionPageState extends State<CommissionPage> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in/api',
      headers: {'Accept': 'application/json'},
    ),
  );

  /// STATE
  List<dynamic> pendingQuotations = [];
  List<dynamic> history = [];
  dynamic selectedQuotation;

  bool isPercentage = true;
  bool loading = false;

  final TextEditingController commissionController = TextEditingController();

  double calculatedPay = 0;
  double totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    fetchPendingQuotations();
    fetchHistory();
  }

  /// ================= APIs =================

  Future<void> fetchPendingQuotations() async {
    final res = await _dio.get(
      '/Quotation/getArchitectQuotations/${widget.architectId}',
    );

    if (res.data['success'] == true) {
      final list = res.data['quotations'] as List;
      setState(() {
        pendingQuotations = list.where((q) => q['isSettled'] == 0).toList();
      });
    }
  }

  Future<void> fetchHistory() async {
    final res = await _dio.get(
      '/Quotation/getArchitectLedger/${widget.architectId}',
    );

    if (res.data['success'] == true) {
      history = res.data['history'];
      totalEarnings = history.fold(
        0,
        (sum, h) => sum + double.parse(h['commissionAmount']),
      );
      setState(() {});
    }
  }

  /// ================= LOGIC =================

  void calculateCommission() {
    if (selectedQuotation == null) return;

    final total = double.parse(selectedQuotation['grandTotal'].toString());
    final input = double.tryParse(commissionController.text) ?? 0;

    if (isPercentage) {
      if (input > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bonus percentage cannot exceed 100%'),
          ),
        );
        commissionController.text = '100';
        calculatedPay = total;
      } else {
        calculatedPay = total * input / 100;
      }
    } else {
      calculatedPay = input;
    }

    setState(() {});
  }

  Future<void> settleCommission() async {
    if (selectedQuotation == null || calculatedPay <= 0) return;

    setState(() => loading = true);

    final res = await _dio.post(
      '/Quotation/settle-commission',
      data: {
        "quotationId": selectedQuotation['id'],
        "architectId": widget.architectId,
        "commissionAmount": calculatedPay.round(),
      },
    );

    setState(() => loading = false);

    if (res.data['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.data['message'])));

      commissionController.clear();
      calculatedPay = 0;
      selectedQuotation = null;

      await fetchPendingQuotations();
      await fetchHistory();
    }
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        title: const Text('Bonus'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalEarningsCard(),
            const SizedBox(height: 16),
            _addCommissionCard(),
            const SizedBox(height: 20),
            _historyCard(),
          ],
        ),
      ),
    );
  }

  /// ================= WIDGETS =================

  Widget _totalEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Colors.green),
          const SizedBox(width: 10),
          const Text('Total Earnings'),
          const Spacer(),
          Text(
            '₹${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _addCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Bonus',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          /// DROPDOWN
          DropdownButtonFormField(
            value: selectedQuotation,
            hint: const Text('Select Project'),
            items:
                pendingQuotations.map((q) {
                  return DropdownMenuItem(
                    value: q,
                    child: Text(q['clientName']),
                  );
                }).toList(),
            onChanged: (val) {
              selectedQuotation = val;
              calculateCommission();
            },
          ),

          const SizedBox(height: 12),

          /// PROJECT TOTAL
          if (selectedQuotation != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedQuotation['clientName'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    '₹${selectedQuotation['grandTotal']}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          /// TOGGLE
          Row(
            children: [
              ChoiceChip(
                label: const Text('% Percentage'),
                selected: isPercentage,
                onSelected: (_) {
                  isPercentage = true;
                  calculateCommission();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('₹ Fixed Amount'),
                selected: !isPercentage,
                onSelected: (_) {
                  isPercentage = false;
                  calculateCommission();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// INPUT
          TextField(
            controller: commissionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: isPercentage ? 'e.g. 8 (Max 100)' : 'e.g. 10000',
            ),
            onChanged: (_) => calculateCommission(),
          ),

          const SizedBox(height: 12),

          /// CALCULATED PAY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calculated Pay'),
              Text(
                '₹${calculatedPay.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// SETTLE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : settleCommission,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child:
                  loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'SETTLE COMMISSION',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text('No history available')
          else
            ...history.map((h) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(h['clientName']),
                subtitle: Text('₹${h['quotationTotal']}'),
                trailing: Text(
                  '+₹${h['commissionAmount']}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
