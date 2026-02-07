import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= MODEL =================
class Category {
  final String id; // ✅ STRING
  final String name;
  final bool isAvailable;

  Category({required this.id, required this.name, required this.isAvailable});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // ✅ SAFE
      name: json['name'] ?? "",
      isAvailable: json['status'] == "Available",
    );
  }

  Category copyWith({String? name, bool? isAvailable}) {
    return Category(
      id: id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// ================= API SERVICE =================
class CategoryApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/categories",
      headers: {"Content-Type": "application/json"},
    ),
  );

  static Future<List<Category>> fetchCategories() async {
    final res = await _dio.get(
      "/list",
      queryParameters: {"page": 1, "limit": 10},
    );

    final List list = res.data['categories'] ?? [];
    return list.map((e) => Category.fromJson(e)).toList();
  }

  static Future<void> addCategory(String name, bool isAvailable) async {
    await _dio.post(
      "/create",
      data: {
        "name": name,
        "status": isAvailable ? "Available" : "Unavailable",
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> updateCategory(
    String id,
    String name,
    bool isAvailable,
  ) async {
    await _dio.put(
      "/update/$id",
      data: {"name": name, "status": isAvailable ? "Available" : "Unavailable"},
    );
  }

  static Future<void> deleteCategory(String id) async {
    await _dio.delete("/delete/$id");
  }
}

/// ================= PROVIDER =================
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
      (ref) => CategoryNotifier(),
    );

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await CategoryApi.fetchCategories();
  }

  Future<void> add(String name, bool isAvailable) async {
    await CategoryApi.addCategory(name, isAvailable);
    await load();
  }

  Future<void> update(Category c) async {
    await CategoryApi.updateCategory(c.id, c.name, c.isAvailable);
    await load();
  }

  Future<void> delete(String id) async {
    await CategoryApi.deleteCategory(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> toggle(Category c, bool value) async {
    await CategoryApi.updateCategory(c.id, c.name, value);
    await load();
  }
}

/// ================= MAIN SCREEN =================
/// ================= MAIN SCREEN =================
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdd = PermissionManager.hasPermission("Category Management_Add");
    final canEdit = PermissionManager.hasPermission("Category Management_Edit");
    final canDelete = PermissionManager.hasPermission(
      "Category Management_Delete",
    );

    final list = ref.watch(categoryProvider);
    final notifier = ref.read(categoryProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// TOP BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFA54A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Search..", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap:
                      canAdd
                          ? () {
                            showDialog(
                              context: context,
                              builder: (_) => const CategoryPopup(),
                            );
                          }
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You don't have permission to add category.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                  child: Opacity(
                    opacity: canAdd ? 1 : 0.4,
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

          /// 🔥 LIST WITH PULL TO REFRESH
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await notifier.load(); // 🔄 API RECALL
              },
              child:
                  list.isEmpty
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 250),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                      : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder:
                            (_, i) => CategoryCard(
                              cat: list[i],
                              canEdit: canEdit,
                              canDelete: canDelete,
                            ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= CARD =================
class CategoryCard extends ConsumerWidget {
  final Category cat;
  final bool canEdit;
  final bool canDelete;
  const CategoryCard({
    super.key,
    required this.cat,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(cat.isAvailable ? "Available" : "Unavailable"),
                backgroundColor:
                    cat.isAvailable
                        ? const Color(0xFFE6F7E6)
                        : const Color(0xFFFDECEA),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  ref.read(categoryProvider.notifier).toggle(cat, v == "a");
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: "a", child: Text("Available")),
                      PopupMenuItem(value: "u", child: Text("Unavailable")),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("ID : ${cat.id}"),
          Text("Name : ${cat.name}"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: canEdit ? 1 : 0.4,
                  child: OutlinedButton(
                    onPressed:
                        canEdit
                            ? () {
                              showDialog(
                                context: context,
                                builder: (_) => CategoryPopup(edit: cat),
                              );
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to edit category.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    child: const Text("Edit"),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Opacity(
                  opacity: canDelete ? 1 : 0.4,
                  child: OutlinedButton(
                    onPressed:
                        canDelete
                            ? () {
                              ref
                                  .read(categoryProvider.notifier)
                                  .delete(cat.id);
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to delete category.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text("Delete"),
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

/// ================= POPUP =================
class CategoryPopup extends ConsumerStatefulWidget {
  final Category? edit;
  const CategoryPopup({super.key, this.edit});

  @override
  ConsumerState<CategoryPopup> createState() => _CategoryPopupState();
}

class _CategoryPopupState extends ConsumerState<CategoryPopup> {
  late TextEditingController nameCtrl;
  late bool isAvailable;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.edit?.name ?? "");
    isAvailable = widget.edit?.isAvailable ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? "Edit Category" : "Add Category"),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: "Category name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool>(
              value: isAvailable,
              items: const [
                DropdownMenuItem(value: true, child: Text("Available")),
                DropdownMenuItem(value: false, child: Text("Unavailable")),
              ],
              onChanged: (v) => setState(() => isAvailable = v!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (isEdit) {
                  ref
                      .read(categoryProvider.notifier)
                      .update(
                        widget.edit!.copyWith(
                          name: nameCtrl.text,
                          isAvailable: isAvailable,
                        ),
                      );
                } else {
                  ref
                      .read(categoryProvider.notifier)
                      .add(nameCtrl.text, isAvailable);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
