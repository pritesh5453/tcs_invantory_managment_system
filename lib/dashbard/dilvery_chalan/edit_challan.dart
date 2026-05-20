import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// ================= EXTENDED MODEL CLASS =================
class ChallanItem {
  final int id;
  final int challanId;
  final int productId;
  final String productName;
  final String size;
  final String quality;
  int dispatchBoxes; // editable
  final int dispatchQty;
  final int remainingStock;
  double rate; // editable
  double? weight; // editable (only for extra items)

  ChallanItem({
    required this.id,
    required this.challanId,
    required this.productId,
    required this.productName,
    required this.size,
    required this.quality,
    required this.dispatchBoxes,
    required this.dispatchQty,
    required this.remainingStock,
    required this.rate,
    this.weight,
  });

  factory ChallanItem.fromJson(
    Map<String, dynamic> json, {
    bool isExtra = false,
  }) {
    return ChallanItem(
      id: json['id'] ?? 0,
      challanId: json['challanId'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      size: json['size'] ?? '',
      quality: json['quality'] ?? '',
      dispatchBoxes: json['dispatchBoxes'] ?? 0,
      dispatchQty: json['dispatchQty'] ?? 0,
      remainingStock: json['remainingStock'] ?? 0,
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      weight: isExtra ? (json['weight'] ?? 0.0).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'challanId': challanId,
      'productId': productId,
      'productName': productName,
      'size': size,
      'quality': quality,
      'dispatchBoxes': dispatchBoxes,
      'dispatchQty': dispatchQty,
      'remainingStock': remainingStock,
      'rate': rate.toStringAsFixed(2),
    };
    if (weight != null) {
      map['weight'] = weight!;
    }
    return map;
  }
}

class EditChallanResponse {
  final Map<String, dynamic> challan;
  final List<ChallanItem> normalItems;
  final List<ChallanItem> extraItems;

  EditChallanResponse({
    required this.challan,
    required this.normalItems,
    required this.extraItems,
  });

  factory EditChallanResponse.fromJson(Map<String, dynamic> json) {
    final challanData = json['challan'] as Map<String, dynamic>;
    final normalItemsData = json['items'] as List? ?? [];
    final extraItemsData = json['extraItems'] as List? ?? [];

    return EditChallanResponse(
      challan: challanData,
      normalItems:
          normalItemsData.map((item) => ChallanItem.fromJson(item)).toList(),
      extraItems:
          extraItemsData
              .map((item) => ChallanItem.fromJson(item, isExtra: true))
              .toList(),
    );
  }
}

// ================= API SERVICE =================
class EditChallanApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in/api/Quotation',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<EditChallanResponse> getEditChallan(int challanId) async {
    try {
      final response = await _dio.get('/get-edit-challan/$challanId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return EditChallanResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load challan data');
      }
    } catch (e) {
      throw Exception('Error fetching challan: $e');
    }
  }

  Future<void> deleteChallanItem(String type, int itemId) async {
    try {
      await _dio.delete('/delete-challan-item/$type/$itemId');
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // ✅ Updated: POST request with items and extraItems
  Future<void> updateChallan(
    int challanId,
    List<ChallanItem> items,
    List<ChallanItem> extraItems,
  ) async {
    try {
      final payload = {
        'items': items.map((item) => item.toJson()).toList(),
        'extraItems': extraItems.map((item) => item.toJson()).toList(),
      };
      final response = await _dio.put(
        '/update-challan/$challanId',
        data: payload,
      );
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message;
      throw Exception('Update failed: $errorMsg');
    } catch (e) {
      throw Exception('Failed to update challan: $e');
    }
  }
}

// ================= EDIT SCREEN UI =================
class EditChallanScreen extends StatefulWidget {
  final int challanId;

  const EditChallanScreen({super.key, required this.challanId});

  @override
  State<EditChallanScreen> createState() => _EditChallanScreenState();
}

class _EditChallanScreenState extends State<EditChallanScreen> {
  final EditChallanApiService _apiService = EditChallanApiService();
  List<ChallanItem> _normalItems = [];
  List<ChallanItem> _extraItems = [];
  Map<String, dynamic>? _challanDetails;
  bool _isLoading = true;
  String? _error;

  // Controllers for editable fields
  final List<TextEditingController> _normalBoxesControllers = [];
  final List<TextEditingController> _normalRateControllers = [];
  final List<TextEditingController> _extraBoxesControllers = [];
  final List<TextEditingController> _extraRateControllers = [];
  final List<TextEditingController> _extraWeightControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responseData = await _apiService.getEditChallan(widget.challanId);
      setState(() {
        _challanDetails = responseData.challan;
        _normalItems = responseData.normalItems;
        _extraItems = responseData.extraItems;
        _isLoading = false;
      });
      _initControllers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _initControllers() {
    for (var item in _normalItems) {
      _normalBoxesControllers.add(
        TextEditingController(text: item.dispatchBoxes.toString()),
      );
      _normalRateControllers.add(
        TextEditingController(text: item.rate.toStringAsFixed(2)),
      );
    }
    for (var item in _extraItems) {
      _extraBoxesControllers.add(
        TextEditingController(text: item.dispatchBoxes.toString()),
      );
      _extraRateControllers.add(
        TextEditingController(text: item.rate.toStringAsFixed(2)),
      );
      _extraWeightControllers.add(
        TextEditingController(text: item.weight?.toStringAsFixed(2) ?? '0.0'),
      );
    }
  }

  void _updateNormalItem(int index) {
    final newBoxes =
        int.tryParse(_normalBoxesControllers[index].text) ??
        _normalItems[index].dispatchBoxes;
    final newRate =
        double.tryParse(_normalRateControllers[index].text) ??
        _normalItems[index].rate;
    setState(() {
      _normalItems[index].dispatchBoxes = newBoxes;
      _normalItems[index].rate = newRate;
    });
  }

  void _updateExtraItem(int index) {
    final newBoxes =
        int.tryParse(_extraBoxesControllers[index].text) ??
        _extraItems[index].dispatchBoxes;
    final newRate =
        double.tryParse(_extraRateControllers[index].text) ??
        _extraItems[index].rate;
    final newWeight =
        double.tryParse(_extraWeightControllers[index].text) ??
        _extraItems[index].weight ??
        0.0;
    setState(() {
      _extraItems[index].dispatchBoxes = newBoxes;
      _extraItems[index].rate = newRate;
      _extraItems[index].weight = newWeight;
    });
  }

  Future<void> _deleteItem(ChallanItem item, bool isExtra, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text(
              'Remove "${item.productName}" from ${isExtra ? 'Extra Items' : 'Normal Items'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final type = isExtra ? 'extra' : 'normal';
      await _apiService.deleteChallanItem(type, item.id);
      setState(() {
        if (isExtra) {
          _extraItems.removeAt(index);
          _extraBoxesControllers.removeAt(index);
          _extraRateControllers.removeAt(index);
          _extraWeightControllers.removeAt(index);
        } else {
          _normalItems.removeAt(index);
          _normalBoxesControllers.removeAt(index);
          _normalRateControllers.removeAt(index);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateChallan() async {
    // Sync all pending changes
    for (int i = 0; i < _normalItems.length; i++) _updateNormalItem(i);
    for (int i = 0; i < _extraItems.length; i++) _updateExtraItem(i);

    try {
      await _apiService.updateChallan(
        widget.challanId,
        _normalItems,
        _extraItems,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var c in _normalBoxesControllers) c.dispose();
    for (var c in _normalRateControllers) c.dispose();
    for (var c in _extraBoxesControllers) c.dispose();
    for (var c in _extraRateControllers) c.dispose();
    for (var c in _extraWeightControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Edit Challan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFA9C42),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChallanHeader(),
                    const SizedBox(height: 24),
                    _buildSection('Normal Items', isExtra: false),
                    const SizedBox(height: 24),
                    _buildSection('Extra Items', isExtra: true),
                    const SizedBox(height: 32),
                    _buildUpdateButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildChallanHeader() {
    final data = _challanDetails;
    if (data == null) return const SizedBox.shrink();

    final series = data['seriesNumber'] ?? '';
    final client = data['client'] ?? '';
    final contact = data['contact'] ?? '';
    final address = data['address'] ?? '';
    final priority = data['priority'] ?? 'NORMAL';
    final isCancel = data['isCancel'] == 1;

    Color priorityColor =
        priority == 'URGENT'
            ? Colors.red
            : (priority == 'MEDIUM' ? Colors.orange : Colors.green);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isCancel ? Colors.red : priorityColor,
              width: 6,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: priorityColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CH $series',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.person, 'Client', client),
            _infoRow(Icons.phone, 'Contact', contact),
            _infoRow(Icons.location_on, 'Address', address),
            if (isCancel)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Cancelled',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required bool isExtra}) {
    final items = isExtra ? _extraItems : _normalItems;
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExtra ? Icons.add_box : Icons.inventory,
                color: const Color(0xFFFA9C42),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No items',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isExtra ? Icons.add_box : Icons.inventory,
              color: const Color(0xFFFA9C42),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFA9C42).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length} items',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA9C42).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: const Color(0xFFFA9C42),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteItem(item, isExtra, index),
                          tooltip: 'Delete item',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller:
                                isExtra
                                    ? _extraBoxesControllers[index]
                                    : _normalBoxesControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Boxes',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (_) =>
                                    isExtra
                                        ? _updateExtraItem(index)
                                        : _updateNormalItem(index),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller:
                                isExtra
                                    ? _extraRateControllers[index]
                                    : _normalRateControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Rate (₹)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (_) =>
                                    isExtra
                                        ? _updateExtraItem(index)
                                        : _updateNormalItem(index),
                          ),
                        ),
                        if (isExtra) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _extraWeightControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateExtraItem(index),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateChallan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFA9C42),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text(
              'Update Challan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
