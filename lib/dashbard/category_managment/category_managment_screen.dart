import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= MODEL =================
class Category {
  final String id;
  final String name;
  final bool isAvailable;

  Category({required this.id, required this.name, required this.isAvailable});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
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

/// ================= PROVIDERS =================
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
      (ref) => CategoryNotifier(),
    );

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered categories provider
final filteredCategoriesProvider = Provider<List<Category>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final categories = ref.watch(categoryProvider);

  if (searchQuery.isEmpty) {
    return categories;
  }

  return categories.where((category) {
    return category.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        category.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (category.isAvailable ? 'Available' : 'Unavailable')
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
  }).toList();
});

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

/// ================= SEARCH BAR WIDGET =================
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  late TextEditingController _searchController;
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize with current search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentQuery = ref.read(searchQueryProvider);
      if (currentQuery.isNotEmpty) {
        _searchController.text = currentQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    // Sync controller with provider state
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: const InputDecoration(
                hintText: "Search by name, ID or status...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
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

    final searchQuery = ref.watch(searchQueryProvider);
    final filteredList = ref.watch(filteredCategoriesProvider);
    final notifier = ref.read(categoryProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// TOP BAR WITH ENABLED SEARCH
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
                Expanded(child: SearchBarWidget()),
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

          /// LIST WITH SEARCH RESULTS
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await notifier.load();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              child:
                  filteredList.isEmpty
                      ? _buildEmptyState(searchQuery)
                      : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder:
                            (_, i) => CategoryCard(
                              cat: filteredList[i],
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

  Widget _buildEmptyState(String searchQuery) {
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 250),
        Center(child: CircularProgressIndicator()),
      ],
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
                labelStyle: TextStyle(
                  color: cat.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
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
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
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
            Text(
              isEdit ? "Edit Category" : "Add Category",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
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
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: true, child: Text("Available")),
                DropdownMenuItem(value: false, child: Text("Unavailable")),
              ],
              onChanged: (v) => setState(() => isAvailable = v!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA54A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter category name"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (isEdit) {
                  ref
                      .read(categoryProvider.notifier)
                      .update(
                        widget.edit!.copyWith(
                          name: nameCtrl.text.trim(),
                          isAvailable: isAvailable,
                        ),
                      );
                } else {
                  ref
                      .read(categoryProvider.notifier)
                      .add(nameCtrl.text.trim(), isAvailable);
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
