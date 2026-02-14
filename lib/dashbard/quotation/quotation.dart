import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  List<Map<String, dynamic>> quotations = [];
  bool loading = true;
  bool loadingMore = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchQuotations();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// ================= FETCH QUOTATIONS API WITH PAGINATION =================
  Future<Map<String, dynamic>> _fetchQuotationsAPI({
    int page = 1,
    String search = '',
  }) async {
    try {
      final response = await dio.get(
        "/Quotation/list",
        queryParameters: {
          'page': page,
          'limit': 10,
          if (search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        return {
          'quotations':
              (data['quotations'] as List).cast<Map<String, dynamic>>(),
          'currentPage': data['pagination']['currentPage'] ?? 1,
          'totalPages': data['pagination']['totalPages'] ?? 1,
          'totalItems': data['pagination']['totalItems'] ?? 0,
          'hasMore':
              (data['pagination']['currentPage'] ?? 1) <
              (data['pagination']['totalPages'] ?? 1),
        };
      } else {
        throw Exception('Failed to load quotations');
      }
    } catch (e) {
      debugPrint("Quotations fetch error: $e");
      throw Exception('Network error: $e');
    }
  }

  Future<void> _fetchQuotations({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        loading = true;
        _currentPage = 1;
        quotations = [];
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final result = await _fetchQuotationsAPI(
        page: _currentPage,
        search: searchQuery,
      );

      setState(() {
        if (isLoadMore) {
          quotations.addAll(result['quotations']);
        } else {
          quotations = result['quotations'];
        }

        _currentPage = result['currentPage'];
        _totalPages = result['totalPages'];
        _hasMoreData = result['hasMore'];
        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      debugPrint("Error fetching quotations: $e");
      setState(() {
        loading = false;
        loadingMore = false;
      });
      _showSnackbar("Failed to load quotations", isError: true);
    }
  }

  /// ================= SCROLL LISTENER FOR PAGINATION =================
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !loadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  /// ================= LOAD MORE DATA =================
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || loadingMore) return;

    setState(() {
      loadingMore = true;
    });

    _currentPage++;
    await _fetchQuotations(isLoadMore: true);
  }

  /// ================= EDIT QUOTATION FUNCTION =================
  Future<void> _openEditQuotation(int quotationId) async {
    try {
      debugPrint("Fetching quotation details for ID: $quotationId");

      final response = await dio.get("/Quotation/list/$quotationId");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final quotationData = response.data['quotation'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => EditQuotationScreen(
                  quotationId: quotationId.toString(),
                  quotationData: quotationData,
                ),
          ),
        );
      } else {
        _showSnackbar("Failed to load quotation", isError: true);
      }
    } catch (e) {
      debugPrint("Edit fetch error: $e");
      _showSnackbar("Error loading quotation", isError: true);
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

  /// ================= SEARCH FUNCTIONALITY (API-BASED) =================
  void _searchQuotations(String query) {
    _searchTimer?.cancel();

    setState(() {
      searchQuery = query;
    });

    // Debounce search (500ms)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchQuotations();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
    });
    _fetchQuotations();
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
    setState(() {
      loading = true;
      _currentPage = 1;
      searchQuery = '';
      _searchController.clear();
    });
    await _fetchQuotations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshQuotations,
          child: Stack(
            children: [
              // ✅ YAHAN PAR SINGLE CHILD SCROLL VIEW KI JAGAH LISTVIEW USE KARENGE
              ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  /// HEADER WITH SEARCH
                  _buildHeader(),

                  const SizedBox(height: 20),

                  /// LOADING INDICATOR
                  if (loading && quotations.isEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  /// EMPTY STATE
                  else if (quotations.isEmpty && !loading)
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
                            const SizedBox(height: 16),
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
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _refreshQuotations,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Refresh"),
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
                                "Quotations (${quotations.length})",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _refreshQuotations,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text("Refresh"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// QUOTATION CARDS - ListView.builder se replace karein
                        ...quotations
                            .asMap()
                            .entries
                            .map(
                              (entry) => InvoiceCard(
                                quotation: entry.value,
                                onEdit: () {
                                  _openEditQuotation(entry.value['id']);
                                },
                                onPay: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SettlementScreen(
                                            quotationId: entry.value['id'],
                                            dueAmount:
                                                double.tryParse(
                                                  entry.value['due_amount']
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
                                            quotationId: entry.value['id'],
                                            quotationData: entry.value,
                                          ),
                                    ),
                                  );
                                },
                                onFollowUp: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => FollowUpScreen(
                                          quotationId: entry.value['id'],
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
                                  _downloadAndOpenPdf(
                                    pdfType,
                                    entry.value['id'],
                                  );
                                },
                              ),
                            )
                            .toList(),

                        /// LOAD MORE INDICATOR
                        if (loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),

                        if (!_hasMoreData && quotations.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                "No more quotations",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                ],
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
                          const CircularProgressIndicator(color: Colors.orange),
                          const SizedBox(height: 20),
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
      ),
    );
  }

  /// ================= HEADER WIDGET =================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 12,
        right: 12,
        bottom: 12,
      ),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _searchQuotations,
                          decoration: InputDecoration(
                            hintText: "Search by client name, ID or contact...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearSearch,
                        ),
                    ],
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
                      builder: (context) => AddQuotationSheet(),
                    ),
                  ).then((_) {
                    _refreshQuotations();
                  });
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
