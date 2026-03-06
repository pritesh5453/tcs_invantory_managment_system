import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_todo.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/chart_model.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/notification.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/request_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/work_panel_screen.dart';

class DashboardPage extends StatefulWidget {
  final int userId;
  final String role;

  const DashboardPage({super.key, required this.userId, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Dio instance
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  List<SalesVsPurchaseData> salesVsPurchaseData = [];
  List<CashFlowData> cashFlowData = [];

  // Dashboard stats data
  Map<String, dynamic> dashboardStats = {};
  List<dynamic> userWiseOrders = [];
  bool isLoading = true;
  String errorMessage = '';

  // Date selection state - automatically set current month dates
  DateTime? fromDate;
  DateTime? toDate;

  // Flag to track if user manually changed dates
  bool _showMonthText = true;

  // Pending request count for notification dot
  int pendingRequestCount = 0;

  // Unread notification count
  int unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();

    // Set default dates to current month (1st to today)
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1); // Month start (1st)
    toDate = now; // Today's date

    _fetchAllData();
  }

  // Fetch Dashboard Stats API
  Future<void> _fetchDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          dashboardStats = response.data['data'];
        });
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } on DioException catch (e) {
      throw Exception('Dashboard stats error: ${e.message}');
    }
  }

  // Fetch chart data
  Future<void> _fetchChartData() async {
    try {
      final response = await _dio.get('/dashboard/charts');

      if (response.statusCode == 200) {
        final chartResponse = ChartDataResponse.fromJson(response.data);

        if (chartResponse.success) {
          setState(() {
            salesVsPurchaseData = chartResponse.data.salesVsPurchase;
            cashFlowData = chartResponse.data.cashFlow;
          });
        }
      }
    } catch (e) {
      print('Chart API Error: $e');
    }
  }

  // Fetch pending request count from /payment/pending
  Future<void> _fetchPendingRequestCount() async {
    try {
      final response = await _dio.get('/payment/pending');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          final requestsList = response.data['requests'] as List? ?? [];
          pendingRequestCount = requestsList.length;
        });
      } else {
        pendingRequestCount = 0;
      }
    } on DioException catch (e) {
      print('Pending request count error: $e');
      pendingRequestCount = 0;
    }
  }

  // Fetch unread notification count from /users/GetNotification
  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final response = await _dio.get(
        '/users/GetNotification',
        queryParameters: {
          'role': 'Admin',
          'page': 1,
          'limit': 100,
        }, // fetch enough to count unread
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final notifications = response.data['data'] as List? ?? [];
        // Count unread – adjust field name if needed (e.g., 'read', 'is_read')
        final unreadCount =
            notifications.where((n) => n['is_read'] == false).length;
        setState(() {
          unreadNotificationCount = unreadCount;
        });
      } else {
        unreadNotificationCount = 0;
      }
    } on DioException catch (e) {
      print('Unread notification count error: $e');
      unreadNotificationCount = 0;
    }
  }

  // Fetch all data
  Future<void> _fetchAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchDashboardStats(),
        _fetchUserWiseOrders(),
        _fetchChartData(),
        _fetchPendingRequestCount(),
        _fetchUnreadNotificationCount(), // NEW
      ]);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch User Wise Orders API
  Future<void> _fetchUserWiseOrders() async {
    try {
      final startDate = fromDate!;
      final endDate = toDate!;

      final response = await _dio.get(
        '/dashboard/user-wise-orders',
        queryParameters: {
          'start': _formatDateForApi(startDate),
          'end': _formatDateForApi(endDate),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          userWiseOrders = response.data['data'];
        });
      } else {
        throw Exception('Failed to load user orders');
      }
    } on DioException catch (e) {
      throw Exception('User orders error: ${e.message}');
    }
  }

  // Helper function to format date for display
  String _formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper function to format date for API
  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate
              ? (fromDate ?? DateTime.now())
              : (toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Can't select future dates
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  // Submit task function
  Future<void> _submitTask() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From Date and To Date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (fromDate!.isAfter(toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From Date cannot be after To Date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (toDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select future dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _showMonthText = false;
    });

    try {
      final response = await _dio.get(
        '/dashboard/user-wise-orders',
        queryParameters: {
          'start': _formatDateForApi(fromDate),
          'end': _formatDateForApi(toDate),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          userWiseOrders = response.data['data'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to load user orders');
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xffFFA34D)),
              const SizedBox(height: 20),
              Text(
                'Loading Dashboard Data...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFA34D),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    _dashboardOverviewCard(isMobile),
                    SizedBox(height: isMobile ? 12 : 16),
                    _assignedTaskCard(context, isMobile),
                    SizedBox(height: isMobile ? 12 : 16),
                    _statsGrid(isMobile, isTablet),
                    SizedBox(height: isMobile ? 12 : 16),
                    _bottomCharts(context, isMobile, isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = DateTime.now();
          setState(() {
            fromDate = DateTime(now.year, now.month, 1);
            toDate = now;
            _showMonthText = true;
          });
          _fetchAllData();
        },
        backgroundColor: const Color(0xffFFA34D),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Reset to Current Month',
      ),
    );
  }

  // 🔶 TOP HEADER with notification dot
  Widget _topHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xffFFA34D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isMobile ? 20 : 28),
          bottomRight: Radius.circular(isMobile ? 20 : 28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Expanded(
              //   child: Container(
              //     height: isMobile ? 44 : 48,
              //     padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              //     ),
              //     // child: Row(
              //     //   children: [
              //     //     Icon(Icons.search, size: isMobile ? 20 : 24),
              //     //     SizedBox(width: isMobile ? 8 : 12),
              //     //     Text(
              //     //       "Search..",
              //     //       style: TextStyle(
              //     //         color: Colors.grey,
              //     //         fontSize: isMobile ? 14 : 16,
              //     //       ),
              //     //     ),
              //     //   ],
              //     // ),
              //   ),
              // ),
              SizedBox(width: isMobile ? 8 : 12),
              // 🔔 NOTIFICATION ICON WITH RED DOT
              // Stack(
              //   clipBehavior: Clip.none,
              //   children: [
              //     Container(
              //       height: isMobile ? 44 : 48,
              //       width: isMobile ? 44 : 48,
              //       decoration: BoxDecoration(
              //         color: Colors.white,
              //         borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              //       ),
              //       child: IconButton(
              //         icon: Icon(
              //           Icons.notifications_none,
              //           size: isMobile ? 20 : 24,
              //         ),
              //         onPressed: () {
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (context) => const NotificationScreen(),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //     if (unreadNotificationCount > 0)
              //       Positioned(
              //         top: 0,
              //         right: 0,
              //         child: Container(
              //           width: isMobile ? 10 : 12,
              //           height: isMobile ? 10 : 12,
              //           decoration: BoxDecoration(
              //             color: Colors.red,
              //             shape: BoxShape.circle,
              //             border: Border.all(color: Colors.white, width: 1.5),
              //           ),
              //         ),
              //       ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔶 DASHBOARD OVERVIEW CARD
  Widget _dashboardOverviewCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        border: Border.all(color: const Color(0xffFFA34D), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              "Dashboard\nOverview",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          Wrap(
            spacing: isMobile ? 6 : 8,
            runSpacing: isMobile ? 6 : 8,
            children: [
              // 🔔 REQUESTS CHIP WITH NOTIFICATION DOT
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentRequestsPage(),
                        ),
                      );
                    },
                    child: _overviewChip(
                      label: "Requests",
                      color: const Color(0xffFFA34D),
                      icon: Icons.notifications,
                      isMobile: isMobile,
                    ),
                  ),
                  if (pendingRequestCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: isMobile ? 12 : 14,
                        height: isMobile ? 12 : 14,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TodoPage(
                            userId: widget.userId,
                            role: widget.role,
                          ),
                    ),
                  );
                },
                child: _overviewChip(
                  label: isMobile ? "To-Do" : "To-Do\nGeneral",
                  color: const Color(0xff2D9CDB),
                  icon: Icons.checklist,
                  isMobile: isMobile,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssignTaskPage(),
                    ),
                  );
                },
                child: _overviewChip(
                  label: "Work Panel",
                  color: const Color(0xff27AE60),
                  icon: Icons.work,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewChip({
    required String label,
    required Color color,
    required IconData icon,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 16 : 18,
            height: isMobile ? 16 : 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: isMobile ? 12 : 14, color: Colors.black),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: isMobile ? 1.0 : 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // 🔶 ASSIGNED TASK CARD - using dynamic API data
  Widget _assignedTaskCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "User Wise Order",
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _dateChip(_formatDateForDisplay(fromDate), isMobile, true),
              _dateChip(_formatDateForDisplay(toDate), isMobile, false),
              GestureDetector(
                onTap: _submitTask,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffFFF6EC),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Name",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Total Attended",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Quotation Count",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic rows from API with Scrollbar
          if (userWiseOrders.isNotEmpty)
            Container(
              height: isMobile ? 180 : 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6.0,
                radius: const Radius.circular(10),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 4,
                  ),
                  itemCount: userWiseOrders.length,
                  itemBuilder: (context, index) {
                    final employee = userWiseOrders[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        border:
                            index < userWiseOrders.length - 1
                                ? const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFF0F0F0),
                                    width: 1.0,
                                  ),
                                )
                                : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee['employeeName'] ?? 'N/A',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (employee['customerCount'] ?? 0).toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (employee['quotationCount'] ?? 0).toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: isMobile ? 180 : 200,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              alignment: Alignment.center,
              child: Text(
                'No data available',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),

          // Current month indicator - only show when not manually submitted
          if (_showMonthText)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: isMobile ? 16 : 18,
                    color: Colors.blue,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Text(
                    "Showing data for ${_getCurrentMonthName()} ${DateTime.now().year}",
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper function to get current month name
  String _getCurrentMonthName() {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[DateTime.now().month - 1];
  }

  Widget _dateChip(String text, bool isMobile, [bool isFromDate = false]) {
    return GestureDetector(
      onTap: () => _selectDate(context, isFromDate),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(fontSize: isMobile ? 13 : 14)),
            SizedBox(width: isMobile ? 6 : 8),
            Icon(Icons.calendar_today, size: isMobile ? 16 : 18),
          ],
        ),
      ),
    );
  }

  // 🔶 STATS GRID - using dynamic API data
  Widget _statsGrid(bool isMobile, bool isTablet) {
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 3;
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.0,
      children: [
        _StatCard(
          "Monthly Customers",
          (dashboardStats['customerCurrentMonthCount'] ?? 0).toString(),
          isMobile: isMobile,
        ),
        _StatCard(
          "Monthly Purchases",
          '₹${dashboardStats['monthlyPurchasesTotal'] ?? 0}',
          isMobile: isMobile,
        ),
        _StatCard(
          "Quotations",
          (dashboardStats['monthlyQuestionCount'] ?? 0).toString(),
          isMobile: isMobile,
        ),
        _StatCard(
          "Delivery Challans",
          (dashboardStats['deliveryChallanCount'] ?? 0).toString(),
          isMobile: isMobile,
        ),
        _StatCard(
          "New Architects",
          (dashboardStats['architectsCount'] ?? 0).toString(),
          isMobile: isMobile,
        ),
        _StatCard(
          "New Products",
          (dashboardStats['productsCount'] ?? 0).toString(),
          isMobile: isMobile,
        ),
      ],
    );
  }

  // 🔶 BOTTOM CHARTS
  Widget _bottomCharts(BuildContext context, bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _chartCard(
            context,
            title: "Purchase Record",
            isPurchase: true,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _chartCard(
            context,
            title: "Cash Flow Trend",
            isPurchase: false,
            isMobile: isMobile,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _chartCard(
            context,
            title: "Purchase Record",
            isPurchase: true,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _chartCard(
            context,
            title: "Cash Flow Trend",
            isPurchase: false,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required bool isPurchase,
    required bool isMobile,
  }) {
    final chartData = isPurchase ? salesVsPurchaseData : cashFlowData;
    final hasData = chartData.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color:
                      isPurchase ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(
                  isPurchase ? Icons.bar_chart : Icons.currency_rupee,
                  color: isPurchase ? Colors.blue : Colors.green,
                  size: isMobile ? 20 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPurchase)
                _filterChip(
                  "LAST ${salesVsPurchaseData.length} MONTHS",
                  isMobile: isMobile,
                )
              else
                Row(
                  children: [
                    _legendDot(Colors.green, "IN", isMobile),
                    SizedBox(width: isMobile ? 8 : 12),
                    _legendDot(Colors.red, "OUT", isMobile),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            height: isMobile ? 200 : 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            ),
            child:
                hasData
                    ? isPurchase
                        ? _buildPurchaseChart(isMobile)
                        : _buildCashFlowChart(isMobile)
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPurchase
                                ? Icons.shopping_cart
                                : Icons.trending_up,
                            color: Colors.grey,
                            size: isMobile ? 40 : 50,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            "No Chart Data",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isMobile ? 15 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseChart(bool isMobile) {
    final maxValue =
        salesVsPurchaseData.isNotEmpty
            ? salesVsPurchaseData
                .map((e) => e.purchase)
                .reduce((a, b) => a > b ? a : b)
            : 0;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 10.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${salesVsPurchaseData[groupIndex].month}\n₹${rod.toY.toInt()}',
                  TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();

                  if (index >= 0 && index < salesVsPurchaseData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        salesVsPurchaseData[index].month,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 45 : 50,
                interval: maxValue / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: TextStyle(fontSize: isMobile ? 10 : 12),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue > 0 ? maxValue / 4 : 1000,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups:
              salesVsPurchaseData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.purchase,
                      width: isMobile ? 16 : 20,
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCashFlowChart(bool isMobile) {
    final maxValue =
        cashFlowData.isNotEmpty
            ? cashFlowData
                .map((e) => e.inAmount > e.outAmount ? e.inAmount : e.outAmount)
                .reduce((a, b) => a > b ? a : b)
            : 0;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 10.0),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < cashFlowData.length) {
                        final data = cashFlowData[index];
                        return LineTooltipItem(
                          '${data.day}\nIN: ₹${data.inAmount.toInt()}\nOUT: ₹${data.outAmount.toInt()}',
                          TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        );
                      }
                      return null;
                    })
                    .where((item) => item != null)
                    .toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 200000,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();

                  if (index >= 0 && index < cashFlowData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        cashFlowData[index].day,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 60 : 70,
                interval: maxValue > 0 ? maxValue / 4 : 1000,

                getTitlesWidget: (value, meta) {
                  String text;

                  if (value >= 1000000) {
                    text = '₹${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value >= 1000) {
                    text = '₹${(value / 1000).toStringAsFixed(0)}K';
                  } else {
                    text = '₹${value.toInt()}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: cashFlowData.length > 0 ? cashFlowData.length - 1 : 0,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots:
                  cashFlowData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.inAmount);
                  }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: isMobile ? 2.5 : 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots:
                  cashFlowData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.outAmount);
                  }).toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: isMobile ? 2.5 : 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text, {required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF5F7FA),
        borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 10 : 12,
          height: isMobile ? 10 : 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// 🔹 STAT CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isMobile;

  const _StatCard(this.title, this.value, {required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
