import 'package:flutter/material.dart';

class Addquotationscreen extends StatefulWidget {
  const Addquotationscreen({super.key});

  @override
  State<Addquotationscreen> createState() => _Addquotationscreen();
}

class _Addquotationscreen extends State<Addquotationscreen> {
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
    super.dispose();
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
                              label: "Client Full Name",
                              controller: nameCtrl,
                              hint: "Enter full name",
                            ),
                            _dropdown("Select Architect", "Architect Name"),
                            _orangeLabel("Client GST Number"),

                            _field(
                              label: "Contact Number",
                              controller: phoneCtrl,
                              hint: "+91",
                              keyboardType: TextInputType.phone,
                            ),

                            _field(
                              label: "Site Address",
                              controller: addressCtrl,
                              hint: "Full address",
                            ),

                            _infoTitle("Introduction Note"),
                            _multiLineField(
                              controller: introCtrl,
                              hint:
                              "this is with reference to our discussion with you regarding your requirement here we quote our best price for your prestigious project as below :"
                            ),

                            _section("Itemized Quotation"),
                            _dropdown("Product Search", "Yogesh Tiles"),

                            _field(
                              label: "Details",
                              controller: detailsCtrl,
                              hint: "---",
                            ),

                            _field(
                              label: "Rate",
                              controller: rateCtrl,
                              hint: "₹00.00",
                              keyboardType: TextInputType.number,
                            ),

                            _qtyRow(),

                            _field(
                              label: "Discount %",
                              controller: discountCtrl,
                              hint: "00.00%",
                              keyboardType: TextInputType.number,
                            ),

                            _totalText(),
                            _addDelete(),

                            _infoTitle("Bank Details & Terms"),
                            _multiLineField(
                              controller: bankCtrl,
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
          "Add Quotation",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintStyle: const TextStyle(color: Colors.grey),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            items: [DropdownMenuItem(value: value, child: Text(value))],
            onChanged: (_) {},
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _qtyRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quantity X Box",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    );
  }

  Widget _totalText() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        "Total\n₹00.00",
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
          label:
          const Text("Delete", style: TextStyle(color: Colors.red)),
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
          Text("Items Total : ₹00.00"),
          Text("Addl. Discount : 00.00",
              style: TextStyle(color: Colors.orange)),
          SizedBox(height: 6),
          Text("Final Quotation Value",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text("₹00.00",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () {},
          child: const Text("Proceed to Save"),
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
      style: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}