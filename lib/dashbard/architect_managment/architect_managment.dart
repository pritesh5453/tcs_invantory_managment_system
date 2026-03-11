import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_commision.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_dash.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
import 'add_architect.dart';
import 'edit_architect.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= SEARCH BAR WIDGET =================
class ArchitectSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;

  const ArchitectSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
  });

  @override
  State<ArchitectSearchBarWidget> createState() =>
      _ArchitectSearchBarWidgetState();
}

class _ArchitectSearchBarWidgetState extends State<ArchitectSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ArchitectSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _searchController.text) {
      _searchController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                // DEBOUNCE IMPLEMENTATION (300ms)
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  widget.onSearchChanged(value);
                });
              },
              decoration: const InputDecoration(
                hintText: "Search by name, whatsapp or commission...",
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

/// ================= ARCHITECT MODEL =================
class Architect {
  final int id;
  final String firstname;
  final String lastname;
  final String whatsapp;
  final int commission;
  final String birthdate;
  final String remark;

  Architect({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.whatsapp,
    required this.commission,
    required this.birthdate,
    required this.remark,
  });

  String get fullName => '$firstname $lastname';

  factory Architect.fromJson(Map<String, dynamic> json) {
    return Architect(
      id: json['id'],
      firstname: json['firstname'] ?? "",
      lastname: json['lastname'] ?? "",
      whatsapp: json['whatsapp'] ?? "",
      commission: json['commission'] ?? 0,
      birthdate: json['birthdate'] ?? "",
      remark: json['remark'] ?? "",
    );
  }
}

/// ================= ARCHITECT RESPONSE MODEL =================
class ArchitectResponse {
  final List<Architect> architects;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  ArchitectResponse({
    required this.architects,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMore,
  });
}

/// ================= CLIENT MODEL =================
class Client {
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String altPhone;
  final String email;

  Client({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.altPhone,
    required this.email,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'] ?? "",
      lastName: json['Last_Name'] ?? "",
      phone: json['phone'] ?? "",
      altPhone: json['altphone'] ?? "",
      email: json['email'] ?? "",
    );
  }
}

/// ================= SCREEN =================
class ArchitectManagementScreen extends StatefulWidget {
  const ArchitectManagementScreen({super.key});

  @override
  State<ArchitectManagementScreen> createState() =>
      _ArchitectManagementScreenState();
}

class _ArchitectManagementScreenState extends State<ArchitectManagementScreen> {
  late bool canAddArchitect;
  late bool canEditArchitect;
  late bool canDeleteArchitect;
  late bool canViewCommission;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  bool loadingMore = false;
  List<Architect> architects = [];

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  // ✅ SEARCH VARIABLES
  String _searchQuery = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();

    canAddArchitect = PermissionManager.hasPermission(
      "Architect Registration_Add",
    );

    canEditArchitect = PermissionManager.hasPermission(
      "Architect Registration_Edit",
    );

    canDeleteArchitect = PermissionManager.hasPermission(
      "Architect Registration_Delete",
    );

    // 🔥 Commission (agar alag permission hai)
    canViewCommission =
        PermissionManager.role == 2 ||
        PermissionManager.role.toLowerCase() == "superadmin";

    // Initial fetch
    fetchArchitects();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// ================= GET ARCHITECTS WITH PAGINATION =================
  Future<ArchitectResponse> _fetchArchitectsAPI({
    int page = 1,
    String search = '',
  }) async {
    try {
      final response = await dio.get(
        "/api/architects/list",
        queryParameters: {
          'page': page,
          'limit': 10,
          if (search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['architects'] ?? [];
        final architects = data.map((e) => Architect.fromJson(e)).toList();

        return ArchitectResponse(
          architects: architects,
          currentPage: response.data['page'] ?? 1,
          totalPages: response.data['totalPages'] ?? 1,
          total: response.data['total'] ?? 0,
          hasMore:
              (response.data['page'] ?? 1) < (response.data['totalPages'] ?? 1),
        );
      } else {
        throw Exception('Failed to load architects');
      }
    } catch (e) {
      debugPrint("API Error: $e");
      throw Exception('Failed to load architects');
    }
  }

  Future<void> fetchArchitects({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        loading = true;
        _currentPage = 1;
        architects = [];
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final response = await _fetchArchitectsAPI(
        page: _currentPage,
        search: _searchQuery,
      );

      setState(() {
        if (isLoadMore) {
          architects.addAll(response.architects);
        } else {
          architects = response.architects;
        }

        _currentPage = response.currentPage;
        _totalPages = response.totalPages;
        _hasMoreData = response.hasMore;
        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() {
        loading = false;
        loadingMore = false;
      });
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
    await fetchArchitects(isLoadMore: true);
  }

  /// ================= SEARCH HANDLER =================
  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    setState(() {
      _searchQuery = value;
    });

    // Debounce search (500ms)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      fetchArchitects();
    });
  }

  /// ================= DELETE ARCHITECT =================
  Future<void> deleteArchitect(int id) async {
    try {
      await dio.delete("/api/architects/delete/$id");
      await fetchArchitects(); // Refresh the list
    } catch (e) {
      debugPrint("Delete error: $e");
      throw Exception('Failed to delete architect');
    }
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Architect"),
            content: const Text(
              "Are you sure you want to delete this architect?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteArchitect(id);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// ================= CLIENT POPUP =================
  void showClientPopup(int architectId) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 420,
            child: FutureBuilder(
              future: dio.get("/api/architects/getCustomersById/$architectId"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List data = snapshot.data?.data['customers'] ?? [];

                if (data.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people_outline, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No clients found"),
                    ],
                  );
                }

                final clients = data.map((e) => Client.fromJson(e)).toList();

                return Column(
                  children: [
                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Clients (${clients.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    /// CLIENT LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (_, i) {
                          final c = clients[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Name : ${c.name} ${c.lastName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (c.email.isNotEmpty)
                                  Text(
                                    "Email : ${c.email}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                if (c.phone.isNotEmpty)
                                  Text(
                                    "Phone : ${c.phone}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                if (c.altPhone.isNotEmpty)
                                  Text(
                                    "Alt Phone : ${c.altPhone}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
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
        body: Column(
          children: [
            /// TOP BAR WITH SEARCH
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
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
                      child: ArchitectSearchBarWidget(
                        onSearchChanged: _onSearchChanged,
                        initialValue: _searchQuery,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap:
                          canAddArchitect
                              ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddArchitectScreen(),
                                  ),
                                ).then((_) => fetchArchitects());
                              }
                              : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You don't have permission to add architect.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                      child: Opacity(
                        opacity: canAddArchitect ? 1 : 0.4,
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// LIST WITH SEARCH RESULTS AND PAGINATION
            Expanded(
              child:
                  loading && architects.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: () async {
                          await fetchArchitects();
                        },
                        child:
                            architects.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  itemCount:
                                      architects.length + (loadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    // Loading more indicator
                                    if (index == architects.length) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Center(
                                          child:
                                              loadingMore
                                                  ? const CircularProgressIndicator()
                                                  : !_hasMoreData
                                                  ? const Text(
                                                    "No more architects",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                  : const SizedBox(),
                                        ),
                                      );
                                    }

                                    final a = architects[index];

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        if (!canViewCommission) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Bonus panel is accessible only to Super Admin.",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CommissionPage(
                                                  architectId: a.id,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ArchitectCard(
                                        architect: a,
                                        canEdit: canEditArchitect,
                                        canDelete: canDeleteArchitect,
                                        onDelete: () => confirmDelete(a.id),
                                        onClients: () => showClientPopup(a.id),
                                      ),
                                    );
                                  },
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No architects found for '$_searchQuery'",
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
      child: Text("No architects found", style: TextStyle(color: Colors.grey)),
    );
  }
}

/// ================= CARD =================
class ArchitectCard extends StatelessWidget {
  final Architect architect;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onClients;

  const ArchitectCard({
    super.key,
    required this.architect,
    required this.canEdit,
    required this.canDelete,
    required this.onDelete,
    required this.onClients,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Name : ${architect.fullName}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == "edit") {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to edit architect.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditArchitectScreen(
                              isEdit: true,
                              architectId: architect.id,
                              firstname: architect.firstname,
                              lastname: architect.lastname,
                              whatsapp: architect.whatsapp,
                              commission: architect.commission,
                              birthdate: architect.birthdate,
                              remark: architect.remark,
                            ),
                      ),
                    );
                  } else if (value == "clients") {
                    onClients();
                  } else if (value == "delete") {
                    if (!canDelete) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to delete architect.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    onDelete();
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: "edit",
                        child: Text("Edit Architect Info"),
                      ),
                      PopupMenuItem(
                        value: "clients",
                        child: Text("Client Count"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete Architect",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Whatsapp No. : +91 ${architect.whatsapp}",
            style: const TextStyle(fontSize: 12.5),
          ),
          Text(
            "Date Of Birth : ${architect.birthdate.length >= 10 ? architect.birthdate.substring(0, 10) : architect.birthdate}",
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
