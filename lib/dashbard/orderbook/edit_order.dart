import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EditOrderScreen extends StatefulWidget {
  final Map order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late TextEditingController productController;
  late TextEditingController brandController;
  late TextEditingController sizeController;
  late TextEditingController qualityController;
  late TextEditingController quantityController;
  late TextEditingController dateController;

  DateTime? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    productController = TextEditingController(text: widget.order["name"]);
    brandController = TextEditingController(text: widget.order["brand"]);
    sizeController = TextEditingController(text: widget.order["size"]);
    qualityController = TextEditingController(text: widget.order["quality"]);
    quantityController = TextEditingController(text: widget.order["quantity"]);

    final date = widget.order["date"].toString().split("T").first;
    dateController = TextEditingController(text: date);
    selectedDate = DateTime.parse(date);
  }

  /// ================= DATE PICKER =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate = picked;
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  /// ================= UPDATE ORDER API =================
  Future<void> _updateOrder() async {
    setState(() => isLoading = true);

    try {
      await Dio().put(
        "https://dashboarduat.theceramicstudio.in/api/orderBook/update/${widget.order["id"]}",
        data: {
          "name": productController.text.trim(),
          "size": sizeController.text.trim(),
          "quality": qualityController.text.trim(),
          "date": dateController.text.trim(),
          "quantity": quantityController.text.trim(),
          "brand": brandController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 150),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Edit Order",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _label("Product Name"),
                      _field(productController),

                      const SizedBox(height: 12),

                      _label("Brand Name"),
                      _field(brandController),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Size"),
                                _field(sizeController),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Quality"),
                                _field(qualityController),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Order Date"),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: _decoration(
                                    "YYYY-MM-DD",
                                    icon: Icons.calendar_month,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Quantity"),
                                _field(quantityController),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Discard"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _updateOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA54A),
                              ),
                              child:
                                  isLoading
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        "Update Order",
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HELPERS =================
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  Widget _field(TextEditingController controller) {
    return TextField(controller: controller, decoration: _decoration(""));
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
