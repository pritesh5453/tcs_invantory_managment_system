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

/// ================= DEBOUNCER FOR SEARCH =================
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
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

    // Initialize with current search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialValue.isNotEmpty) {
        _searchController.text = widget.initialValue;
      }
    });
  }

  @override
  void didUpdateWidget(DeliveryChallanSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with parent state
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
        /// 🔍 SEARCH BAR - Employee Management ki tarah
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

        /// ➕ ADD BUTTON - Employee Management ki tarah exact
        InkWell(
          onTap:
              widget.canAdd && widget.onAddPressed != null
                  ? widget.onAddPressed
                  : () {
                    if (!widget.canAdd) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to add delivery challan. Please contact support.",
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

  DeliveryChallan({
    required this.id,
    required this.quotationId,
    required this.client,
    required this.deliveryBoy,
    required this.tempo,
    required this.totalItems,
  });

  factory DeliveryChallan.fromJson(Map<String, dynamic> json) {
    return DeliveryChallan(
      id: json['id'],
      quotationId: json['quotationId'],
      client: json['client'],
      deliveryBoy: json['deliveryBoy'] ?? "",
      tempo: json['tempo'] ?? "",
      totalItems: json['totalItems'],
    );
  }
}

/// ================= SCREEN =================
class DeliveryChalanScreen extends StatefulWidget {
  const DeliveryChalanScreen({super.key});

  @override
  State<DeliveryChalanScreen> createState() => _DeliveryChalanScreenState();
}

class _DeliveryChalanScreenState extends State<DeliveryChalanScreen> {
  late bool canView;
  late bool canAddChallan;
  late bool canUpdateTimeline;
  late bool canDelete;
  late bool canPrint;
  late bool canReturnPrint;

  final Dio dio = Dio();

  bool loading = false;
  bool loadingMore = false;
  String searchQuery = '';
  List<DeliveryChallan> challans = [];
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    canView = PermissionManager.hasPermission("Delivery Challans_View");
    canAddChallan = PermissionManager.hasPermission("Delivery Challans_Add");
    canUpdateTimeline = PermissionManager.hasPermission(
      "Delivery Challans_Update",
    );
    canDelete = PermissionManager.hasPermission("Delivery Challans_Delete");
    canPrint = PermissionManager.hasPermission("Delivery Challans_Print");
    canReturnPrint = PermissionManager.hasPermission(
      "Delivery Challans_ReturnPrint",
    );

    fetchChallans();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= FETCH API WITH PAGINATION =================
  Future<void> fetchChallans({String? search, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        loading = true;
        _currentPage = 1;
        challans = [];
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final Map<String, dynamic> queryParams = {
        "page": _currentPage,
        "limit": 10,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('Fetching delivery challans with query: $queryParams');

      final res = await dio.get(
        "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan/list",
        queryParameters: queryParams,
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final List data = res.data['challans'];
        final pagination = res.data['pagination'] ?? {};

        setState(() {
          if (isLoadMore) {
            challans.addAll(
              data.map((e) => DeliveryChallan.fromJson(e)).toList(),
            );
          } else {
            challans = data.map((e) => DeliveryChallan.fromJson(e)).toList();
          }

          _currentPage = pagination['currentPage'] ?? _currentPage;
          _totalPages = pagination['totalPages'] ?? _totalPages;
          _hasMoreData = (_currentPage) < (_totalPages);

          loading = false;
          loadingMore = false;
        });
      } else {
        throw Exception('Failed to load delivery challans');
      }
    } catch (e) {
      debugPrint("Delivery Challan API Error: $e");
      setState(() {
        loading = false;
        loadingMore = false;
      });
      _showError("Failed to load delivery challans");
    }
  }

  /// ================= SCROLL LISTENER =================
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
    await fetchChallans(search: searchQuery, isLoadMore: true);
  }

  /// ================= SEARCH FUNCTIONALITY =================
  void _searchChallans(String query) {
    setState(() {
      searchQuery = query;
    });

    _debouncer.run(() {
      fetchChallans(search: query);
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
    });
    fetchChallans();
  }

  /// ================= ADD CHALLAN FUNCTION =================
  void _onAddPressed() {
    if (!canAddChallan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You don't have permission to add delivery challan. Please contact support.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDeliveryChallanScreen()),
    );
  }

  /// ================= DELETE API =================
  Future<void> deleteChallan(int id) async {
    try {
      final res = await dio.delete(
        "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan/delete/$id",
      );

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );
        fetchChallans(search: searchQuery);
      }
    } catch (e) {
      _showError("Delete failed");
    }
  }

  /// ================= PRINT PDF =================
  Future<void> _printPdf({
    required int challanId,
    required bool isReturn,
  }) async {
    try {
      debugPrint("========== PRINT PDF START ==========");

      final Dio pdfDio = Dio(
        BaseOptions(
          baseUrl:
              "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan",
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

      // ✅ SAFE DIRECTORY (no permission needed)
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
                          deleteChallan(id);
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

  /// ================= REFRESH FUNCTION =================
  Future<void> _refreshChallans() async {
    setState(() {
      loading = true;
      searchQuery = '';
    });
    await fetchChallans();
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
    return Scaffold(
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

          /// ================= LIST WITH PAGINATION =================
          Expanded(
            child:
                loading && challans.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _refreshChallans,
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          /// EMPTY STATE
                          if (challans.isEmpty && !loading)
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: _buildEmptyState(),
                            )
                          /// CHALLAN LIST
                          else if (challans.isNotEmpty)
                            ..._buildChallanList(),

                          /// LOAD MORE INDICATOR
                          if (loadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),

                          if (!_hasMoreData && challans.isNotEmpty)
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
                    ),
          ),
        ],
      ),
    );
  }

  /// ================= BUILD CHALLAN LIST WIDGETS =================
  List<Widget> _buildChallanList() {
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Delivery Challans (${challans.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      ...challans
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _chalanCard(context, entry.value),
            ),
          )
          .toList(),
    ];
  }

  /// ================= EMPTY STATE =================
  Widget _buildEmptyState() {
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

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No delivery challans found",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// ================= CHALAN CARD =================
  Widget _chalanCard(BuildContext context, DeliveryChallan chalan) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chalan no. : CH ${chalan.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              /// 🔥 3 DOT MENU
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  debugPrint("MENU SELECTED: $value for ID ${chalan.id}");

                  if (value == "dc") {
                    if (!canPrint) {
                      _showError("You don't have permission to print DC");
                      return;
                    }
                    _printPdf(challanId: chalan.id, isReturn: false);
                  }

                  if (value == "return") {
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

          /// BUTTONS
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
