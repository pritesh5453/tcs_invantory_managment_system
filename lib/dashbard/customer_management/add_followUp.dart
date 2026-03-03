import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AddFollowUpPopup extends StatefulWidget {
  final int customerId;

  const AddFollowUpPopup({super.key, required this.customerId});

  @override
  State<AddFollowUpPopup> createState() => _AddFollowUpPopupState();
}

class _AddFollowUpPopupState extends State<AddFollowUpPopup> {
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  final TextEditingController nextDateCtrl = TextEditingController(); // 👈 new

  bool isLoading = false;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  InputDecoration _dec({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  /// ================= SAVE API =================
  Future<void> _saveFollowUp() async {
    if (dateCtrl.text.isEmpty ||
        noteCtrl.text.isEmpty ||
        nextDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Convert DD/MM/YYYY to YYYY-MM-DD
      String formatDate(String ddMmYyyy) {
        final parts = ddMmYyyy.split('/');
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }

      final response = await _dio.post(
        "/api/users/followup/add",
        data: {
          "customerId": widget.customerId,
          "date": formatDate(dateCtrl.text),
          "response": noteCtrl.text,
          "nextFollowupDate": formatDate(nextDateCtrl.text), // 👈 new field
        },
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data['message'])));

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save follow-up")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= DATE PICKER HELPER =================
  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== HEADER =====
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "Add Follow Up",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text("Date :"),
            const SizedBox(height: 6),

            /// ===== DATE =====
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: _dec(
                hint: "DD/MM/YYYY",
                suffix: const Icon(Icons.calendar_month),
              ),
              onTap: () => _selectDate(dateCtrl),
            ),

            const SizedBox(height: 14),

            /// ===== NEXT FOLLOW-UP DATE =====
            const Text("Next Follow-Up Date :"),
            const SizedBox(height: 6),
            TextField(
              controller: nextDateCtrl,
              readOnly: true,
              decoration: _dec(
                hint: "DD/MM/YYYY",
                suffix: const Icon(Icons.calendar_month),
              ),
              onTap: () => _selectDate(nextDateCtrl),
            ),

            const SizedBox(height: 14),

            /// ===== NOTE =====
            const Text("Note"),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: _dec(
                hint: "Add discussion points, reminders, or next steps...",
              ),
            ),

            const SizedBox(height: 20),

            /// ===== SAVE BUTTON =====
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                onPressed: isLoading ? null : _saveFollowUp,
                child:
                    isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "Save",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
