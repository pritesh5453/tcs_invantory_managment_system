import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class Addquotationscreen extends StatefulWidget {
  const Addquotationscreen({super.key});

  @override
  State<Addquotationscreen> createState() => _AddquotationscreenState();
}

class _AddquotationscreenState extends State<Addquotationscreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final introCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "1");
  final boxCtrl = TextEditingController(text: "1");
  final altPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final architectCtrl = TextEditingController();
  final attendedByCtrl = TextEditingController();
  final productNameCtrl = TextEditingController();

  // Variables for dynamic items
  List<Map<String, dynamic>> items = [];
  bool isSaving = false;

  // Default texts for introduction and bank details
  final String defaultIntroText =
      "This is with reference to our discussion with you regarding your requirement; here we quote our best price for your prestigious project as below:";

  final String defaultBankText =
      """<p>Above rates are including GST @ 18%, Excluding unloading charge and this are Nashik warehouse rates.</p><table width="100%" style="box-sizing: border-box; caption-side: bottom; border-collapse: collapse; width: 1387.46px; font-size: 18px;"><tbody style="box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;"><tr style="box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;"><td width="20%" style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">Payment Term</strong></td><td width="5%" style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">:</strong></td><td width="70%" style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><em style="box-sizing: border-box;">100% Advance.</em></td></tr><tr style="box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;"><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">Delivery Period</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">:</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;">7 TO 8 Days from the date of order / dispatch schedule.</td></tr><tr style="box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;"><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">Billing</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">:</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;">GST Billing @ 18%</td></tr><tr style="box-sizing: border-box; border-color: inherit; border-style: solid; border-width: 0px;"><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">Validity of price</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;"><strong style="box-sizing: border-box; font-weight: bolder;">:</strong></td><td style="box-sizing: border-box; border: 1px solid rgb(236, 236, 236); padding: 5px 3px;">30 Days from Date of Quotation</td></tr></tbody></table><p><strong style="box-sizing: border-box; font-weight: bolder;">BANK DETAILS :</strong><strong style="box-sizing: border-box; font-weight: bolder;">Yes Bank :&nbsp;</strong>THE CERAMIC STUDIO</p><p><strong style="box-sizing: border-box; font-weight: bolder;">A/c no. :&nbsp;</strong>002163700002424</p><p><strong style="box-sizing: border-box; font-weight: bolder;">Branch :</strong>&nbsp;Canada Corner</p><p><strong style="box-sizing: border-box; font-weight: bolder;">IFSC :&nbsp;</strong>YESB0000021</p><p>We again express our gratitude for your esteemed organization and looking forward for a long and healthy business relationship. Assuring you of our best service all the times.Thanking You .</p><p><br></p><p><strong style="box-sizing: border-box; font-weight: bolder;">THE CERAMIC STUDIO-NASHIK.</strong></p><p><strong style="box-sizing: border-box; font-weight: bolder;">SALES (8847784888)</strong></p><p><strong style="box-sizing: border-box; font-weight: bolder;">ACCOUNT (8847785888)</strong></p>""";

  @override
  void initState() {
    super.initState();
    // Set default values
    introCtrl.text = defaultIntroText;
    bankCtrl.text = defaultBankText;
    // Add first item
    _addNewItem();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    gstCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    detailsCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    introCtrl.dispose();
    bankCtrl.dispose();
    qtyCtrl.dispose();
    boxCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    architectCtrl.dispose();
    attendedByCtrl.dispose();
    productNameCtrl.dispose();
    super.dispose();
  }

  /// ================= ADD NEW ITEM =================
  void _addNewItem() {
    setState(() {
      items.add({
        'productId': 0,
        'productName':
            productNameCtrl.text.isNotEmpty
                ? productNameCtrl.text
                : "Sample Product",
        'size': "",
        'quality': "",
        'rate':
            rateCtrl.text.isNotEmpty ? double.tryParse(rateCtrl.text) ?? 0 : 0,
        'box': boxCtrl.text.isNotEmpty ? int.tryParse(boxCtrl.text) ?? 1 : 1,
        'cov': 0,
        'Weight': "0",
        'discount':
            discountCtrl.text.isNotEmpty
                ? double.tryParse(discountCtrl.text) ?? 0
                : 0,
        'Coverage': "0",
        'TWgt': "0",
        'total': _calculateTotal(),
        'area': detailsCtrl.text,
        'search':
            productNameCtrl.text.isNotEmpty
                ? productNameCtrl.text
                : "Sample Product",
        'showList': false,
        'filteredProducts': [],
      });
    });
  }

  /// ================= DELETE ITEM =================
  void _deleteItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least one item is required"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= CALCULATE TOTAL =================
  String _calculateTotal() {
    try {
      final rate = double.tryParse(rateCtrl.text) ?? 0;
      final qty = int.tryParse(qtyCtrl.text) ?? 1;
      final box = int.tryParse(boxCtrl.text) ?? 1;
      final discount = double.tryParse(discountCtrl.text) ?? 0;

      double total = rate * qty * box;
      if (discount > 0) {
        total = total - (total * discount / 100);
      }

      return total.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  /// ================= CALCULATE GRAND TOTAL =================
  double _calculateGrandTotal() {
    double grandTotal = 0;
    for (var item in items) {
      final total = double.tryParse(item['total'].toString()) ?? 0;
      grandTotal += total;
    }
    return grandTotal;
  }

  /// ================= SAVE QUOTATION API =======
  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);

    // Prepare the request body
    final body = {
      "additionalDiscount": 0,
      "clientDetails": {
        "clientid":
            0, // This should be fetched or selected from existing clients
        "name": nameCtrl.text.trim(),
        "contactNo": phoneCtrl.text.trim(),
        "altContactNo": altPhoneCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "gstNo": gstCtrl.text.trim(),
        "attendedBy": attendedByCtrl.text.trim(),
        "architect": architectCtrl.text.trim(),
        "Attended": "",
      },
      "headerSection": introCtrl.text.trim(),
      "bottomSection": bankCtrl.text.trim(),
      "rows":
          items.map((item) {
            return {
              "productId": item['productId'],
              "productName": item['productName'],
              "size": item['size'],
              "quality": item['quality'],
              "rate": item['rate'],
              "box": item['box'],
              "cov": item['cov'],
              "Weight": item['Weight'],
              "discount": item['discount'],
              "Coverage": item['Coverage'],
              "TWgt": item['TWgt'],
              "total": item['total'],
              "area": item['area'],
              "search": item['search'],
              "showList": item['showList'],
              "filteredProducts": item['filteredProducts'],
            };
          }).toList(),
      "grandTotal": _calculateGrandTotal(),
    };

    try {
      debugPrint("Sending request body: ${body.toString()}");

      final response = await dio.post("/Quotation/saveQuotation", data: body);

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? "Quotation saved successfully!",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form after successful save
        _clearForm();

        // Navigate back after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      } else {
        throw Exception(response.data['message'] ?? "Failed to save quotation");
      }
    } catch (e) {
      debugPrint("Save quotation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  /// ================= CLEAR FORM =================
  void _clearForm() {
    nameCtrl.clear();
    gstCtrl.clear();
    phoneCtrl.clear();
    addressCtrl.clear();
    detailsCtrl.clear();
    rateCtrl.clear();
    discountCtrl.clear();
    introCtrl.text = defaultIntroText;
    bankCtrl.text = defaultBankText;
    qtyCtrl.text = "1";
    boxCtrl.text = "1";
    altPhoneCtrl.clear();
    emailCtrl.clear();
    architectCtrl.clear();
    attendedByCtrl.clear();
    productNameCtrl.clear();
    items.clear();
    _addNewItem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      color: Colors.white,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(),

                            _section("Client Details"),
                            _field(
                              label: "Client Full Name *",
                              controller: nameCtrl,
                              hint: "Enter full name",
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter client name';
                                }
                                return null;
                              },
                            ),

                            _field(
                              label: "Architect Name",
                              controller: architectCtrl,
                              hint: "Enter architect name",
                            ),

                            _orangeLabel("Client GST Number"),
                            _field(
                              label: "GST Number",
                              controller: gstCtrl,
                              hint: "Enter GST number",
                            ),

                            _field(
                              label: "Contact Number *",
                              controller: phoneCtrl,
                              hint: "+91 1234567890",
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter contact number';
                                }
                                if (value.length < 10) {
                                  return 'Please enter valid contact number';
                                }
                                return null;
                              },
                            ),

                            _field(
                              label: "Alternate Contact Number",
                              controller: altPhoneCtrl,
                              hint: "+91 9876543210",
                              keyboardType: TextInputType.phone,
                            ),

                            _field(
                              label: "Email Address",
                              controller: emailCtrl,
                              hint: "client@example.com",
                              keyboardType: TextInputType.emailAddress,
                            ),

                            _field(
                              label: "Attended By",
                              controller: attendedByCtrl,
                              hint: "Enter attended by name",
                            ),

                            _field(
                              label: "Site Address *",
                              controller: addressCtrl,
                              hint: "Full address with city and pin code",
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter site address';
                                }
                                return null;
                              },
                            ),

                            _infoTitle("Introduction Note"),
                            _multiLineField(
                              controller: introCtrl,
                              hint: defaultIntroText,
                            ),

                            _section("Itemized Quotation"),

                            // Items List
                            for (int i = 0; i < items.length; i++)
                              _buildItemCard(i),

                            _field(
                              label: "Product Name *",
                              controller: productNameCtrl,
                              hint: "Enter product name",
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter product name';
                                }
                                return null;
                              },
                            ),

                            _field(
                              label: "Details",
                              controller: detailsCtrl,
                              hint: "Additional details about the product",
                            ),

                            _field(
                              label: "Rate *",
                              controller: rateCtrl,
                              hint: "₹00.00",
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter rate';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter valid number';
                                }
                                return null;
                              },
                            ),

                            _qtyRow(),

                            _field(
                              label: "Discount %",
                              controller: discountCtrl,
                              hint: "00.00",
                              keyboardType: TextInputType.number,
                            ),

                            _totalText(),
                            _addDelete(),

                            _infoTitle("Bank Details & Terms"),
                            _multiLineField(
                              controller: bankCtrl,
                              hint: defaultBankText,
                            ),

                            _summary(),
                            _saveButton(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              top: 18,
              right: 22,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= BUILD ITEM CARD =================
  Widget _buildItemCard(int index) {
    final item = items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Item ${index + 1}: ${item['productName']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteItem(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Rate: ₹${item['rate']}"),
          Text("Quantity: ${qtyCtrl.text} x Box: ${boxCtrl.text}"),
          Text("Discount: ${item['discount']}%"),
          Text(
            "Total: ₹${item['total']}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.purple),
          SizedBox(width: 85),
          Text(
            "Add Quotation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _infoTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: (value) {
              // Update items when rate, discount, qty or box changes
              if (items.isNotEmpty) {
                setState(() {
                  items[items.length - 1]['rate'] =
                      double.tryParse(rateCtrl.text) ?? 0;
                  items[items.length - 1]['box'] =
                      int.tryParse(boxCtrl.text) ?? 1;
                  items[items.length - 1]['discount'] =
                      double.tryParse(discountCtrl.text) ?? 0;
                  items[items.length - 1]['area'] = detailsCtrl.text;
                  items[items.length - 1]['productName'] =
                      productNameCtrl.text.isNotEmpty
                          ? productNameCtrl.text
                          : "Sample Product";
                  items[items.length - 1]['search'] =
                      productNameCtrl.text.isNotEmpty
                          ? productNameCtrl.text
                          : "Sample Product";
                  items[items.length - 1]['total'] = _calculateTotal();
                });
              }
            },
            decoration: InputDecoration(
              hintStyle: const TextStyle(color: Colors.grey),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiLineField({
    required TextEditingController controller,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: 3,
        maxLines: null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _qtyRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quantity X Box *",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _qtyField(qtyCtrl, "Quantity")),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("X", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: _qtyField(boxCtrl, "Box")),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _qtyField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // Update items when qty or box changes
              if (items.isNotEmpty) {
                setState(() {
                  items[items.length - 1]['box'] =
                      int.tryParse(boxCtrl.text) ?? 1;
                  items[items.length - 1]['total'] = _calculateTotal();
                });
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalText() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        "Total\n₹${_calculateTotal()}",
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _addDelete() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {
            _addNewItem();
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Add Item"),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () {
            if (items.length > 1) {
              _deleteItem(items.length - 1);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cannot delete the only item"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _summary() {
    final grandTotal = _calculateGrandTotal();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Items Total : ₹${grandTotal.toStringAsFixed(2)}"),
          Text(
            "Additional Discount : 0.00%",
            style: TextStyle(color: Colors.orange),
          ),
          const SizedBox(height: 6),
          const Text(
            "Final Quotation Value",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "₹${grandTotal.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA44D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: isSaving ? null : _saveQuotation,
          child:
              isSaving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    "Proceed to Save",
                    style: TextStyle(fontSize: 16),
                  ),
        ),
      ),
    );
  }
}

Widget _orangeLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    ),
  );
}
