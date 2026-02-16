import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
import 'add_new_supplier.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= SEARCH BAR WIDGET =================
class SupplierSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;

  const SupplierSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
  });

  @override
  State<SupplierSearchBarWidget> createState() =>
      _SupplierSearchBarWidgetState();
}

class _SupplierSearchBarWidgetState extends State<SupplierSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(SupplierSearchBarWidget oldWidget) {
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
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                hintText: "Search by name or mobile...",
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
class Supplier {
  final int id;
  final String name;
  final String mobile;

  Supplier({required this.id, required this.name, required this.mobile});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'].toString(),
    );
  }
}

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  late bool canAddSupplier;
  late bool canEditSupplier;
  late bool canDeleteSupplier;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api/suppliers",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  List<Supplier> suppliers = [];
  List<Supplier> filteredSuppliers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    canAddSupplier = PermissionManager.hasPermission("Supplier Management_Add");
    canEditSupplier = PermissionManager.hasPermission(
      "Supplier Management_Edit",
    );
    canDeleteSupplier = PermissionManager.hasPermission(
      "Supplier Management_Delete",
    );

    fetchSuppliers();
  }

  /// ================= GET LIST API =================
  Future<void> fetchSuppliers() async {
    setState(() => loading = true);
    try {
      final res = await dio.get(
        "/list",
        queryParameters: {"page": 1, "limit": 10},
      );

      final List list = res.data['suppliers'];
      suppliers = list.map((e) => Supplier.fromJson(e)).toList();
      _filterSuppliers();
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => loading = false);
  }

  /// ================= FILTER SUPPLIERS =================
  void _filterSuppliers() {
    if (searchQuery.isEmpty) {
      filteredSuppliers = List.from(suppliers);
    } else {
      filteredSuppliers =
          suppliers.where((supplier) {
            return supplier.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                supplier.mobile.contains(searchQuery);
          }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _filterSuppliers();
    });
  }

  /// ================= DELETE API =================
  void deleteSupplier(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Supplier"),
            content: const Text(
              "Are you sure you want to delete this supplier?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await dio.delete("/delete/$id");
                  fetchSuppliers();
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

  /// ================= UPDATE API =================
  Future<void> updateSupplier(int id, String name, String mobile) async {
    await dio.put("/update/$id", data: {"name": name, "mobile": mobile});
    fetchSuppliers();
  }

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
        body: SafeArea(
          child: Column(
            children: [
              /// 🔶 HEADER WITH SEARCH
              Container(
                height: 120,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        /// 🔍 SEARCH BAR (ENABLED)
                        Expanded(
                          child: SupplierSearchBarWidget(
                            onSearchChanged: _onSearchChanged,
                            initialValue: searchQuery,
                          ),
                        ),
                        const SizedBox(width: 12),

                        /// ➕ ADD BUTTON (UNCHANGED)
                        InkWell(
                          onTap:
                              canAddSupplier
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const AddNewSupplierScreen(),
                                      ),
                                    ).then((_) => fetchSuppliers());
                                  }
                                  : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You don't have permission to add supplier.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                          borderRadius: BorderRadius.circular(14),
                          child: Opacity(
                            opacity: canAddSupplier ? 1 : 0.4,
                            child: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// 📋 SUPPLIER LIST WITH SEARCH
              Expanded(
                child:
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () async {
                            await fetchSuppliers();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                          child:
                              filteredSuppliers.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: filteredSuppliers.length,
                                    itemBuilder: (context, index) {
                                      final supplier = filteredSuppliers[index];
                                      return SupplierCard(
                                        index: index + 1,
                                        name: supplier.name,
                                        mobile: supplier.mobile,
                                        canEdit: canEditSupplier,
                                        canDelete: canDeleteSupplier,
                                        onEdit: () async {
                                          final updatedSupplier =
                                              await Navigator.push<
                                                Map<String, String>
                                              >(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => EditSupplierScreen(
                                                        id: supplier.id,
                                                        name: supplier.name,
                                                        mobile: supplier.mobile,
                                                      ),
                                                ),
                                              );

                                          if (updatedSupplier != null) {
                                            await updateSupplier(
                                              supplier.id,
                                              updatedSupplier["name"]!,
                                              updatedSupplier["mobile"]!,
                                            );
                                          }
                                        },
                                        onDelete:
                                            () => deleteSupplier(supplier.id),
                                      );
                                    },
                                  ),
                        ),
              ),
            ],
          ),
        ),
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
      child: Text("No suppliers found", style: TextStyle(color: Colors.grey)),
    );
  }
}

/// ================= SUPPLIER CARD =================
class SupplierCard extends StatelessWidget {
  final int index;
  final String name;
  final String mobile;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierCard({
    super.key,
    required this.index,
    required this.name,
    required this.mobile,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Index: ${index.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: "Supplier Name : ",
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: "Mobile number : ",
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: mobile,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Opacity(
                opacity: canEdit ? 1 : 0.4,
                child: OutlinedButton.icon(
                  onPressed:
                      canEdit
                          ? onEdit
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You don't have permission to edit supplier.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                ),
              ),

              const Spacer(),
              Opacity(
                opacity: canDelete ? 1 : 0.4,
                child: OutlinedButton(
                  onPressed:
                      canDelete
                          ? onDelete
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You don't have permission to delete supplier.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text("Delete"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= EDIT SUPPLIER SCREEN =================
class EditSupplierScreen extends StatelessWidget {
  final int id;
  final String name;
  final String mobile;

  const EditSupplierScreen({
    super.key,
    required this.id,
    required this.name,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: name);
    final mobileController = TextEditingController(text: mobile);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  const Text(
                    "Edit Supplier Info",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                "Supplier Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "Mobile Number",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter supplier name"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (mobileController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter mobile number"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, {
                      "name": nameController.text.trim(),
                      "mobile": mobileController.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA9C42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
