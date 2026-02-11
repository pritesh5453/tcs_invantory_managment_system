import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= MODEL =================
class Quality {
  final int id;
  final String name;
  final String status;

  Quality({required this.id, required this.name, required this.status});

  bool get isAvailable => status == "Available";

  factory Quality.fromJson(Map<String, dynamic> json) {
    return Quality(id: json['id'], name: json['name'], status: json['status']);
  }

  Quality copyWith({String? name, String? status}) {
    return Quality(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }
}

/// ================= DIO CLIENT =================
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/qualities",
      headers: {"Content-Type": "application/json"},
    ),
  );
});

/// ================= PROVIDERS =================
final qualityProvider =
    StateNotifierProvider<QualityNotifier, AsyncValue<List<Quality>>>(
      (ref) => QualityNotifier(ref),
    );

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Pagination state provider
final paginationStateProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
      return PaginationNotifier();
    });

class PaginationState {
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool hasMoreData;

  PaginationState({
    required this.currentPage,
    required this.totalPages,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  PaginationState.initial()
    : currentPage = 1,
      totalPages = 1,
      isLoadingMore = false,
      hasMoreData = true;

  PaginationState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? hasMoreData,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

class PaginationNotifier extends StateNotifier<PaginationState> {
  PaginationNotifier() : super(PaginationState.initial());

  void setLoadingMore(bool isLoading) {
    state = state.copyWith(isLoadingMore: isLoading);
  }

  void updatePagination(int currentPage, int totalPages) {
    state = state.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      hasMoreData: currentPage < totalPages,
    );
  }

  void reset() {
    state = PaginationState.initial();
  }
}

// Filtered qualities provider with pagination
final filteredQualitiesProvider = Provider<AsyncValue<List<Quality>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final qualities = ref.watch(qualityProvider);
  final pagination = ref.watch(paginationStateProvider);

  return qualities.when(
    data: (qualitiesList) {
      if (searchQuery.isEmpty) {
        return AsyncData(qualitiesList);
      }
      final filteredList =
          qualitiesList.where((quality) {
            return quality.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                quality.id.toString().contains(searchQuery) ||
                quality.status.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
          }).toList();
      return AsyncData(filteredList);
    },
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
  );
});

class QualityNotifier extends StateNotifier<AsyncValue<List<Quality>>> {
  final Ref ref;

  QualityNotifier(this.ref) : super(const AsyncLoading()) {
    fetchQualities();
  }

  Dio get dio => ref.read(dioProvider);

  /// ---------- LIST WITH PAGINATION ----------
  Future<void> fetchQualities({bool isLoadMore = false}) async {
    try {
      final pagination = ref.read(paginationStateProvider.notifier);

      if (!isLoadMore) {
        pagination.reset();
        state = const AsyncLoading();
      } else {
        pagination.setLoadingMore(true);
      }

      final currentPage =
          isLoadMore ? ref.read(paginationStateProvider).currentPage + 1 : 1;

      final res = await dio.get(
        "/list",
        queryParameters: {"page": currentPage, "limit": 10},
      );

      final List data = res.data['qualities'] ?? [];
      final paginationData = res.data['pagination'] ?? {};
      final totalPages = paginationData['totalPages'] ?? 1;

      if (isLoadMore) {
        final currentList = state.value ?? [];
        state = AsyncData([
          ...currentList,
          ...data.map((e) => Quality.fromJson(e)).toList(),
        ]);
      } else {
        state = AsyncData(data.map((e) => Quality.fromJson(e)).toList());
      }

      pagination.updatePagination(currentPage, totalPages);
      pagination.setLoadingMore(false);
    } catch (e, st) {
      state = AsyncError(e, st);
      ref.read(paginationStateProvider.notifier).setLoadingMore(false);
    }
  }

  /// ---------- CREATE ----------
  Future<void> createQuality(String name) async {
    await dio.post(
      "/create",
      data: {
        "name": name,
        "status": "Available",
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
    fetchQualities();
  }

  /// ---------- UPDATE ----------
  Future<void> updateQuality(Quality q) async {
    await dio.put(
      "/update/${q.id}",
      data: {"name": q.name, "status": q.status},
    );
    fetchQualities();
  }

  /// ---------- DELETE ----------
  Future<void> deleteQuality(int id) async {
    await dio.delete("/delete/$id");
    fetchQualities();
  }

  /// ---------- TOGGLE STATUS ----------
  Future<void> toggleStatus(Quality q, bool value) async {
    await updateQuality(
      q.copyWith(status: value ? "Available" : "unAvailable"),
    );
  }

  /// ---------- LOAD MORE ----------
  Future<void> loadMore() async {
    final pagination = ref.read(paginationStateProvider);
    if (pagination.isLoadingMore || !pagination.hasMoreData) return;

    await fetchQualities(isLoadMore: true);
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
class QualityManagementScreen extends ConsumerWidget {
  const QualityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdd = PermissionManager.hasPermission("Quality Management_Add");
    final canEdit = PermissionManager.hasPermission("Quality Management_Edit");
    final canDelete = PermissionManager.hasPermission(
      "Quality Management_Delete",
    );

    final searchQuery = ref.watch(searchQueryProvider);
    final filteredState = ref.watch(filteredQualitiesProvider);
    final pagination = ref.watch(paginationStateProvider);
    final scrollController = ScrollController();

    // Scroll listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          !pagination.isLoadingMore &&
          pagination.hasMoreData &&
          searchQuery.isEmpty) {
        ref.read(qualityProvider.notifier).loadMore();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// TOP BAR WITH SEARCH
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
                              builder: (_) => const QualityPopup(),
                            );
                          }
                          : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You don't have permission to add quality.",
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
            child: filteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (list) {
                if (searchQuery.isNotEmpty && list.isEmpty) {
                  return Center(
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
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(qualityProvider.notifier).fetchQualities();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      /// QUALITIES LIST
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index < list.length) {
                            return QualityCard(
                              q: list[index],
                              canEdit: canEdit,
                              canDelete: canDelete,
                            );
                          }
                          return null;
                        }, childCount: list.length),
                      ),

                      /// EMPTY STATE
                      if (list.isEmpty && searchQuery.isEmpty)
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
                                Text(
                                  "No qualities found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
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
                      if (!pagination.hasMoreData && list.isNotEmpty)
                        SliverToBoxAdapter(
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                "No more qualities",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),

                      /// EXTRA SPACE AT BOTTOM
                      SliverToBoxAdapter(child: Container(height: 50)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= CARD =================
class QualityCard extends ConsumerWidget {
  final Quality q;
  final bool canEdit;
  final bool canDelete;
  const QualityCard({
    super.key,
    required this.q,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS + MENU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(q.status),
                backgroundColor:
                    q.isAvailable
                        ? const Color(0xFFE6F7E6)
                        : const Color(0xFFFDECEA),
                labelStyle: TextStyle(
                  color: q.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == "available") {
                    ref.read(qualityProvider.notifier).toggleStatus(q, true);
                  } else {
                    ref.read(qualityProvider.notifier).toggleStatus(q, false);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: "available",
                        child: Text("Available"),
                      ),
                      PopupMenuItem(
                        value: "unavailable",
                        child: Text("Unavailable"),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info("Quality Id", q.id.toString()),
              _info("Standard Name", q.name),
            ],
          ),

          const SizedBox(height: 16),

          /// EDIT / DELETE
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: canEdit ? 1 : 0.4,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                    onPressed:
                        canEdit
                            ? () {
                              showDialog(
                                context: context,
                                builder: (_) => QualityPopup(edit: q),
                              );
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to edit quality.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: canDelete ? 1 : 0.4,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed:
                        canDelete
                            ? () {
                              ref
                                  .read(qualityProvider.notifier)
                                  .deleteQuality(q.id);
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to delete quality.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _info(String t, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// ================= ADD / EDIT POPUP =================
class QualityPopup extends ConsumerStatefulWidget {
  final Quality? edit;
  const QualityPopup({super.key, this.edit});

  @override
  ConsumerState<QualityPopup> createState() => _QualityPopupState();
}

class _QualityPopupState extends ConsumerState<QualityPopup> {
  late TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.edit?.name ?? "");
  }

  @override
  void dispose() {
    ctrl.dispose();
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
              isEdit ? "Edit Quality" : "Add New Quality",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: "Quality Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA54A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter quality name"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (isEdit) {
                  await ref
                      .read(qualityProvider.notifier)
                      .updateQuality(widget.edit!.copyWith(name: ctrl.text));
                } else {
                  await ref
                      .read(qualityProvider.notifier)
                      .createQuality(ctrl.text);
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
