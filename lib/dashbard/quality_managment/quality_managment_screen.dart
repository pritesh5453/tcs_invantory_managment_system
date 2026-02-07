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

/// ================= PROVIDER =================
final qualityProvider =
    StateNotifierProvider<QualityNotifier, AsyncValue<List<Quality>>>(
      (ref) => QualityNotifier(ref),
    );

class QualityNotifier extends StateNotifier<AsyncValue<List<Quality>>> {
  final Ref ref;

  QualityNotifier(this.ref) : super(const AsyncLoading()) {
    fetchQualities();
  }

  Dio get dio => ref.read(dioProvider);

  /// ---------- LIST ----------
  Future<void> fetchQualities() async {
    try {
      final res = await dio.get(
        "/list",
        queryParameters: {"page": 1, "limit": 10},
      );

      final List data = res.data['qualities'];
      state = AsyncData(data.map((e) => Quality.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
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

    final state = ref.watch(qualityProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// TOP BAR (UI SAME)
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

          /// LIST
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data:
                  (list) => RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(qualityProvider.notifier).fetchQualities();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder:
                          (_, i) => QualityCard(
                            q: list[i],
                            canEdit: canEdit,
                            canDelete: canDelete,
                          ),
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
