import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_commision.dart';
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
              onChanged: widget.onSearchChanged,
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

  Architect({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.whatsapp,
    required this.commission,
    required this.birthdate,
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
    );
  }
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
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/architects",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  List<Architect> architects = [];
  List<Architect> filteredArchitects = [];
  String searchQuery = '';

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
    fetchArchitects();
  }

  /// ================= GET ARCHITECTS =================
  Future<void> fetchArchitects() async {
    setState(() => loading = true);
    try {
      final res = await dio.get("/list");
      architects =
          (res.data['architects'] as List)
              .map((e) => Architect.fromJson(e))
              .toList();
      _filterArchitects();
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => loading = false);
  }

  /// ================= FILTER ARCHITECTS =================
  void _filterArchitects() {
    if (searchQuery.isEmpty) {
      filteredArchitects = List.from(architects);
    } else {
      filteredArchitects =
          architects.where((architect) {
            return architect.fullName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                architect.whatsapp.contains(searchQuery) ||
                architect.commission.toString().contains(searchQuery) ||
                architect.firstname.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                architect.lastname.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
          }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _filterArchitects();
    });
  }

  /// ================= DELETE ARCHITECT =================
  Future<void> deleteArchitect(int id) async {
    await dio.delete("/delete/$id");
    fetchArchitects();
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
              future: dio.get("/getCustomersById/$architectId"),
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
    return Scaffold(
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
                      initialValue: searchQuery,
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

          /// LIST WITH SEARCH RESULTS
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: () async {
                        await fetchArchitects();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      child:
                          filteredArchitects.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: filteredArchitects.length,
                                itemBuilder: (context, index) {
                                  final a = filteredArchitects[index];

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      if (!canViewCommission) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Commission panel is accessible only to Super Admin.",
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
    );
  }

  Widget _buildEmptyState() {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No architects found for '$searchQuery'",
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
                              remark: "",
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
                      return;
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
            "Commission : ${architect.commission}%",
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
