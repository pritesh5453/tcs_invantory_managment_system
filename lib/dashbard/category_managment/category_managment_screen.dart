import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

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
      baseUrl: "https://dashboard.theceramicstudio.in/api/categories",
      headers: {"Content-Type": "application/json"},
    ),
  );

  static Future<Map<String, dynamic>> fetchCategories({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {"page": page, "limit": limit};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final res = await _dio.get("/list", queryParameters: queryParams);

    final List list = res.data['categories'] ?? [];
    final pagination = res.data['pagination'] ?? {};

    return {
      'categories': list.map((e) => Category.fromJson(e)).toList(),
      'currentPage': pagination['page'] ?? 1,
      'totalPages': pagination['totalPages'] ?? 1,
      'totalItems': pagination['totalItems'] ?? 0,
    };
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

// Pagination state provider
final paginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
      return PaginationNotifier();
    });

class PaginationState {
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool hasMoreData;
  final int totalItems;

  PaginationState({
    required this.currentPage,
    required this.totalPages,
    required this.isLoadingMore,
    required this.hasMoreData,
    required this.totalItems,
  });

  PaginationState.initial()
    : currentPage = 1,
      totalPages = 1,
      isLoadingMore = false,
      hasMoreData = true,
      totalItems = 0;

  PaginationState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? hasMoreData,
    int? totalItems,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

class PaginationNotifier extends StateNotifier<PaginationState> {
  PaginationNotifier() : super(PaginationState.initial());

  void setLoadingMore(bool isLoading) {
    state = state.copyWith(isLoadingMore: isLoading);
  }

  void updatePagination(int currentPage, int totalPages, int totalItems) {
    state = state.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      hasMoreData: currentPage < totalPages,
      totalItems: totalItems,
    );
  }

  void reset() {
    state = PaginationState.initial();
  }
}

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

  Future<void> load({bool isLoadMore = false, String? search}) async {
    try {
      final pagination = PaginationNotifier();

      if (!isLoadMore) {
        pagination.reset();
        state = [];
      } else {
        pagination.setLoadingMore(true);
      }

      final currentPage = isLoadMore ? pagination.state.currentPage + 1 : 1;

      final response = await CategoryApi.fetchCategories(
        page: currentPage,
        limit: 10,
        search: search,
      );

      final List<Category> newCategories = response['categories'];
      final int currentPageNum = response['currentPage'];
      final int totalPages = response['totalPages'];
      final int totalItems = response['totalItems'];

      if (isLoadMore) {
        state = [...state, ...newCategories];
      } else {
        state = newCategories;
      }

      pagination.updatePagination(currentPageNum, totalPages, totalItems);
      pagination.setLoadingMore(false);
    } catch (e) {
      debugPrint("Error loading categories: $e");
      PaginationNotifier().setLoadingMore(false);
    }
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

Future<void> loadMore({String? search}) async {
    final pagination = PaginationNotifier();
    if (pagination.state.isLoadingMore || !pagination.state.hasMoreData) return;

    await load(isLoadMore: true, search: search);
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
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentQuery = ref.read(searchQueryProvider);
      if (currentQuery.isNotEmpty) {
        _searchController.text = currentQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

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
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(
                  const Duration(milliseconds: 500),
                  () {
                    ref.read(searchQueryProvider.notifier).state = value;
                    ref.read(categoryProvider.notifier).load(search: value);
                  },
                );
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
                ref.read(categoryProvider.notifier).load();
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
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final pagination = ref.read(paginationProvider);
    final searchQuery = ref.read(searchQueryProvider);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !pagination.isLoadingMore &&
        pagination.hasMoreData &&
        searchQuery.isEmpty) {
      ref.read(categoryProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = PermissionManager.hasPermission("Category Management_Add");
    final canEdit = PermissionManager.hasPermission("Category Management_Edit");
    final canDelete = PermissionManager.hasPermission(
      "Category Management_Delete",
    );

    final searchQuery = ref.watch(searchQueryProvider);
    final filteredList = ref.watch(filteredCategoriesProvider);
    final notifier = ref.read(categoryProvider.notifier);
    final pagination = ref.watch(paginationProvider);
    final allCategories = ref.watch(categoryProvider);

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
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    /// CATEGORY COUNT
                    if (allCategories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Categories (${allCategories.length} of ${pagination.totalItems})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                    /// CATEGORY LIST
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index < filteredList.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: CategoryCard(
                              cat: filteredList[index],
                              canEdit: canEdit,
                              canDelete: canDelete,
                            ),
                          );
                        }
                        return null;
                      }, childCount: filteredList.length),
                    ),

                    /// EMPTY STATE
                    if (filteredList.isEmpty &&
                        searchQuery.isEmpty &&
                        allCategories.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No categories found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    /// SEARCH EMPTY STATE
                    if (filteredList.isEmpty && searchQuery.isNotEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No results found for '$searchQuery'",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Try searching with different keywords",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    /// LOAD MORE INDICATOR
                    if (pagination.isLoadingMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),

                    /// NO MORE DATA MESSAGE
                    if (!pagination.hasMoreData && allCategories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              "No more categories",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),

                    /// EXTRA SPACE AT BOTTOM
                    SliverToBoxAdapter(child: Container(height: 50)),
                  ],
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
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text("Delete Category"),
                                      content: Text(
                                        "Are you sure you want to delete '${cat.name}'?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(
                                              context,
                                            ); // close dialog

                                            await ref
                                                .read(categoryProvider.notifier)
                                                .delete(cat.id);

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Category deleted successfully",
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Yes",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
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
