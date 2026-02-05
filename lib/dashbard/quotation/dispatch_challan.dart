import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DispatchChallanScreen extends StatefulWidget {
  final int quotationId;
  final Map<String, dynamic> quotationData;

  const DispatchChallanScreen({
    super.key,
    required this.quotationId,
    required this.quotationData,
  });

  @override
  State<DispatchChallanScreen> createState() => _DispatchChallanScreenState();
}

class _DispatchChallanScreenState extends State<DispatchChallanScreen> {
  final TextEditingController dispatchCtrl = TextEditingController(text: "0");
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  // Form controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final vehicleCtrl = TextEditingController();

  int dispatchQty = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill vehicle number with default
    _inputField(contactCtrl, "MH-15", keyboardType: TextInputType.phone);
    debugPrint("Quotation Data: ${widget.quotationData}");
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    contactCtrl.dispose();
    vehicleCtrl.dispose();
    super.dispose();
  }

  int getTotalWarehouseBoxes() {
    int total = 0;

    final items = widget.quotationData['items'];
    if (items != null && items is List) {
      for (final item in items) {
        final stock = item['currentStock'] ?? 0;

        total += stock is int ? stock : int.tryParse(stock.toString()) ?? 0;
      }
    }

    return total;
  }

  /// ================= GET FIRST ITEM =================
  Map<String, dynamic>? getFirstItem() {
    final items = widget.quotationData['items'];
    if (items != null && items is List && items.isNotEmpty) {
      return items[0];
    }
    return null;
  }

  /// ================= GET PENDING BOXES =================
  int getPendingBoxes() {
    final firstItem = getFirstItem();
    if (firstItem != null) {
      final remainingBoxes = firstItem['remainingBoxes'] ?? 0;
      return remainingBoxes is int
          ? remainingBoxes
          : int.tryParse(remainingBoxes.toString()) ?? 0;
    }
    return 0;
  }

  /// ================= VALIDATE FORM =================
  bool _validateForm() {
    if (firstNameCtrl.text.trim().isEmpty) {
      _showSnackbar("Please enter first name");
      return false;
    }
    if (lastNameCtrl.text.trim().isEmpty) {
      _showSnackbar("Please enter last name");
      return false;
    }
    if (contactCtrl.text.trim().isEmpty) {
      _showSnackbar("Please enter contact number");
      return false;
    }
    if (contactCtrl.text.trim().length < 10) {
      _showSnackbar("Please enter valid contact number");
      return false;
    }
    if (vehicleCtrl.text.trim().isEmpty) {
      _showSnackbar("Please enter vehicle number");
      return false;
    }
    if (dispatchQty <= 0) {
      _showSnackbar("Please enter dispatch quantity");
      return false;
    }

    // Check if dispatch quantity exceeds warehouse boxes
    final warehouseBoxes = getTotalWarehouseBoxes();
    if (dispatchQty > warehouseBoxes) {
      _showSnackbar(
        "Cannot exceed available stock in warehouse ($warehouseBoxes boxes)",
      );
      return false;
    }

    return true;
  }

  /// ================= GENERATE CHALLAN API =================
  Future<void> _generateChallan() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get first item details
      final firstItem = getFirstItem();
      if (firstItem == null) {
        _showSnackbar("No items found in quotation", isError: true);
        return;
      }

      // Prepare request body
      final body = {
        "quotationId": widget.quotationId,
        "client": widget.quotationData['clientName']?.toString() ?? "",
        "contact": widget.quotationData['contactNo']?.toString() ?? "",
        "address": widget.quotationData['address']?.toString() ?? "",
        "driverDetails": {
          "deliveryBoy":
              "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}",
          "contact": contactCtrl.text.trim(),
          "tempo": vehicleCtrl.text.trim(),
        },
        "items": [
          {
            "productId": firstItem['productId'],
            "productName": firstItem['productName']?.toString() ?? "",
            "rate": firstItem['rate']?.toString() ?? "0",
            "dispatchBoxes": dispatchQty,
          },
        ],
      };

      debugPrint("Generating challan with body: ${body.toString()}");

      final response = await dio.post("/Quotation/generate-dc", data: body);

      if (response.data['success'] == true) {
        _showSnackbar(
          response.data['message'] ??
              "Delivery Challan Generated Successfully!",
          isError: false,
        );

        // Reset form
        firstNameCtrl.clear();
        lastNameCtrl.clear();
        contactCtrl.clear();
        vehicleCtrl.text = "MH-15";
        setState(() => dispatchQty = 0);

        // Close screen after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      } else {
        _showSnackbar(
          response.data['message'] ?? "Failed to generate challan",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Generate challan error: $e");
      _showSnackbar("Network error: ${e.toString()}", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= SHOW SNACKBAR =================
  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = getFirstItem();
    final productName = firstItem?['productName']?.toString() ?? "Product";
    final pendingBoxes = getPendingBoxes();
    final warehouseBoxes = getTotalWarehouseBoxes();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_shipping, color: Colors.blue),
                      SizedBox(width: 85),
                      Text(
                        "Dispatch Challan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    /// DELIVERY BOY DETAILS
                    const Text(
                      "Delivery Boy",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(firstNameCtrl, "First name"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _inputField(lastNameCtrl, "Last name")),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Contact Number",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _inputField(
                      contactCtrl,
                      "Enter Number...",
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Vehicle number (tempo)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _inputField(vehicleCtrl, "MH-15"),

                    const SizedBox(height: 14),
                    const Text(
                      "Items for Dispatch",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "In Warehouse: $warehouseBoxes boxes",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Pending in Quote: $pendingBoxes Boxes",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Dispatch Now",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                /// MANUAL INPUT
                                Expanded(
                                  child: TextField(
                                    controller: dispatchCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.left,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final qty = int.tryParse(value) ?? 0;
                                      _setDispatchQty(qty);
                                    },
                                  ),
                                ),

                                /// ARROWS
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        _setDispatchQty(dispatchQty + 1);
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_up,
                                        size: 20,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _setDispatchQty(dispatchQty - 1);
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Box",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    // Extra space at the bottom of scrollable content
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed buttons at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFA9C42),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: isLoading ? null : _generateChallan,
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  "Generate Challan",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setDispatchQty(int value) {
    final warehouseBoxes = getTotalWarehouseBoxes();

    if (value < 0) value = 0;

    if (value > warehouseBoxes) {
      _showSnackbar(
        "Cannot exceed available stock in warehouse ($warehouseBoxes boxes)",
      );
      value = warehouseBoxes;
    }

    setState(() {
      dispatchQty = value;
      dispatchCtrl.text = dispatchQty.toString();
    });
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
