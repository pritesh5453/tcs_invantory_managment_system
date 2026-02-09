import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:tcs_invantory_managment_system/dashbard/quotation/add_quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/dispatch_challan.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/edit_quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/settlement.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/follow_up_screen.dart';

class Quontation_home_screen extends StatefulWidget {
  const Quontation_home_screen({super.key});

  @override
  State<Quontation_home_screen> createState() => _Quontation_home_screenState();
}

class _Quontation_home_screenState extends State<Quontation_home_screen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  List<Map<String, dynamic>> quotations = [];
  bool loading = true;
  String searchQuery = '';
  List<Map<String, dynamic>> filteredQuotations = [];
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
  }

  /// ================= FETCH QUOTATIONS API =================
  Future<void> _fetchQuotations() async {
    try {
      final response = await dio.get("/Quotation/list");

      if (response.data['success'] == true) {
        setState(() {
          quotations =
              (response.data['quotations'] as List)
                  .cast<Map<String, dynamic>>()
                  .toList();

          // Extract and store currentStock for each item in each quotation
          for (var quotation in quotations) {
            if (quotation['items'] != null && quotation['items'] is List) {
              for (var item in quotation['items']) {
                item['currentStock'] = item['currentStock'] ?? 0;
              }
            }
          }

          filteredQuotations = quotations;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _showErrorSnackbar("Failed to load quotations");
      }
    } catch (e) {
      debugPrint("Quotations fetch error: $e");
      setState(() => loading = false);
      _showErrorSnackbar("Network error: $e");
    }
  }

  /// ================= DOWNLOAD AND OPEN PDF =================
  Future<void> _downloadAndOpenPdf(String pdfType, int quotationId) async {
    try {
      setState(() => _isDownloadingPdf = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $pdfType PDF...'),
          backgroundColor: Colors.orange,
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/quotation_${quotationId}_${pdfType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final response = await dio.get(
        "/Quotation/print/$quotationId",
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        final result = await OpenFilex.open(filePath);

        if (result.type == ResultType.done) {
          _showSnackbar('$pdfType PDF opened successfully!', isError: false);
        } else {
          _showSnackbar('Unable to open PDF', isError: true);
        }
      } else {
        _showSnackbar(
          'Failed to download PDF (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("PDF download error: $e");
      _showSnackbar('PDF error: $e', isError: true);
    } finally {
      setState(() => _isDownloadingPdf = false);
    }
  }

  /// ================= SEARCH FUNCTIONALITY =================
  void _searchQuotations(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredQuotations = quotations;
      } else {
        filteredQuotations =
            quotations.where((quotation) {
              final clientName =
                  quotation['clientName']?.toString().toLowerCase() ?? '';
              final quotationId =
                  quotation['id']?.toString().toLowerCase() ?? '';
              final contactNo =
                  quotation['contactNo']?.toString().toLowerCase() ?? '';

              return clientName.contains(query.toLowerCase()) ||
                  quotationId.contains(query.toLowerCase()) ||
                  contactNo.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ================= REFRESH FUNCTION =================
  Future<void> _refreshQuotations() async {
    setState(() => loading = true);
    await _fetchQuotations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshQuotations,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  /// HEADER WITH SEARCH
                  _buildHeader(),

                  SizedBox(height: 20),

                  /// LOADING INDICATOR
                  if (loading)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  /// EMPTY STATE
                  else if (filteredQuotations.isEmpty && !loading)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.isEmpty
                                  ? Icons.receipt_long_outlined
                                  : Icons.search_off,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? "No quotations found"
                                  : "No results for '$searchQuery'",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (searchQuery.isEmpty) ...[
                              SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _refreshQuotations,
                                icon: Icon(Icons.refresh),
                                label: Text("Refresh"),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  /// QUOTATION LIST
                  else
                    Column(
                      children: [
                        /// QUOTATION COUNT
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Quotations (${filteredQuotations.length})",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _refreshQuotations,
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text("Refresh"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// QUOTATION CARDS
                        ...filteredQuotations
                            .map(
                              (quotation) => InvoiceCard(
                                quotation: quotation,
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditQuotationScreen(
                                            quotationId: quotation['id'],
                                            quotationData: {},
                                          ),
                                    ),
                                  );
                                },
                                onPay: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SettlementScreen(
                                            quotationId: quotation['id'],
                                            dueAmount:
                                                double.tryParse(
                                                  quotation['due_amount']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0,
                                            quotationData: {},
                                          ),
                                    ),
                                  );
                                },
                                onDispatch: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DispatchChallanScreen(
                                            quotationId: quotation['id'],
                                            quotationData: quotation,
                                          ),
                                    ),
                                  );
                                },
                                onFollowUp: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => FollowUpScreen(
                                          quotationId: quotation['id'],
                                          onFollowUpSaved: () {
                                            _refreshQuotations();
                                            _showSnackbar(
                                              "Follow-up saved successfully!",
                                              isError: false,
                                            );
                                          },
                                        ),
                                  );
                                },
                                onDownloadPdf: (pdfType) {
                                  _downloadAndOpenPdf(pdfType, quotation['id']);
                                },
                              ),
                            )
                            .toList(),

                        SizedBox(height: 20),
                      ],
                    ),
                ],
              ),
            ),

            // PDF Downloading Overlay
            if (_isDownloadingPdf)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 20),
                        Text(
                          'Downloading PDF...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER WIDGET =================
  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFA54A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                /// SEARCH FIELD
                Expanded(
                  child: TextField(
                    onChanged: _searchQuotations,
                    decoration: InputDecoration(
                      hintText: "Search by client name, ID or contact...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// ADD BUTTON
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Addquotationscreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA9C42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= INVOICE CARD WIDGET =================
class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onDispatch;
  final VoidCallback? onFollowUp;
  final Function(String) onDownloadPdf;

  const InvoiceCard({
    super.key,
    required this.quotation,
    required this.onEdit,
    required this.onPay,
    required this.onDispatch,
    this.onFollowUp,
    required this.onDownloadPdf,
  });

  /// ================= FORMAT DATE =================
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  /// ================= FORMAT AMOUNT =================
  String _formatAmount(String amount) {
    try {
      final value = double.tryParse(amount) ?? 0;
      if (value == 0) return "₹0";

      if (value >= 10000000) {
        return "₹${(value / 10000000).toStringAsFixed(2)}Cr";
      } else if (value >= 100000) {
        return "₹${(value / 100000).toStringAsFixed(2)}L";
      } else if (value >= 1000) {
        return "₹${(value / 1000).toStringAsFixed(2)}K";
      }

      return "₹${value.toStringAsFixed(2)}";
    } catch (e) {
      return "₹$amount";
    }
  }

  /// ================= GET STATUS =================
  Widget _buildStatus() {
    final isSettled = quotation['isSettled'] == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSettled ? const Color(0xFFE7F7E9) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSettled ? "Settled" : "Active",
        style: TextStyle(
          color: isSettled ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS & QUOTATION ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatus(),
              Text(
                "Q#${quotation['id']}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// CLIENT NAME & DATE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quotation['clientName']?.toString() ?? "N/A",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(quotation['createdAt']?.toString() ?? ""),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          /// CONTACT
          if (quotation['contactNo'] != null &&
              quotation['contactNo'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                quotation['contactNo'].toString(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),

          const SizedBox(height: 14),

          /// AMOUNT ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              amountColumn(
                "Grand Total",
                _formatAmount(quotation['grandTotal']?.toString() ?? "0"),
              ),
              divider(),
              amountColumn(
                "Paid Amount",
                _formatAmount(quotation['paid_amount']?.toString() ?? "0"),
              ),
              divider(),
              amountColumn(
                "Due Amount",
                _formatAmount(quotation['due_amount']?.toString() ?? "0"),
                valueColor: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ACTION BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Edit Button
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.blue),
                label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                ),
                onPressed: onEdit,
              ),

              const Spacer(flex: 1),

              /// Pay Button
              InkWell(
                onTap: onPay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.credit_card, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text("Pay", style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              /// More Options Button
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == "delivery_chalan") {
                    onDispatch();
                  } else if (value == "follow_up") {
                    if (onFollowUp != null) {
                      onFollowUp!();
                    }
                  } else if (value == "Code") {
                    onDownloadPdf("Code");
                  } else if (value == "Name") {
                    onDownloadPdf("Name");
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: "delivery_chalan",
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, size: 18),
                            SizedBox(width: 8),
                            Text("Delivery Challan"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "follow_up",
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 8),
                            Text("Follow Up"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "Code",
                        child: Row(
                          children: [
                            Icon(Icons.code, size: 18),
                            SizedBox(width: 8),
                            Text("Code"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: "Name",
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 18),
                            SizedBox(width: 8),
                            Text("Name"),
                          ],
                        ),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text("More"),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// ================= HELPER WIDGETS =================
  static Widget amountColumn(
    String title,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget divider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
