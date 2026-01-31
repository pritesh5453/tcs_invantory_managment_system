import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/update_timeline.dart';

/// ================= MODEL =================
class DeliveryChallan {
  final int id;
  final int quotationId;
  final String client;
  final String deliveryBoy;
  final String tempo;
  final int totalItems;

  DeliveryChallan({
    required this.id,
    required this.quotationId,
    required this.client,
    required this.deliveryBoy,
    required this.tempo,
    required this.totalItems,
  });

  factory DeliveryChallan.fromJson(Map<String, dynamic> json) {
    return DeliveryChallan(
      id: json['id'],
      quotationId: json['quotationId'],
      client: json['client'],
      deliveryBoy: json['deliveryBoy'] ?? "",
      tempo: json['tempo'] ?? "",
      totalItems: json['totalItems'],
    );
  }
}

/// ================= SCREEN =================
class DeliveryChalanScreen extends StatefulWidget {
  const DeliveryChalanScreen({super.key});

  @override
  State<DeliveryChalanScreen> createState() => _DeliveryChalanScreenState();
}

class _DeliveryChalanScreenState extends State<DeliveryChalanScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan",
      responseType: ResponseType.bytes, // 🔥 IMPORTANT for PDF
    ),
  );

  bool loading = false;
  List<DeliveryChallan> challans = [];

  @override
  void initState() {
    super.initState();
    fetchChallans();
  }

  /// ================= FETCH API =================
  Future<void> fetchChallans() async {
    setState(() => loading = true);
    try {
      final res = await Dio().get(
        "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan/list",
        queryParameters: {"page": 1, "limit": 10},
      );

      final List data = res.data['challans'];
      challans = data.map((e) => DeliveryChallan.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Delivery Challan API Error: $e");
    }
    setState(() => loading = false);
  }

  /// ================= DELETE API =================
  Future<void> deleteChallan(int id) async {
    try {
      final res = await Dio().delete(
        "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan/delete/$id",
      );

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );
        fetchChallans();
      }
    } catch (e) {
      _showError("Delete failed");
    }
  }

  /// ================= PRINT PDF =================
  Future<void> _printPdf({
    required int challanId,
    required bool isReturn,
  }) async {
    try {
      debugPrint("========== PDF PRINT START ==========");
      debugPrint("ChallanId: $challanId");
      debugPrint("Is Return: $isReturn");

      final Dio pdfDio = Dio(
        BaseOptions(
          baseUrl:
              "https://dashboarduat.theceramicstudio.in/api/Quotation/delivery-challan",
          responseType: ResponseType.bytes,
          headers: {"Accept": "application/pdf"},
        ),
      );

      final url = isReturn ? "/printreturn/$challanId" : "/print/$challanId";

      debugPrint("PDF URL: ${pdfDio.options.baseUrl}$url");

      final response = await pdfDio.get(url);

      debugPrint("Response Status: ${response.statusCode}");

      List<int> bytes = response.data;

      // ✅ DOWNLOADS FOLDER
      final directory = Directory("/storage/emulated/0/Download");
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath =
          "${directory.path}/DC_${challanId}_${isReturn ? "RETURN" : "NORMAL"}.pdf";

      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);

      debugPrint("PDF WRITE SUCCESS ✅");
      debugPrint("File Path: $filePath");

      // 🔥 AUTO OPEN PDF
      final result = await OpenFilex.open(filePath);
      debugPrint("OpenFile result: ${result.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF downloaded & opened"),
          backgroundColor: Colors.green,
        ),
      );

      debugPrint("========== PDF PRINT END ==========");
    } catch (e) {
      debugPrint("PDF ERROR: $e");
      _showError("PDF download failed");
    }
  }

  void _showDeleteConfirm(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Delivery Challan"),
            content: const Text(
              "Are you sure you want to delete this challan?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  deleteChallan(id);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          /// ================= TOP SEARCH BAR =================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFA9C42),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search..",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ================= LIST =================
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: challans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _chalanCard(context, challans[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  /// ================= CHALAN CARD =================
  Widget _chalanCard(BuildContext context, DeliveryChallan chalan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chalan no. : CH ${chalan.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              /// 🔥 3 DOT MENU
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "dc") {
                    _printPdf(challanId: chalan.id, isReturn: false);
                  } else {
                    _printPdf(challanId: chalan.id, isReturn: true);
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(value: "dc", child: Text("DC Print")),
                      PopupMenuItem(
                        value: "return",
                        child: Text("Return DC Print"),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Recipient Details : ${chalan.client}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            "Delivery Boy : ${chalan.deliveryBoy.isEmpty ? "-" : chalan.deliveryBoy}",
          ),

          const SizedBox(height: 18),

          /// BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => UpdateTimelineScreen(challanId: chalan.id),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.blue,
                ),
                label: const Text(
                  "Update Timeline",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              OutlinedButton(
                onPressed: () => _showDeleteConfirm(chalan.id),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
