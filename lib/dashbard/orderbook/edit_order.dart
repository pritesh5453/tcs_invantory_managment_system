import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/order_model.dart'
    as order_model;
import 'package:tcs_invantory_managment_system/dashbard/orderbook/order_services.dart';

class EditOrderScreen extends StatefulWidget {
  final order_model.Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  List<order_model.Brand> _brands = [];
  order_model.Brand? _selectedBrand;
  DateTime _orderDate = DateTime.now();
  final List<_EditProductRowData> _productRows = [];
  bool _isLoading = false;
  bool _isLoadingBrands = false;

  @override
  void initState() {
    super.initState();
    _orderDate = widget.order.orderDate;
    _loadBrands();
    _initializeProducts();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final brands = await OrderApiService.fetchBrands();
      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
        // ✅ Correct way to find matching brand
        final matchingBrands = _brands.where(
          (b) => b.name == widget.order.brandName,
        );
        _selectedBrand =
            matchingBrands.isNotEmpty ? matchingBrands.first : null;
      });
    } catch (e) {
      setState(() => _isLoadingBrands = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load brands: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeProducts() {
    for (var p in widget.order.products) {
      _productRows.add(
        _EditProductRowData(
          productName: p.productName,
          size: p.size,
          quality: p.quality,
          quantity: p.quantity.toString(),
        ),
      );
    }
    // If no products, add one empty row
    if (_productRows.isEmpty) {
      _productRows.add(_EditProductRowData());
    }
  }

  void _addProductRow() {
    setState(() {
      _productRows.add(_EditProductRowData());
    });
  }

  void _removeProductRow(int index) {
    if (_productRows.length > 1) {
      setState(() {
        _productRows.removeAt(index);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _orderDate) {
      setState(() => _orderDate = picked);
    }
  }

  bool _validateForm() {
    if (_selectedBrand == null) {
      _showSnack('Please select a brand', Colors.orange);
      return false;
    }
    for (var i = 0; i < _productRows.length; i++) {
      final row = _productRows[i];
      if (row.selectedProduct == null && row.productName.isEmpty) {
        _showSnack('Row ${i + 1}: Please select a product', Colors.orange);
        return false;
      }
      if (row.quantity.isEmpty) {
        _showSnack('Row ${i + 1}: Please enter quantity', Colors.orange);
        return false;
      }
      if (int.tryParse(row.quantity) == null || int.parse(row.quantity) <= 0) {
        _showSnack(
          'Row ${i + 1}: Quantity must be a positive number',
          Colors.orange,
        );
        return false;
      }
    }
    return true;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _submitEdit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final products =
        _productRows.map((row) {
          final prod = row.selectedProduct;
          return {
            'productName': prod?.name ?? row.productName,
            'size': prod?.size ?? row.size,
            'quality': prod?.quality ?? row.quality,
            'quantity': row.quantity,
          };
        }).toList();

    try {
      final response = await OrderApiService.updateOrder(
        orderId: widget.order.id,
        brandId: _selectedBrand!.id.toString(),
        brandName: _selectedBrand!.name,
        orderDate: DateFormat('yyyy-MM-dd').format(_orderDate),
        products: products,
      );

      if (response['success'] == true && mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Success'),
                content: Text(
                  'Order updated successfully!\nOrder ID: ${response['orderId'] ?? widget.order.orderId}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context, true); // return with success
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        throw Exception(response['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showSnack('Failed to update order: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Order'),
        backgroundColor: const Color(0xFFFFA54A),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoadingBrands
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildBrandDropdown(),
                    const SizedBox(height: 24),
                    const Text(
                      'PRODUCTS LIST',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildProductRows(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed:
                            _selectedBrand == null ? null : _addProductRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFA54A),
                          side: const BorderSide(color: Color(0xFFFFA54A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA54A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Update Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'ORDER DATE',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('dd-MM-yyyy').format(_orderDate),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<order_model.Brand>(
          value: _selectedBrand,
          hint: const Text('SELECT BRAND'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items:
              _brands.map((brand) {
                return DropdownMenuItem<order_model.Brand>(
                  value: brand,
                  child: Text(brand.name),
                );
              }).toList(),
          onChanged: (brand) {
            setState(() {
              _selectedBrand = brand;
              // Optionally clear products if brand changes? But we keep existing.
            });
          },
        ),
      ),
    );
  }

  List<Widget> _buildProductRows() {
    return _productRows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            EditProductSearchField(
              key: ValueKey('${row.id}_${row.productName}'),
              brandName: _selectedBrand?.name,
              onProductSelected: (suggestion) {
                row.selectedProduct = suggestion;
                if (suggestion != null) {
                  row.productName = suggestion.name;
                  row.size = suggestion.size;
                  row.quality = suggestion.quality;
                }
              },
              initialProductName: row.productName,
              initialSize: row.size,
              initialQuality: row.quality,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: row.quantity)
                      ..selection = TextSelection.collapsed(
                        offset: row.quantity.length,
                      ),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => row.quantity = value,
                  ),
                ),
                if (_productRows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeProductRow(index),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ---------- Helper Classes ----------

class _EditProductRowData {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
  ProductSuggestion? selectedProduct;
  String productName;
  String size;
  String quality;
  String quantity;

  _EditProductRowData({
    this.productName = '',
    this.size = '',
    this.quality = '',
    this.quantity = '1',
  });
}

// ---------- Product Search Field for Edit (pre-filled) ----------

class EditProductSearchField extends StatefulWidget {
  final String? brandName;
  final Function(ProductSuggestion?) onProductSelected;
  final String initialProductName;
  final String initialSize;
  final String initialQuality;

  const EditProductSearchField({
    super.key,
    required this.brandName,
    required this.onProductSelected,
    this.initialProductName = '',
    this.initialSize = '',
    this.initialQuality = '',
  });

  @override
  State<EditProductSearchField> createState() => _EditProductSearchFieldState();
}

class _EditProductSearchFieldState extends State<EditProductSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  ProductSuggestion? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialProductName;
    // If initial data looks like a selected product, we might treat it as such
    if (widget.initialProductName.isNotEmpty &&
        widget.initialSize.isNotEmpty &&
        widget.initialQuality.isNotEmpty) {
      // We don't have full ProductSuggestion, so just keep text
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<List<ProductSuggestion>> _searchProducts(String query) async {
    if (query.isEmpty || widget.brandName == null) return [];
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return [];
    return await OrderApiService.searchProducts(
      query: query,
      brandName: widget.brandName!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Autocomplete<ProductSuggestion>(
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty || widget.brandName == null) {
              return const Iterable.empty();
            }
            return await _searchProducts(textEditingValue.text);
          },
          displayStringForOption: (option) => option.name,
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            // Sync with internal controller
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_controller.text != textEditingController.text) {
                textEditingController.text = _controller.text;
              }
            });
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText:
                    widget.brandName == null
                        ? 'Select brand first'
                        : 'Search product...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                enabled: widget.brandName != null,
                suffixIcon:
                    _controller.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            textEditingController.clear();
                            widget.onProductSelected(null);
                            setState(() {
                              _selectedSuggestion = null;
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                _controller.text = value;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: Container(
                  width: 350,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name),
                        subtitle: Text('${option.size}  •  ${option.quality}'),
                        onTap: () {
                          onSelected(option);
                          _controller.text = option.name;
                          setState(() => _selectedSuggestion = option);
                          widget.onProductSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (option) {
            _controller.text = option.name;
            setState(() => _selectedSuggestion = option);
            widget.onProductSelected(option);
          },
        ),
        if (_selectedSuggestion == null &&
            widget.initialProductName.isNotEmpty &&
            widget.initialSize.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${widget.initialSize} • ${widget.initialQuality}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }
}
