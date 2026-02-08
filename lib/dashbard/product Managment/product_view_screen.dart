import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ProductViewScreen extends StatefulWidget {
  final int productId;

  const ProductViewScreen({super.key, required this.productId});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  bool loading = true;
  Map<String, dynamic>? product;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  /// ================= API CALL =================
  Future<void> fetchProduct() async {
    try {
      final res = await dio.get("/product/list/${widget.productId}");

      if (res.data['success'] == true) {
        setState(() {
          product = res.data['product'];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("VIEW API ERROR: $e");
      setState(() => loading = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFA54A),
        title: const Text("Product Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : product == null
              ? const Center(child: Text("No data found"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// PRODUCT IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product!['image_url'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _infoRow("Name", product!['name'].toString().trim()),
                      _infoRow(
                        "Category",
                        product!['category'].toString().trim(),
                      ),
                      _infoRow("Brand", product!['brand'].toString().trim()),
                      _infoRow("Rate", "₹${product!['rate']}"),
                      _infoRow(
                        "Quality",
                        product!['quality'].toString().trim(),
                      ),
                      _infoRow(
                        "Godown",
                        (product!['godown'] as List).join(", "),
                      ),

                      const SizedBox(height: 12),

                      /// BATCH DETAILS
                      const Text(
                        "Batch Details",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),

                      ...(product!['batches'] as List).map(
                        (b) => Text(
                          "Batch ${b['batch_no']}: Qty=${b['qty']}, Loc=${b['location']}",
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// BARCODE & QR
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                      //   children: const [
                      //     _BarcodeBlock(
                      //       icon: Icons.barcode_reader,
                      //       label: "test3",
                      //     ),
                      //     _BarcodeBlock(
                      //       icon: Icons.qr_code,
                      //       label: "gajre.ramesh@gmail.com",
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// INFO ROW
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= BARCODE / QR BLOCK =================
class _BarcodeBlock extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BarcodeBlock({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Icon(icon, size: 80), const SizedBox(height: 6), Text(label)],
    );
  }
}
