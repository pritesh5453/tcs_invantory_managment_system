import 'package:flutter/material.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: const [
                TopBar(),
                Expanded(child: CrmTable()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Color(0xff1E1E1E),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "CERAMIC\nSTUDIO",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _menuItem("Dashboard", Icons.dashboard),
          _menuItem("Customer Management", Icons.people, active: true),
          _menuItem("Employee Registration", Icons.person_add),
          _menuItem("Product Management", Icons.inventory),
          _menuItem("Reports", Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}




class CrmTable extends StatelessWidget {
  const CrmTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 20),
          _tableHeader(),
          _rowData(),
          _rowData(),
          _rowData(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Customer Management (CRM)",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text("Add Customer"),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _rowText(
        bold: true,
        color: Colors.white,
        texts: [
          "Customer",
          "Employee",
          "Mobile",
          "Architect",
          "Next Follow Up",
          "Status",
          "Action"
        ],
      ),
    );
  }

  Widget _rowData() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _rowText(
        texts: [
          "Sunny Gupta",
          "Sagar",
          "789586674",
          "Architect 2",
          "2025-12-15 18:30",
          "Button",
          "History | Follow Up"
        ],
      ),
    );
  }

  Widget _rowText({
    required List<String> texts,
    bool bold = false,
    Color color = Colors.black,
  }) {
    return Row(
      children: texts
          .map(
            (e) => Expanded(
              child: Text(
                e,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}





class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.notifications),
          const SizedBox(width: 20),
          const CircleAvatar(backgroundColor: Colors.orange),
        ],
      ),
    );
  }
}
