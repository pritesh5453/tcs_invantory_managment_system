import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FollowUpScreen extends StatefulWidget {
  final int quotationId;
  final VoidCallback onFollowUpSaved;

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
      },
    ),
  );

  final TextEditingController remarksCtrl = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime? nextFollowUpDate;

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

  /// FOLLOW UP DATE
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

  /// NEXT FOLLOW UP DATE
  Future<void> _pickNextFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextFollowUpDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => nextFollowUpDate = picked);
    }
  }

  /// SAVE FOLLOW UP
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
        "next_followup_date":
            nextFollowUpDate != null
                ? DateFormat("yyyy-MM-dd").format(nextFollowUpDate!)
                : null,
      };

      final response = await dio.post(
        "/Quotation/followup/store",
        data: body,
        options: Options(validateStatus: (s) => true),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSnackbar("Follow-up saved successfully", isError: false);

        remarksCtrl.clear();
        nextFollowUpDate = null;

        widget.onFollowUpSaved();

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

  /// FETCH HISTORY
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
                    /// FOLLOW UP DATE
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat("dd-MM-yyyy").format(selectedDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// NEXT FOLLOW UP DATE
                    const Text("Next Follow Up Date"),
                    const SizedBox(height: 6),

                    InkWell(
                      onTap: _pickNextFollowUpDate,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              nextFollowUpDate == null
                                  ? "Select next follow up date"
                                  : DateFormat(
                                    "dd-MM-yyyy",
                                  ).format(nextFollowUpDate!),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
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
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No follow-ups found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: followUps.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = followUps[index];

                          // Parse dates
                          final followUpDate = DateTime.parse(
                            item['follow_up_date'],
                          );
                          final createdAt = DateTime.parse(item['created_at']);

                          // 🔥 FIX: Handle next follow up date (can be null)
                          DateTime? nextDate;
                          if (item['next_follow_up_date'] != null) {
                            nextDate = DateTime.parse(
                              item['next_follow_up_date'],
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Remarks
                                Text(
                                  item['remarks'] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Follow Up Date
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Follow Up: ${DateFormat('dd MMM yyyy').format(followUpDate)}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),

                                // 🔥 Next Follow Up Date (if exists)
                                if (nextDate != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Next FollowUp: ${DateFormat('dd MMM yyyy').format(nextDate)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 4),

                                // Created At
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
