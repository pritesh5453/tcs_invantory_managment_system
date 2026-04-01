import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// ================= HELPERS =================
Widget label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
  hintText: hint,
  isDense: true,
  suffixIcon: suffix,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);

/// ================= IMAGE TYPE =================
enum DocType { profile, aadhar, pan }

/// ================= ADD EMPLOYEE SCREEN =================
class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  // ===== CONTROLLERS =====
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final expenseCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();
  final commissionCtrl = TextEditingController();

  // ===== FOCUS NODES =====
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _expenseFocus = FocusNode();
  final FocusNode _salaryFocus = FocusNode();
  final FocusNode _commissionFocus = FocusNode();

  // ===== IMAGES =====
  File? profileImage;
  File? aadharImage;
  File? panImage;

  bool isLoading = false;

  final Dio dio = Dio(
    BaseOptions(baseUrl: "https://dashboard.theceramicstudio.in"),
  );

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Add listeners to automatically generate email
    firstNameCtrl.addListener(_generateEmail);
    lastNameCtrl.addListener(_generateEmail);
  }

  @override
  void dispose() {
    // Remove listeners
    firstNameCtrl.removeListener(_generateEmail);
    lastNameCtrl.removeListener(_generateEmail);

    // Dispose controllers
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    dobCtrl.dispose();
    passwordCtrl.dispose();
    expenseCtrl.dispose();
    salaryCtrl.dispose();
    commissionCtrl.dispose();

    // Dispose focus nodes
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _dobFocus.dispose();
    _passwordFocus.dispose();
    _expenseFocus.dispose();
    _salaryFocus.dispose();
    _commissionFocus.dispose();

    super.dispose();
  }

  /// ================= EMAIL GENERATION LOGIC =================
  void _generateEmail() {
    String firstName = firstNameCtrl.text.trim().toLowerCase();
    String lastName = lastNameCtrl.text.trim().toLowerCase();

    String generatedEmail = "";

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      generatedEmail = "$firstName.$lastName@tcs";
    } else if (firstName.isNotEmpty) {
      generatedEmail = "$firstName@tcs";
    }

    setState(() {
      emailCtrl.text = generatedEmail;
    });
  }

  /// ================= IMAGE PICKER =================
  Future<void> pickImage(DocType type) async {
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (img != null) {
      setState(() {
        if (type == DocType.profile) {
          profileImage = File(img.path);
        } else if (type == DocType.aadhar) {
          aadharImage = File(img.path);
        } else {
          panImage = File(img.path);
        }
      });
    }
  }

  /// ================= ADD EMPLOYEE API =================
  Future<void> addEmployee() async {
    if (firstNameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        dobCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final formData = FormData.fromMap({
        "name": "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}",
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "birthdate": dobCtrl.text,
        "commission":
            commissionCtrl.text.isEmpty ? "0.00" : commissionCtrl.text,
        "salary": salaryCtrl.text.isEmpty ? "0.00" : salaryCtrl.text,
        "expense": expenseCtrl.text.isEmpty ? "0.00" : expenseCtrl.text,
        "advance": "0.00",
        if (profileImage != null)
          "profile": await MultipartFile.fromFile(
            profileImage!.path,
            filename: profileImage!.path.split('/').last,
          ),
        if (aadharImage != null)
          "aadhar": await MultipartFile.fromFile(
            aadharImage!.path,
            filename: aadharImage!.path.split('/').last,
          ),
        if (panImage != null)
          "pancard": await MultipartFile.fromFile(
            panImage!.path,
            filename: panImage!.path.split('/').last,
          ),
      });

      debugPrint("====== FORM DATA FIELDS ======");
      for (var f in formData.fields) {
        debugPrint("${f.key} : ${f.value}");
      }
      debugPrint("====== FORM DATA FILES ======");
      for (var f in formData.files) {
        debugPrint(f.key);
      }

      final response = await dio.post(
        "/api/employees/add",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("DATA: ${response.data}");

      if (response.data is Map && response.data["success"] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data["message"])));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data["error"] ?? "Failed to add employee"),
          ),
        );
      }
    } catch (e) {
      debugPrint("ADD EMPLOYEE ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA54A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add New Employee"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== PROFILE PHOTO =====
            Center(
              child: InkWell(
                onTap: () => pickImage(DocType.profile),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  child:
                      profileImage == null
                          ? const Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                "Upload Profile Photo",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            /// FIRST NAME / LAST NAME
            label("Employee Name"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstNameCtrl,
                    focusNode: _firstNameFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _lastNameFocus.requestFocus(),
                    decoration: _dec("First name"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lastNameCtrl,
                    focusNode: _lastNameFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _phoneFocus.requestFocus(),
                    decoration: _dec("Last name"),
                  ),
                ),
              ],
            ),

            /// MOBILE
            label("Mobile Number"),
            TextField(
              controller: phoneCtrl,
              focusNode: _phoneFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _dobFocus.requestFocus(),
              keyboardType: TextInputType.phone,
              decoration: _dec("enter mobile number"),
            ),

            /// EMAIL (auto‑generated, read‑only)
            label("Email Address"),
            TextField(
              controller: emailCtrl,
              readOnly: true,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec("email will auto-generate"),
            ),
            const SizedBox(height: 4),
            const Text(
              "Note: Email will be auto-generated from name",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),

            /// DATE OF BIRTH (read‑only, with picker)
            label("Date Of Birth"),
            TextField(
              controller: dobCtrl,
              focusNode: _dobFocus,
              readOnly: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: _dec(
                "DD/MM/YYYY",
                suffix: const Icon(Icons.calendar_today, size: 18),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                  initialDate: DateTime.now(),
                );
                if (d != null) {
                  dobCtrl.text =
                      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                  // After selection, move focus to the next field
                  _passwordFocus.requestFocus();
                }
              },
            ),

            const SizedBox(height: 16),
            const Text(
              "Payroll & Access",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            /// PASSWORD
            label("Access Password"),
            TextField(
              controller: passwordCtrl,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _expenseFocus.requestFocus(),
              obscureText: true,
              decoration: _dec("Enter password"),
            ),

            /// EXPENSE
            label("Allowed Expense"),
            TextField(
              controller: expenseCtrl,
              focusNode: _expenseFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _salaryFocus.requestFocus(),
              keyboardType: TextInputType.number,
              decoration: _dec("enter expense"),
            ),

            /// SALARY
            label("Salary"),
            TextField(
              controller: salaryCtrl,
              focusNode: _salaryFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _commissionFocus.requestFocus(),
              keyboardType: TextInputType.number,
              decoration: _dec("enter salary"),
            ),

            /// BONUS
            label("Bonus (%)"),
            TextField(
              controller: commissionCtrl,
              focusNode: _commissionFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commissionFocus.unfocus(),
              keyboardType: TextInputType.number,
              decoration: _dec("enter Bonus"),
            ),

            const SizedBox(height: 16),
            const Text(
              "Verification Documents",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            /// AADHAR
            label("Upload Aadhar Card"),
            InkWell(
              onTap: () => pickImage(DocType.aadhar),
              child: InputDecorator(
                decoration: _dec("upload aadhar card"),
                child: Text(
                  aadharImage == null
                      ? "Upload Aadhar Card"
                      : "Aadhar Selected",
                ),
              ),
            ),

            /// PAN
            label("Upload Pan Card"),
            InkWell(
              onTap: () => pickImage(DocType.pan),
              child: InputDecorator(
                decoration: _dec("upload pan card"),
                child: Text(
                  panImage == null ? "Upload Pan Card" : "Pan Selected",
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: isLoading ? null : addEmployee,
        label:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Save"),
      ),
    );
  }
}
