import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EditCustomerPopup extends StatefulWidget {
  final int customerId;

  const EditCustomerPopup({super.key, required this.customerId});

  @override
  State<EditCustomerPopup> createState() => _EditCustomerPopupState();
}

class _EditCustomerPopupState extends State<EditCustomerPopup> {
  // ================= CONTROLLERS =================
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final projectCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String priority = "Low";
  String? siteType;

  String? assignedEmployee;
  String? assignedArchitect;

  bool isLoading = false;
  bool isFetching = true;

  // ================= LISTS =================
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];

  List<Map<String, dynamic>> architects = [];
  List<Map<String, dynamic>> filteredArchitects = [];

  final Dio dio = Dio(
    BaseOptions(baseUrl: "https://dashboard.theceramicstudio.in"),
  );

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
    _fetchEmployees();
    _fetchArchitects();
  }

  // ================= FETCH CUSTOMER =================
  Future<void> _fetchCustomer() async {
    try {
      final res = await dio.get("/api/users/list");
      final List list = res.data['customers'];

      final customer = list.firstWhere((e) => e['id'] == widget.customerId);

      firstNameCtrl.text = customer['name'] ?? '';
      lastNameCtrl.text = customer['Last_Name'] ?? '';
      mobileCtrl.text = customer['phone'] ?? '';
      emailCtrl.text = customer['email'] ?? '';
      projectCtrl.text = customer['projectName'] ?? '';
      siteCtrl.text = customer['siteName'] ?? '';
      notesCtrl.text = customer['notes'] ?? '';

      priority = customer['priority'] ?? "Low";
      siteType = customer['siteType'];
      assignedEmployee = customer['assignedEmployee'];
      assignedArchitect = customer['assignedArchitect'];
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load customer")));
    } finally {
      setState(() => isFetching = false);
    }
  }

  // ================= FETCH EMPLOYEES =================
  Future<void> _fetchEmployees() async {
    final res = await dio.get("/api/employees/list");
    final List list = res.data['employees'];

    employees = list.map((e) => {"id": e['id'], "name": e['name']}).toList();
    filteredEmployees = List.from(employees);
    setState(() {});
  }

  // ================= FETCH ARCHITECTS =================
  Future<void> _fetchArchitects() async {
    final res = await dio.get("/api/architects/list");
    final List list = res.data['architects'];

    architects =
        list.map((e) {
          final first = (e['firstname'] ?? '').toString().trim();
          final last = (e['lastname'] ?? '').toString().trim();

          return {
            "id": e['id'],
            "name": "$first $last".trim(), // ✅ FULL NAME
          };
        }).toList();

    filteredArchitects = List.from(architects);
    setState(() {});
  }

  // ================= EMPLOYEE PICKER =================
  void _openEmployeePicker() {
    _openPicker(
      title: "Search employee",
      list: employees,
      onSelect: (name) => setState(() => assignedEmployee = name),
    );
  }

  // ================= ARCHITECT PICKER =================
  void _openArchitectPicker() {
    _openPicker(
      title: "Search architect",
      list: architects,
      onSelect: (name) => setState(() => assignedArchitect = name),
    );
  }

  // ================= COMMON PICKER =================
  void _openPicker({
    required String title,
    required List<Map<String, dynamic>> list,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        List<Map<String, dynamic>> tempList = List.from(list);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    // drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // search
                    TextField(
                      decoration: InputDecoration(
                        hintText: title,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          tempList =
                              list.where((e) {
                                final name =
                                    (e['name'] ?? '').toString().toLowerCase();
                                return name.contains(v.toLowerCase());
                              }).toList();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // list
                    Expanded(
                      child: ListView.builder(
                        itemCount: tempList.length,
                        itemBuilder: (_, i) {
                          final item = tempList[i];
                          final name = item['name'] ?? 'Unknown';

                          return ListTile(
                            title: Text(name),
                            onTap: () {
                              onSelect(name);
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
      },
    );
  }

  // ================= UPDATE =================
  Future<void> updateCustomer() async {
    setState(() => isLoading = true);

    try {
      await dio.put(
        "/api/users/update/${widget.customerId}",
        data: {
          "name": firstNameCtrl.text,
          "Last_Name": lastNameCtrl.text,
          "phone": mobileCtrl.text,
          "email": emailCtrl.text,
          "assignedEmployee": assignedEmployee,
          "assignedArchitect": assignedArchitect,
          "priority": priority,
          "projectName": projectCtrl.text.isEmpty ? null : projectCtrl.text,
          "siteName": siteCtrl.text.isEmpty ? null : siteCtrl.text,
          "siteType": siteType,
          "notes": notesCtrl.text.isEmpty ? null : notesCtrl.text,
        },
      );

      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Update failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child:
          isFetching
              ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Customer Name"),
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

                    const SizedBox(height: 12),
                    const Text("Mobile Number"),
                    TextField(
                      controller: mobileCtrl,
                      decoration: _dec("Mobile"),
                    ),

                    const SizedBox(height: 12),
                    const Text("Email Address"),
                    TextField(controller: emailCtrl, decoration: _dec("Email")),

                    const SizedBox(height: 16),
                    const Text(
                      "Project Details",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 10),
                    TextField(
                      controller: projectCtrl,
                      decoration: _dec("Project name"),
                    ),

                    const SizedBox(height: 10),
                    TextField(
                      controller: siteCtrl,
                      decoration: _dec("Site name"),
                    ),

                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: siteType,
                      decoration: _dec("Site type"),
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

                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: _dec("Priority"),
                      items: const [
                        DropdownMenuItem(value: "Low", child: Text("Low")),
                        DropdownMenuItem(
                          value: "Medium",
                          child: Text("Medium"),
                        ),
                        DropdownMenuItem(value: "High", child: Text("High")),
                      ],
                      onChanged: (v) => setState(() => priority = v!),
                    ),

                    const SizedBox(height: 10),
                    const Text("Assign Employee"),
                    InkWell(
                      onTap: _openEmployeePicker,
                      child: InputDecorator(
                        decoration: _dec("Select employee"),
                        child: Text(
                          assignedEmployee ?? "Select employee",
                          style: TextStyle(
                            color:
                                assignedEmployee == null
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text("Associate Architect"),
                    InkWell(
                      onTap: _openArchitectPicker,
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

                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: _dec("Additional notes"),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : updateCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Save Changes",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
