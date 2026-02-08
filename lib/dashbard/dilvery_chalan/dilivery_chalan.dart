import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
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

  const DeliveryChallanSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
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
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: widget.onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search by client name, ID or delivery boy...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                widget.onSearchChanged('');
                _searchFocusNode.requestFocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
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
  late bool canUpdateTimeline;
  late bool canDelete;
  late bool canPrint;
  late bool canReturnPrint;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan",
      responseType: ResponseType.bytes, // 🔥 IMPORTANT for PDF
    ),
  );

  bool loading = false;
  String searchQuery = '';
  List<DeliveryChallan> challans = [];
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    canView = PermissionManager.hasPermission("Delivery Challans_View");
    canUpdateTimeline = PermissionManager.hasPermission(
      "Delivery Challans_Update",
    );
    canDelete = PermissionManager.hasPermission("Delivery Challans_Delete");
    canPrint = PermissionManager.hasPermission("Delivery Challans_Print");
    canReturnPrint = PermissionManager.hasPermission(
      "Delivery Challans_ReturnPrint",
    );

    fetchChallans();
  }

  /// ================= FETCH API WITH SEARCH =================
  Future<void> fetchChallans({String? search}) async {
    setState(() => loading = true);
    try {
      final Map<String, dynamic> queryParams = {"page": 1, "limit": 10};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('Fetching delivery challans with query: $queryParams');

      final res = await Dio().get(
        "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan/list",
        queryParameters: queryParams,
      );

      final List data = res.data['challans'];
      challans = data.map((e) => DeliveryChallan.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Delivery Challan API Error: $e");
    }
    setState(() => loading = false);
  }

  /// ================= SEARCH FUNCTIONALITY =================
  void _searchChallans(String query) {
    setState(() {
      searchQuery = query;
      loading = true;
    });

    _debouncer.run(() {
      fetchChallans(search: query);
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      loading = true;
    });
    fetchChallans();
  }

  /// ================= DELETE API =================
  Future<void> deleteChallan(int id) async {
    try {
      final res = await Dio().delete(
        "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan/delete/$id",
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
      debugPrint("========== PDF PRINT START ==========");
      debugPrint("ChallanId: $challanId");
      debugPrint("Is Return: $isReturn");

      final Dio pdfDio = Dio(
        BaseOptions(
          baseUrl:
              "https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan",
          responseType: ResponseType.bytes,
          headers: {"Accept": "application/pdf"},
        ),
      );

      final url = isReturn ? "/printreturn/$challanId" : "/print/$challanId";

      debugPrint("PDF URL: ${pdfDio.options.baseUrl}$url");

      final response = await pdfDio.get(url);

      debugPrint("Response Status: ${response.statusCode}");

      List<int> bytes = response.data;

      // ✅ DOWNLOADS FOLDER
      final directory = Directory("/storage/emulated/0/Download");
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath =
          "${directory.path}/DC_${challanId}_${isReturn ? "RETURN" : "NORMAL"}.pdf";

      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);

      debugPrint("PDF WRITE SUCCESS ✅");
      debugPrint("File Path: $filePath");

      // 🔥 AUTO OPEN PDF
      final result = await OpenFilex.open(filePath);
      debugPrint("OpenFile result: ${result.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF downloaded & opened"),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint("========== PDF PRINT END ==========");
    } catch (e) {
      debugPrint("PDF ERROR: $e");
      _showError("PDF download failed");
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
              child: Row(
                children: [
                  Expanded(
                    child: DeliveryChallanSearchBarWidget(
                      onSearchChanged: _searchChallans,
                      initialValue: searchQuery,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ================= LIST =================
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _refreshChallans,
                      child:
                          challans.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: challans.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _chalanCard(context, challans[index]);
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
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
                onSelected: (value) {
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
                    (_) => [
                      PopupMenuItem(
                        value: "dc",
                        child: Row(
                          children: [
                            Icon(
                              Icons.print,
                              color: canPrint ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "DC Print",
                              style: TextStyle(
                                color: canPrint ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "return",
                        child: Row(
                          children: [
                            Icon(
                              Icons.print,
                              color:
                                  canReturnPrint ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Return DC Print",
                              style: TextStyle(
                                color:
                                    canReturnPrint ? Colors.black : Colors.grey,
                              ),
                            ),
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
