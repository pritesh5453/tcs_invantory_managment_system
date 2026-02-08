import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class UpdateTimelineScreen extends StatefulWidget {
  final int challanId;

  const UpdateTimelineScreen({super.key, required this.challanId});

  @override
  State<UpdateTimelineScreen> createState() => _UpdateTimelineScreenState();
}

class _UpdateTimelineScreenState extends State<UpdateTimelineScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  bool saving = false;

  String? selectedStatus;
  List trackingList = [];

  @override
  void initState() {
    super.initState();
    fetchTracking();
  }

  /// ================= VIEW TRACKING =================
  Future<void> fetchTracking() async {
    setState(() => loading = true);
    try {
      final res = await dio.get("/tracking/${widget.challanId}");
      trackingList = res.data;
    } catch (e) {
      _showError("Failed to load tracking");
    }
    setState(() => loading = false);
  }

  /// ================= ADD TRACKING =================
  Future<void> addTracking() async {
    if (_dateController.text.isEmpty || selectedStatus == null) {
      _showError("Please select date and status");
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        "challanId": widget.challanId,
        "trackedAt": DateFormat(
          "yyyy-MM-dd",
        ).format(DateFormat("dd/MM/yyyy").parse(_dateController.text)),
        "status": selectedStatus,
      };

      final res = await dio.post("/tracking", data: body);

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );

        _dateController.clear();
        _timeController.clear();
        selectedStatus = null;

        fetchTracking(); // 🔄 refresh list
      } else {
        _showError("Failed to add tracking");
      }
    } catch (e) {
      _showError("Server error");
    }

    setState(() => saving = false);
  }

  /// ================= DATE PICKER =================
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF9F43)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {});
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
              /// ================= HEADER =================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE7F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Update Timeline",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.deepOrange,
                      size: 26,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// ================= DATE =================
              const Text(
                "Date",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  hintText: "DD/MM/YYYY",
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ================= STATUS =================
              const Text(
                "Status",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: "Preparing For Dispatch",
                    child: Text("Preparing For Dispatch"),
                  ),
                  DropdownMenuItem(value: "Dispatch", child: Text("Dispatch")),
                  DropdownMenuItem(
                    value: "On the Way",
                    child: Text("On the Way"),
                  ),
                  DropdownMenuItem(
                    value: "Delivered",
                    child: Text("Delivered"),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                },
                decoration: InputDecoration(
                  hintText: "Select",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ================= TRACKING LIST =================
              const Text(
                "Tracking History",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              Expanded(
                child:
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : trackingList.isEmpty
                        ? const Center(child: Text("No tracking found"))
                        : ListView.builder(
                          itemCount: trackingList.length,
                          itemBuilder: (context, index) {
                            final t = trackingList[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFF9F43),
                              ),
                              title: Text(t['status']),
                              subtitle: Text(
                                DateFormat(
                                  "dd MMM yyyy",
                                ).format(DateTime.parse(t['tracked_at'])),
                              ),
                            );
                          },
                        ),
              ),

              /// ================= SAVE BUTTON =================
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 110,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: saving ? null : addTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F43),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child:
                        saving
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
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
