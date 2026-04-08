import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/add%20product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/edit_product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/product_view_screen.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// ================= DEBOUNCER CLASS =================
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// ================= SEARCH BAR WIDGET =================
class ProductSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;

  const ProductSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
  });

  @override
  State<ProductSearchBarWidget> createState() => _ProductSearchBarWidgetState();
}

class _ProductSearchBarWidgetState extends State<ProductSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ProductSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _searchController.text) {
      _searchController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      widget.onSearchChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search products by name...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                widget.onSearchChanged('');
                _searchFocusNode.requestFocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// ================= PRODUCT MODEL =================
class Product {
  final int id;
  final String name;
  final String size;
  final String brand;
  final String category;
  final String quality;
  final String rate;
  final String cov;
  final String godown;
  final String image;
  final String imageUrl;
  final int qty;
  final List<dynamic> batches;

  int get availableQuantity {
    if (batches.isEmpty) {
      return 0;
    }

    int total = 0;
    for (var batch in batches) {
      if (batch is Map<String, dynamic>) {
        final batchQty = batch['qty'];
        if (batchQty != null) {
          if (batchQty is int) {
            total += batchQty;
          } else if (batchQty is String) {
            total += int.tryParse(batchQty) ?? 0;
          } else if (batchQty is double) {
            total += batchQty.toInt();
          } else if (batchQty is num) {
            total += batchQty.toInt();
          }
        }
      }
    }
    return total;
  }

  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.brand,
    required this.category,
    required this.quality,
    required this.rate,
    required this.cov,
    required this.godown,
    required this.image,
    required this.imageUrl,
    required this.qty,
    required this.batches,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final batches = json['batches'] ?? [];

    List<dynamic> batchesList = [];
    if (batches is List) {
      batchesList = batches;
    } else if (batches is String) {
      try {
        batchesList = jsonDecode(batches) ?? [];
      } catch (e) {
        print('Error parsing batches string: $e');
      }
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      size: json['size'] ?? "",
      brand: json['brand'] ?? "",
      category: json['category'] ?? "",
      quality: json['quality'] ?? "",
      rate: json['rate']?.toString() ?? "0",
      cov: json['cov'] ?? "",
      godown: json['godown']?.toString() ?? "",
      image: json['image'] ?? "default-product.jpg",
      imageUrl: json['image_url'] ?? "",
      qty: json['qty'] ?? json['availQty'] ?? 0,
      batches: batchesList,
    );
  }
}

/// ================= CONFIGURE EXPORT SCREEN (REUSED FROM PREVIOUS SOLUTION) =================
class ConfigureExportScreen extends StatefulWidget {
  const ConfigureExportScreen({super.key});

  @override
  State<ConfigureExportScreen> createState() => _ConfigureExportScreenState();
}

class _ConfigureExportScreenState extends State<ConfigureExportScreen> {
  // Data states
  List<ExportProduct> products = [];
  List<DropdownItem> brands = [];
  List<DropdownItem> qualities = [];
  bool isLoading = false;
  String? errorMessage;

  // Filter states
  String selectedSize = '';
  String selectedBrand = '';
  String selectedQuality = '';
  List<String> availableSizes = ['All Sizes'];

  // Selection & image visibility
  Set<int> selectedProductIds = {};
  Map<int, bool> imageIncludedMap = {};

  // Additional UI states
  bool includeImagesInPdf = true;
  String exportMode = 'Auto'; // 'Auto' or 'Manual'

  @override
  void initState() {
    super.initState();
    _fetchBrandsAndQualities();
    _fetchProducts();
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
      } else {
        throw Exception('Failed to load filters');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading filters: $e';
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final sizeParam = selectedSize == 'All Sizes' ? '' : selectedSize;
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

          final Set<String> sizesSet = {};
          for (var product in fetchedProducts) {
            sizesSet.add(product.size);
          }
          final newSizes = ['All Sizes', ...sizesSet.toList()..sort()];

          final newSelectedIds = <int>{};
          final newImageIncluded = <int, bool>{};

          for (var product in fetchedProducts) {
            if (selectedProductIds.contains(product.id)) {
              newSelectedIds.add(product.id);
            }
            newImageIncluded[product.id] =
                imageIncludedMap[product.id] ?? false;
          }

          setState(() {
            products = fetchedProducts;
            availableSizes = newSizes;
            if (!availableSizes.contains(selectedSize)) {
              selectedSize = 'All Sizes';
            }
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleSelection(ExportProduct product) {
    setState(() {
      if (selectedProductIds.contains(product.id)) {
        selectedProductIds.remove(product.id);
      } else {
        selectedProductIds.add(product.id);
      }
    });
  }

  void _toggleImageIncluded(ExportProduct product) {
    setState(() {
      imageIncludedMap[product.id] = !(imageIncludedMap[product.id] ?? false);
    });
  }

  Future<void> _generateAndExportPdf() async {
    if (selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products selected for export')),
      );
      return;
    }

    final selectedProducts =
        products.where((p) => selectedProductIds.contains(p.id)).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Export Summary - ${exportMode} Mode',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Products Exported: ${selectedProducts.length}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                tableWidth: pw.TableWidth.max,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Brand',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Size',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Stock',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Include Image',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...selectedProducts.map((product) {
                    final includeImage =
                        includeImagesInPdf &&
                        (imageIncludedMap[product.id] ?? false);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.brandName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.size),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.totalStock),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(includeImage ? 'Yes' : 'No'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                includeImagesInPdf
                    ? '* Image inclusion is enabled for selected items where toggled ON'
                    : '* Global "Include Images in PDF" is OFF, so no product images included',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'export_products_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Configure Export'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Search Size",
                          hintText: "e.g. 600x1200",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedSize = value;
                          });
                          _fetchProducts();
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.28,
                      child: DropdownButtonFormField<String>(
                        value:
                            selectedBrand.isEmpty
                                ? 'All Brands'
                                : selectedBrand,
                        decoration: const InputDecoration(
                          labelText: 'Brands',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.black,
                        ),
                        isExpanded: true,
                        items:
                            brands.map((brand) {
                              return DropdownMenuItem(
                                value: brand.name,
                                child: Text(
                                  brand.name,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedBrand = newValue;
                            });
                            _fetchProducts();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.28,
                      child: DropdownButtonFormField<String>(
                        value:
                            selectedQuality.isEmpty
                                ? 'All Qualities'
                                : selectedQuality,
                        decoration: const InputDecoration(
                          labelText: 'Qualities',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                        isExpanded: true,
                        items:
                            qualities.map((quality) {
                              return DropdownMenuItem(
                                value: quality.name,
                                child: Text(
                                  quality.name,
                                  style: TextStyle(color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedQuality = newValue;
                            });
                            _fetchProducts();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Export Mode: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    ToggleButtons(
                      isSelected: [
                        exportMode == 'Auto',
                        exportMode == 'Manual',
                      ],
                      onPressed: (index) {
                        setState(() {
                          exportMode = index == 0 ? 'Auto' : 'Manual';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: Colors.orange,
                      color: Colors.orange,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Auto'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Manual'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include Images in PDF'),
                  value: includeImagesInPdf,
                  onChanged: (value) {
                    setState(() {
                      includeImagesInPdf = value ?? true;
                    });
                  },
                  activeColor: Colors.orange,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ready to export ${products.length} items',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'Selected: ${selectedProductIds.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
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
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : products.isEmpty
                    ? const Center(child: Text('No products match the filters'))
                    : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isSelected = selectedProductIds.contains(
                          product.id,
                        );
                        final imageIncluded =
                            imageIncludedMap[product.id] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(product),
                              activeColor: Colors.orange,
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${product.brandName} | ${product.size} | Stock: ${product.totalStock}',
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                imageIncluded
                                    ? Icons.image
                                    : Icons.image_not_supported,
                                color:
                                    imageIncluded ? Colors.orange : Colors.grey,
                              ),
                              onPressed: () => _toggleImageIncluded(product),
                              tooltip: 'Toggle image visibility in PDF',
                            ),
                            onTap: () => _toggleSelection(product),
                          ),
                        );
                      },
                    ),
          ),
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
              onPressed: _generateAndExportPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text('Export Selected (${selectedProductIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
    );
  }
}

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

/// ================= MAIN PRODUCT REGISTRATION SCREEN (MODIFIED) =================
class ProductRegistrationScreen extends StatefulWidget {
  const ProductRegistrationScreen({super.key});

  @override
  State<ProductRegistrationScreen> createState() =>
      _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  late bool canViewProduct;
  late bool canAddProduct;
  late bool canEditProduct;
  late bool canDeleteProduct;

  late Dio _dio;
  final ScrollController _scrollController = ScrollController();

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;

  int page = 1;
  String searchQuery = '';
  bool _lowStockFilter = false;

  List<Product> products = [];

  @override
  void initState() {
    super.initState();

    canAddProduct = PermissionManager.hasPermission("Product Registration_Add");
    canEditProduct = PermissionManager.hasPermission(
      "Product Registration_Edit",
    );
    canDeleteProduct = PermissionManager.hasPermission(
      "Product Registration_Delete",
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: "https://dashboard.theceramicstudio.in/api",
        headers: {"Accept": "application/json"},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !loadingMore &&
          hasMore) {
        fetchMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() {
      page = 1;
      hasMore = true;
      products.clear();
      loading = true;
    });

    try {
      await fetchMoreProducts();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> fetchMoreProducts() async {
    if (!hasMore || loadingMore) return;

    setState(() => loadingMore = true);

    try {
      final Map<String, dynamic> queryParams = {"page": page};
      if (searchQuery.isNotEmpty) {
        queryParams["search"] = searchQuery;
      }
      if (_lowStockFilter) {
        queryParams["lowStock"] = true;
      }

      print('Fetching products with query: $queryParams');

      final res = await _dio.get("/product/list", queryParameters: queryParams);

      if (res.data != null && res.data['products'] != null) {
        final List list = res.data['products'];
        final pagination = res.data['pagination'];

        print('Fetched ${list.length} products for search: $searchQuery');

        final newProducts = <Product>[];
        for (var i = 0; i < list.length; i++) {
          try {
            final product = Product.fromJson(list[i]);
            newProducts.add(product);
          } catch (e) {
            print('Error parsing product at index $i: $e');
          }
        }

        if (mounted) {
          setState(() {
            page++;
            products.addAll(newProducts);

            if (page > pagination['totalPages']) {
              hasMore = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("PAGINATION ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load products: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => loadingMore = false);
    }
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      page = 1;
      hasMore = true;
      products.clear();
    });
    fetchProducts();
  }

  void _toggleLowStock() {
    setState(() {
      _lowStockFilter = !_lowStockFilter;
      page = 1;
      hasMore = true;
      products.clear();
    });
    fetchProducts();
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      _lowStockFilter = false;
      page = 1;
      hasMore = true;
      products.clear();
    });
    fetchProducts();
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final res = await _dio.delete("/product/delete/$productId");

      if (res.data['success'] == true) {
        if (mounted) {
          setState(() {
            products.removeWhere((p) => p.id == productId);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Product deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");

      String errorMessage = "Delete failed";

      if (e is DioException) {
        final response = e.response;

        if (response != null &&
            response.data != null &&
            response.data['message'] != null) {
          errorMessage = response.data['message'];
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, int productId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Product"),
            content: const Text(
              "Are you sure you want to delete this product?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteProduct(productId);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );

        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: SafeArea(
          child: Column(
            children: [
              /// TOP BAR WITH SEARCH AND ADD BUTTON (LOW STOCK REMOVED FROM HERE)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search bar - now takes full remaining width
                        Expanded(
                          child: ProductSearchBarWidget(
                            onSearchChanged: onSearchChanged,
                            initialValue: searchQuery,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add button
                        InkWell(
                          onTap:
                              canAddProduct
                                  ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => const AddProductSheet(),
                                    );
                                  }
                                  : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You don't have permission to add product.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                          child: Opacity(
                            opacity: canAddProduct ? 1 : 0.4,
                            child: Container(
                              height: 42,
                              width: 42,
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
                    // Clear filters button (if any filter active)
                    if (searchQuery.isNotEmpty || _lowStockFilter)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, color: Colors.white),
                          label: const Text(
                            "Clear Filters",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              /// NEW ROW: LOW STOCK BUTTON + EXPORT REPORT BUTTON
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    // Low Stock toggle button
                    InkWell(
                      onTap: _toggleLowStock,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _lowStockFilter
                                  ? const Color(0xffFFA54A)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                _lowStockFilter
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 18,
                              color:
                                  _lowStockFilter
                                      ? Colors.white
                                      : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Low Stock",
                              style: TextStyle(
                                color:
                                    _lowStockFilter
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                fontWeight:
                                    _lowStockFilter
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export Report button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConfigureExportScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 18,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Export Report",
                              style: TextStyle(
                                color: Colors.orange,
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

              /// LIST OF PRODUCTS
              Expanded(
                child:
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () async {
                            await fetchProducts();
                          },
                          child:
                              products.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount:
                                        products.length + (hasMore ? 1 : 0),
                                    itemBuilder: (_, i) {
                                      if (i < products.length) {
                                        return ProductCard(
                                          product: products[i],
                                          canEdit: canEditProduct,
                                          canDelete: canDeleteProduct,
                                          onDelete:
                                              (id) => _showDeleteDialog(
                                                context,
                                                id,
                                              ),
                                          onEdit: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              builder:
                                                  (_) => EditProductSheet(
                                                    productId: products[i].id,
                                                    product: products[i],
                                                  ),
                                            );
                                          },
                                          onView: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ProductViewScreen(
                                                      productId: products[i].id,
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child:
                                                loadingMore
                                                    ? const CircularProgressIndicator()
                                                    : const SizedBox(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    List<String> filters = [];
    if (searchQuery.isNotEmpty) filters.add("'$searchQuery'");
    if (_lowStockFilter) filters.add("low stock");

    String filterDesc = filters.join(', ');

    if (filterDesc.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No products found for $filterDesc",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting filters",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text("No products found", style: TextStyle(color: Colors.grey)),
    );
  }
}

/// ================= PRODUCT CARD =================
class ProductCard extends StatelessWidget {
  final Product product;
  final bool canEdit;
  final bool canDelete;
  final Function(int) onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const ProductCard({
    super.key,
    required this.product,
    required this.canEdit,
    required this.canDelete,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final availableQty = product.availableQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      availableQty > 0
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  availableQty > 0 ? "In Stock" : "Out of Stock",
                  style: TextStyle(
                    fontSize: 12,
                    color: availableQty > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    onView();
                  } else if (value == 'edit') {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to edit product.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    onEdit();
                  } else if (value == 'delete') {
                    if (!canDelete) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to delete product.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    onDelete(product.id);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text("View"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text("Edit"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child:
                    product.imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        )
                        : const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${product.id}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Category: ${product.category}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Quality: ${product.quality}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Rate: ₹${product.rate}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Batches: ${product.batches.length} | Available Qty: $availableQty",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
