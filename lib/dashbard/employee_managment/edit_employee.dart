import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// =======================================================
/// EMPLOYEE MODEL (AS IS – NO CHANGE)
/// =======================================================
class EmployeeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String dob;
  final String password;
  final String expense;
  final String salary;
  final String commission;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.dob,
    required this.password,
    required this.expense,
    required this.salary,
    required this.commission,
    required this.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final nameParts = (json['name'] ?? '').split(' ');

    final int parsedId =
        int.tryParse(json['employee_id']?.toString() ?? '') ??
        int.tryParse(json['id']?.toString() ?? '') ??
        0;

    return EmployeeModel(
      id: parsedId,
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      mobile: json['phone'] ?? '',
      email: json['email'] ?? '',
      dob: json['birthdate'] ?? '',
      password: json['password'] ?? '',
      expense: json['expense']?.toString() ?? '0',
      salary: json['salary']?.toString() ?? '0',
      commission: json['commission']?.toString() ?? '0',
      isActive: json['status'] == 'active',
    );
  }
}

/// =======================================================
/// EDIT EMPLOYEE SCREEN (FINAL STABLE)
/// =======================================================
class EditEmployeePopup extends StatefulWidget {
  final EmployeeModel employee;

  const EditEmployeePopup({super.key, required this.employee});

  @override
  State<EditEmployeePopup> createState() => _EditEmployeePopupState();
}

class _EditEmployeePopupState extends State<EditEmployeePopup> {
  final Dio dio = Dio(
    BaseOptions(
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ),
  );

  bool isUpdating = false;

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController mobileCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController expenseCtrl;
  late TextEditingController salaryCtrl;
  late TextEditingController commissionCtrl;

  @override
  void initState() {
    super.initState();

    debugPrint("🚀 EDIT SCREEN OPENED");
    debugPrint("🆔 EMPLOYEE ID => ${widget.employee.id}");

    firstNameCtrl = TextEditingController(text: widget.employee.firstName);
    lastNameCtrl = TextEditingController(text: widget.employee.lastName);
    mobileCtrl = TextEditingController(text: widget.employee.mobile);
    emailCtrl = TextEditingController(text: widget.employee.email);
    dobCtrl = TextEditingController(text: widget.employee.dob);
    passwordCtrl = TextEditingController(text: widget.employee.password);
    expenseCtrl = TextEditingController(text: widget.employee.expense);
    salaryCtrl = TextEditingController(text: widget.employee.salary);
    commissionCtrl = TextEditingController(text: widget.employee.commission);
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  /// =======================================================
  /// UPDATE EMPLOYEE API (DATE SAFE)
  /// =======================================================
  Future<void> updateEmployee() async {
    debugPrint("=======================================");
    debugPrint("🟠 UPDATE BUTTON CLICKED");
    debugPrint("🆔 EMPLOYEE ID => ${widget.employee.id}");

    setState(() => isUpdating = true);

    final url =
        "https://dashboarduat.theceramicstudio.in/api/employees/update/${widget.employee.id}";

    /// ---------- SAFE DOB HANDLING ----------
    String? formattedDob;
    if (dobCtrl.text.trim().isNotEmpty) {
      try {
        formattedDob = DateTime.parse(dobCtrl.text).toUtc().toIso8601String();
      } catch (e) {
        debugPrint("❌ INVALID DOB => ${dobCtrl.text}");
      }
    }

    final Map<String, dynamic> body = {
      "name": "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}",
      "email": emailCtrl.text.trim(),
      "password": passwordCtrl.text.trim(),
      "commission": double.tryParse(commissionCtrl.text) ?? 0,
      "phone": mobileCtrl.text.trim(),
      "salary": double.tryParse(salaryCtrl.text) ?? 0,
      "expense": double.tryParse(expenseCtrl.text) ?? 0,
      "advance": 0.00,
      "status": widget.employee.isActive ? "active" : "blocked",
    };

    if (formattedDob != null) {
      body["birthdate"] = formattedDob;
    }

    debugPrint("🌐 REQUEST URL => $url");
    debugPrint("📦 REQUEST BODY =>");
    body.forEach((k, v) => debugPrint("   $k : $v"));

    try {
      final response = await dio.put(url, data: body);

      debugPrint("✅ STATUS CODE => ${response.statusCode}");
      debugPrint("📥 RESPONSE => ${response.data}");

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data["success"] == true) {
        debugPrint("🎉 UPDATE SUCCESS");
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data["message"])));
      }
    } catch (e) {
      debugPrint("🔥 UPDATE ERROR => $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }

    setState(() => isUpdating = false);
    debugPrint("=======================================");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA54A),
        title: const Text("Edit Employee"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: firstNameCtrl,
              decoration: _dec("First Name"),
            ),
            const SizedBox(height: 10),
            TextField(controller: lastNameCtrl, decoration: _dec("Last Name")),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, decoration: _dec("Mobile")),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: _dec("Email")),
            const SizedBox(height: 10),
            TextField(
              controller: dobCtrl,
              decoration: _dec("Birthdate (yyyy-MM-dd)"),
            ),
            const SizedBox(height: 10),
            TextField(controller: passwordCtrl, decoration: _dec("Password")),
            const SizedBox(height: 10),
            TextField(controller: expenseCtrl, decoration: _dec("Expense")),
            const SizedBox(height: 10),
            TextField(controller: salaryCtrl, decoration: _dec("Salary")),
            const SizedBox(height: 10),
            TextField(
              controller: commissionCtrl,
              decoration: _dec("Commission (%)"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isUpdating ? null : updateEmployee,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA54A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child:
                  isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Update",
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
