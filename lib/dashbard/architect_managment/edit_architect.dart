import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EditArchitectScreen extends StatefulWidget {
  final bool isEdit;
  final int architectId;

  final String firstname;
  final String lastname;
  final String whatsapp;
  final int commission;
  final String birthdate;
  final String remark;

  const EditArchitectScreen({
    super.key,
    this.isEdit = false,
    required this.architectId,
    required this.firstname,
    required this.lastname,
    required this.whatsapp,
    required this.commission,
    required this.birthdate,
    required this.remark,
  });

  @override
  State<EditArchitectScreen> createState() => _EditArchitectScreenState();
}

class _EditArchitectScreenState extends State<EditArchitectScreen> {
  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController whatsappCtrl;
  late TextEditingController dobController;
  late TextEditingController remarkCtrl;

  bool loading = false;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api/architects",
      headers: {"Content-Type": "application/json"},
    ),
  );

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.firstname);
    lastNameCtrl = TextEditingController(text: widget.lastname);
    whatsappCtrl = TextEditingController(text: widget.whatsapp);
    dobController = TextEditingController(
      text: widget.birthdate.substring(0, 10),
    );
    remarkCtrl = TextEditingController(text: widget.remark);
  }

  /// ================= UPDATE API =================
  Future<void> updateArchitect() async {
    setState(() => loading = true);
    try {
      await dio.put(
        "/update/${widget.architectId}",
        data: {
          "firstname": firstNameCtrl.text,
          "lastname": lastNameCtrl.text,
          "whatsapp": whatsappCtrl.text,
          "remark": remarkCtrl.text,

          "birthdate": widget.birthdate,
          "createdAt": DateTime.now().toIso8601String(),
        },
      );

      Navigator.pop(context, true); // 👈 success
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.purple),
                  const SizedBox(width: 12),
                  const Text(
                    "Edit Architect",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _field("First Name", firstNameCtrl),
              _field("Last Name", lastNameCtrl),
              _field("Whatsapp", whatsappCtrl, type: TextInputType.phone),

              _field("Remarks", remarkCtrl, max: 3),

              const Spacer(),

              ElevatedButton(
                onPressed: loading ? null : updateArchitect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA44D),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Update Architect"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    int max = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: max,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
