import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FollowUpScreen extends StatefulWidget {
  final int quotationId;
  final VoidCallback onFollowUpSaved; // ✅ CALLBACK

  const FollowUpScreen({
    super.key,
    required this.quotationId,
    required this.onFollowUpSaved,
  });

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        // "Authorization": "Bearer YOUR_TOKEN",
      },
    ),
  );

  final TextEditingController remarksCtrl = TextEditingController();

  DateTime selectedDate = DateTime.now();
  bool isSaving = false;
  bool isLoadingHistory = false;

  List<dynamic> followUps = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowUpHistory();
  }

  @override
  void dispose() {
    remarksCtrl.dispose();
    super.dispose();
  }

  /// ================= DATE PICKER =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  /// ================= SAVE FOLLOW UP =================
  Future<void> _saveFollowUp() async {
    if (remarksCtrl.text.trim().isEmpty) {
      _showSnackbar("Please enter remarks");
      return;
    }

    setState(() => isSaving = true);

    try {
      final body = {
        "quotation_id": widget.quotationId,
        "remarks": remarksCtrl.text.trim(),
        "date": DateFormat("yyyy-MM-dd").format(selectedDate),
      };

      final response = await dio.post(
        "/Quotation/followup/store",
        data: body,
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSnackbar("Follow-up saved successfully", isError: false);

        remarksCtrl.clear();

        // 🔥 CALLBACK FIRE
        widget.onFollowUpSaved();

        // Refresh history
        await _fetchFollowUpHistory();
      } else {
        _showSnackbar(response.data['message'] ?? "Failed to save follow-up");
      }
    } catch (e) {
      _showSnackbar("Network error");
    } finally {
      setState(() => isSaving = false);
    }
  }

  /// ================= FETCH FOLLOW UP HISTORY =================
  Future<void> _fetchFollowUpHistory() async {
    setState(() => isLoadingHistory = true);

    try {
      final response = await dio.get(
        "/Quotation/followup/${widget.quotationId}",
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          followUps = response.data['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      setState(() => isLoadingHistory = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Follow Up",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// DATE
                    const Text("Follow Up Date"),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          DateFormat("dd-MM-yyyy").format(selectedDate),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      "Note: Tracking date is automatically set to today.",
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),

                    const SizedBox(height: 16),

                    /// REMARKS
                    const Text("Details / Remarks"),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "What was discussed with the client?",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// HISTORY
                    const Text(
                      "Follow Up History",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isLoadingHistory)
                      const Center(child: CircularProgressIndicator())
                    else if (followUps.isEmpty)
                      const Text("No follow-ups found")
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: followUps.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = followUps[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['remarks'] ?? ""),
                            subtitle: Text(
                              "Follow Up: ${DateFormat("dd MMM yyyy").format(DateTime.parse(item['follow_up_date']))}\nCreated: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.parse(item['created_at']))}",
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            /// FOOTER BUTTONS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveFollowUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child:
                          isSaving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text("Save Entry"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
