import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AddArchitectScreen extends StatefulWidget {
  final bool isEdit;
  const AddArchitectScreen({super.key, this.isEdit = false});

  @override
  State<AddArchitectScreen> createState() => _AddArchitectScreenState();
}

class _AddArchitectScreenState extends State<AddArchitectScreen> {
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController whatsappCtrl = TextEditingController();
  final TextEditingController commissionCtrl = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController remarkCtrl = TextEditingController();

  bool loading = false;
  DateTime? selectedDob;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/architects",
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// ================= CREATE API =================
  Future<void> createArchitect() async {
    if (firstNameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        whatsappCtrl.text.isEmpty ||
        commissionCtrl.text.isEmpty ||
        selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await dio.post(
        "/create",
        data: {
          "firstname": firstNameCtrl.text,
          "lastname": lastNameCtrl.text,
          "whatsapp": whatsappCtrl.text,
          "commission": commissionCtrl.text,
          "birthdate":
              "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
          "remark": remarkCtrl.text,
        },
      );

      Navigator.pop(context, true); // 👈 success → refresh list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: const Color(0xFFFA9C42)),

            /// 🔳 White Card
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_add_alt, color: Colors.purple),
                              SizedBox(width: 20),
                              Text(
                                "Add Architect",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _label("Employee Name"),
                      Row(
                        children: [
                          Expanded(
                            child: _textField("First name", firstNameCtrl),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _textField("Last name", lastNameCtrl),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _label("Whatsapp No"),
                      _textField(
                        "Enter Number...",
                        whatsappCtrl,
                        type: TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      _label("Commission (%)"),
                      _textField(
                        "%",
                        commissionCtrl,
                        type: TextInputType.number,
                      ),

                      const SizedBox(height: 14),

                      _label("Date Of Birth"),
                      TextField(
                        controller: dobController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            selectedDob = picked;
                            dobController.text =
                                "${picked.day.toString().padLeft(2, '0')}/"
                                "${picked.month.toString().padLeft(2, '0')}/"
                                "${picked.year}";
                          }
                        },
                        decoration: _inputDecoration(
                          "DD/MM/YYYY",
                          icon: Icons.calendar_month,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _label("Internal Remarks"),
                      TextField(
                        controller: remarkCtrl,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          "Add internal notes for team reference only...",
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Discard"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: loading ? null : createArchitect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA44D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child:
                                  loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text("Save Architect"),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _textField(
    String hint,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
