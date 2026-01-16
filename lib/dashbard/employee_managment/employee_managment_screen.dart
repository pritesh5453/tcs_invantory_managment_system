import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeManagmentScreen extends StatefulWidget {
  const EmployeeManagmentScreen({super.key});

  @override
  State<EmployeeManagmentScreen> createState() =>
      _EmployeeManagmentScreenState();
}

class _EmployeeManagmentScreenState extends State<EmployeeManagmentScreen> {
  File? aadharImage;
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            /// ---------------- APP BAR ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  /// Search Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, size: 20, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                "Search..",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return const Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.all(16),
                                child: AddEmployeePopup(),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// ---------------- LIST ----------------
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 2,
                itemBuilder: (_, index) {
                  return EmployeeCard(isActive: index == 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// EMPLOYEE CARD
// =======================================================

class EmployeeCard extends StatelessWidget {
  final bool isActive;

  const EmployeeCard({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusText = isActive ? "Active" : "Blocked";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS + MENU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.more_vert),
            ],
          ),

          const SizedBox(height: 10),

          /// DETAILS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _infoColumn(
                  "Name",
                  "Pritesh Pawar",
                  "Salary",
                  "₹25000",
                  isStrike: !isActive,
                ),
              ),
              Expanded(
                child: _infoColumn(
                  "Mobile Number",
                  "+91 9876543210",
                  "Email Address",
                  "omkarkushare3@gmail.com",
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            children: [
              // ================= EDIT =================
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(16),
                            child: EditEmployeePopup(
                              employee: employee, // 🔥 selected employee
                            ),
                          ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ================= DELETE =================
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text("Delete Employee"),
                            content: const Text(
                              "Are you sure you want to delete this employee?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // close dialog
                                  onDelete(); // 🔥 remove from list
                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("Delete"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(
    String t1,
    String v1,
    String t2,
    String v2, {
    bool isStrike = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t1, style: _labelStyle),
        const SizedBox(height: 2),
        Text(
          v1,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                isStrike ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Text(t2, style: _labelStyle),
        const SizedBox(height: 2),
        Text(v2, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void onDelete() {}
}

class employee {}

const _labelStyle = TextStyle(color: Colors.grey, fontSize: 12);

// =======================================================
// ADD EMPLOYEE POPUP
// =======================================================
class AddEmployeePopup extends StatefulWidget {
  const AddEmployeePopup({super.key});

  @override
  State<AddEmployeePopup> createState() => _AddEmployeePopupState();
}

class _AddEmployeePopupState extends State<AddEmployeePopup> {
  final TextEditingController dobCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? aadharImage;
  File? panImage;

  InputDecoration _dec(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      suffixIcon: suffix,
    );
  }

  // ================= IMAGE PICKER =================

  Future<void> pickImage(bool isAadhar) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, // camera हवं असेल तर ImageSource.camera
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (isAadhar) {
          aadharImage = File(image.path);
        } else {
          panImage = File(image.path);
        }
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 650),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const Icon(Icons.person_add, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "Add New Employee",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // PERSONAL INFO
            const Text(
              "Personal Information",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(decoration: _dec("First name"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(decoration: _dec("Last name"))),
              ],
            ),

            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: _dec("enter mobile number.."),
            ),

            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: _dec("enter email address.."),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: dobCtrl,
              readOnly: true,
              decoration: _dec(
                "DD/MM/YYYY",
                suffix: const Icon(Icons.calendar_today, size: 18),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                  initialDate: DateTime.now(),
                );
                if (date != null) {
                  dobCtrl.text = "${date.day}/${date.month}/${date.year}";
                }
              },
            ),

            const SizedBox(height: 20),

            // PAYROLL
            const Text(
              "Payroll & Access",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            TextField(decoration: _dec("enter Access Password..")),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: _dec("enter Expense.."),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: _dec("enter salary.."),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: _dec("enter Commission (%).."),
            ),

            const SizedBox(height: 20),

            // DOCUMENTS
            const Text(
              "Verification Documents",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),
            _uploadTile(
              title: "Upload Aadhar Card",
              file: aadharImage,
              onTap: () => pickImage(true),
            ),

            const SizedBox(height: 12),
            _uploadTile(
              title: "Upload Pan Card",
              file: panImage,
              onTap: () => pickImage(false),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // TODO: API / Firebase upload
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UPLOAD TILE =================

  Widget _uploadTile({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file == null ? title : "Image Selected",
                    style: TextStyle(
                      color: file == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.upload),
              ],
            ),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}

/////
class EditEmployeePopup extends StatefulWidget {
  final employee;

  const EditEmployeePopup({super.key, required this.employee});

  @override
  State<EditEmployeePopup> createState() => _EditEmployeePopupState();
}

class _EditEmployeePopupState extends State<EditEmployeePopup> {
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

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Edit Employee Info",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: firstNameCtrl,
              decoration: _dec("First name"),
            ),
            const SizedBox(height: 10),
            TextField(controller: lastNameCtrl, decoration: _dec("Last name")),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, decoration: _dec("Mobile")),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: _dec("Email")),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // update logic later
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
