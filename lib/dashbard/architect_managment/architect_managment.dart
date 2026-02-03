import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_commision.dart';
import 'add_architect.dart';
import 'edit_architect.dart';

/// ================= ARCHITECT MODEL =================
class Architect {
  final int id;
  final String firstname;
  final String lastname;
  final String whatsapp;
  final int commission;
  final String birthdate;

  Architect({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.whatsapp,
    required this.commission,
    required this.birthdate,
  });

  factory Architect.fromJson(Map<String, dynamic> json) {
    return Architect(
      id: json['id'],
      firstname: json['firstname'] ?? "",
      lastname: json['lastname'] ?? "",
      whatsapp: json['whatsapp'] ?? "",
      commission: json['commission'] ?? 0,
      birthdate: json['birthdate'] ?? "",
    );
  }
}

/// ================= CLIENT MODEL =================
class Client {
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String altPhone;
  final String email;

  Client({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.altPhone,
    required this.email,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'] ?? "",
      lastName: json['Last_Name'] ?? "",
      phone: json['phone'] ?? "",
      altPhone: json['altphone'] ?? "",
      email: json['email'] ?? "",
    );
  }
}

/// ================= SCREEN =================
class ArchitectManagementScreen extends StatefulWidget {
  const ArchitectManagementScreen({super.key});

  @override
  State<ArchitectManagementScreen> createState() =>
      _ArchitectManagementScreenState();
}

class _ArchitectManagementScreenState extends State<ArchitectManagementScreen> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api/architects",
      headers: {"Content-Type": "application/json"},
    ),
  );

  bool loading = false;
  List<Architect> architects = [];

  @override
  void initState() {
    super.initState();
    fetchArchitects();
  }

  /// ================= GET ARCHITECTS =================
  Future<void> fetchArchitects() async {
    setState(() => loading = true);
    try {
      final res = await dio.get("/list");
      architects =
          (res.data['architects'] as List)
              .map((e) => Architect.fromJson(e))
              .toList();
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => loading = false);
  }

  /// ================= DELETE ARCHITECT =================
  Future<void> deleteArchitect(int id) async {
    await dio.delete("/delete/$id");
    fetchArchitects();
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Architect"),
            content: const Text(
              "Are you sure you want to delete this architect?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteArchitect(id);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// ================= CLIENT POPUP =================
  void showClientPopup(int architectId) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 420,
            child: FutureBuilder(
              future: dio.get("/getCustomersById/$architectId"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List data = snapshot.data?.data['customers'] ?? [];

                if (data.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people_outline, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No clients found"),
                    ],
                  );
                }

                final clients = data.map((e) => Client.fromJson(e)).toList();

                return Column(
                  children: [
                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Clients (${clients.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    /// CLIENT LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (_, i) {
                          final c = clients[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Name : ${c.name} ${c.lastName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (c.email.isNotEmpty)
                                  Text(
                                    "Email : ${c.email}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                if (c.phone.isNotEmpty)
                                  Text(
                                    "Phone : ${c.phone}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                if (c.altPhone.isNotEmpty)
                                  Text(
                                    "Alt Phone : ${c.altPhone}",
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// TOP BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFA54A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddArchitectScreen(),
                        ),
                      ).then((_) => fetchArchitects());
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: fetchArchitects,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: architects.length,
                        itemBuilder: (context, index) {
                          final a = architects[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CommissionPage(architectId: a.id),
                                ),
                              );
                            },
                            child: ArchitectCard(
                              architect: a,
                              onDelete: () => confirmDelete(a.id),
                              onClients: () => showClientPopup(a.id),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/// ================= CARD =================
class ArchitectCard extends StatelessWidget {
  final Architect architect;
  final VoidCallback onDelete;
  final VoidCallback onClients;

  const ArchitectCard({
    super.key,
    required this.architect,
    required this.onDelete,
    required this.onClients,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Name : ${architect.firstname} ${architect.lastname}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == "edit") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditArchitectScreen(
                              isEdit: true,
                              architectId: architect.id,
                              firstname: architect.firstname,
                              lastname: architect.lastname,
                              whatsapp: architect.whatsapp,
                              commission: architect.commission,
                              birthdate: architect.birthdate,
                              remark: "",
                            ),
                      ),
                    );
                  } else if (value == "clients") {
                    onClients();
                  } else if (value == "delete") {
                    onDelete();
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: "edit",
                        child: Text("Edit Architect Info"),
                      ),
                      PopupMenuItem(
                        value: "clients",
                        child: Text("Client Count"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete Architect",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Whatsapp No. : +91 ${architect.whatsapp}",
            style: const TextStyle(fontSize: 12.5),
          ),
          Text(
            "Commission : ${architect.commission}%",
            style: const TextStyle(fontSize: 12.5),
          ),
          Text(
            "Date Of Birth : ${architect.birthdate.substring(0, 10)}",
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
