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
      baseUrl: "https://dashboard.theceramicstudio.in/api/qualities",
      headers: {"Content-Type": "application/json"},
    ),
  );
});

/// ================= SEARCH QUERY PROVIDER =================
final searchQueryProvider = StateProvider<String>((ref) => '');

/// ================= QUALITY NOTIFIER (now with built-in pagination) =================
class QualityNotifier extends StateNotifier<AsyncValue<List<Quality>>> {
  final Ref ref;

  // Pagination state – kept internally, not in a separate provider
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  QualityNotifier(this.ref) : super(const AsyncLoading()) {
    // Initial fetch – does NOT modify any external provider
    _fetchInitial();
  }

  Dio get dio => ref.read(dioProvider);

  // Public getters for pagination (used by the UI)
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Internal method for the initial load (no pagination updates)
  Future<void> _fetchInitial() async {
    try {
      state = const AsyncLoading();
      final res = await dio.get(
        "/list",
        queryParameters: {"page": 1, "limit": 10},
      );

      final List data = res.data['qualities'] ?? [];
      final paginationData = res.data['pagination'] ?? {};
      _totalPages = paginationData['totalPages'] ?? 1;
      _hasMoreData = 1 < _totalPages;
      _currentPage = 1;

      state = AsyncData(data.map((e) => Quality.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Public method to fetch qualities (with pagination support)
  Future<void> fetchQualities({bool isLoadMore = false}) async {
    // Prevent concurrent loads
    if (isLoadMore && (_isLoadingMore || !_hasMoreData)) return;

    if (isLoadMore) {
      _isLoadingMore = true;
      // Notify UI that loadingMore changed (we need to trigger rebuild)
      // Since state doesn't change, we must notify listeners manually.
      // To keep it simple, we'll use a separate provider for pagination flags.
      // But for now, we'll call a helper to update pagination state without changing the list.
      _notifyPaginationListeners();
    }

    try {
      final page = isLoadMore ? _currentPage + 1 : 1;

      final res = await dio.get(
        "/list",
        queryParameters: {"page": page, "limit": 10},
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
        _currentPage = page;
      } else {
        state = AsyncData(data.map((e) => Quality.fromJson(e)).toList());
        _currentPage = 1;
      }

      _totalPages = totalPages;
      _hasMoreData = _currentPage < _totalPages;
    } catch (e, st) {
      if (!isLoadMore) {
        state = AsyncError(e, st);
      }
    } finally {
      if (isLoadMore) {
        _isLoadingMore = false;
        _notifyPaginationListeners();
      }
    }
  }

  /// Force a refresh (reset to page 1)
  Future<void> refresh() async {
    await fetchQualities(isLoadMore: false);
  }

  /// Load next page
  Future<void> loadMore() async {
    await fetchQualities(isLoadMore: true);
  }

  /// Notify listeners that pagination flags changed (without altering the list)
  /// We achieve this by updating a dummy provider that widgets can listen to.
  /// But for simplicity, we'll create a separate provider for pagination.
  /// However, to keep the example self-contained, we'll instead expose the pagination
  /// via a separate provider that watches this notifier's internal state.
  /// See below: `paginationInfoProvider`.
  void _notifyPaginationListeners() {
    // This method is a placeholder. We'll use a separate provider to expose pagination.
    // The real notification happens via that provider's state changes.
  }

  // CRUD methods (unchanged)
  Future<void> createQuality(String name) async {
    await dio.post(
      "/create",
      data: {
        "name": name,
        "status": "Available",
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
    await refresh();
  }

  Future<void> updateQuality(Quality q) async {
    await dio.put(
      "/update/${q.id}",
      data: {"name": q.name, "status": q.status},
    );
    await refresh();
  }

  Future<void> deleteQuality(int id) async {
    await dio.delete("/delete/$id");
    await refresh();
  }

  Future<void> toggleStatus(Quality q, bool value) async {
    await updateQuality(
      q.copyWith(status: value ? "Available" : "unAvailable"),
    );
  }
}

/// ================= PROVIDER FOR QUALITY LIST =================
final qualityProvider =
    StateNotifierProvider<QualityNotifier, AsyncValue<List<Quality>>>((ref) {
      return QualityNotifier(ref);
    });

/// ================= PROVIDER FOR PAGINATION INFO =================
/// This provider watches the QualityNotifier and exposes its pagination state.
// final paginationInfoProvider = Provider<PaginationInfo>((ref) {
//   final notifier = ref.watch(qualityProvider.notifier);
//   // We need to rebuild when the notifier's internal pagination changes.
//   // To achieve that, we listen to a dummy state that we update manually.
//   // A simpler way is to use `ref.listen` inside the widget to get the notifier
//   // and read its properties directly, but that won't cause rebuilds.
//   // Instead, we can create a small StateProvider that the notifier updates.
//   // For brevity, we'll keep pagination inside the widget using a `State` that we update.
//   // However, to follow Riverpod patterns, we'll use a separate StateProvider that the notifier can update.
//   // Let's implement a simple solution: expose pagination as a separate stream.
//   // But for now, I'll provide a getter that can be used with `ref.watch(qualityProvider.notifier).hasMoreData` etc.,
//   // but that won't cause rebuilds when those flags change. So we need a different approach.
//   // To keep the answer concise, I'll modify the UI to use a `ConsumerStatefulWidget` that holds local pagination state
//   // and updates it via callbacks from the notifier. That is simpler and avoids over‑engineering.
//   // I'll show that in the screen widget.
//   throw UnimplementedError(
//     'See explanation above – we will handle pagination inside the screen widget.',
//   );
// });

/// ================= FILTERED QUALITIES PROVIDER (unchanged) =================
final filteredQualitiesProvider = Provider<AsyncValue<List<Quality>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final qualities = ref.watch(qualityProvider);

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

/// ================= SEARCH BAR WIDGET (unchanged) =================
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
class QualityManagementScreen extends ConsumerStatefulWidget {
  const QualityManagementScreen({super.key});

  @override
  ConsumerState<QualityManagementScreen> createState() =>
      _QualityManagementScreenState();
}

class _QualityManagementScreenState
    extends ConsumerState<QualityManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(qualityProvider.notifier);
    if (notifier.isLoadingMore || !notifier.hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _hasMoreData =
          notifier.hasMoreData; // initial value, will be updated after load
    });

    await notifier.loadMore();

    setState(() {
      _isLoadingMore = false;
      _hasMoreData = notifier.hasMoreData;
    });
  }

  Future<void> _refresh() async {
    final notifier = ref.read(qualityProvider.notifier);
    await notifier.refresh();
    setState(() {
      _hasMoreData = notifier.hasMoreData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = PermissionManager.hasPermission("Quality Management_Add");
    final canEdit = PermissionManager.hasPermission("Quality Management_Edit");
    final canDelete = PermissionManager.hasPermission(
      "Quality Management_Delete",
    );

    final searchQuery = ref.watch(searchQueryProvider);
    final filteredState = ref.watch(filteredQualitiesProvider);

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
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
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

                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),

                      if (!_hasMoreData && list.isNotEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                "No more qualities",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),

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
