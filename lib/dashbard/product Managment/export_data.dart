import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Models (same as before)
class ExportProduct {
  final int id;
  final String name;
  final String size;
  final String quality;
  final String brandName;
  final String totalStock;
  ExportProduct({
    required this.id,
    required this.name,
    required this.size,
    required this.quality,
    required this.brandName,
    required this.totalStock,
  });
  factory ExportProduct.fromJson(Map<String, dynamic> json) {
    return ExportProduct(
      id: json['id'],
      name: json['name'],
      size: json['size'],
      quality: json['quality'],
      brandName: json['brand_name'],
      totalStock: json['total_stock'],
    );
  }
}

class DropdownItem {
  final String id;
  final String name;
  DropdownItem({required this.id, required this.name});
}

class ConfigureExportScreen extends StatefulWidget {
  const ConfigureExportScreen({super.key});

  @override
  State<ConfigureExportScreen> createState() => _ConfigureExportScreenState();
}

class _ConfigureExportScreenState extends State<ConfigureExportScreen> {
  List<ExportProduct> products = [];
  List<DropdownItem> brands = [];
  List<DropdownItem> qualities = [];
  bool isLoading = false;
  bool isExporting = false;
  String? errorMessage;

  final TextEditingController _sizeController = TextEditingController();
  String selectedSize = '';
  String selectedBrand = '';
  String selectedQuality = '';

  Set<int> selectedProductIds = {};
  Map<int, bool> imageIncludedMap = {};

  Timer? _debounceTimer;

  bool get isAllProductsSelected =>
      products.isNotEmpty && selectedProductIds.length == products.length;

  bool get isAllImagesSelected =>
      products.isNotEmpty &&
      imageIncludedMap.values.where((v) => v == true).length == products.length;

  @override
  void initState() {
    super.initState();
    _fetchBrandsAndQualities();
    _fetchProducts();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSizeChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => selectedSize = value);
      _fetchProducts();
    });
  }

  Future<void> _fetchBrandsAndQualities() async {
    try {
      final brandResponse = await http.get(
        Uri.parse(
          'https://dashboard.theceramicstudio.in/api/brands/GetAlllist',
        ),
      );
      final qualityResponse = await http.get(
        Uri.parse(
          'https://dashboard.theceramicstudio.in/api/qualities/GetAlllist',
        ),
      );

      if (brandResponse.statusCode == 200 &&
          qualityResponse.statusCode == 200) {
        final brandData = json.decode(brandResponse.body);
        final qualityData = json.decode(qualityResponse.body);

        if (brandData['success'] == true) {
          final List<dynamic> brandList = brandData['brands'];
          setState(() {
            brands = [
              DropdownItem(id: '', name: 'All Brands'),
              ...brandList.map(
                (b) => DropdownItem(id: b['name'], name: b['name']),
              ),
            ];
          });
        }

        if (qualityData['success'] == true) {
          final List<dynamic> qualityList = qualityData['qualities'];
          setState(() {
            qualities = [
              DropdownItem(id: '', name: 'All Qualities'),
              ...qualityList.map(
                (q) => DropdownItem(id: q['name'], name: q['name']),
              ),
            ];
          });
        }
      }
    } catch (e) {
      setState(() => errorMessage = 'Error loading filters: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final sizeParam = selectedSize.trim();
      final brandParam = selectedBrand == 'All Brands' ? '' : selectedBrand;
      final qualityParam =
          selectedQuality == 'All Qualities' ? '' : selectedQuality;

      final url = Uri.parse(
        'https://dashboard.theceramicstudio.in/api/product/export-list?size=$sizeParam&brand=$brandParam&quality=$qualityParam',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> productsJson = data['products'];
          final List<ExportProduct> fetchedProducts =
              productsJson.map((json) => ExportProduct.fromJson(json)).toList();

          final newSelectedIds = <int>{};
          final newImageIncluded = <int, bool>{};
          for (var product in fetchedProducts) {
            if (selectedProductIds.contains(product.id))
              newSelectedIds.add(product.id);
            newImageIncluded[product.id] =
                imageIncludedMap[product.id] ?? false;
          }

          setState(() {
            products = fetchedProducts;
            selectedProductIds = newSelectedIds;
            imageIncludedMap = newImageIncluded;
          });
        } else {
          throw Exception('API returned success false');
        }
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        products = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleSelection(ExportProduct product) {
    setState(() {
      if (selectedProductIds.contains(product.id))
        selectedProductIds.remove(product.id);
      else
        selectedProductIds.add(product.id);
    });
  }

  void _toggleImageIncluded(ExportProduct product) {
    setState(() {
      imageIncludedMap[product.id] = !(imageIncludedMap[product.id] ?? false);
    });
  }

  void _toggleSelectAllProducts(bool? selectAll) {
    if (selectAll == null) return;
    setState(() {
      if (selectAll) {
        selectedProductIds = products.map((p) => p.id).toSet();
      } else {
        selectedProductIds.clear();
      }
    });
  }

  void _toggleSelectAllImages(bool? selectAll) {
    if (selectAll == null) return;
    setState(() {
      for (var product in products) {
        imageIncludedMap[product.id] = selectAll;
      }
    });
  }

  // ✅ NEW: Save PDF and show Open/Share bottom sheet (same as DeliveryChalanScreen)
  Future<void> _exportPdf() async {
    if (selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products selected for export')),
      );
      return;
    }

    setState(() => isExporting = true);

    try {
      final selectedIds = selectedProductIds.join(',');
      final showImageIds = imageIncludedMap.entries
          .where((entry) => entry.value == true)
          .map((e) => e.key.toString())
          .join(',');

      final uri = Uri.parse(
        'https://dashboard.theceramicstudio.in/api/product/export-pdf'
        '?showImageIds=$showImageIds&selectedIds=$selectedIds',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading PDF...'),
          backgroundColor: Colors.orange,
        ),
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showError('Storage not available');
        return;
      }

      final fileName =
          'products_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      _showPdfOptionsDialog(filePath, fileName);
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      setState(() => isExporting = false);
    }
  }

  void _showPdfOptionsDialog(String filePath, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PDF Downloaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to do?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.visibility,
                    label: 'Open',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await OpenFilex.open(filePath);
                      if (result.type != ResultType.done) {
                        _showError('Unable to open PDF');
                      }
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Share.shareXFiles([
                        XFile(filePath),
                      ], text: 'Products Export PDF');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFFA54A)),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFFFFA54A),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFA54A),
          secondary: Color(0xFFFFA54A),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFA54A), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith(
            (states) =>
                states.contains(MaterialState.selected)
                    ? const Color(0xFFFFA54A)
                    : null,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        appBar: AppBar(
          title: const Text('Products'),
          centerTitle: false,
          elevation: 0,
          backgroundColor: const Color(0xFFFFA54A),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // Filters section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder:
                        (context, _) =>
                            isSmallScreen
                                ? Column(
                                  children: [
                                    _buildSizeSearchField(),
                                    const SizedBox(height: 12),
                                    _buildBrandDropdown(),
                                    const SizedBox(height: 12),
                                    _buildQualityDropdown(),
                                  ],
                                )
                                : Row(
                                  children: [
                                    Flexible(child: _buildSizeSearchField()),
                                    const SizedBox(width: 8),
                                    Flexible(child: _buildBrandDropdown()),
                                    const SizedBox(width: 8),
                                    Flexible(child: _buildQualityDropdown()),
                                  ],
                                ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Master checkboxes row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isAllProductsSelected,
                        onChanged: _toggleSelectAllProducts,
                        activeColor: const Color(0xFFFFA54A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Select All (${selectedProductIds.length}/${products.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isAllImagesSelected,
                        onChanged: _toggleSelectAllImages,
                        activeColor: const Color(0xFFFFA54A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Include Images (${imageIncludedMap.values.where((v) => v == true).length}/${products.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Product list
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA54A),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : products.isEmpty
                      ? const Center(
                        child: Text('No products match the filters'),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isSelected = selectedProductIds.contains(
                            product.id,
                          );
                          final imageIncluded =
                              imageIncludedMap[product.id] ?? false;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(product),
                                activeColor: const Color(0xFFFFA54A),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.brandName} | ${product.size}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    'Stock: ${product.totalStock}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  imageIncluded
                                      ? Icons.image
                                      : Icons.image_not_supported,
                                  color:
                                      imageIncluded
                                          ? const Color(0xFFFFA54A)
                                          : Colors.grey,
                                ),
                                onPressed: () => _toggleImageIncluded(product),
                                tooltip: 'Include image in PDF',
                              ),
                              onTap: () => _toggleSelection(product),
                            ),
                          );
                        },
                      ),
            ),
            // Export button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isExporting ? null : _exportPdf,
                icon:
                    isExporting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.picture_as_pdf),
                label: Text(
                  isExporting
                      ? 'Exporting PDF...'
                      : 'Export Selected (${selectedProductIds.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI helpers (unchanged)
  Widget _buildSizeSearchField() {
    return TextFormField(
      controller: _sizeController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        labelText: 'Search by Size',
        hintText: 'e.g., 600X1200, 600*200',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
        suffixIcon:
            _sizeController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _sizeController.clear();
                    _onSizeChanged('');
                  },
                )
                : null,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      onChanged: _onSizeChanged,
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBrand.isEmpty ? 'All Brands' : selectedBrand,
      decoration: const InputDecoration(
        labelText: 'Brands',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      dropdownColor: Colors.white,
      isExpanded: true,
      items:
          brands.map((brand) {
            return DropdownMenuItem(value: brand.name, child: Text(brand.name));
          }).toList(),
      onChanged: (newValue) {
        if (newValue != null) setState(() => selectedBrand = newValue);
        _fetchProducts();
      },
    );
  }

  Widget _buildQualityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedQuality.isEmpty ? 'All Qualities' : selectedQuality,
      decoration: const InputDecoration(
        labelText: 'Qualities',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      dropdownColor: Colors.white,
      isExpanded: true,
      items:
          qualities.map((q) {
            return DropdownMenuItem(value: q.name, child: Text(q.name));
          }).toList(),
      onChanged: (newValue) {
        if (newValue != null) setState(() => selectedQuality = newValue);
        _fetchProducts();
      },
    );
  }
}
