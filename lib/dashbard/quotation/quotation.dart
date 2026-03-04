import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/add_delivery_challan.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
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

  // User data from SharedPreferences
  String? _userRole;
  int? _userId;
  bool _userDataLoaded = false;

  // Tab selection
  String _selectedTab = "All"; // "All" or "My"

  // Separate lists for each tab
  List<Map<String, dynamic>> _allQuotations = [];
  List<Map<String, dynamic>> _myQuotations = [];

  // Pagination for All tab
  int _allCurrentPage = 1;
  int _allTotalPages = 1;
  bool _allHasMore = true;
  bool _allLoading = true;
  bool _allLoadingMore = false;

  // Pagination for My tab
  int _myCurrentPage = 1;
  int _myTotalPages = 1;
  bool _myHasMore = true;
  bool _myLoading = false;
  bool _myLoadingMore = false;

  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();

  String searchQuery = '';
  String projectNameQuery = '';

  // Priority filter
  int? _selectedPriority; // null = all priorities

  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTimer?.cancel();
    _searchController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }

  /// Load user role and ID from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
      _userId = prefs.getInt('userId');
      _userDataLoaded = true;
    });
    _loadAllQuotations();
  }

  bool _isEmployee() => _userRole == 'employee';
  int _getEmployeeId() => _userId ?? 0;

  void _onTabSelected(String tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
    });
    if (tab == "All" && _allQuotations.isEmpty) {
      _loadAllQuotations();
    } else if (tab == "My" && _myQuotations.isEmpty) {
      _loadMyQuotations();
    }
  }

  /// Fetch All Quotations
  Future<void> _loadAllQuotations({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _allLoading = true;
        _allCurrentPage = 1;
        _allQuotations = [];
      });
    } else {
      setState(() {
        _allLoadingMore = true;
      });
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _allCurrentPage,
        'limit': 10,
      };
      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;
      if (projectNameQuery.isNotEmpty)
        queryParams['projectName'] = projectNameQuery;
      if (_selectedPriority != null)
        queryParams['priority'] = _selectedPriority;

      final response = await dio.get(
        "/Quotation/list",
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        final List<Map<String, dynamic>> newQuotations =
            (data['quotations'] as List).cast<Map<String, dynamic>>();

        setState(() {
          if (isLoadMore) {
            _allQuotations.addAll(newQuotations);
          } else {
            _allQuotations = newQuotations;
          }
          _allCurrentPage = data['pagination']['currentPage'] ?? 1;
          _allTotalPages = data['pagination']['totalPages'] ?? 1;
          _allHasMore = _allCurrentPage < _allTotalPages;
          _allLoading = false;
          _allLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load quotations');
      }
    } catch (e) {
      debugPrint("All Quotations fetch error: $e");
      setState(() {
        _allLoading = false;
        _allLoadingMore = false;
      });
      _showSnackbar("Failed to load quotations", isError: true);
    }
  }

  /// Fetch My Quotations
  Future<void> _loadMyQuotations({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _myLoading = true;
        _myCurrentPage = 1;
        _myQuotations = [];
      });
    } else {
      setState(() {
        _myLoadingMore = true;
      });
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _myCurrentPage,
        'limit': 10,
        'employeeId': _getEmployeeId(),
      };
      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;
      if (projectNameQuery.isNotEmpty)
        queryParams['projectName'] = projectNameQuery;
      if (_selectedPriority != null)
        queryParams['priority'] = _selectedPriority;

      final response = await dio.get(
        "/Quotation/Quatation",
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        final List<Map<String, dynamic>> newQuotations =
            (data['quotations'] as List).cast<Map<String, dynamic>>();

        setState(() {
          if (isLoadMore) {
            _myQuotations.addAll(newQuotations);
          } else {
            _myQuotations = newQuotations;
          }
          _myCurrentPage = data['pagination']['currentPage'] ?? 1;
          _myTotalPages = data['pagination']['totalPages'] ?? 1;
          _myHasMore = _myCurrentPage < _myTotalPages;
          _myLoading = false;
          _myLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load my quotations');
      }
    } catch (e) {
      debugPrint("My Quotations fetch error: $e");
      setState(() {
        _myLoading = false;
        _myLoadingMore = false;
      });
      _showSnackbar("Failed to load my quotations", isError: true);
    }
  }

  void _fetchCurrentTab({bool isLoadMore = false}) {
    if (_selectedTab == "All") {
      _loadAllQuotations(isLoadMore: isLoadMore);
    } else {
      _loadMyQuotations(isLoadMore: isLoadMore);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final bool loadingMore =
          _selectedTab == "All" ? _allLoadingMore : _myLoadingMore;
      final bool hasMore = _selectedTab == "All" ? _allHasMore : _myHasMore;
      if (!loadingMore && hasMore) {
        _loadMoreData();
      }
    }
  }

  void _loadMoreData() {
    if (_selectedTab == "All") {
      if (!_allHasMore || _allLoadingMore) return;
      setState(() {
        _allCurrentPage++;
      });
      _loadAllQuotations(isLoadMore: true);
    } else {
      if (!_myHasMore || _myLoadingMore) return;
      setState(() {
        _myCurrentPage++;
      });
      _loadMyQuotations(isLoadMore: true);
    }
  }

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
      String url = "/Quotation/print/$quotationId";
      if (pdfType == "Name") {
        url = "/Quotation/print/$quotationId?mode=qname";
      }
      final response = await dio.get(
        url,
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

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    setState(() {
      searchQuery = query;
    });
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (_selectedTab == "All") {
        _allCurrentPage = 1;
        _loadAllQuotations();
      } else {
        _myCurrentPage = 1;
        _loadMyQuotations();
      }
    });
  }

  void _onProjectNameChanged(String query) {
    _searchTimer?.cancel();
    setState(() {
      projectNameQuery = query;
    });
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (_selectedTab == "All") {
        _allCurrentPage = 1;
        _loadAllQuotations();
      } else {
        _myCurrentPage = 1;
        _loadMyQuotations();
      }
    });
  }

  void _onPriorityChanged(int? priority) {
    setState(() {
      _selectedPriority = priority;
    });
    // Reset pagination and reload current tab
    if (_selectedTab == "All") {
      _allCurrentPage = 1;
      _loadAllQuotations();
    } else {
      _myCurrentPage = 1;
      _loadMyQuotations();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _projectNameController.clear();
    setState(() {
      searchQuery = '';
      projectNameQuery = '';
      _selectedPriority = null;
    });
    if (_selectedTab == "All") {
      _allCurrentPage = 1;
      _loadAllQuotations();
    } else {
      _myCurrentPage = 1;
      _loadMyQuotations();
    }
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

  Future<void> _refreshQuotations() async {
    if (_selectedTab == "All") {
      _allCurrentPage = 1;
      await _loadAllQuotations();
    } else {
      _myCurrentPage = 1;
      await _loadMyQuotations();
    }
  }

  // ================= DELETE QUOTATION =================
  Future<void> _deleteQuotation(int quotationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Quotation'),
            content: Text(
              'Are you sure you want to delete quotation #$quotationId? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await dio.delete("/Quotation/delete/$quotationId");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          _showSnackbar('Quotation deleted successfully!', isError: false);
          await _refreshQuotations();
        } else {
          _showSnackbar(
            data['message'] ?? 'Failed to delete quotation',
            isError: true,
          );
        }
      } else {
        _showSnackbar('Server error (${response.statusCode})', isError: true);
      }
    } on DioException catch (e) {
      debugPrint("Delete DioException: $e");
      if (e.response != null) {
        // Server responded with error status
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String errorMsg = 'Server error';
        if (statusCode == 500) {
          errorMsg =
              'Server error (500). Please try again later or contact support.';
        } else if (data != null && data['message'] != null) {
          errorMsg = data['message'];
        } else {
          errorMsg = 'Error ${statusCode ?? ''}';
        }
        _showSnackbar(errorMsg, isError: true);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        _showSnackbar(
          'Connection timeout. Please check your internet.',
          isError: true,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        _showSnackbar('No internet connection.', isError: true);
      } else {
        _showSnackbar('Network error: $e', isError: true);
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      _showSnackbar('Unexpected error: $e', isError: true);
    }
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    if (!_userDataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isEmployee = _isEmployee();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshQuotations,
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildHeader(),

                    if (isEmployee) ...[
                      const SizedBox(height: 16),
                      _buildTabs(),
                    ],

                    const SizedBox(height: 20),

                    if (_selectedTab == "All")
                      _buildAllQuotationsList()
                    else
                      _buildMyQuotationsList(),

                    const SizedBox(height: 20),
                  ],
                ),

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
                            const CircularProgressIndicator(
                              color: Colors.orange,
                            ),
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
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildTabButton("All", _selectedTab == "All"),
          const SizedBox(width: 12),
          _buildTabButton("My", _selectedTab == "My"),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFA54A) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isActive ? Colors.orange : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              title == "All" ? "All Quotations" : "My Quotations",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentHistory(int quotationId) {
    showDialog(
      context: context,
      builder: (ctx) => PaymentHistoryDialog(quotationId: quotationId),
    );
  }

  Widget _buildAllQuotationsList() {
    if (_allLoading && _allQuotations.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_allQuotations.isEmpty && !_allLoading) {
      return _buildEmptyState();
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quotations (${_allQuotations.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshQuotations,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Refresh"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
          ),
          ..._allQuotations
              .asMap()
              .entries
              .map(
                (entry) => InvoiceCard(
                  quotation: entry.value,
                  userRole: _userRole, // 👈 pass user role
                  onEdit: () => _openEditQuotation(entry.value['id']),
                  onPay:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuotationSettlementScreen(
                                quotationId: entry.value['id'],
                                dueAmount:
                                    double.tryParse(
                                      entry.value['due_amount']?.toString() ??
                                          '0',
                                    ) ??
                                    0,
                                quotationData: {},
                              ),
                        ),
                      ),
                  onDispatch:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddDeliveryChallanScreen(
                                quotationId: entry.value['id'],
                              ),
                        ),
                      ),
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
                  onDownloadPdf:
                      (pdfType) =>
                          _downloadAndOpenPdf(pdfType, entry.value['id']),
                  onPaymentHistory:
                      () => _showPaymentHistory(entry.value['id']),
                  onDelete: _deleteQuotation,
                ),
              )
              .toList(),
          if (_allLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_allHasMore && _allQuotations.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No more quotations",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildMyQuotationsList() {
    if (_myLoading && _myQuotations.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_myQuotations.isEmpty && !_myLoading) {
      return _buildEmptyState();
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Quotations (${_myQuotations.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshQuotations,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Refresh"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
          ),
          ..._myQuotations
              .asMap()
              .entries
              .map(
                (entry) => InvoiceCard(
                  quotation: entry.value,
                  userRole: _userRole, // 👈 pass user role
                  onEdit: () => _openEditQuotation(entry.value['id']),
                  onPay:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuotationSettlementScreen(
                                quotationId: entry.value['id'],
                                dueAmount:
                                    double.tryParse(
                                      entry.value['due_amount']?.toString() ??
                                          '0',
                                    ) ??
                                    0,
                                quotationData: {},
                              ),
                        ),
                      ),
                  onDispatch:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddDeliveryChallanScreen(
                                quotationId: entry.value['id'],
                              ),
                        ),
                      ),
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
                  onDownloadPdf:
                      (pdfType) =>
                          _downloadAndOpenPdf(pdfType, entry.value['id']),
                  onPaymentHistory:
                      () => _showPaymentHistory(entry.value['id']),
                  onDelete: _deleteQuotation,
                ),
              )
              .toList(),
          if (_myLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_myHasMore && _myQuotations.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No more quotations",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildEmptyState() {
    String filterDesc = '';
    if (searchQuery.isNotEmpty) filterDesc += "'$searchQuery'";
    if (projectNameQuery.isNotEmpty) {
      filterDesc +=
          filterDesc.isEmpty
              ? "'$projectNameQuery'"
              : " in project '$projectNameQuery'";
    }
    if (_selectedPriority != null) {
      String priorityText = '';
      if (_selectedPriority == 1)
        priorityText = 'Low';
      else if (_selectedPriority == 2)
        priorityText = 'Medium';
      else if (_selectedPriority == 3)
        priorityText = 'Urgent';
      filterDesc +=
          filterDesc.isEmpty
              ? 'priority: $priorityText'
              : ', priority: $priorityText';
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty &&
                      projectNameQuery.isEmpty &&
                      _selectedPriority == null
                  ? Icons.receipt_long_outlined
                  : Icons.search_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              filterDesc.isEmpty
                  ? "No quotations found"
                  : "No results for $filterDesc",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isEmpty &&
                projectNameQuery.isEmpty &&
                _selectedPriority == null)
              TextButton.icon(
                onPressed: _refreshQuotations,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
          ],
        ),
      ),
    );
  }

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
          // First row: search + add button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: "Search by client name...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (searchQuery.isNotEmpty ||
                          projectNameQuery.isNotEmpty ||
                          _selectedPriority != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearSearch,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          // Second row: project name filter + priority dropdown side by side
          Row(
            children: [
              // Project name filter (slightly smaller)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(Icons.folder, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _projectNameController,
                          onChanged: _onProjectNameChanged,
                          decoration: const InputDecoration(
                            hintText: "Project name...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Priority dropdown (takes remaining space)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(Icons.priority_high, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedPriority,
                            hint: const Text(
                              "Priority",
                              style: TextStyle(color: Colors.grey),
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text("All"),
                              ),
                              const DropdownMenuItem<int?>(
                                value: 1,
                                child: Text("Low"),
                              ),
                              const DropdownMenuItem<int?>(
                                value: 2,
                                child: Text("Medium"),
                              ),
                              const DropdownMenuItem<int?>(
                                value: 3,
                                child: Text("Urgent"),
                              ),
                            ],
                            onChanged: _onPriorityChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // for spacing
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
}

// ================= INVOICE CARD WIDGET =================
class InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> quotation;
  final String? userRole; // 👈 new parameter
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onDispatch;
  final VoidCallback? onFollowUp;
  final Function(String) onDownloadPdf;
  final VoidCallback? onPaymentHistory;
  final Function(int quotationId) onDelete;

  const InvoiceCard({
    super.key,
    required this.quotation,
    required this.userRole, // 👈 required
    required this.onEdit,
    required this.onPay,
    required this.onDispatch,
    this.onFollowUp,
    required this.onDownloadPdf,
    this.onPaymentHistory,
    required this.onDelete,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

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

  Widget _buildStatus() {
    final String type = quotation['type']?.toString() ?? "Active";
    final bool isFinal = type.toLowerCase() == "final";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isFinal ? const Color(0xFFE7F7E9) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: isFinal ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if user is admin or superadmin
    final bool canDelete = userRole == 'admin' || userRole == 'superadmin';

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
          if (quotation['projectName'] != null &&
              quotation['projectName'].toString().trim().isNotEmpty)
            Text(
              quotation['projectName'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.blue),
                label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                ),
                onPressed: onEdit,
              ),
              const Spacer(flex: 1),
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
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == "delivery_chalan") {
                    onDispatch();
                  } else if (value == "follow_up") {
                    onFollowUp?.call();
                  } else if (value == "Code") {
                    onDownloadPdf("Code");
                  } else if (value == "Name") {
                    onDownloadPdf("Name");
                  } else if (value == "payment_history") {
                    onPaymentHistory?.call();
                  } else if (value == "delete") {
                    onDelete(quotation['id']);
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[
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
                    const PopupMenuItem(
                      value: "payment_history",
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text("Payment History"),
                        ],
                      ),
                    ),
                  ];

                  // 👇 Only add delete option for admin/superadmin
                  if (canDelete) {
                    items.add(
                      const PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  }

                  return items;
                },
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

// ================= PAYMENT HISTORY DIALOG =================
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
                            _buildRow("Billing Type", p['billingType'] ?? '-'),
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
}
