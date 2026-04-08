import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart';

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
  String? errorMessage;

  // ✅ Size search field
  final TextEditingController _sizeController = TextEditingController();
  String selectedSize = '';
  String selectedBrand = '';
  String selectedQuality = '';

  Set<int> selectedProductIds = {};
  Map<int, bool> imageIncludedMap = {};

  bool includeImagesInPdf = true;
  String exportMode = 'Auto';
  Timer? _debounceTimer;

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

  void _selectAll() =>
      setState(() => selectedProductIds = products.map((p) => p.id).toSet());
  void _clearAll() => setState(() => selectedProductIds.clear());

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
                      _pdfHeaderCell('Name'),
                      _pdfHeaderCell('Brand'),
                      _pdfHeaderCell('Size'),
                      _pdfHeaderCell('Stock'),
                      _pdfHeaderCell('Include Image'),
                    ],
                  ),
                  ...selectedProducts.map((product) {
                    final includeImage =
                        includeImagesInPdf &&
                        (imageIncludedMap[product.id] ?? false);
                    return pw.TableRow(
                      children: [
                        _pdfDataCell(product.name),
                        _pdfDataCell(product.brandName),
                        _pdfDataCell(product.size),
                        _pdfDataCell(product.totalStock),
                        _pdfDataCell(includeImage ? 'Yes' : 'No'),
                      ],
                    );
                  }),
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

  pw.Widget _pdfHeaderCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );
  pw.Widget _pdfDataCell(String text) =>
      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text));

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
        toggleButtonsTheme: ToggleButtonsThemeData(
          selectedColor: Colors.white,
          fillColor: const Color(0xFFFFA54A),
          color: const Color(0xFFFFA54A),
          borderColor: const Color(0xFFFFA54A),
          selectedBorderColor: const Color(0xFFFFA54A),
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
          title: const Text('Configure Export'),
          centerTitle: false,
          elevation: 0,
          backgroundColor: const Color(0xFFFFA54A),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
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
                                    _buildSizeSearchField(), // ✅ Search bar
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Export Mode:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: [
                          exportMode == 'Auto',
                          exportMode == 'Manual',
                        ],
                        onPressed:
                            (index) => setState(
                              () => exportMode = index == 0 ? 'Auto' : 'Manual',
                            ),
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFFFFA54A),
                        color: const Color(0xFFFFA54A),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Auto'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: includeImagesInPdf,
                        onChanged:
                            (val) => setState(
                              () => includeImagesInPdf = val ?? true,
                            ),
                        activeColor: const Color(0xFFFFA54A),
                      ),
                      const Text('Include Images in PDF'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to export ${products.length} items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selected: ${selectedProductIds.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA54A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _selectAll,
                        child: const Text(
                          'Select All',
                          style: TextStyle(color: Color(0xFFFFA54A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearAll,
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
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

  // ✅ Size search field (TextFormField, not dropdown)
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
      iconEnabledColor: Colors.black87,
      selectedItemBuilder:
          (context) =>
              brands
                  .map(
                    (brand) => Text(
                      brand.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                  .toList(),
      items:
          brands
              .map(
                (brand) => DropdownMenuItem(
                  value: brand.name,
                  child: Text(
                    brand.name,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              )
              .toList(),
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
      iconEnabledColor: Colors.black87,
      selectedItemBuilder:
          (context) =>
              qualities
                  .map(
                    (q) => Text(
                      q.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                  .toList(),
      items:
          qualities
              .map(
                (q) => DropdownMenuItem(
                  value: q.name,
                  child: Text(
                    q.name,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              )
              .toList(),
      onChanged: (newValue) {
        if (newValue != null) setState(() => selectedQuality = newValue);
        _fetchProducts();
      },
    );
  }
}
