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
      home: CategoryManagementScreen(),
    );
  }
}

/// ================= MODEL =================
class Category {
  final String id;
  final String name;
  final bool isAvailable;

  Category({required this.id, required this.name, required this.isAvailable});

  Category copyWith({String? name, bool? isAvailable}) {
    return Category(
      id: id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// ================= PROVIDER =================
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
      (ref) => CategoryNotifier(),
    );

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier()
    : super([
        Category(id: "01", name: "New Product 01", isAvailable: true),
        Category(id: "02", name: "New Product 02", isAvailable: true),
        Category(id: "03", name: "New Product 03", isAvailable: false),
      ]);

  void add(Category c) => state = [...state, c];

  void update(Category c) {
    state = [
      for (final e in state)
        if (e.id == c.id) c else e,
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
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// 🔶 TOP BAR
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
                      builder: (_) => const CategoryPopup(),
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

          /// 🔶 LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => CategoryCard(cat: list[i]),
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
  const CategoryCard({super.key, required this.cat});

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
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  ref.read(categoryProvider.notifier).toggle(cat.id, v == "a");
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info("Index", cat.id),
              _info("Category Name", cat.name),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CategoryPopup(edit: cat),
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
                    ref.read(categoryProvider.notifier).delete(cat.id);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  isEdit ? "Edit Category" : "Add New Category",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text("Category Name"),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: "enter category name..",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const Text("Availability Status"),
            const SizedBox(height: 6),
            DropdownButtonFormField<bool>(
              value: isAvailable,
              items: const [
                DropdownMenuItem(value: true, child: Text("Available")),
                DropdownMenuItem(value: false, child: Text("Unavailable")),
              ],
              onChanged: (v) => setState(() => isAvailable = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
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
                        .add(
                          Category(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            name: nameCtrl.text,
                            isAvailable: isAvailable,
                          ),
                        );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
