import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// =======================================================
/// EMPLOYEE MODEL (UPDATED with all fields)
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
  final String advance;
  final bool isActive;
  final String? aadharPhoto;
  final String? pancardPhoto;
  final String? profilePhoto;
  final String? createdAt;
  final String? fcmToken;
  final String? aadharUrl;
  final String? pancardUrl;
  final String? profileUrl;

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
    required this.advance,
    required this.isActive,
    this.aadharPhoto,
    this.pancardPhoto,
    this.profilePhoto,
    this.createdAt,
    this.fcmToken,
    this.aadharUrl,
    this.pancardUrl,
    this.profileUrl,
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
      advance: json['advance']?.toString() ?? '0',
      isActive: json['status'] == 'active',
      aadharPhoto: json['aadhar_photo']?.toString(),
      pancardPhoto: json['pancard_photo']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      createdAt: json['createdAt']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      aadharUrl: json['aadhar_url']?.toString(),
      pancardUrl: json['pancard_url']?.toString(),
      profileUrl: json['profile_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': '$firstName $lastName'.trim(),
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'email': email,
      'dob': dob,
      'password': password,
      'expense': expense,
      'salary': salary,
      'commission': commission,
      'advance': advance,
      'isActive': isActive,
      'aadharPhoto': aadharPhoto,
      'pancardPhoto': pancardPhoto,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
      'aadharUrl': aadharUrl,
      'pancardUrl': pancardUrl,
      'profileUrl': profileUrl,
    };
  }
}

/// =======================================================
/// EDIT EMPLOYEE SCREEN (WITH ALL FIELDS AND IMAGE UPLOAD)
/// =======================================================
class EditEmployeePopup extends StatefulWidget {
  final Map<String, dynamic> employeeData;

  const EditEmployeePopup({super.key, required this.employeeData});

  @override
  State<EditEmployeePopup> createState() => _EditEmployeePopupState();
}

class _EditEmployeePopupState extends State<EditEmployeePopup> {
  final Dio dio = Dio(
    BaseOptions(baseUrl: "https://dashboard.theceramicstudio.in"),
  );

  bool isUpdating = false;
  bool _obscurePassword = true;

  // Controllers
  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController mobileCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController expenseCtrl;
  late TextEditingController salaryCtrl;
  late TextEditingController commissionCtrl;
  late TextEditingController advanceCtrl;

  // Image files for upload
  File? profileImage;
  File? aadharImage;
  File? panImage;

  // Existing image URLs
  String? profileUrl;
  String? aadharUrl;
  String? pancardUrl;
  String? createdAt;
  String? fcmToken;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final data = widget.employeeData;

    print("📦 Raw employee data: $data");

    // Name splitting logic
    final fullName = data['name'] ?? '';
    final nameParts = fullName.trim().split(' ');

    String firstName = '';
    String lastName = '';

    if (nameParts.isNotEmpty) {
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }

    // Use stored firstName/lastName if available
    if (data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
      firstName = data['firstName'];
    }
    if (data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
      lastName = data['lastName'];
    }

    firstNameCtrl = TextEditingController(text: firstName);
    lastNameCtrl = TextEditingController(text: lastName);
    mobileCtrl = TextEditingController(
      text: data['mobile'] ?? data['phone'] ?? '',
    );
    emailCtrl = TextEditingController(text: data['email'] ?? '');

    // 🔥 FIX: Get birthdate from data
    String birthdate = data['dob'] ?? data['birthdate'] ?? '';
    print("📅 Birthdate from data: $birthdate");
    dobCtrl = TextEditingController(text: birthdate);

    passwordCtrl = TextEditingController(text: data['password'] ?? '');
    expenseCtrl = TextEditingController(text: data['expense'] ?? '0');
    salaryCtrl = TextEditingController(text: data['salary'] ?? '0');
    commissionCtrl = TextEditingController(text: data['commission'] ?? '0');
    advanceCtrl = TextEditingController(text: data['advance'] ?? '0');

    // 🔥 FIX: Store URLs from multiple possible keys
    profileUrl =
        data['profileUrl'] ?? data['profile_url'] ?? data['profile_photo'];
    aadharUrl = data['aadharUrl'] ?? data['aadhar_url'] ?? data['aadhar_photo'];
    pancardUrl =
        data['pancardUrl'] ?? data['pancard_url'] ?? data['pancard_photo'];
    createdAt = data['createdAt'] ?? data['created_at'];
    fcmToken = data['fcmToken'] ?? data['fcm_token'];

    print("✅ Populated employee data:");
    print("   First Name: $firstName");
    print("   Last Name: $lastName");
    print("   Birthdate: $birthdate");
    print("   Profile URL: $profileUrl");
    print("   Aadhar URL: $aadharUrl");
    print("   Pan URL: $pancardUrl");
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    mobileCtrl.dispose();
    emailCtrl.dispose();
    dobCtrl.dispose();
    passwordCtrl.dispose();
    expenseCtrl.dispose();
    salaryCtrl.dispose();
    commissionCtrl.dispose();
    advanceCtrl.dispose();
    super.dispose();
  }

  /// ================= IMAGE PICKER =================
  Future<void> pickImage(String type) async {
    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (img != null) {
      setState(() {
        if (type == 'profile') {
          profileImage = File(img.path);
        } else if (type == 'aadhar') {
          aadharImage = File(img.path);
        } else if (type == 'pan') {
          panImage = File(img.path);
        }
      });
    }
  }

  /// ================= VIEW IMAGE =================
  void _viewImage(String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No image available")));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(url, height: 300, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// 🔹 COMMON DECORATION WITH LABEL
  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  /// 🔹 Read-only field decoration
  InputDecoration _readOnlyDec(String label) => InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.grey.shade100,
    suffixIcon: const Icon(Icons.lock, size: 16, color: Colors.grey),
  );

  /// =======================================================
  /// UPDATE EMPLOYEE API
  /// =======================================================
  Future<void> updateEmployee() async {
    if (firstNameCtrl.text.isEmpty ||
        mobileCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        dobCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    setState(() => isUpdating = true);

    try {
      final employeeId = widget.employeeData['id'];

      String? formattedDob;
      if (dobCtrl.text.trim().isNotEmpty) {
        try {
          formattedDob = DateTime.parse(dobCtrl.text).toUtc().toIso8601String();
        } catch (_) {}
      }

      final formData = FormData.fromMap({
        "name": "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}",
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "phone": mobileCtrl.text.trim(),
        "birthdate": dobCtrl.text,
        "commission": double.tryParse(commissionCtrl.text) ?? 0,
        "salary": double.tryParse(salaryCtrl.text) ?? 0,
        "expense": double.tryParse(expenseCtrl.text) ?? 0,
        "advance": double.tryParse(advanceCtrl.text) ?? 0,
        "status":
            widget.employeeData['isActive'] == true ? "active" : "blocked",

        // ===== FILES =====
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

      /// -------- DEBUG --------
      debugPrint("====== FORM DATA FIELDS ======");
      for (var f in formData.fields) {
        debugPrint("${f.key} : ${f.value}");
      }
      debugPrint("====== FORM DATA FILES ======");
      for (var f in formData.files) {
        debugPrint(f.key);
      }

      final response = await dio.put(
        "/api/employees/update/$employeeId",
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data["message"] ?? "Employee updated successfully",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data["error"] ?? "Failed to update employee",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE EMPLOYEE ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      setState(() => isUpdating = false);
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== PROFILE PHOTO =====
            Center(
              child: InkWell(
                onTap: () => pickImage('profile'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          profileImage != null
                              ? FileImage(profileImage!)
                              : (profileUrl != null && profileUrl!.isNotEmpty
                                      ? NetworkImage(profileUrl!)
                                      : null)
                                  as ImageProvider?,
                      child:
                          (profileImage == null &&
                                  (profileUrl == null || profileUrl!.isEmpty))
                              ? const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    if (profileUrl != null && profileUrl!.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _viewImage(profileUrl),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove_red_eye,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: InkWell(
                onTap: () => pickImage('profile'),
                child: Text(
                  "Tap to change profile photo",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Basic Info Section
            const Text(
              "Basic Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstNameCtrl,
                    decoration: _dec("First Name"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lastNameCtrl,
                    decoration: _dec("Last Name"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: mobileCtrl,
              decoration: _dec("Mobile Number"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            TextField(controller: emailCtrl, decoration: _dec("Email Address")),
            const SizedBox(height: 10),

            // 🔥 FIX: Birthdate field - now properly populated
            TextField(
              controller: dobCtrl,
              decoration: _dec("Birthdate (yyyy-MM-dd)"),
              readOnly: true,
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
                }
              },
            ),
            const SizedBox(height: 10),

            // Password Field with Eye Button
            TextField(
              controller: passwordCtrl,
              decoration: _dec("Password").copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 20),

            // Financial Info Section
            const Text(
              "Financial Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: salaryCtrl,
              decoration: _dec("Salary (₹)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: expenseCtrl,
              decoration: _dec("Allowed Expense (₹)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: commissionCtrl,
              decoration: _dec("Commission (%)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // Documents Section (like Add Employee)
            const Text(
              "Verification Documents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Aadhar Card
            label("Upload Aadhar Card"),
            InkWell(
              onTap: () => pickImage('aadhar'),
              child: InputDecorator(
                decoration: _dec("upload aadhar card").copyWith(
                  suffixIcon:
                      (aadharUrl != null && aadharUrl!.isNotEmpty) ||
                              aadharImage != null
                          ? IconButton(
                            icon: Icon(
                              aadharImage != null
                                  ? Icons.check_circle
                                  : Icons.visibility,
                              color:
                                  aadharImage != null
                                      ? Colors.green
                                      : Colors.blue,
                            ),
                            onPressed: () {
                              if (aadharImage != null) {
                                // Show selected image
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => Dialog(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.file(
                                                aadharImage!,
                                                height: 300,
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text("Close"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                );
                              } else {
                                _viewImage(aadharUrl);
                              }
                            },
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        aadharImage != null
                            ? "Aadhar Selected (new)"
                            : (aadharUrl != null && aadharUrl!.isNotEmpty
                                ? "Aadhar already uploaded"
                                : "Upload Aadhar Card"),
                        style: TextStyle(
                          color:
                              aadharImage != null
                                  ? Colors.green
                                  : (aadharUrl != null && aadharUrl!.isNotEmpty
                                      ? Colors.blue
                                      : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Pan Card
            label("Upload Pan Card"),
            InkWell(
              onTap: () => pickImage('pan'),
              child: InputDecorator(
                decoration: _dec("upload pan card").copyWith(
                  suffixIcon:
                      (pancardUrl != null && pancardUrl!.isNotEmpty) ||
                              panImage != null
                          ? IconButton(
                            icon: Icon(
                              panImage != null
                                  ? Icons.check_circle
                                  : Icons.visibility,
                              color:
                                  panImage != null ? Colors.green : Colors.blue,
                            ),
                            onPressed: () {
                              if (panImage != null) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => Dialog(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.file(
                                                panImage!,
                                                height: 300,
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text("Close"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                );
                              } else {
                                _viewImage(pancardUrl);
                              }
                            },
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        panImage != null
                            ? "Pan Selected (new)"
                            : (pancardUrl != null && pancardUrl!.isNotEmpty
                                ? "Pan already uploaded"
                                : "Upload Pan Card"),
                        style: TextStyle(
                          color:
                              panImage != null
                                  ? Colors.green
                                  : (pancardUrl != null &&
                                          pancardUrl!.isNotEmpty
                                      ? Colors.blue
                                      : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Additional Information (read-only)
            if (createdAt != null || fcmToken != null) ...[
              const Text(
                "Additional Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (createdAt != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: TextEditingController(
                      text: DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.parse(createdAt!)),
                    ),
                    decoration: _readOnlyDec("Created At"),
                    enabled: false,
                  ),
                ),

              if (fcmToken != null && fcmToken!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: TextEditingController(
                      text: "Device registered",
                    ),
                    decoration: _readOnlyDec("FCM Token"),
                    enabled: false,
                  ),
                ),

              const SizedBox(height: 10),
            ],

            // Update Button
            Center(
              child: ElevatedButton(
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
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for labels
Widget label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);
