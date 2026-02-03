import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON ke liye
import 'package:tcs_invantory_managment_system/auth/login_screen.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/Inventory%20Management/Inventory_Management.dart';
import 'package:tcs_invantory_managment_system/dashbard/Payment%20History/payment_hostory_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/Supplier%20managment/supplier_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/brand_managment/brand_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/category_managment/category_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/customer_management_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/dashboard_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_dash.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/dilivery_chalan.dart';
import 'package:tcs_invantory_managment_system/dashbard/employee_managment/employee_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/orderbook.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart';
import 'package:tcs_invantory_managment_system/dashbard/quality_managment/quality_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/reports/reports_screen.dart';

// Menu Item Model
class MenuItem {
  final String title;
  final IconData icon;
  final String moduleName; // API se match karne ke liye module name

  MenuItem({required this.title, required this.icon, required this.moduleName});
}

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
  String userRole = "";
  String userName = "";
  bool isLoading = true;

  // All possible menu items with their module names
  final List<MenuItem> allPossibleMenuItems = [
    MenuItem(title: "Dashboard", icon: Icons.dashboard, moduleName: ""),
    MenuItem(
      title: "Customer Management",
      icon: Icons.people,
      moduleName: "Customer Management",
    ),
    MenuItem(
      title: "Employee Registration",
      icon: Icons.person_add,
      moduleName: "Employee Registration",
    ),
    MenuItem(
      title: "Quality Management",
      icon: Icons.verified_user,
      moduleName: "Quality Management",
    ),
    MenuItem(
      title: "Category Management",
      icon: Icons.category,
      moduleName: "Category Management",
    ),
    MenuItem(
      title: "Brand Management",
      icon: Icons.branding_watermark,
      moduleName: "Brand Management",
    ),
    MenuItem(
      title: "Product Management",
      icon: Icons.inventory_2,
      moduleName: "Product Registration",
    ),
    MenuItem(
      title: "Supplier Management",
      icon: Icons.inventory_2,
      moduleName: "Supplier Management",
    ),
    MenuItem(
      title: "Architect Registration",
      icon: Icons.inventory_2,
      moduleName: "Architect Registration",
    ),
    MenuItem(
      title: "Inventory",
      icon: Icons.store,
      moduleName: "Inventory Management",
    ),
    MenuItem(
      title: "Quotation",
      icon: Icons.request_quote,
      moduleName: "Quotation Management",
    ),
    MenuItem(
      title: "Delivery Challan",
      icon: Icons.local_shipping,
      moduleName: "Delivery Challans",
    ),
    MenuItem(title: "Reports", icon: Icons.report, moduleName: ""),
    MenuItem(title: "Order Book", icon: Icons.book_online, moduleName: ""),
    MenuItem(
      title: "Payment History",
      icon: Icons.payment,
      moduleName: "Quotation Management",
    ),
    MenuItem(title: "Logout", icon: Icons.logout, moduleName: ""),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    slideAnim = Tween<double>(
      begin: -280,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> _initializeApp() async {
    try {
      await PermissionManager.init();
      await _loadUserData();
    } catch (e) {
      print("Error initializing app: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        userRole = prefs.getString("role") ?? "employee";
        userName = prefs.getString("userName") ?? "";
      });
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // Dynamic menu items based on role and permissions
  List<MenuItem> getFilteredMenuItems() {
    // Employee ke liye: Dashboard, Logout + jinke permissions hain
    if (userRole == "employee") {
      return allPossibleMenuItems.where((item) {
        // Dashboard aur Logout to hamesha show honge
        if (item.title == "Dashboard" || item.title == "Logout") {
          return true;
        }

        // Reports aur Order Book employee ke liye nahi honge
        if (item.title == "Reports" || item.title == "Order Book") {
          return false;
        }

        // Permission check karo
        if (item.moduleName.isEmpty) return false;

        // Check if user has any permission for this module
        return PermissionManager.hasAnyPermission(item.moduleName);
      }).toList();
    }

    // Admin/SuperAdmin ke liye: Full access (sab show karo)
    return allPossibleMenuItems;
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              userRole: userRole,
              userName: userName,
              filteredMenuItems: getFilteredMenuItems(),
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
                    userRole: userRole,
                    userName: userName,
                    filteredMenuItems: getFilteredMenuItems(),
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
  final String userRole;
  final String userName;
  final List<MenuItem> filteredMenuItems;

  const MainScreenWidget({
    super.key,
    required this.selectedPage,
    required this.onMenuPressed,
    required this.userRole,
    required this.userName,
    required this.filteredMenuItems,
  });

  // Check if user can access a screen
  bool _canAccessScreen(String screenName) {
    // Employee ke liye check
    if (userRole == "employee") {
      // Dashboard to hamesha access
      if (screenName == "Dashboard") {
        return true;
      }

      // Logout ke liye special handling
      if (screenName == "Logout") {
        return true;
      }

      // Find the menu item for this screen
      final menuItem = filteredMenuItems.firstWhere(
        (item) => item.title == screenName,
        orElse: () => MenuItem(title: "", icon: Icons.error, moduleName: ""),
      );

      // Agar menu item nahi mila to access nahi
      if (menuItem.title.isEmpty) return false;

      // Permission check
      if (menuItem.moduleName.isEmpty) return true;

      return PermissionManager.hasAnyPermission(menuItem.moduleName);
    }

    // Admin/SuperAdmin ke liye full access
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Agar employee hai to Employee Dashboard show karo
    if (userRole == "employee") {
      return Scaffold(
        backgroundColor: const Color(0xffF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xffFFA54A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: onMenuPressed,
          ),
          title: Text(
            selectedPage == "Dashboard" ? "Employee Dashboard" : selectedPage,
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  // TODO: Open profile screen
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        body: _pageContent(),
      );
    }

    // Agar admin/superadmin hai to purana wala UI
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
        actions: const [
          // Profile icon removed for simplicity
        ],
      ),
      body: _pageContent(),
    );
  }

  Widget _pageContent() {
    // Permission check for all users
    if (!_canAccessScreen(selectedPage)) {
      return _accessDeniedScreen();
    }

    // Agar employee hai to employee dashboard dikhao
    if (userRole == "employee") {
      if (selectedPage == "Dashboard") {
        return EmployeeDashboardScreen();
      }
      // Employee ke liye baki screens
      return _getScreenForPage(selectedPage);
    }

    // Agar admin/superadmin hai to purane wale screens dikhao
    return _getScreenForPage(selectedPage);
  }

  Widget _getScreenForPage(String pageName) {
    switch (pageName) {
      case "Dashboard":
        return userRole == "employee"
            ? EmployeeDashboardScreen()
            : DashboardPage();
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
            pageName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  Widget _accessDeniedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 60, color: Colors.red),
          SizedBox(height: 20),
          Text(
            "Access Denied",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "You don't have permission to access this page",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// DRAWER
/// ===================================================================

class AnimatedDrawerWidget extends StatelessWidget {
  final String selectedPage;
  final Function(String) onPageSelected;
  final VoidCallback onClose;
  final String userRole;
  final String userName;
  final List<MenuItem> filteredMenuItems;

  const AnimatedDrawerWidget({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onClose,
    required this.userRole,
    required this.userName,
    required this.filteredMenuItems,
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
                  children:
                      filteredMenuItems
                          .map(
                            (menuItem) =>
                                _item(context, menuItem.icon, menuItem.title),
                          )
                          .toList(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 10),
          Text(
            userName.isNotEmpty ? userName : "User",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userRole.toUpperCase(),
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
