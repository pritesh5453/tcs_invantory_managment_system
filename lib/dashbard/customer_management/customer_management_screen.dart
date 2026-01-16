import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart';

// ================= BOTTOM SHEET =================

// ================= HELPERS (🟢 इथेच टाक) =================

Widget label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

Widget textField({TextInputType type = TextInputType.text}) => TextField(
  keyboardType: type,
  decoration: InputDecoration(
    hintText: "Text..",
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget dropdown() => DropdownButtonFormField(
  items: const [],
  onChanged: (v) {},
  decoration: InputDecoration(
    hintText: "Select",
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

class CustomerManagementScreen extends StatelessWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.orange,
      //   onPressed: () {
      //     openAddProductSheet(context); // 🔥 THIS WAS MISSING
      //   },
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
      body: SafeArea(
        child: Column(
          children: [
            // ================= APP BAR =================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  //
                  const SizedBox(height: 14),

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
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const AddCustomerSheet(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= LIST =================
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 2,
                itemBuilder: (_, index) {
                  return const CustomerCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CUSTOMER CARD =================
class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Coustemer Info",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Spacer(),
              //    Icon(Icons.more_vert),
            ],
          ),

          const SizedBox(height: 10),

          infoRow("Customer Name:", "Pritesh Pawar"),
          infoRow("Mobile No.", "7875272898"),
          infoRow("Employee:", "Sumit"),
          infoRow("Residential:", "Pranesh"),

          const SizedBox(height: 14),

          Row(
            children: [
              actionBtn(
                icon: Icons.edit,
                text: "Edit",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditCustomerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),

              actionBtn(
                icon: Icons.history,
                text: "History",
                color: Colors.grey,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const FollowUpHistoryDialog(),
                  );
                },
              ),

              const SizedBox(width: 10),
              actionBtn(
                icon: Icons.phone,
                text: "Follow UP",
                color: Colors.black,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const NextFollowUpDialog(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= HELPERS =================
Widget infoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: "$title ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}

Widget actionBtn({
  required IconData icon,
  required String text,
  required Color color,
  VoidCallback? onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

// Class for editing customer information

class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({super.key});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  // ================= CONTROLLERS =================
  final firstNameCtrl = TextEditingController(text: "omkar");
  final lastNameCtrl = TextEditingController(text: "Kushare");
  final mobileCtrl = TextEditingController(text: "7875272898");
  final emailCtrl = TextEditingController(text: "Kushare07@gmail.com");
  final projectCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  final notesCtrl = TextEditingController(text: "The cermic Studio Tiles");

  String priority = "Low";
  String? siteType;
  String? employee;
  String? architect;

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    "Edit Customer Info",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= CUSTOMER NAME =================
              const Text("Customer Name"),
              const SizedBox(height: 6),
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

              const SizedBox(height: 14),

              const Text("Mobile Number"),
              const SizedBox(height: 6),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec("enter mobile number"),
              ),

              const SizedBox(height: 14),

              const Text("Email Address"),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec("enter email address"),
              ),

              const SizedBox(height: 20),

              // ================= PROJECT DETAILS =================
              const Text(
                "Project Details",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              const Text("Project Name"),
              const SizedBox(height: 6),
              TextField(
                controller: projectCtrl,
                decoration: _dec("enter project name"),
              ),

              const SizedBox(height: 14),

              const Text("Site Name / Location"),
              const SizedBox(height: 6),
              TextField(
                controller: siteCtrl,
                decoration: _dec("enter site name"),
              ),

              const SizedBox(height: 14),

              const Text("Site Type"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: siteType,
                decoration: _dec("Select option"),
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

              const SizedBox(height: 14),

              const Text("Priority Level"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: _dec(""),
                items: const [
                  DropdownMenuItem(value: "Low", child: Text("Low")),
                  DropdownMenuItem(value: "Medium", child: Text("Medium")),
                  DropdownMenuItem(value: "High", child: Text("High")),
                ],
                onChanged: (v) => setState(() => priority = v!),
              ),

              const SizedBox(height: 20),

              // ================= INTERNAL ASSIGNMENT =================
              const Text(
                "Internal Assignment",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              const Text("Assigned Employee"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: employee,
                decoration: _dec("Select option"),
                items: const [
                  DropdownMenuItem(value: "Sumit", child: Text("Sumit")),
                  DropdownMenuItem(value: "Sagar", child: Text("Sagar")),
                ],
                onChanged: (v) => setState(() => employee = v),
              ),

              const SizedBox(height: 14),

              const Text("Associated Architect"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: architect,
                decoration: _dec("Select option"),
                items: const [
                  DropdownMenuItem(
                    value: "Architect 1",
                    child: Text("Architect 1"),
                  ),
                  DropdownMenuItem(
                    value: "Architect 2",
                    child: Text("Architect 2"),
                  ),
                ],
                onChanged: (v) => setState(() => architect = v),
              ),

              const SizedBox(height: 14),

              const Text("Additional Notes"),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: _dec("Any specific requirement or follow-up"),
              ),
            ],
          ),
        ),
      ),

      // ================= SAVE BUTTON =================
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.orange,
          onPressed: () {
            Navigator.pop(context);
          },
          label: const Text("Save", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

// NEXT FOLLOW UP DIALOG
///
///

class NextFollowUpDialog extends StatefulWidget {
  const NextFollowUpDialog({super.key});

  @override
  State<NextFollowUpDialog> createState() => _NextFollowUpDialogState();
}

class _NextFollowUpDialogState extends State<NextFollowUpDialog> {
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  InputDecoration _dec({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              children: [
                const Icon(Icons.person_add, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "Next Follow up",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ================= DATE =================
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: _dec(
                hint: "DD/MM/YYYY",
                suffix: const Icon(Icons.calendar_month),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  dateCtrl.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                }
              },
            ),

            const SizedBox(height: 14),

            // ================= NOTE =================
            const Text("Note"),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 4,
              decoration: _dec(
                hint: "Add discussion points, reminders, or next steps...",
              ),
            ),

            const SizedBox(height: 20),

            // ================= SAVE =================
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  // TODO: save follow-up
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//

class FollowUpHistoryDialog extends StatelessWidget {
  const FollowUpHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              children: [
                const Icon(Icons.person_add, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "Follow-Up History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 4),
            const Text(
              "Track all conversations with this customer",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 12),

            // ================= HISTORY LIST =================
            SizedBox(
              height: 360,
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (_, index) {
                  return _historyCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HISTORY CARD =================
  Widget _historyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "16/12/2025   13:00",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Handled by: ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: "Pranesh"),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Notes : ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: "Discussed tile samples and pricing options."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//////
class AddCustomerSheet extends StatelessWidget {
  const AddCustomerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add New Customer",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== PERSONAL CONTACT =====
            label("Customer Name"),
            Row(
              children: [
                Expanded(child: textField()),
                const SizedBox(width: 10),
                Expanded(child: textField()),
              ],
            ),

            label("Mobile Number"),
            textField(type: TextInputType.phone),

            label("Alternate Mobile Number"),
            textField(type: TextInputType.phone),

            label("Email Address"),
            textField(type: TextInputType.emailAddress),

            const SizedBox(height: 10),

            // ===== PROJECT DETAILS =====
            const Text(
              "Project Details",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            label("Project Name"),
            textField(),

            label("Site Name / Location"),
            textField(),

            label("Site Type"),
            dropdown(),

            label("Priority Level"),
            dropdown(),

            const SizedBox(height: 10),

            // ===== INTERNAL ASSIGNMENT =====
            const Text(
              "Internal Assignment",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            label("Assigned Employee"),
            dropdown(),

            label("Associated Architect"),
            dropdown(),

            label("Additional Notes"),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Any specific requirement or follow-up",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== SAVE BUTTON =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
