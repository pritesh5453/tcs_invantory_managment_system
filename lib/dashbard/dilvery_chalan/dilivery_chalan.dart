import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/add_delivery_challan.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/update_timeline.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

/// ================= DEBOUNCER =================
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// ================= SEARCH BAR WIDGET =================
class DeliveryChallanSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;
  final VoidCallback? onAddPressed;
  final bool canAdd;

  const DeliveryChallanSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
    this.onAddPressed,
    this.canAdd = true,
  });

  @override
  State<DeliveryChallanSearchBarWidget> createState() =>
      _DeliveryChallanSearchBarWidgetState();
}

class _DeliveryChallanSearchBarWidgetState
    extends State<DeliveryChallanSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialValue.isNotEmpty) {
        _searchController.text = widget.initialValue;
      }
    });
  }

  @override
  void didUpdateWidget(DeliveryChallanSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _searchController.text) {
      _searchController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search..",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.onSearchChanged('');
                                },
                              )
                              : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap:
              widget.canAdd && widget.onAddPressed != null
                  ? widget.onAddPressed
                  : () {
                    if (!widget.canAdd) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to add delivery challan.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
          child: Opacity(
            opacity: widget.canAdd ? 1 : 0.4,
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// ================= MODEL =================
class DeliveryChallan {
  final int id;
  final int quotationId;
  final String client;
  final String deliveryBoy;
  final String tempo;
  final int totalItems;
  final bool isBlackChallan; // 👈 new field

  DeliveryChallan({
    required this.id,
    required this.quotationId,
    required this.client,
    required this.deliveryBoy,
    required this.tempo,
    required this.totalItems,
    required this.isBlackChallan,
  });

  factory DeliveryChallan.fromJson(Map<String, dynamic> json) {
    return DeliveryChallan(
      id: json['id'],
      quotationId: json['quotationId'],
      client: json['client'],
      deliveryBoy: json['deliveryBoy'] ?? "",
      tempo: json['tempo'] ?? "",
      totalItems: json['totalItems'],
      isBlackChallan: (json['isBlackChallan'] ?? 0) == 1,
    );
  }
}

/// ================= MAIN SCREEN =================
class DeliveryChalanScreen extends StatefulWidget {
  const DeliveryChalanScreen({super.key});

  @override
  State<DeliveryChalanScreen> createState() => _DeliveryChalanScreenState();
}

class _DeliveryChalanScreenState extends State<DeliveryChalanScreen>
    with SingleTickerProviderStateMixin {
  late bool canView;
  late bool canAddChallan;
  late bool canUpdateTimeline;
  late bool canDelete;
  late bool canPrint;
  late bool canReturnPrint;

  final Dio dio = Dio();

  // Tab Controller
  late TabController _tabController;
  int _currentTabIndex = 0; // 0 = White, 1 = Black

  // Separate states for each type
  Map<int, List<DeliveryChallan>> _challans = {0: [], 1: []};
  Map<int, bool> _loading = {0: false, 1: false};
  Map<int, bool> _loadingMore = {0: false, 1: false};
  Map<int, int> _currentPage = {0: 1, 1: 1};
  Map<int, int> _totalPages = {0: 1, 1: 1};
  Map<int, bool> _hasMoreData = {0: true, 1: true};

  String searchQuery = '';
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Permission checks
    canView = PermissionManager.hasPermission("Delivery Challans_View");
    canAddChallan = true; // sabko add access
    canUpdateTimeline = PermissionManager.hasPermission(
      "Delivery Challans_Update Timeline",
    );
    canDelete = PermissionManager.hasPermission("Delivery Challans_Delete");
    canPrint = PermissionManager.hasPermission("Delivery Challans_Print DC");
    canReturnPrint = PermissionManager.hasPermission(
      "Delivery Challans_Return DC",
    );

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load initial data for White tab (index 0)
    _fetchChallans(type: 'WHITE');

    _scrollController.addListener(_scrollListener);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
      if (_challans[_currentTabIndex]!.isEmpty &&
          !_loading[_currentTabIndex]!) {
        _fetchChallans(type: type);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= FETCH API WITH TYPE & PAGINATION =================
  Future<void> _fetchChallans({
    required String type,
    bool isLoadMore = false,
  }) async {
    final tabIndex = type == 'WHITE' ? 0 : 1;

    if (!isLoadMore) {
      setState(() {
        _loading[tabIndex] = true;
        _currentPage[tabIndex] = 1;
        _challans[tabIndex] = [];
      });
    } else {
      setState(() {
        _loadingMore[tabIndex] = true;
      });
    }

    try {
      final Map<String, dynamic> queryParams = {
        "page": _currentPage[tabIndex],
        "limit": 10,
        "challanType": type, // 👈 filter by type
      };
      if (searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      debugPrint('Fetching $type challans with query: $queryParams');

      final res = await dio.get(
        "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan/list",
        queryParameters: queryParams,
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final List data = res.data['challans'];
        final pagination = res.data['pagination'] ?? {};

        final newList = data.map((e) => DeliveryChallan.fromJson(e)).toList();

        setState(() {
          if (isLoadMore) {
            _challans[tabIndex]!.addAll(newList);
          } else {
            _challans[tabIndex] = newList;
          }

          _currentPage[tabIndex] =
              pagination['currentPage'] ?? _currentPage[tabIndex];
          _totalPages[tabIndex] =
              pagination['totalPages'] ?? _totalPages[tabIndex];
          _hasMoreData[tabIndex] =
              _currentPage[tabIndex]! < _totalPages[tabIndex]!;

          _loading[tabIndex] = false;
          _loadingMore[tabIndex] = false;
        });
      } else {
        throw Exception('Failed to load delivery challans');
      }
    } catch (e) {
      debugPrint("Delivery Challan API Error: $e");
      setState(() {
        _loading[tabIndex] = false;
        _loadingMore[tabIndex] = false;
      });
      _showError("Failed to load $type challans");
    }
  }

  /// ================= SCROLL LISTENER =================
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_loadingMore[_currentTabIndex]! &&
        _hasMoreData[_currentTabIndex]!) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
    if (!_hasMoreData[_currentTabIndex]! || _loadingMore[_currentTabIndex]!)
      return;

    _currentPage[_currentTabIndex] = _currentPage[_currentTabIndex]! + 1;
    await _fetchChallans(type: type, isLoadMore: true);
  }

  /// ================= SEARCH =================
  void _searchChallans(String query) {
    setState(() {
      searchQuery = query;
    });
    _debouncer.run(() {
      final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
      _fetchChallans(type: type);
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
    });
    final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
    _fetchChallans(type: type);
  }

  /// ================= ADD =================
  void _onAddPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDeliveryChallanScreen()),
    ).then((_) {
      // Refresh current tab after adding
      final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
      _fetchChallans(type: type);
    });
  }

  /// ================= DELETE =================
  Future<void> _deleteChallan(int id) async {
    try {
      final res = await dio.delete(
        "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan/delete/$id",
      );
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );
        final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
        _fetchChallans(type: type);
      }
    } catch (e) {
      _showError("Delete failed");
    }
  }

  /// ================= PRINT =================
  Future<void> _printPdf({
    required int challanId,
    required bool isReturn,
  }) async {
    try {
      debugPrint("========== PRINT PDF START ==========");

      final Dio pdfDio = Dio(
        BaseOptions(
          baseUrl:
              "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan",
          responseType: ResponseType.bytes,
        ),
      );

      final url = isReturn ? "/printreturn/$challanId" : "/print/$challanId";
      debugPrint("Request URL: ${pdfDio.options.baseUrl}$url");

      final response = await pdfDio.get(url);

      if (response.statusCode != 200) {
        _showError("Invalid response from server");
        return;
      }

      final bytes = response.data as List<int>;
      debugPrint("PDF Bytes Length: ${bytes.length}");

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showError("Storage not available");
        return;
      }

      final filePath =
          "${directory.path}/DC_${challanId}_${isReturn ? "RETURN" : "NORMAL"}.pdf";

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      debugPrint("✅ PDF SAVED AT: $filePath");

      await OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF downloaded successfully"),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint("========== PRINT PDF END ==========");
    } catch (e, stack) {
      debugPrint("❌ PDF DOWNLOAD EXCEPTION");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stack");
      _showError("Unable to download PDF");
    }
  }

  void _showDeleteConfirm(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Delivery Challan"),
            content: const Text(
              "Are you sure you want to delete this challan?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canDelete ? Colors.red : Colors.grey,
                ),
                onPressed:
                    canDelete
                        ? () {
                          Navigator.pop(context);
                          _deleteChallan(id);
                        }
                        : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "You don't have permission to delete delivery challan",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _refreshChallans() async {
    setState(() {
      searchQuery = '';
    });
    final type = _currentTabIndex == 0 ? 'WHITE' : 'BLACK';
    await _fetchChallans(type: type);
  }

  @override
  Widget build(BuildContext context) {
    if (!canView) {
      return const Scaffold(
        body: Center(
          child: Text(
            "You don't have permission to view Delivery Challans",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );
        return false;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7F9),
          body: Column(
            children: [
              /// ================= TOP SEARCH BAR =================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFFA9C42),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DeliveryChallanSearchBarWidget(
                              onSearchChanged: _searchChallans,
                              initialValue: searchQuery,
                              onAddPressed: _onAddPressed,
                              canAdd: canAddChallan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// ================= TABS =================
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orange,
                  tabs: [
                    Tab(
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= TAB VIEWS =================
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(type: 'WHITE', index: 0),
                    _buildTabContent(type: 'BLACK', index: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({required String type, required int index}) {
    final isLoading = _loading[index]! && _challans[index]!.isEmpty;
    final challans = _challans[index]!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshChallans,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          /// Header with count and color
          Container(
            padding: const EdgeInsets.all(16),
            color: type == 'WHITE' ? Colors.red.shade50 : Colors.blue.shade50,
            child: Row(children: [const SizedBox(width: 12)]),
          ),

          /// Empty state
          if (challans.isEmpty && !isLoading)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(type),
            )
          else
            ...challans.map(
              (ch) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _chalanCard(context, ch),
              ),
            ),

          /// Load more indicator
          if (_loadingMore[index]!)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!_hasMoreData[index]! && challans.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No more delivery challans",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No results found for '$searchQuery'",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'WHITE' ? Icons.receipt_outlined : Icons.receipt,
            size: 60,
            color: type == 'WHITE' ? Colors.red.shade200 : Colors.blue.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "No $type challans found",
            style: TextStyle(
              color:
                  type == 'WHITE' ? Colors.red.shade400 : Colors.blue.shade400,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CHALAN CARD =================
  Widget _chalanCard(BuildContext context, DeliveryChallan chalan) {
    final bool isWhite = !chalan.isBlackChallan; // White = isBlackChallan == 0
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Left border color based on type
        border: Border(
          left: BorderSide(color: isWhite ? Colors.red : Colors.blue, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chalan no. : CH ${chalan.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == "dc") {
                    if (!canPrint) {
                      _showError("You don't have permission to print DC");
                      return;
                    }
                    _printPdf(challanId: chalan.id, isReturn: false);
                  } else if (value == "return") {
                    if (!canReturnPrint) {
                      _showError(
                        "You don't have permission to print Return DC",
                      );
                      return;
                    }
                    _printPdf(challanId: chalan.id, isReturn: true);
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(
                        value: "dc",
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 8),
                            Text("DC Print"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "return",
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 8),
                            Text("Return DC Print"),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Recipient Details : ${chalan.client}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Delivery Boy : ${chalan.deliveryBoy.isEmpty ? "-" : chalan.deliveryBoy}",
          ),
          const SizedBox(height: 4),
          Text("Tempo No. : ${chalan.tempo.isEmpty ? "-" : chalan.tempo}"),
          const SizedBox(height: 4),
          Text("Total Items : ${chalan.totalItems}"),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Opacity(
                opacity: canUpdateTimeline ? 1 : 0.4,
                child: OutlinedButton.icon(
                  onPressed:
                      canUpdateTimeline
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UpdateTimelineScreen(
                                      challanId: chalan.id,
                                    ),
                              ),
                            );
                          }
                          : () {
                            _showError(
                              "You don't have permission to update delivery timeline",
                            );
                          },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        canUpdateTimeline ? Colors.blue : Colors.grey,
                  ),
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: canUpdateTimeline ? Colors.blue : Colors.grey,
                  ),
                  label: Text(
                    "Update Timeline",
                    style: TextStyle(
                      color: canUpdateTimeline ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: canDelete ? 1 : 0.4,
                child: OutlinedButton(
                  onPressed:
                      canDelete
                          ? () => _showDeleteConfirm(chalan.id)
                          : () {
                            _showError(
                              "You don't have permission to delete delivery challan",
                            );
                          },
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: canDelete ? Colors.red : Colors.grey,
                    ),
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
