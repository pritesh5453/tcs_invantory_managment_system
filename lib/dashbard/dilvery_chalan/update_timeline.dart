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
  // Controllers for the three new fields
  final TextEditingController _deliveryBoyController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _driverContactController =
      TextEditingController();

  // Existing controllers for tracking
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false; // for tracking history
  bool saving = false; // for add tracking button
  bool updating = false; // for update delivery button

  String? selectedStatus;
  List trackingList = [];

  @override
  void initState() {
    super.initState();
    fetchTracking();
    _fetchChallanDetails(); // Load existing delivery details
  }

  @override
  void dispose() {
    _deliveryBoyController.dispose();
    _vehicleNumberController.dispose();
    _driverContactController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  /// Fetch existing challan details (delivery boy, tempo, contact) from the list API
  Future<void> _fetchChallanDetails() async {
    try {
      final response = await dio.get(
        "/Quotation/delivery-challan/list",
        queryParameters: {
          "page": 1,
          "limit": 10,
          "search": "",
          "challanType": "ALL",
          "priority": "",
        },
      );

      if (response.data['success'] == true) {
        final List challans = response.data['challans'];
        // Find the challan with matching id
        final challan = challans.firstWhere(
          (c) => c['id'] == widget.challanId,
          orElse: () => null,
        );

        if (challan != null) {
          setState(() {
            _deliveryBoyController.text = challan['deliveryBoy'] ?? '';
            _vehicleNumberController.text = challan['tempo'] ?? '';
            _driverContactController.text = challan['contact'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching challan details: $e");
      // Optionally show a snackbar, but we can silently fail
    }
  }

  /// Update delivery details using the dedicated API
  Future<void> _updateDeliveryDetails() async {
    // Basic validation (optional)
    if (_deliveryBoyController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        _driverContactController.text.isEmpty) {
      _showError("Please fill all delivery fields");
      return;
    }

    setState(() => updating = true);

    try {
      final response = await dio.put(
        "/Quotation/updateDelivery/${widget.challanId}",
        data: {
          "deliveryBoy": _deliveryBoyController.text,
          "vehicleNumber": _vehicleNumberController.text,
          "driverContact": _driverContactController.text,
        },
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally refetch to confirm (though we already have the new values)
        // _fetchChallanDetails();
      } else {
        _showError("Update failed");
      }
    } catch (e) {
      _showError("Server error during update");
    } finally {
      setState(() => updating = false);
    }
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

              /// ========== NEW SECTION: DELIVERY DETAILS ==========
              const Text(
                "Delivery Details",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // Delivery Boy
              const Text(
                "Delivery Boy",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _deliveryBoyController,
                decoration: InputDecoration(
                  hintText: "Enter delivery boy name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Vehicle Number
              const Text(
                "Vehicle Number",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  hintText: "Enter vehicle number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Driver Contact
              const Text(
                "Driver Contact",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _driverContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter driver contact",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Update button for delivery details (aligned right)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 110,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: updating ? null : _updateDeliveryDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F43),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child:
                        updating
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              "Update",
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ========== EXISTING SECTION: TRACKING ENTRY ==========
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

              /// ================= SAVE BUTTON (for tracking) =================
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
