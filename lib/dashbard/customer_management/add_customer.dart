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

InputDecoration _dec(String hint, {bool isRequired = false}) => InputDecoration(
  hintText: hint + (isRequired ? " *" : ""),
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red),
  ),
);

/// ================= ADD CUSTOMER SCREEN =================
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  // ===== FORM KEY FOR VALIDATION =====
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // ===== CONTROLLERS =====
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final projectCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  final billingNameController = TextEditingController();
  final notesCtrl = TextEditingController();

  // ===== FOCUS NODES =====
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _altPhoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _gstFocus = FocusNode();
  final FocusNode _projectFocus = FocusNode();
  final FocusNode _siteFocus = FocusNode();
  final FocusNode _billingNameFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  String? siteType;
  String? priority;

  String? assignedEmployee;
  int? assignedEmployeeId;

  String? assignedArchitect;

  bool isLoading = false;

  // ===== ERROR FLAGS FOR MANDATORY FIELDS =====
  bool _showEmployeeError = false;
  bool _showArchitectError = false;

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

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    gstCtrl.dispose();
    projectCtrl.dispose();
    siteCtrl.dispose();
    billingNameController.dispose();
    notesCtrl.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _altPhoneFocus.dispose();
    _emailFocus.dispose();
    _gstFocus.dispose();
    _projectFocus.dispose();
    _siteFocus.dispose();
    _billingNameFocus.dispose();
    _notesFocus.dispose();

    super.dispose();
  }

  // ================= FETCH EMPLOYEES =================
  Future<void> _fetchEmployees() async {
    final res = await dio.get("/api/employees/Getlist");
    employees =
        (res.data['employees'] as List)
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
        (res.data['architects'] as List)
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
    required bool isEmployeePicker,
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
                          if (isEmployeePicker) {
                            setState(() => _showEmployeeError = false);
                          } else {
                            setState(() => _showArchitectError = false);
                          }
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

  // ================= VALIDATE MANDATORY FIELDS =================
  bool _validateMandatoryFields() {
    bool isValid = true;

    // Check email format (optional but must be valid)
    if (emailCtrl.text.trim().isNotEmpty &&
        !_isValidEmail(emailCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }
    // Check customer name (first and last)
    if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer Name is required"),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    // Check mobile number
    if (phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mobile Number is required"),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    // Check assigned employee
    if (assignedEmployee == null || assignedEmployee!.isEmpty) {
      setState(() => _showEmployeeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Assigned Employee is required"),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    // Check associated architect
    if (assignedArchitect == null || assignedArchitect!.isEmpty) {
      setState(() => _showArchitectError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Associated Architect is required"),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  // ================= ADD CUSTOMER =================
  Future<void> _addCustomer() async {
    if (!_validateMandatoryFields()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await dio.post(
        "/api/users/add",
        data: {
          "name": firstNameCtrl.text,
          "Last_Name": lastNameCtrl.text,
          "phone": phoneCtrl.text,
          "altphone": altPhoneCtrl.text,
          "email": emailCtrl.text,
          "GstNumber": gstCtrl.text,
          "assignedEmployee": assignedEmployee,
          "assignedArchitect": assignedArchitect,
          "status": "New",
          "notes": notesCtrl.text,
          "projectName": projectCtrl.text,
          "siteName": siteCtrl.text,
          "siteType": siteType,
          "priority": priority,
          "billingName": billingNameController.text,
          "assignedEmployeeId": assignedEmployeeId,
          "assignedEmployeeName": assignedEmployee,
        },
      );

      print("SUCCESS RESPONSE: ${response.data}");

      Navigator.pop(context, true);
    } catch (e) {
      print("ADD CUSTOMER ERROR: $e");

      if (e is DioException) {
        print("STATUS CODE: ${e.response?.statusCode}");
        print("RESPONSE DATA: ${e.response?.data}");
      }

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
              label("Customer Name *"),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstNameCtrl,
                      focusNode: _firstNameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _lastNameFocus.requestFocus(),
                      decoration: _dec("First name", isRequired: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lastNameCtrl,
                      focusNode: _lastNameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocus.requestFocus(),
                      decoration: _dec("Last name", isRequired: true),
                    ),
                  ),
                ],
              ),

              label("Mobile Number *"),
              TextField(
                controller: phoneCtrl,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _altPhoneFocus.requestFocus(),
                keyboardType: TextInputType.phone,
                decoration: _dec("Mobile", isRequired: true),
              ),

              label("Alternate Mobile Number"),
              TextField(
                controller: altPhoneCtrl,
                focusNode: _altPhoneFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _emailFocus.requestFocus(),
                keyboardType: TextInputType.phone,
                decoration: _dec("Alternate mobile"),
              ),

              label("Email Address"),
              TextField(
                controller: emailCtrl,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _gstFocus.requestFocus(),
                decoration: _dec("Email"),
              ),

              label("GST Number"),
              TextField(
                controller: gstCtrl,
                focusNode: _gstFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _projectFocus.requestFocus(),
                decoration: _dec("GST Number"),
              ),

              const SizedBox(height: 16),

              const Text(
                "Project Details",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              label("Project Name"),
              TextField(
                controller: projectCtrl,
                focusNode: _projectFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _siteFocus.requestFocus(),
                decoration: _dec("Project"),
              ),

              label("Site Name / Location"),
              TextField(
                controller: siteCtrl,
                focusNode: _siteFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _billingNameFocus.requestFocus(),
                decoration: _dec("Site"),
              ),

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

              label("Billing Name"),
              TextField(
                controller: billingNameController,
                focusNode: _billingNameFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _notesFocus.requestFocus(),
                decoration: _dec("Billing Name"),
              ),

              const SizedBox(height: 16),
              const Text(
                "Internal Assignment",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              label("Assigned Employee *"),
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
                    isEmployeePicker: true,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _showEmployeeError ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              if (_showEmployeeError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    "Assigned Employee is required",
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),

              label("Associated Architect *"),
              InkWell(
                onTap: () {
                  _openPicker(
                    title: "Search architect",
                    list: architects,
                    onSelect: (e) {
                      assignedArchitect = e['name'];
                      setState(() {});
                    },
                    isEmployeePicker: false,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _showArchitectError ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              if (_showArchitectError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    "Associated Architect is required",
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),

              label("Additional Notes"),
              TextField(
                controller: notesCtrl,
                focusNode: _notesFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _notesFocus.unfocus(),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Any specific requirement or follow-up",
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : const Text("Save", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
