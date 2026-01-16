import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// ================= APP =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QualityManagementScreen(),
    );
  }
}

/// ================= MODEL =================
class Quality {
  final String id;
  final String name;
  final bool isAvailable;

  Quality({required this.id, required this.name, required this.isAvailable});

  Quality copyWith({String? name, bool? isAvailable}) {
    return Quality(
      id: id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// ================= PROVIDER =================
final qualityProvider = StateNotifierProvider<QualityNotifier, List<Quality>>(
  (ref) => QualityNotifier(),
);

class QualityNotifier extends StateNotifier<List<Quality>> {
  QualityNotifier()
    : super([
        Quality(id: "01", name: "New Product 01", isAvailable: true),
        Quality(id: "02", name: "New Product 02", isAvailable: false),
        Quality(id: "03", name: "New Product 03", isAvailable: true),
      ]);

  void add(Quality q) => state = [...state, q];

  void update(Quality q) {
    state = [
      for (final e in state)
        if (e.id == q.id) q else e,
    ];
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void toggle(String id, bool value) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(isAvailable: value) else e,
    ];
  }
}

/// ================= MAIN SCREEN =================
class QualityManagementScreen extends ConsumerWidget {
  const QualityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(qualityProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// TOP BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 20),
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
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const QualityPopup(),
                    );
                  },
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
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => QualityCard(q: list[i]),
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
  const QualityCard({super.key, required this.q});

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
          /// STATUS + 3 DOT MENU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(q.isAvailable ? "Available" : "Unavailable"),
                backgroundColor:
                    q.isAvailable
                        ? const Color(0xFFE6F7E6)
                        : const Color(0xFFFDECEA),
                labelStyle: TextStyle(
                  color: q.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),

              /// 3 DOT MENU
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'available') {
                    ref.read(qualityProvider.notifier).toggle(q.id, true);
                  } else if (value == 'unavailable') {
                    ref.read(qualityProvider.notifier).toggle(q.id, false);
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(
                        value: 'available',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text("Available"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unavailable',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text("Unavailable"),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info("Quality Id", q.id),
              _info("Standard Name", q.name),
            ],
          ),

          const SizedBox(height: 16),

          /// EDIT / DELETE
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => QualityPopup(edit: q),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("Delete"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () {
                    ref.read(qualityProvider.notifier).delete(q.id);
                  },
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
              onPressed: () {
                if (isEdit) {
                  ref
                      .read(qualityProvider.notifier)
                      .update(widget.edit!.copyWith(name: ctrl.text));
                } else {
                  ref
                      .read(qualityProvider.notifier)
                      .add(
                        Quality(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: ctrl.text,
                          isAvailable: true,
                        ),
                      );
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
