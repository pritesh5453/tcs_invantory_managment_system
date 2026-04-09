import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/add_architect.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/add%20product.dart';

// ---------- Model for a product in the quotation ----------
class QuotationProduct {
  final int? productId;
  final String productName;
  final String size;
  final String quality;
  final double rate;
  final double discount; // percentage
  final double coverage;
  final String area;
  final double weight;
  final int box; // quantity
  final double discountedRate; // computed
  final double twgt; // computed
  final double total; // computed

  QuotationProduct({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quality,
    required this.rate,
    required this.discount,
    required this.coverage,
    required this.area,
    required this.weight,
    required this.box,
    required this.discountedRate,
    required this.twgt,
    required this.total,
  });

  factory QuotationProduct.fromForm({
    required int? productId,
    required String productName,
    required String size,
    required String quality,
    required double rate,
    required double discount,
    required double coverage,
    required String area,
    required double weight,
    required int box,
  }) {
    final discountedRate = rate * (1 - discount / 100);
    final twgt = weight * box;
    final total = discountedRate * box * coverage;
    return QuotationProduct(
      productId: productId,
      productName: productName,
      size: size,
      quality: quality,
      rate: rate,
      discount: discount,
      coverage: coverage,
      area: area,
      weight: weight,
      box: box,
      discountedRate: discountedRate,
      twgt: twgt,
      total: total,
    );
  }
}

// ---------- MAIN QUOTATION SHEET ----------
class AddQuotationSheet extends StatefulWidget {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddQuotationSheet(),
    );
  }

  @override
  State<AddQuotationSheet> createState() => _AddQuotationSheetState();
}

class _AddQuotationSheetState extends State<AddQuotationSheet> {
  final Dio _dio = Dio();

  // Client Details Controllers
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientGstController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _altNumberController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Additional Discount & Charges
  final TextEditingController _additionalDiscountController =
      TextEditingController();
  final TextEditingController _transportationController =
      TextEditingController();
  final TextEditingController _unloadingController = TextEditingController();

  // Architect Data - now using a clean modal picker
  List<dynamic> _architects = [];
  String? _selectedArchitectId;
  String? _selectedArchitectName;

  // Customers (for auto-fill)
  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  bool _showCustomerDropdown = false;
  Timer? _customerSearchDebounce;
  int? _selectedClientId;

  // Attended By Data
  List<dynamic> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  // Form controllers
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _billNoController = TextEditingController();

  // List of added products
  List<QuotationProduct> _quotationProducts = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingArchitects = false;
  bool _isLoadingEmployees = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchArchitects();
      await _fetchEmployees('');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchArchitects() async {
    setState(() => _isLoadingArchitects = true);
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/architects/list',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _architects = response.data['architects'];
        });
      }
    } catch (e) {
      debugPrint('Architect fetch error: $e');
    } finally {
      setState(() => _isLoadingArchitects = false);
    }
  }

  void _showArchitectPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        List<dynamic> filteredList = _architects;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Text(
                    'Select Architect',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search architect...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      searchQuery = value.toLowerCase();
                      setModalState(() {
                        if (searchQuery.isEmpty) {
                          filteredList = _architects;
                        } else {
                          filteredList =
                              _architects.where((arch) {
                                final name =
                                    '${arch['firstname']} ${arch['lastname']}'
                                        .toLowerCase();
                                return name.contains(searchQuery);
                              }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        _isLoadingArchitects
                            ? const Center(child: CircularProgressIndicator())
                            : filteredList.isEmpty
                            ? const Center(child: Text('No architects found'))
                            : ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (ctx, index) {
                                final arch = filteredList[index];
                                final fullName =
                                    '${arch['firstname']} ${arch['lastname']}';
                                return ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: Text(fullName),
                                  onTap: () {
                                    setState(() {
                                      _selectedArchitectId =
                                          arch['id'].toString();
                                      _selectedArchitectName = fullName;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchCustomers(String search) async {
    if (search.trim().isEmpty) {
      setState(() {
        _filteredCustomers = [];
        _showCustomerDropdown = false;
      });
      return;
    }
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/users/list',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _customers = response.data['customers'];
          _filteredCustomers = _customers;
          _showCustomerDropdown = true;
        });
      }
    } catch (e) {
      debugPrint("Customer fetch error: $e");
    }
  }

  Future<void> _fetchEmployees(String search) async {
    setState(() => _isLoadingEmployees = true);
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/employees/Getlist',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _employees = response.data['employees']);
      }
    } catch (e) {
      debugPrint('Employees fetch error: $e');
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }

  // ---------- Open product popup for adding new product ----------
  Future<void> _addProduct() async {
    final result = await showModalBottomSheet<QuotationProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProductPopup(),
    );
    if (result != null) {
      setState(() {
        _quotationProducts.add(result);
      });
    }
  }

  // ---------- Open product popup for editing existing product ----------
  Future<void> _editProduct(int index) async {
    final result = await showModalBottomSheet<QuotationProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddProductPopup(initialProduct: _quotationProducts[index]),
    );
    if (result != null) {
      setState(() {
        _quotationProducts[index] = result;
      });
    }
  }

  // ---------- Remove product ----------
  void _removeProduct(int index) {
    setState(() {
      _quotationProducts.removeAt(index);
    });
  }

  // ---------- Calculations ----------
  double _calculateTotalAmount() {
    return _quotationProducts.fold(0, (sum, p) => sum + p.total);
  }

  double _calculateGrandTotal() {
    double subtotal = _calculateTotalAmount();
    double additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    double transportation =
        double.tryParse(_transportationController.text) ?? 0;
    double unloading = double.tryParse(_unloadingController.text) ?? 0;

    double discountAmount = subtotal * (additionalDiscount / 100);
    double afterDiscount = subtotal - discountAmount;
    return afterDiscount + transportation + unloading;
  }

  // ---------- Validation ----------
  bool _validateForm() {
    if (_clientNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter client name');
      return false;
    }
    if (_contactNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter contact number');
      return false;
    }
    if (_siteAddressController.text.trim().isEmpty) {
      _showSnackBar('Please enter site address');
      return false;
    }
    if (_selectedEmployeeId == null) {
      _showSnackBar('Please select attended by');
      return false;
    }
    if (_quotationProducts.isEmpty) {
      _showSnackBar('Please add at least one product');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------- Save Quotation ----------
  Future<void> _saveQuotation() async {
    if (!_validateForm()) return;
    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> rowsData = [];
      for (var p in _quotationProducts) {
        rowsData.add({
          "productId": p.productId,
          "productName": p.productName,
          "size": p.size,
          "quality": p.quality,
          "rate": p.rate,
          "discount": p.discount,
          "DisAmount": p.rate * p.discount / 100,
          "disRate": p.discountedRate,
          "box": p.box,
          "cov": p.coverage,
          "Weight": p.weight,
          "TWgt": p.twgt,
          "Coverage": p.coverage.toString(),
          "total": p.total,
          "area": p.area,
          "showList": false,
          "search": p.productName,
          "activeIndex": -1,
          "filteredProducts": [],
        });
      }

      final clientDetails = {
        "clientid": _selectedClientId,
        "name": _clientNameController.text.trim(),
        "contactNo": _contactNumberController.text.trim(),
        "altContactNo": _altNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "GstNumber": _clientGstController.text.trim(),
        "address": _siteAddressController.text.trim(),
        "architect": _selectedArchitectId ?? "",
        "attendedBy": _selectedEmployeeId ?? "",
        "Attended": "",
        "transportation": _transportationController.text,
        "unloading": _unloadingController.text,
      };

      const headerSection =
          "This is with reference to our discussion with you regarding your requirement; here we quote our best price for your prestigious project as below:";
      const bottomSection =
          "<p>Above rates are including GST @ 18%, Excluding unloading charge and this are Nashik warehouse rates.</p>"
          "<table width=\"100%\" style=\"box-sizing: border-box; caption-side: bottom; border-collapse: collapse; width: 1387.46px; font-size: 18px;\">"
          "<tbody style=\"box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;\">"
          "<tr style=\"box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;\">"
          "<td width=\"20%\" style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">Payment Term</strong></td>"
          "<td width=\"5%\" style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">:</strong></td>"
          "<td width=\"70%\" style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><em style=\"box-sizing: border-box;\">100% Advance.</em></td>"
          "</tr>"
          "<tr style=\"box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;\">"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">Delivery Period</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">:</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\">7 TO 8 Days from the date of order / dispatch schedule.</td>"
          "</tr>"
          "<tr style=\"box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;\">"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">Billing</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">:</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\">GST Billing @ 18%</td>"
          "</tr>"
          "<tr style=\"box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;\">"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">Validity of price</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\"><strong style=\"box-sizing: border-box; font-weight: bolder;\">:</strong></td>"
          "<td style=\"box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;\">30 Days from Date of Quotation</td>"
          "</tr>"
          "</tbody>"
          "</table>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">BANK DETAILS :</strong><strong style=\"box-sizing: border-box; font-weight: bolder;\">Yes Bank :<span>&nbsp;</span></strong>THE CERAMIC STUDIO</p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">A/c no. :<span>&nbsp;</span></strong>002163700002424</p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">Branch :</strong><span>&nbsp;</span>Canada Corner</p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">IFSC :<span>&nbsp;</span></strong>YESB0000021</p>"
          "<p>We again express our gratitude for your esteemed organization and looking forward for a long and healthy business relationship. Assuring you of our best service all the times.Thanking You .</p>"
          "<p><br></p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">THE CERAMIC STUDIO-NASHIK.</strong></p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">SALES (8847784888)</strong></p>"
          "<p><strong style=\"box-sizing: border-box; font-weight: bolder;\">ACCOUNT (8847785888)</strong></p>\n\n";

      final requestBody = {
        "additionalDiscount":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "clientDetails": clientDetails,
        "headerSection": headerSection,
        "bottomSection": bottomSection,
        "rows": rowsData,
        "grandTotal": double.parse(_calculateGrandTotal().toStringAsFixed(2)),
      };

      debugPrint('Request Body: ${requestBody.toString()}');

      final response = await _dio.post(
        'https://dashboard.theceramicstudio.in/api/Quotation/saveQuotation',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Quotation saved successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          _showErrorSnackBar(
            responseData['message'] ?? 'Failed to save quotation',
          );
        }
      } else {
        _showErrorSnackBar(
          'Server error: ${response.statusCode}\n${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      _showErrorSnackBar('Dio error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Unexpected error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final discountAmount = totalAmount * (additionalDiscount / 100);
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Material(
        child: Container(
          margin: const EdgeInsets.only(top: 50),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header with Add Product button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Create Quotation",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Add Product",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xffFFA54A),
                              ),
                            )
                            : SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AddProductSheet(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.black,
                                          ),
                                          label: const Text(
                                            "Add New Product",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // CLIENT DETAILS SECTION
                                  const Text(
                                    'CLIENT DETAILS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFA54A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Client Full Name
                                  _buildClientLabel('CLIENT FULL NAME'),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: TextField(
                                            controller: _clientNameController,
                                            onChanged: (value) {
                                              _selectedClientId = null;
                                              if (_customerSearchDebounce
                                                      ?.isActive ??
                                                  false) {
                                                _customerSearchDebounce!
                                                    .cancel();
                                              }
                                              _customerSearchDebounce = Timer(
                                                const Duration(
                                                  milliseconds: 400,
                                                ),
                                                () => _fetchCustomers(value),
                                              );
                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_clientNameController
                                                  .text
                                                  .isNotEmpty) {
                                                _showCustomerDropdown = true;
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              hintText: "Search customer...",
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        if (_showCustomerDropdown &&
                                            _filteredCustomers.isNotEmpty)
                                          Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    bottomLeft: Radius.circular(
                                                      8,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(8),
                                                  ),
                                            ),
                                            child: ListView.builder(
                                              itemCount:
                                                  _filteredCustomers.length,
                                              itemBuilder: (context, index) {
                                                final customer =
                                                    _filteredCustomers[index];
                                                final fullName =
                                                    "${customer['name']} ${customer['Last_Name'] ?? ''}";
                                                return ListTile(
                                                  title: Text(fullName),
                                                  subtitle: Text(
                                                    customer['phone'] ?? '',
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _clientNameController
                                                          .text = fullName;
                                                      _contactNumberController
                                                              .text =
                                                          customer['phone'] ??
                                                          '';
                                                      _altNumberController
                                                              .text =
                                                          customer['altphone'] ??
                                                          '';
                                                      _emailController.text =
                                                          customer['email'] ??
                                                          '';
                                                      _siteAddressController
                                                              .text =
                                                          customer['siteName'] ??
                                                          '';
                                                      _selectedClientId =
                                                          customer['id'];
                                                      _showCustomerDropdown =
                                                          false;

                                                      // Auto-select architect
                                                      final architectName =
                                                          customer['assignedArchitect'];
                                                      if (architectName !=
                                                          null) {
                                                        final architect =
                                                            _architects.firstWhere(
                                                              (a) =>
                                                                  "${a['firstname']} ${a['lastname']}"
                                                                      .toLowerCase()
                                                                      .trim() ==
                                                                  architectName
                                                                      .toLowerCase()
                                                                      .trim(),
                                                              orElse:
                                                                  () => null,
                                                            );
                                                        if (architect != null) {
                                                          _selectedArchitectId =
                                                              architect['id']
                                                                  .toString();
                                                          _selectedArchitectName =
                                                              '${architect['firstname']} ${architect['lastname']}';
                                                        }
                                                      }

                                                      // Auto-select employee
                                                      final employeeName =
                                                          customer['assignedEmployee'];
                                                      if (employeeName !=
                                                          null) {
                                                        final employee =
                                                            _employees.firstWhere(
                                                              (e) =>
                                                                  (e['name'] ??
                                                                          '')
                                                                      .toLowerCase()
                                                                      .trim() ==
                                                                  employeeName
                                                                      .toLowerCase()
                                                                      .trim(),
                                                              orElse:
                                                                  () => null,
                                                            );
                                                        if (employee != null) {
                                                          _selectedEmployeeId =
                                                              employee['id']
                                                                  .toString();
                                                        }
                                                      }
                                                    });
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Client GST Number
                                  _buildClientLabel('CLIENT GST NUMBER'),
                                  const SizedBox(height: 4),
                                  _buildClientTextField(
                                    _clientGstController,
                                    '27XXXXX...',
                                  ),
                                  const SizedBox(height: 12),

                                  // Contact Number and Alt Number
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel('CONTACT NUMBER'),
                                            const SizedBox(height: 4),
                                            _buildClientTextField(
                                              _contactNumberController,
                                              '+91',
                                              keyboardType: TextInputType.phone,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel('ALT NUMBER'),
                                            const SizedBox(height: 4),
                                            _buildClientTextField(
                                              _altNumberController,
                                              '+91',
                                              keyboardType: TextInputType.phone,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Client Email
                                  _buildClientLabel('CLIENT EMAIL (OPTIONAL)'),
                                  const SizedBox(height: 4),
                                  _buildClientTextField(
                                    _emailController,
                                    'client@example.com',
                                  ),
                                  const SizedBox(height: 12),

                                  // Site Address
                                  _buildClientLabel('SITE ADDRESS'),
                                  const SizedBox(height: 4),
                                  _buildClientTextField(
                                    _siteAddressController,
                                    'Full location...',
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 12),

                                  // Architect and Attended By
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel(
                                              'SELECT ARCHITECT',
                                            ),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: _showArchitectPicker,
                                              child: Container(
                                                height: 40,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _selectedArchitectName ??
                                                            'Select architect',
                                                        style: TextStyle(
                                                          color:
                                                              _selectedArchitectName ==
                                                                      null
                                                                  ? Colors
                                                                      .grey
                                                                      .shade600
                                                                  : Colors
                                                                      .black87,
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const AddArchitectScreen(),
                                                ),
                                              ).then((_) => _fetchArchitects());
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel('ATTENDED BY'),
                                            const SizedBox(height: 4),
                                            Container(
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: _selectedEmployeeId,
                                                  hint:
                                                      _isLoadingEmployees
                                                          ? const Text(
                                                            'Loading...',
                                                          )
                                                          : const Text(
                                                            'Choose Person...',
                                                          ),
                                                  items:
                                                      _employees.map((
                                                        employee,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value:
                                                              employee['id']
                                                                  .toString(),
                                                          child: Text(
                                                            employee['name'] ??
                                                                '',
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedEmployeeId =
                                                          value;
                                                      final selectedEmployee =
                                                          _employees.firstWhere(
                                                            (e) =>
                                                                e['id']
                                                                    .toString() ==
                                                                value,
                                                            orElse: () => null,
                                                          );
                                                      if (selectedEmployee !=
                                                          null) {
                                                        _selectedEmployeeName =
                                                            selectedEmployee['name'];
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 16),

                                  // PRODUCT DETAILS SECTION
                                  const Text(
                                    'PRODUCT DETAILS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFA54A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // List of added products
                                  if (_quotationProducts.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No products added yet. Tap + to add.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _quotationProducts.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final p = _quotationProducts[index];
                                        return _buildProductCard(index, p);
                                      },
                                    ),

                                  const SizedBox(height: 16),

                                  // Add Product Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _addProduct,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xffFFA54A),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: Color(0xffFFA54A),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "+ ADD PRODUCT",
                                              style: TextStyle(
                                                color: Color(0xffFFA54A),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Additional Discount Section
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildClientLabel(
                                          'ADDITIONAL DISCOUNT',
                                        ),
                                        const SizedBox(height: 8),
                                        _buildClientTextField(
                                          _additionalDiscountController,
                                          'Enter discount percentage...',
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'This discount will be applied on the total amount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Transportation & Unloading Section
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ADDITIONAL CHARGES',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildClientLabel(
                                                    'TRANSPORTATION (₹)',
                                                  ),
                                                  const SizedBox(height: 4),
                                                  _buildClientTextField(
                                                    _transportationController,
                                                    '0',
                                                    onChanged:
                                                        (_) => setState(() {}),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildClientLabel(
                                                    'UNLOADING (₹)',
                                                  ),
                                                  const SizedBox(height: 4),
                                                  _buildClientTextField(
                                                    _unloadingController,
                                                    '0',
                                                    onChanged:
                                                        (_) => setState(() {}),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'These charges will be added to the final total.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // FINAL QUOTATION VALUE
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xffFFA54A,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xffFFA54A,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Subtotal
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Subtotal',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '₹${totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Additional Discount
                                        if (additionalDiscount > 0)
                                          Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Additional Discount ($additionalDiscount%)',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  Text(
                                                    '-₹${discountAmount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),

                                        // Transportation
                                        if (double.tryParse(
                                              _transportationController.text,
                                            ) !=
                                            0)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Transportation',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                '+₹${double.tryParse(_transportationController.text)?.toStringAsFixed(2) ?? '0'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),

                                        // Unloading
                                        if (double.tryParse(
                                              _unloadingController.text,
                                            ) !=
                                            0)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Unloading',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                '+₹${double.tryParse(_unloadingController.text)?.toStringAsFixed(2) ?? '0'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),

                                        if (double.tryParse(
                                                  _transportationController
                                                      .text,
                                                ) !=
                                                0 ||
                                            double.tryParse(
                                                  _unloadingController.text,
                                                ) !=
                                                0)
                                          const SizedBox(height: 8),

                                        Divider(
                                          color: Colors.grey.shade400,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Final Quotation Value',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xffFFA54A),
                                              ),
                                            ),
                                            Text(
                                              '₹${grandTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xffFFA54A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : () =>
                                                      Navigator.pop(context),
                                          child: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xffFFA54A,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : _saveQuotation,
                                          child:
                                              _isSubmitting
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Proceed to Save',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Helpers ----------
  Widget _buildClientLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildClientTextField(
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
    void Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  // ---------- Product Card UI with edit on tap ----------
  Widget _buildProductCard(int index, QuotationProduct p) {
    return GestureDetector(
      onTap: () => _editProduct(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeProduct(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoRow('Size', p.size)),
                Expanded(child: _buildInfoRow('Quality', p.quality)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Rate', '₹${p.rate.toStringAsFixed(2)}'),
                ),
                Expanded(child: _buildInfoRow('Box', p.box.toString())),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Weight',
                    '${p.weight.toStringAsFixed(2)} kg',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Total Wt',
                    '${p.twgt.toStringAsFixed(2)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildInfoRow('Area', p.area)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${p.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xffFFA54A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _billNoController.dispose();
    _clientNameController.dispose();
    _clientGstController.dispose();
    _contactNumberController.dispose();
    _altNumberController.dispose();
    _siteAddressController.dispose();
    _emailController.dispose();
    _additionalDiscountController.dispose();
    _transportationController.dispose();
    _unloadingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ---------- POPUP FOR ADDING/EDITING PRODUCT (WITH FOCUS CHAINING) ----------
class AddProductPopup extends StatefulWidget {
  final QuotationProduct? initialProduct;

  const AddProductPopup({super.key, this.initialProduct});

  @override
  State<AddProductPopup> createState() => _AddProductPopupState();
}

class _AddProductPopupState extends State<AddProductPopup> {
  final Dio _dio = Dio();
  Timer? _searchDebounce;
  bool _isSelectingProduct = false;

  // Product search
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _showDropdown = false;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Selected product details
  Map<String, dynamic>? _selectedProduct;
  String _selectedSize = '';
  String _selectedQuality = '';

  // Form fields (editable)
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _coverageController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _boxController = TextEditingController();

  // Computed fields (read-only)
  final TextEditingController _discountedRateController =
      TextEditingController();
  final TextEditingController _twgtController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  // Focus nodes for text fields
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _rateFocusNode = FocusNode();
  final FocusNode _coverageFocusNode = FocusNode();
  final FocusNode _boxFocusNode = FocusNode();
  final FocusNode _discountFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _areaFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    _rateController.addListener(_updateCalculations);
    _discountController.addListener(_updateCalculations);
    _coverageController.addListener(_updateCalculations);
    _weightController.addListener(_updateCalculations);
    _boxController.addListener(_updateCalculations);

    // Scroll listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _currentPage < _totalPages) {
        _loadMoreProducts();
      }
    });

    if (widget.initialProduct != null) {
      _fillWithProduct(widget.initialProduct!);
    }
  }

  void _fillWithProduct(QuotationProduct product) {
    _isSelectingProduct = true;

    // Create a map representation of the product to add to _products
    Map<String, dynamic> productMap = {
      'id': product.productId,
      'name': product.productName,
      'size': product.size,
      'quality': product.quality,
      'rate': product.rate,
      'cov': product.coverage,
      'weight': product.weight,
    };

    // Add to _products if not already present (so that size/quality appear in dropdowns)
    bool exists = _products.any((p) => p['id'] == product.productId);
    if (!exists) {
      _products.add(productMap);
      _filteredProducts.add(productMap);
    }

    setState(() {
      _selectedProduct = productMap;
      _searchController.text = product.productName;
      _selectedSize = product.size;
      _selectedQuality = product.quality;
      _rateController.text = product.rate.toString();
      _coverageController.text = product.coverage.toString();
      _weightController.text = product.weight.toString();
      _boxController.text = product.box.toString();
      _discountController.text = product.discount.toString();
      _areaController.text = product.area;
    });
    _updateCalculations();
    Future.microtask(() => _isSelectingProduct = false);
  }

  void _onSearchChanged() {
    if (_isSelectingProduct || !_showDropdown) return;
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts(_searchController.text, page: 1);
    });
  }

  void _updateCalculations() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final coverage = double.tryParse(_coverageController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final box = int.tryParse(_boxController.text) ?? 0;

    final discountedRate = rate * (1 - discount / 100);
    final twgt = weight * box;
    final total = discountedRate * box * coverage;

    _discountedRateController.text = discountedRate.toStringAsFixed(2);
    _twgtController.text = twgt.toStringAsFixed(2);
    _totalController.text = total.toStringAsFixed(2);
  }

  Future<void> _fetchProducts(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredProducts = [];
        _showDropdown = false;
        _currentPage = 1;
        _totalPages = 1;
        _isLoadingMore = false;
      });
      return;
    }

    if (page == 1) {
      // Reset for new search
      setState(() {
        _currentPage = 1;
        _totalPages = 1;
        _products = [];
        _filteredProducts = [];
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list',
        queryParameters: {'search': query, 'page': page},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newProducts = response.data['products'] as List<dynamic>? ?? [];

        // Extract pagination info – adjust keys to match your API response
        final pagination = response.data['pagination'] ?? {};
        _totalPages = pagination['totalPages'] ?? 1;

        setState(() {
          if (page == 1) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _filteredProducts =
              _products; // Keep filtered list same as full list for simplicity
          _showDropdown = true;
          _currentPage = page;
        });
      }
    } catch (e) {
      debugPrint('Product search error: $e');
    } finally {
      if (page != 1) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    _fetchProducts(_searchController.text, page: _currentPage + 1);
  }

  Future<Map<String, dynamic>?> _fetchProductById(int id) async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list/$id',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['product'];
      }
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
    }
    return null;
  }

  List<String> _getSizes() {
    if (_searchController.text.isEmpty) return [];
    return _products
        .where((p) => p['name'] == _searchController.text)
        .map((p) => p['size']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _getQualities() {
    if (_searchController.text.isEmpty || _selectedSize.isEmpty) return [];
    return _products
        .where(
          (p) =>
              p['name'] == _searchController.text &&
              p['size']?.toString() == _selectedSize,
        )
        .map((p) => p['quality']?.toString() ?? '')
        .where((q) => q.isNotEmpty)
        .toSet()
        .toList();
  }

  void _selectProduct(Map<String, dynamic> product) {
    _isSelectingProduct = true;
    _searchDebounce?.cancel();

    setState(() {
      _selectedProduct = product;
      _searchController.text = product['name'] ?? '';
      _selectedSize = product['size']?.toString() ?? '';
      _selectedQuality = product['quality']?.toString() ?? '';
      _rateController.text = product['rate']?.toString() ?? '0';
      _coverageController.text = product['cov']?.toString() ?? '0';
      _weightController.text = product['weight']?.toString() ?? '0';
      _showDropdown = false;
    });
    _updateCalculations();
    Future.microtask(() => _isSelectingProduct = false);
  }

  void _scanQrCode() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scan Product QR'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 300,
              child: MobileScanner(
                onDetect: (BarcodeCapture capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No QR code found')),
                    );
                    return;
                  }
                  final code = barcodes.first.rawValue;
                  if (code == null || code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid QR code')),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context); // close scanner

                  final productId = int.tryParse(code);
                  if (productId == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Invalid product ID')),
                    );
                    return;
                  }

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Fetching product...')),
                  );

                  final product = await _fetchProductById(productId);
                  if (product == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Product not found')),
                    );
                    return;
                  }

                  bool exists = _products.any((p) => p['id'] == product['id']);
                  if (!exists) {
                    _products.add(product);
                    _filteredProducts.add(product);
                  }

                  _isSelectingProduct = true;
                  setState(() {
                    _selectedProduct = product;
                    _searchController.text = product['name'] ?? '';
                    _selectedSize = product['size']?.toString() ?? '';
                    _selectedQuality = product['quality']?.toString() ?? '';
                    _rateController.text = product['rate']?.toString() ?? '0';
                    _coverageController.text =
                        product['cov']?.toString() ?? '0';
                    _weightController.text =
                        product['weight']?.toString() ?? '0';
                    _showDropdown = false;
                  });
                  _updateCalculations();
                  Future.microtask(() => _isSelectingProduct = false);

                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Product "${product['name']}" loaded'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _save() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    if (_selectedSize.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select size')));
      return;
    }
    if (_selectedQuality.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select quality')));
      return;
    }
    final box = int.tryParse(_boxController.text);
    if (box == null || box <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity (box)')),
      );
      return;
    }

    final rate = double.tryParse(_rateController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final coverage = double.tryParse(_coverageController.text) ?? 0;
    final area = _areaController.text.trim();
    final weight = double.tryParse(_weightController.text) ?? 0;

    final product = QuotationProduct.fromForm(
      productId: _selectedProduct!['id'],
      productName: _searchController.text,
      size: _selectedSize,
      quality: _selectedQuality,
      rate: rate,
      discount: discount,
      coverage: coverage,
      area: area,
      weight: weight,
      box: box,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getSizes();
    final qualities = _getQualities();

    return Material(
      child: Container(
        margin: const EdgeInsets.only(top: 50),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xffFFA54A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialProduct == null
                        ? "Add Product"
                        : "Edit Product",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        onPressed: _scanQrCode,
                        tooltip: 'Scan QR',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form with keyboard padding
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PRODUCT SEARCH
                      const Text(
                        'PRODUCT NAME',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Search product...',
                                  border: InputBorder.none,
                                ),
                                onTap:
                                    () => setState(() => _showDropdown = true),
                              ),
                            ),
                            if (_showDropdown && _filteredProducts.isNotEmpty)
                              Container(
                                height: 150,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey),
                                  ),
                                ),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount:
                                      _filteredProducts.length +
                                      (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (ctx, i) {
                                    if (i == _filteredProducts.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final p = _filteredProducts[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(p['name'] ?? ''),
                                      subtitle: Text(
                                        'Size: ${p['size']} | Quality: ${p['quality']}',
                                      ),
                                      onTap: () => _selectProduct(p),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. SIZE & QUALITY
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown('SIZE', sizes, _selectedSize, (val) {
                            setState(() {
                              _selectedSize = val;
                              _selectedQuality = '';
                              final matches =
                                  _products
                                      .where(
                                        (p) =>
                                            p['name'] ==
                                                _searchController.text &&
                                            p['size']?.toString() == val,
                                      )
                                      .toList();
                              if (matches.length == 1) {
                                _selectProduct(matches.first);
                              }
                            });
                          }),

                          const SizedBox(height: 12),

                          _buildDropdown(
                            'QUALITY',
                            qualities,
                            _selectedQuality,
                            (val) {
                              setState(() {
                                _selectedQuality = val;
                                final match = _products.firstWhere(
                                  (p) =>
                                      p['name'] == _searchController.text &&
                                      p['size']?.toString() == _selectedSize &&
                                      p['quality']?.toString() == val,
                                  orElse: () => null,
                                );
                                if (match != null) _selectProduct(match);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. RATE
                      _buildTextField(
                        'RATE (₹)',
                        _rateController,
                        keyboardType: TextInputType.number,
                        focusNode: _rateFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _coverageFocusNode.requestFocus(),
                      ),

                      const SizedBox(height: 12),

                      // 4. COVERAGE
                      _buildTextField(
                        'COVERAGE',
                        _coverageController,
                        keyboardType: TextInputType.number,
                        focusNode: _coverageFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _boxFocusNode.requestFocus(),
                      ),

                      const SizedBox(height: 12),

                      // 5. BOX
                      _buildTextField(
                        'BOX (Quantity)',
                        _boxController,
                        keyboardType: TextInputType.number,
                        focusNode: _boxFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _discountFocusNode.requestFocus(),
                      ),

                      const SizedBox(height: 12),

                      // 6. DISCOUNT %
                      _buildTextField(
                        'DISCOUNT (%)',
                        _discountController,
                        keyboardType: TextInputType.number,
                        focusNode: _discountFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _weightFocusNode.requestFocus(),
                      ),

                      const SizedBox(height: 12),

                      // 7. DISCOUNTED RATE (read-only)
                      _buildReadOnlyField(
                        'DISC. RATE (₹)',
                        _discountedRateController,
                      ),

                      const SizedBox(height: 12),

                      // 8. WEIGHT
                      _buildTextField(
                        'WEIGHT',
                        _weightController,
                        keyboardType: TextInputType.number,
                        focusNode: _weightFocusNode,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _areaFocusNode.requestFocus(),
                      ),

                      const SizedBox(height: 12),

                      // 9. TWGT (read-only)
                      _buildReadOnlyField('TWGT', _twgtController),

                      const SizedBox(height: 12),

                      // 10. TOTAL AMOUNT (read-only)
                      _buildReadOnlyField('TOTAL AMOUNT (₹)', _totalController),

                      const SizedBox(height: 12),

                      // 11. AREA
                      _buildTextField(
                        'AREA',
                        _areaController,
                        keyboardType: TextInputType.text,
                        focusNode: _areaFocusNode,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _areaFocusNode.unfocus(),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffFFA54A),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _save,
                              child: Text(
                                widget.initialProduct == null
                                    ? 'ADD PRODUCT'
                                    : 'UPDATE PRODUCT',
                                style: const TextStyle(color: Colors.white),
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: const Text('Select'),
              items:
                  items
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: TextField(
            controller: controller,
            enabled: false,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _discountController.removeListener(_updateCalculations);
    _rateController.removeListener(_updateCalculations);
    _coverageController.removeListener(_updateCalculations);
    _weightController.removeListener(_updateCalculations);
    _boxController.removeListener(_updateCalculations);
    _discountController.dispose();
    _rateController.dispose();
    _coverageController.dispose();
    _areaController.dispose();
    _weightController.dispose();
    _boxController.dispose();
    _discountedRateController.dispose();
    _twgtController.dispose();
    _totalController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();

    _searchFocusNode.dispose();
    _rateFocusNode.dispose();
    _coverageFocusNode.dispose();
    _boxFocusNode.dispose();
    _discountFocusNode.dispose();
    _weightFocusNode.dispose();
    _areaFocusNode.dispose();

    super.dispose();
  }
}
