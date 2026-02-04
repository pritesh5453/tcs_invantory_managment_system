import 'package:flutter/material.dart';

class EditQuotationScreen extends StatefulWidget {
  const EditQuotationScreen({super.key, required quotationId});

  @override
  State<EditQuotationScreen> createState() => _EditQuotationScreenState();
}

class _EditQuotationScreenState extends State<EditQuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController(text: "Pritesh Pawar");
  final gstCtrl = TextEditingController(text: "27xxxxxxx");
  final phoneCtrl = TextEditingController(text: "+91 7875272898");
  final addressCtrl = TextEditingController(text: "Untwadi, Nashik");
  final detailsCtrl = TextEditingController(text: "66mm");
  final rateCtrl = TextEditingController(text: "₹120");
  final discountCtrl = TextEditingController(text: "12.00%");
  final qtyCtrl = TextEditingController(text: "1");
  final boxCtrl = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(),

                            _section("Client Details"),
                            _field("Client Full Name", nameCtrl),
                            _dropdown("Select Architect", "Sagar"),
                            _orangeLabel("Client GST Number"),
                            _field("GST", gstCtrl),
                            _field("Contact Number", phoneCtrl),
                            _field("Site Address", addressCtrl),

                            _infoTitle("Introduction Note"),
                            _hintOnlyMultiline(
                              hint:
                                  "This is with reference to our discussion with you regarding your requirement. "
                                  "Here we quote our best price for your prestigious project as below:",
                            ),

                            _section("Itemized Quotation"),
                            _dropdown("Product Search", "Yogesh Tiles"),
                            _field("Details", detailsCtrl),
                            _field("Rate", rateCtrl),

                            _qtyRow(),

                            _field("Discount %", discountCtrl),

                            _totalText(),
                            _addDelete(),

                            _infoTitle("Bank Details & Terms"),
                            _hintOnlyMultiline(
                              hint:
                                  "Above rates include GST 18%. Unloading charges excluded.",
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

  Widget _header() {
    return Row(
      children: const [
        Icon(Icons.person, color: Colors.purple),
        SizedBox(width: 85),
        Text(
          "Edit Quotation",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _orangeLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
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

  Widget _dropdown(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: [DropdownMenuItem(value: value, child: Text(value))],
        onChanged: (_) {},
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _hintOnlyMultiline({required String hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        minLines: 4,
        maxLines: null,
        enabled: false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
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
          "Quantity X Box",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _qtyField(qtyCtrl)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("X", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: _qtyField(boxCtrl)),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _qtyField(TextEditingController controller) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
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
    );
  }

  Widget _totalText() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        "Total\n₹120.00",
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _addDelete() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Add"),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _summary() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text("Items Total : ₹120.00"),
          Text(
            "Addl. Discount : 12.00",
            style: TextStyle(color: Colors.orange),
          ),
          SizedBox(height: 6),
          Text(
            "Final Quotation Value",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "₹105.6",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
          ),
          onPressed: () {},
          child: const Text("Proceed to Save"),
        ),
      ),
    );
  }
}
