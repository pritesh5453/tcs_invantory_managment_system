import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FollowUpHistoryPopup extends StatefulWidget {
  final int customerId;

  const FollowUpHistoryPopup({super.key, required this.customerId});

  @override
  State<FollowUpHistoryPopup> createState() => _FollowUpHistoryPopupState();
}

class _FollowUpHistoryPopupState extends State<FollowUpHistoryPopup> {
  late Future<List<FollowUp>> followUpFuture;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  @override
  void initState() {
    super.initState();
    followUpFuture = _fetchFollowUps();
  }

  /// ================= FETCH API =================
  Future<List<FollowUp>> _fetchFollowUps() async {
    final response = await _dio.get(
      "/api/users/followups/${widget.customerId}",
    );

    final List list = response.data['followups'];
    return list.map((e) => FollowUp.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== HEADER =====
            Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "Follow-Up History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 4),
            const Text(
              "Track all conversations with this customer",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 12),

            /// ===== HISTORY LIST =====
            SizedBox(
              height: 360,
              child: FutureBuilder<List<FollowUp>>(
                future: followUpFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Failed to load follow-ups"),
                    );
                  }

                  final followUps = snapshot.data!;

                  if (followUps.isEmpty) {
                    return const Center(
                      child: Text("No follow-up history found"),
                    );
                  }

                  return ListView.builder(
                    itemCount: followUps.length,
                    itemBuilder: (_, index) {
                      return _historyCard(followUps[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HISTORY CARD =================
  Widget _historyCard(FollowUp item) {
    final date = DateFormat("dd/MM/yyyy").format(DateTime.parse(item.date));
    final time = DateFormat("HH:mm").format(DateTime.parse(item.createdAt));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$date   $time",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Handled by: ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: "System"),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: "Notes : ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: item.response),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= MODEL =================
class FollowUp {
  final int id;
  final int customerId;
  final String date;
  final String response;
  final String createdAt;

  FollowUp({
    required this.id,
    required this.customerId,
    required this.date,
    required this.response,
    required this.createdAt,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'],
      customerId: json['customerId'],
      date: json['date'],
      response: json['response'],
      createdAt: json['createdAt'],
    );
  }
}
