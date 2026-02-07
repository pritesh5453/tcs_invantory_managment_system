import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= MODEL =================
class Brand {
  final int id;
  final String name;
  final String status;

  Brand({required this.id, required this.name, required this.status});

  bool get isAvailable => status == "Available";

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(id: json['id'], name: json['name'], status: json['status']);
  }
}

/// ================= SCREEN =================
class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  late bool canViewBrand;
  late bool canAddBrand;
  late bool canEditBrand;
  late bool canDeleteBrand;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/brands",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  List<Brand> brands = [];

  @override
  void initState() {
    super.initState();

    canAddBrand = PermissionManager.hasPermission("Brand Management_Add");

    canEditBrand = PermissionManager.hasPermission("Brand Management_Edit");

    canDeleteBrand = PermissionManager.hasPermission("Brand Management_Delete");

    fetchBrands();
  }

  /// ================= LIST API =================
  Future<void> fetchBrands() async {
    setState(() => loading = true);
    try {
      final res = await dio.get(
        "/list",
        queryParameters: {"page": 1, "limit": 10},
      );

      final List list = res.data['brands'];
      brands = list.map((e) => Brand.fromJson(e)).toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => loading = false);
  }

  /// ================= ADD / EDIT SHEET =================
  void openBrandSheet({Brand? brand}) {
    final nameController = TextEditingController(text: brand?.name ?? "");
    bool isAvailable = brand?.isAvailable ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        brand == null ? "Add New Brand" : "Edit Brand",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// BRAND NAME
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Brand Name",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// STATUS DROPDOWN
                  DropdownButtonFormField<bool>(
                    value: isAvailable,
                    items: const [
                      DropdownMenuItem(value: true, child: Text("Available")),
                      DropdownMenuItem(
                        value: false,
                        child: Text("Unavailable"),
                      ),
                    ],
                    onChanged: (v) {
                      setModalState(() => isAvailable = v!);
                    },
                    decoration: const InputDecoration(
                      labelText: "Availability Status",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFFA54A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        if (brand == null) {
                          await createBrand(nameController.text, isAvailable);
                        } else {
                          await updateBrand(
                            brand.id,
                            nameController.text,
                            isAvailable,
                          );
                        }
                        Navigator.pop(context);
                        fetchBrands();
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ================= CREATE API =================
  Future<void> createBrand(String name, bool isAvailable) async {
    await dio.post(
      "/create",
      data: {"name": name, "status": isAvailable ? "Available" : "Unavailable"},
    );
  }

  /// ================= UPDATE API =================
  Future<void> updateBrand(int id, String name, bool isAvailable) async {
    await dio.put(
      "/update/$id",
      data: {"name": name, "status": isAvailable ? "Available" : "Unavailable"},
    );
  }

  /// ================= DELETE API =================
  void deleteBrand(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Brand"),
            content: const Text("Are you sure you want to delete this brand?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await dio.delete("/delete/$id");
                  fetchBrands();
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

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xffFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "Search..",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap:
                        canAddBrand
                            ? () => openBrandSheet()
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to add brand.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    child: Opacity(
                      opacity: canAddBrand ? 1 : 0.4,
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

            /// LIST
            Expanded(
              child:
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: fetchBrands,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: brands.length,
                          itemBuilder: (context, index) {
                            final brand = brands[index];
                            return BrandCard(
                              brand: brand,
                              canEdit: canEditBrand,
                              canDelete: canDeleteBrand,
                              onEdit: () => openBrandSheet(brand: brand),
                              onDelete: () => deleteBrand(brand.id),
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
}

/// ================= CARD =================
class BrandCard extends StatelessWidget {
  final Brand brand;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BrandCard({
    super.key,
    required this.brand,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  brand.isAvailable
                      ? Colors.green.shade100
                      : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              brand.isAvailable ? "Available" : "Unavailable",
              style: TextStyle(
                fontSize: 12,
                color: brand.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Brand Identity: ${brand.name}",
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                                  "You don't have permission to edit brand.",
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
                                  "You don't have permission to delete brand.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
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
