import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// ================= HELPERS =================
Widget label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);

/// ================= ADD CUSTOMER SCREEN =================
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  // ===== CONTROLLERS =====
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final projectCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String? siteType;
  String? priority;

  String? assignedEmployee;
  int? assignedEmployeeId;

  String? assignedArchitect;

  bool isLoading = false;

  // ===== LISTS =====
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> architects = [];

  final Dio dio = Dio(
    BaseOptions(baseUrl: "https://dashboard.theceramicstudio.in"),
  );

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchArchitects();
  }

  // ================= FETCH EMPLOYEES =================
  Future<void> _fetchEmployees() async {
    final res = await dio.get("/api/employees/list");
    employees =
        res.data['employees']
            .map<Map<String, dynamic>>(
              (e) => {"id": e['id'], "name": e['name']},
            )
            .toList();
    setState(() {});
  }

  // ================= FETCH ARCHITECTS =================
  Future<void> _fetchArchitects() async {
    final res = await dio.get("/api/architects/list");
    architects =
        res.data['architects']
            .map<Map<String, dynamic>>(
              (e) => {
                "id": e['id'],
                "name": "${e['firstname'] ?? ''} ${e['lastname'] ?? ''}".trim(),
              },
            )
            .toList();
    setState(() {});
  }

  // ================= COMMON PICKER =================
  void _openPicker({
    required String title,
    required List<Map<String, dynamic>> list,
    required Function(Map<String, dynamic>) onSelect,
  }) {
    List<Map<String, dynamic>> temp = List.from(list);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: title,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() {
                      temp =
                          list
                              .where(
                                (e) => e['name'].toLowerCase().contains(
                                  v.toLowerCase(),
                                ),
                              )
                              .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: temp.length,
                    itemBuilder: (_, i) {
                      return ListTile(
                        title: Text(temp[i]['name']),
                        onTap: () {
                          onSelect(temp[i]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= ADD CUSTOMER =================
  Future<void> _addCustomer() async {
    setState(() => isLoading = true);

    try {
      await dio.post(
        "/api/users/add",
        data: {
          "name": firstNameCtrl.text,
          "Last_Name": lastNameCtrl.text,
          "phone": phoneCtrl.text,
          "altphone": altPhoneCtrl.text,
          "email": emailCtrl.text,
          "assignedEmployee": assignedEmployee,
          "assignedArchitect": assignedArchitect,
          "status": "New",
          "notes": notesCtrl.text,
          "projectName": projectCtrl.text,
          "siteName": siteCtrl.text,
          "siteType": siteType,
          "priority": priority,
          "assignedEmployeeId": assignedEmployeeId,
          "assignedEmployeeName": assignedEmployee,
        },
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add customer")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ---------- APP BAR ----------
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA54A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Customer",
          style: TextStyle(color: Colors.white),
        ),
      ),

      /// ---------- BODY ----------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label("Customer Name"),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstNameCtrl,
                      decoration: _dec("First name"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lastNameCtrl,
                      decoration: _dec("Last name"),
                    ),
                  ),
                ],
              ),

              label("Mobile Number"),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec("Mobile"),
              ),

              label("Alternate Mobile Number"),
              TextField(
                controller: altPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec("Alternate mobile"),
              ),

              label("Email Address"),
              TextField(controller: emailCtrl, decoration: _dec("Email")),

              const SizedBox(height: 16),

              const Text(
                "Project Details",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              label("Project Name"),
              TextField(controller: projectCtrl, decoration: _dec("Project")),

              label("Site Name / Location"),
              TextField(controller: siteCtrl, decoration: _dec("Site")),

              label("Site Type"),
              DropdownButtonFormField<String>(
                value: siteType,
                decoration: _dec("Select"),
                items: const [
                  DropdownMenuItem(
                    value: "Residential",
                    child: Text("Residential"),
                  ),
                  DropdownMenuItem(
                    value: "Commercial",
                    child: Text("Commercial"),
                  ),
                ],
                onChanged: (v) => setState(() => siteType = v),
              ),

              label("Priority Level"),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: _dec("Select"),
                items: const [
                  DropdownMenuItem(value: "Low", child: Text("Low")),
                  DropdownMenuItem(value: "Medium", child: Text("Medium")),
                  DropdownMenuItem(value: "High", child: Text("High")),
                ],
                onChanged: (v) => setState(() => priority = v),
              ),

              const SizedBox(height: 16),
              const Text(
                "Internal Assignment",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              label("Assigned Employee"),
              InkWell(
                onTap: () {
                  _openPicker(
                    title: "Search employee",
                    list: employees,
                    onSelect: (e) {
                      assignedEmployee = e['name'];
                      assignedEmployeeId = e['id'];
                      setState(() {});
                    },
                  );
                },
                child: InputDecorator(
                  decoration: _dec("Select employee"),
                  child: Text(
                    assignedEmployee ?? "Select employee",
                    style: TextStyle(
                      color:
                          assignedEmployee == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),

              label("Associated Architect"),
              InkWell(
                onTap: () {
                  _openPicker(
                    title: "Search architect",
                    list: architects,
                    onSelect: (e) {
                      assignedArchitect = e['name'];
                      setState(() {});
                    },
                  );
                },
                child: InputDecorator(
                  decoration: _dec("Select architect"),
                  child: Text(
                    assignedArchitect ?? "Select architect",
                    style: TextStyle(
                      color:
                          assignedArchitect == null
                              ? Colors.grey
                              : Colors.black,
                    ),
                  ),
                ),
              ),

              label("Additional Notes"),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: _dec("Any specific requirement or follow-up"),
              ),
            ],
          ),
        ),
      ),

      /// ---------- SAVE BUTTON ----------
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: isLoading ? null : _addCustomer,
        label:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Save", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
