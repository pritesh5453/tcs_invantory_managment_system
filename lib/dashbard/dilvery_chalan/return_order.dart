import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReturnItemsPage extends StatefulWidget {
  final int challanId;
  const ReturnItemsPage({Key? key, required this.challanId}) : super(key: key);

  @override
  _ReturnItemsPageState createState() => _ReturnItemsPageState();
}

class _ReturnItemsPageState extends State<ReturnItemsPage> {
  List<ReturnItem> _items = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      final url = Uri.parse(
        'https://dashboard.theceramicstudio.in/api/Quotation/delivery-challan-items/${widget.challanId}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          final items = data.map((item) => ReturnItem.fromJson(item)).toList();
          setState(() {
            _items = items;
            _isLoading = false;
          });
          _createControllers();
        } else {
          setState(() {
            _error = 'Failed to load data: ${jsonData['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _createControllers() {
    for (var item in _items) {
      _controllers[item.id] = TextEditingController(
        text: item.returnQuantity.toString(),
      );
    }
  }

  void _updateQuantity(ReturnItem item, int newValue) {
    final clamped = newValue.clamp(0, item.dispatchQty);
    if (item.returnQuantity != clamped) {
      setState(() {
        item.returnQuantity = clamped;
        _controllers[item.id]?.text = clamped.toString();
      });
    }
  }

  void _incrementQuantity(ReturnItem item) {
    if (item.returnQuantity < item.dispatchQty) {
      _updateQuantity(item, item.returnQuantity + 1);
    }
  }

  void _decrementQuantity(ReturnItem item) {
    if (item.returnQuantity > 0) {
      _updateQuantity(item, item.returnQuantity - 1);
    }
  }

  Future<void> _submitReturn() async {
    // Safety: clamp all return quantities to dispatch quantity
    for (var item in _items) {
      if (item.returnQuantity > item.dispatchQty) {
        _updateQuantity(item, item.dispatchQty);
      }
    }

    final itemsToReturn =
        _items.where((item) => item.returnQuantity > 0).map((item) {
          return {
            'id': item.id,
            'productId': item.productId,
            'productName': item.productName,
            'itemType': item.itemType,
            'returnQuantity': item.returnQuantity,
            'originalDispatchQty': item.dispatchQty,
          };
        }).toList();

    if (itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one return quantity'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'challanId': widget.challanId,
        'returnedAt': DateTime.now().toIso8601String(),
        'items': itemsToReturn,
      };

      final url = Uri.parse(
        'https://dashboard.theceramicstudio.in/api/Quotation/process-return',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resData['message'] ?? 'Return processed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resData['message'] ?? 'Failed to process return'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error while submitting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Items'),
        backgroundColor: const Color(0xFFFA9C42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchItems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA9C42),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildReturnCard(item);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReturn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFA9C42),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Process Return',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildReturnCard(ReturnItem item) {
    final controller = _controllers[item.id];
    if (controller == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: const Color(0xFFFA9C42), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.size,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Dispatched Qty:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.dispatchQty}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Return Qty:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _decrementQuantity(item),
                        icon: const Icon(Icons.remove, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            final qty = int.tryParse(value) ?? 0;
                            final clamped = qty.clamp(0, item.dispatchQty);
                            if (clamped != item.returnQuantity) {
                              setState(() {
                                item.returnQuantity = clamped;
                                controller.text = clamped.toString();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _incrementQuantity(item),
                        icon: const Icon(Icons.add, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Model class
class ReturnItem {
  final int id;
  final int productId;
  final String productName;
  final String size;
  final int dispatchQty;
  final String itemType;
  int returnQuantity;

  ReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.size,
    required this.dispatchQty,
    required this.itemType,
    this.returnQuantity = 0,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      size: json['size'] ?? '',
      dispatchQty: json['dispatchQty'],
      itemType: json['itemType'] ?? 'standard',
    );
  }
}
