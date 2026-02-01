import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/auth/login_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/Inventory%20Management/Inventory_Management.dart';
import 'package:tcs_invantory_managment_system/dashbard/Payment%20History/payment_hostory_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/Supplier%20managment/supplier_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/brand_managment/brand_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/category_managment/category_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/customer_management_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/dashboard_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/dilivery_chalan.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/employee_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/orderbook.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart';
import 'package:tcs_invantory_managment_system/dashbard/quality_managment/quality_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/reports/reports_screen.dart';

class HomeWithAnimatedDrawer extends StatefulWidget {
  const HomeWithAnimatedDrawer({super.key});

  @override
  State<HomeWithAnimatedDrawer> createState() => _HomeWithAnimatedDrawerState();
}

class _HomeWithAnimatedDrawerState extends State<HomeWithAnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> slideAnim;

  bool isOpen = false;
  String selectedPage = "Dashboard";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    slideAnim = Tween<double>(
      begin: -280,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void toggleDrawer() {
    if (isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => isOpen = !isOpen);
  }

  void selectPage(String page) {
    setState(() {
      selectedPage = page;
    });
    toggleDrawer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// ================= MAIN SCREEN (STATIC) =================
            MainScreenWidget(
              selectedPage: selectedPage,
              onMenuPressed: toggleDrawer,
            ),

            /// ================= DARK OVERLAY =================
            if (isOpen)
              GestureDetector(
                onTap: toggleDrawer,
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),

            /// ================= DRAWER =================
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(slideAnim.value, 0),
                  child: AnimatedDrawerWidget(
                    selectedPage: selectedPage,
                    onPageSelected: selectPage,
                    onClose: toggleDrawer,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// MAIN SCREEN
/// ===================================================================

class MainScreenWidget extends StatelessWidget {
  final String selectedPage;
  final VoidCallback onMenuPressed;

  const MainScreenWidget({
    super.key,
    required this.selectedPage,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA54A),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA54A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: onMenuPressed,
        ),
        title: Text(selectedPage, style: const TextStyle(color: Colors.black)),

        // 👇 PROFILE ICON SIRF DASHBOARD PAR
        actions:
            selectedPage == "Dashboard"
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Open profile screen / menu
                      },
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                    ),
                  ),
                ]
                : [],
      ),

      body: _pageContent(),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.black,
      //   onPressed: () {},
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _pageContent() {
    switch (selectedPage) {
      case "Dashboard":
        return DashboardScreen();
      case "Customer Management":
        return CustomerManagementScreen();
      case "Employee Registration":
        return EmployeeManagmentScreen();
      case "Quality Management":
        return QualityManagementScreen();
      case "Category Management":
        return CategoryManagementScreen();
      case "Brand Management":
        return BrandManagementScreen();
      case "Product Management":
        return ProductRegistrationScreen();
      case "Supplier Management":
        return SupplierManagementScreen();
      case "Architect Registration":
        return ArchitectManagementScreen();
      case "Inventory":
        return InventoryManagementScreen();
      case "Quotation":
        return Quontation_home_screen();
      case "Delivery Challan":
        return DeliveryChalanScreen();
      case "Reports":
        return AdvanceAnalyticsScreen();
      case "Order Book":
        return OrderBookManagementScreen();
      case "Payment History":
        return PaymentHistoryScreen();

      default:
        return Center(
          child: Text(
            selectedPage,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}

/// ===================================================================
/// DRAWER
/// ===================================================================

class AnimatedDrawerWidget extends StatelessWidget {
  final String selectedPage;
  final Function(String) onPageSelected;
  final VoidCallback onClose;

  const AnimatedDrawerWidget({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 280,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _item(context, Icons.dashboard, "Dashboard"),
                    _item(context, Icons.people, "Customer Management"),
                    _item(context, Icons.person_add, "Employee Registration"),
                    _item(context, Icons.verified_user, "Quality Management"),
                    _item(context, Icons.category, "Category Management"),
                    _item(
                      context,
                      Icons.branding_watermark,
                      "Brand Management",
                    ),
                    _item(context, Icons.inventory_2, "Product Management"),
                    _item(context, Icons.inventory_2, "Supplier Management"),
                    _item(context, Icons.inventory_2, "Architect Registration"),
                    _item(context, Icons.store, "Inventory"),
                    _item(context, Icons.request_quote, "Quotation"),
                    _item(context, Icons.local_shipping, "Delivery Challan"),
                    _item(context, Icons.report, "Reports"),
                    _item(context, Icons.book_online, "Order Book"),
                    _item(context, Icons.payment, "Payment History"),
                    _item(context, Icons.logout, "Logout"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/images/Logo_2.png",
            width: 120,
            height: 60,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Image.asset(
              "assets/images/Vector_1.png",
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title) {
    final bool selected = selectedPage == title;

    return InkWell(
      onTap: () {
        if (title == "Logout") {
          onClose();
          showLogoutDialog(context);
        } else {
          onPageSelected(title);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? Colors.orange.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.orange : Colors.white70,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.orange : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLogoutDialog(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _logout(outerContext);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔥 CLEAR LOGIN STATE

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
