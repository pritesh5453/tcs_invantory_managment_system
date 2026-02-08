import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tcs_invantory_managment_system/auth/login_screen.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/Employee%20Attendance/employee_attendance.dart';
import 'package:tcs_invantory_managment_system/dashbard/Expence%20Panel/expence_panel.dart';
import 'package:tcs_invantory_managment_system/dashbard/Inventory%20Management/Inventory_Management.dart';
import 'package:tcs_invantory_managment_system/dashbard/Payment%20History/payment_hostory_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/Special_Access/employee_list.dart';
import 'package:tcs_invantory_managment_system/dashbard/Supplier%20managment/supplier_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/architect_managment.dart';
import 'package:tcs_invantory_managment_system/dashbard/brand_managment/brand_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/category_managment/category_managment_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/customer_management_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/dashboard_screen.dart';
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
  final String moduleName;
  final bool isSpecial; // Special flag for top 3 items

  MenuItem({
    required this.title,
    required this.icon,
    required this.moduleName,
    this.isSpecial = false,
  });
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
  int userId = 0;
  bool isLoading = true;

  // Special top items (will appear at the top of drawer)
  final List<MenuItem> specialMenuItems = [
    MenuItem(
      title: "Permissions",
      icon: Icons.access_time,
      moduleName: "",
      isSpecial: true,
    ),
    MenuItem(
      title: "Employee Attendance",
      icon: Icons.calendar_today,
      moduleName: "Employee Attendance",
      isSpecial: true,
    ),
    MenuItem(
      title: "Expense Stock Management",
      icon: Icons.calendar_today,
      moduleName: "Expense Stock Management",
      isSpecial: true,
    ),
  ];

  // Regular menu items (will appear after divider)
  final List<MenuItem> regularMenuItems = [
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
      icon: Icons.architecture,
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
      moduleName: "Payment History",
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
        userId = prefs.getInt("userId") ?? 0;
        userRole = prefs.getString("role") ?? "employee";
        userName = prefs.getString("userName") ?? "";
      });
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // Get filtered special items (top 3 items)
  List<MenuItem> getFilteredSpecialItems() {
    // Agar admin ya superadmin hai to sab kuch dikhao
    if (userRole == "admin" || userRole == "superadmin") {
      return specialMenuItems;
    }

    // Employee ke liye permission-based filtering
    if (userRole == "employee") {
      return specialMenuItems.where((item) {
        // Permissions employee ke liye nahi honge
        if (item.title == "Permissions") {
          return false;
        }

        // Permission check karo
        if (item.moduleName.isEmpty) return false;

        // Check if user has any permission for this module
        return PermissionManager.hasAnyPermission(item.moduleName);
      }).toList();
    }

    return specialMenuItems;
  }

  // Get filtered regular items
  List<MenuItem> getFilteredRegularItems() {
    // Agar admin ya superadmin hai to sab kuch dikhao
    if (userRole == "admin" || userRole == "superadmin") {
      return regularMenuItems;
    }

    // Employee ke liye permission-based filtering
    if (userRole == "employee") {
      return regularMenuItems.where((item) {
        // Dashboard aur Logout to hamesha show honge
        if (item.title == "Dashboard" || item.title == "Logout") {
          return true;
        }

        // Reports aur Order Book employee ke liye nahi honge
        if (item.title == "Reports" || item.title == "Order Book") {
          return false;
        }

        // Permissions employee ke liye nahi (ye to special mein hai hi)
        if (item.title == "Permissions") {
          return false;
        }

        // Permission check karo
        if (item.moduleName.isEmpty) return false;

        // Check if user has any permission for this module
        return PermissionManager.hasAnyPermission(item.moduleName);
      }).toList();
    }

    return regularMenuItems;
  }

  // Combined menu items (special first, then regular)
  List<MenuItem> getCombinedMenuItems() {
    final filteredSpecial = getFilteredSpecialItems();
    final filteredRegular = getFilteredRegularItems();
    return [...filteredSpecial, ...filteredRegular];
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
              userId: userId,
              filteredMenuItems: getCombinedMenuItems(),
              specialMenuItems: getFilteredSpecialItems(),
              regularMenuItems: getFilteredRegularItems(),
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
                    filteredMenuItems: getCombinedMenuItems(),
                    specialMenuItems: getFilteredSpecialItems(),
                    regularMenuItems: getFilteredRegularItems(),
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
  final int userId;
  final List<MenuItem> filteredMenuItems;
  final List<MenuItem> specialMenuItems;
  final List<MenuItem> regularMenuItems;

  const MainScreenWidget({
    super.key,
    required this.selectedPage,
    required this.onMenuPressed,
    required this.userRole,
    required this.userName,
    required this.userId,
    required this.filteredMenuItems,
    required this.specialMenuItems,
    required this.regularMenuItems,
  });

  // Check if user can access a screen
  bool _canAccessScreen(String screenName) {
    // Admin aur SuperAdmin ko full access
    if (userRole == "admin" || userRole == "superadmin") {
      return true;
    }

    // Dashboard aur Logout to hamesha access
    if (screenName == "Dashboard" || screenName == "Logout") {
      return true;
    }

    // Employee ke liye special checks
    if (userRole == "employee") {
      // Reports aur Order Book employee ke liye nahi
      if (screenName == "Reports" || screenName == "Order Book") {
        return false;
      }

      // Permissions employee ke liye nahi
      if (screenName == "Permissions") {
        return false;
      }
    }

    // Find the menu item for this screen
    final menuItem = filteredMenuItems.firstWhere(
      (item) => item.title == screenName,
      orElse: () => MenuItem(title: "", icon: Icons.error, moduleName: ""),
    );

    // Agar menu item nahi mila to access nahi
    if (menuItem.title.isEmpty) return false;

    // If the moduleName is empty (like for Dashboard, Logout), allow access
    if (menuItem.moduleName.isEmpty) return true;

    // Check if user has any permission for this module
    return PermissionManager.hasAnyPermission(menuItem.moduleName);
  }

  @override
  Widget build(BuildContext context) {
    if (userId == 0) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Invalid user session.\nPlease login again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

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
    if (userRole == "employee" && selectedPage == "Dashboard") {
      return EmployeeDashboardScreen(
        userId: userId,
        role: userRole,
        userName: userName,
      );
    }

    // Sabke liye common screens
    return _getScreenForPage(selectedPage);
  }

  Widget _getScreenForPage(String pageName) {
    switch (pageName) {
      case "Dashboard":
        return userRole == "employee"
            ? EmployeeDashboardScreen(
              userId: userId,
              role: userRole,
              userName: userName,
            )
            : DashboardPage(userId: userId, role: userRole);
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
      case "Permissions":
        return EmployeesListScreen();
      case "Employee Attendance":
        return EmployeeAttendanceScreen();
      case "Expense Stock Management":
        return ExpenseStockManagementScreen();
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
          const Icon(Icons.block, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            "Access Denied",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "You don't have permission to access $selectedPage",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
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
  final List<MenuItem> specialMenuItems;
  final List<MenuItem> regularMenuItems;

  const AnimatedDrawerWidget({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onClose,
    required this.userRole,
    required this.userName,
    required this.filteredMenuItems,
    required this.specialMenuItems,
    required this.regularMenuItems,
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
                    /// SPECIAL ITEMS (Top 3 items - Bold)
                    if (specialMenuItems.isNotEmpty)
                      Column(
                        children:
                            specialMenuItems
                                .map(
                                  (menuItem) => _item(
                                    context,
                                    menuItem.icon,
                                    menuItem.title,
                                    isSpecial: true,
                                  ),
                                )
                                .toList(),
                      ),

                    /// DIVIDER
                    if (specialMenuItems.isNotEmpty &&
                        regularMenuItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Divider(
                          color: Colors.grey.shade700,
                          thickness: 1,
                          height: 1,
                        ),
                      ),

                    /// REGULAR ITEMS
                    if (regularMenuItems.isNotEmpty)
                      Column(
                        children:
                            regularMenuItems
                                .map(
                                  (menuItem) => _item(
                                    context,
                                    menuItem.icon,
                                    menuItem.title,
                                    isSpecial: false,
                                  ),
                                )
                                .toList(),
                      ),
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
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title, {
    bool isSpecial = false,
  }) {
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
              color:
                  selected
                      ? Colors.orange
                      : (isSpecial ? Colors.white : Colors.white70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      selected
                          ? Colors.orange
                          : (isSpecial ? Colors.white : Colors.white70),
                  fontSize: 14,
                  fontWeight:
                      isSpecial
                          ? FontWeight.bold
                          : (selected ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ),
            // Special items ke liye ek indicator (optional)
            if (isSpecial && !selected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(3),
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
