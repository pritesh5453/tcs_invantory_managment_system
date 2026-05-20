import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/admin_todo.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/cancel_DC_req.dart';
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

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
  Map<String, dynamic> dashboardStats = {};
  List<dynamic> userWiseOrders = [];
  int pendingCancelDcCount = 0;
  int pendingRequestCount = 0;
  int unreadNotificationCount = 0;

  late DateTime fromDate;
  late DateTime toDate;
  bool _showMonthText = true;

  String _cachedFromDateDisplay = '';
  String _cachedToDateDisplay = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = now;
    _updateCachedDates();
    _fetchAllData();
  }

  void _updateCachedDates() {
    _cachedFromDateDisplay = _formatDateForDisplay(fromDate);
    _cachedToDateDisplay = _formatDateForDisplay(toDate);
  }

  String _formatDateForDisplay(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateForApi(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchDashboardStats(),
        _fetchUserWiseOrders(),
        _fetchChartData(),
        _fetchPendingRequestCount(),
        _fetchUnreadNotificationCount(),
        _fetchPendingCancelDcCount(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchPendingCancelDcCount() async {
    try {
      final response = await _dio.get('/dashboard/cancelled-delivery-challans');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        final pending =
            data.where((item) => item['status'] == 'Pending').length;
        setState(() => pendingCancelDcCount = pending);
      }
    } catch (e) {
      pendingCancelDcCount = 0;
    }
  }

  Future<void> _fetchDashboardStats() async {
    final response = await _dio.get('/dashboard/stats');
    if (response.statusCode == 200 && response.data['success'] == true) {
      setState(() => dashboardStats = response.data['data']);
    }
  }

  Future<void> _fetchChartData() async {
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
  }

  Future<void> _fetchPendingRequestCount() async {
    try {
      final response = await _dio.get('/payment/pending');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(
          () =>
              pendingRequestCount =
                  (response.data['requests'] as List?)?.length ?? 0,
        );
      }
    } catch (e) {
      pendingRequestCount = 0;
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final response = await _dio.get(
        '/users/GetNotification',
        queryParameters: {'role': 'Admin', 'page': 1, 'limit': 100},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final notifications = response.data['data'] as List? ?? [];
        setState(
          () =>
              unreadNotificationCount =
                  notifications.where((n) => n['is_read'] == false).length,
        );
      }
    } catch (e) {
      unreadNotificationCount = 0;
    }
  }

  Future<void> _fetchUserWiseOrders() async {
    final response = await _dio.get(
      '/dashboard/user-wise-orders',
      queryParameters: {
        'start': _formatDateForApi(fromDate),
        'end': _formatDateForApi(toDate),
      },
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      setState(() => userWiseOrders = response.data['data']);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate)
          fromDate = picked;
        else
          toDate = picked;
        _updateCachedDates();
      });
    }
  }

  Future<void> _submitTask() async {
    if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From Date cannot be after To Date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _showMonthText = false);
    try {
      final response = await _dio.get(
        '/dashboard/user-wise-orders',
        queryParameters: {
          'start': _formatDateForApi(fromDate),
          'end': _formatDateForApi(toDate),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => userWiseOrders = response.data['data']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _refresh() async {
    await _fetchAllData();
  }

  String _getCurrentMonthName() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[DateTime.now().month - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xffFFA34D),
        child: SafeArea(
          child: Column(
            children: [
              _TopHeader(isMobile: isMobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _DashboardOverviewCard(
                        isMobile: isMobile,
                        userId: widget.userId,
                        role: widget.role,
                        pendingRequestCount: pendingRequestCount,
                        pendingCancelDcCount: pendingCancelDcCount,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      _UserWiseOrdersTable(
                        isMobile: isMobile,
                        fromDateDisplay: _cachedFromDateDisplay,
                        toDateDisplay: _cachedToDateDisplay,
                        showMonthText: _showMonthText,
                        userWiseOrders: userWiseOrders,
                        onFromDateTap: () => _selectDate(context, true),
                        onToDateTap: () => _selectDate(context, false),
                        onSubmit: _submitTask,
                        currentMonthName: _getCurrentMonthName(),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      _StatsGrid(
                        isMobile: isMobile,
                        dashboardStats: dashboardStats,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      _BottomCharts(
                        isMobile: isMobile,
                        salesVsPurchaseData: salesVsPurchaseData,
                        cashFlowData: cashFlowData,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     final now = DateTime.now();
      //     setState(() {
      //       fromDate = DateTime(now.year, now.month, 1);
      //       toDate = now;
      //       _updateCachedDates();
      //       _showMonthText = true;
      //     });
      //     _refresh();
      //   },
      //   backgroundColor: const Color(0xffFFA34D),
      //   foregroundColor: Colors.white,
      //   child: const Icon(Icons.refresh),
      //   tooltip: 'Reset to Current Month',
      // ),
    );
  }
}

// ==================== SUB-WIDGETS ====================

class _TopHeader extends StatelessWidget {
  final bool isMobile;
  const _TopHeader({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xffFFA34D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isMobile ? 20 : 28),
          bottomRight: Radius.circular(isMobile ? 20 : 28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          // Search and notification widgets are intentionally left empty (as in original)
        ],
      ),
    );
  }
}

class _DashboardOverviewCard extends StatelessWidget {
  final bool isMobile;
  final int userId;
  final String role;
  final int pendingRequestCount;
  final int pendingCancelDcCount;

  const _DashboardOverviewCard({
    required this.isMobile,
    required this.userId,
    required this.role,
    required this.pendingRequestCount,
    required this.pendingCancelDcCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double spacing = screenWidth * 0.04; // 4% of width
    double runSpacing = screenWidth * 0.04;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        border: Border.all(color: const Color(0xffFFA34D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Title on top
          Text(
            "Dashboard Overview",
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: isMobile ? 10 : 14),

          // 🔥 Buttons below
          Wrap(
            alignment: WrapAlignment.start,
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              // Requests
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentRequestsPage(),
                          ),
                        ),
                    child: _OverviewChip(
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
                        width: screenWidth * 0.03,
                        height: screenWidth * 0.03,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),

              // To-Do
              InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TodoPage(userId: userId, role: role),
                      ),
                    ),
                child: _OverviewChip(
                  label: "To-Do",
                  color: const Color(0xff2D9CDB),
                  icon: Icons.checklist,
                  isMobile: isMobile,
                ),
              ),

              // Work Panel
              InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssignTaskPage()),
                    ),
                child: _OverviewChip(
                  label: "Work Panel",
                  color: const Color(0xff27AE60),
                  icon: Icons.work,
                  isMobile: isMobile,
                ),
              ),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CancelledChallansScreen(),
                          ),
                        ),
                    child: _OverviewChip(
                      label: "Cancel DC Requests",
                      color: const Color.fromARGB(255, 235, 56, 25),
                      icon: Icons.cancel, // better icon
                      isMobile: isMobile,
                    ),
                  ),
                  if (pendingCancelDcCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: screenWidth * 0.03,
                        height: screenWidth * 0.03,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _OverviewChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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
            ),
          ),
        ],
      ),
    );
  }
}

class _UserWiseOrdersTable extends StatelessWidget {
  final bool isMobile;
  final String fromDateDisplay;
  final String toDateDisplay;
  final bool showMonthText;
  final List<dynamic> userWiseOrders;
  final VoidCallback onFromDateTap;
  final VoidCallback onToDateTap;
  final VoidCallback onSubmit;
  final String currentMonthName;

  const _UserWiseOrdersTable({
    required this.isMobile,
    required this.fromDateDisplay,
    required this.toDateDisplay,
    required this.showMonthText,
    required this.userWiseOrders,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onSubmit,
    required this.currentMonthName,
  });

  @override
  Widget build(BuildContext context) {
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
              _DateChip(
                text: fromDateDisplay,
                isMobile: isMobile,
                onTap: onFromDateTap,
              ),
              _DateChip(
                text: toDateDisplay,
                isMobile: isMobile,
                onTap: onToDateTap,
              ),
              GestureDetector(
                onTap: onSubmit,
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
          // Header row
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffFFF6EC),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    "Name",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Total Attended",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Quotation Count",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Data rows
          if (userWiseOrders.isNotEmpty)
            SizedBox(
              height: isMobile ? 180 : 200,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6.0,
                radius: const Radius.circular(10),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                  itemCount: userWiseOrders.length,
                  itemExtent: 45, // fixed height for performance
                  itemBuilder: (context, index) {
                    final employee = userWiseOrders[index];
                    return Row(
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
                    );
                  },
                ),
              ),
            )
          else
            SizedBox(
              height: isMobile ? 180 : 200,
              child: const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (showMonthText)
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
                  const SizedBox(width: 8),
                  Text(
                    "Showing data for $currentMonthName ${DateTime.now().year}",
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
}

class _DateChip extends StatelessWidget {
  final String text;
  final bool isMobile;
  final VoidCallback onTap;

  const _DateChip({
    required this.text,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

class _StatsGrid extends StatelessWidget {
  final bool isMobile;
  final Map<String, dynamic> dashboardStats;

  const _StatsGrid({required this.isMobile, required this.dashboardStats});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isMobile ? 2 : 3;
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
}

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

class _BottomCharts extends StatelessWidget {
  final bool isMobile;
  final List<SalesVsPurchaseData> salesVsPurchaseData;
  final List<CashFlowData> cashFlowData;

  const _BottomCharts({
    required this.isMobile,
    required this.salesVsPurchaseData,
    required this.cashFlowData,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _ChartCard(
            title: "Purchase Record",
            isPurchase: true,
            isMobile: isMobile,
            salesVsPurchaseData: salesVsPurchaseData,
            cashFlowData: cashFlowData,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _ChartCard(
            title: "Cash Flow Trend",
            isPurchase: false,
            isMobile: isMobile,
            salesVsPurchaseData: salesVsPurchaseData,
            cashFlowData: cashFlowData,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _ChartCard(
              title: "Purchase Record",
              isPurchase: true,
              isMobile: isMobile,
              salesVsPurchaseData: salesVsPurchaseData,
              cashFlowData: cashFlowData,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _ChartCard(
              title: "Cash Flow Trend",
              isPurchase: false,
              isMobile: isMobile,
              salesVsPurchaseData: salesVsPurchaseData,
              cashFlowData: cashFlowData,
            ),
          ),
        ],
      );
    }
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final bool isPurchase;
  final bool isMobile;
  final List<SalesVsPurchaseData> salesVsPurchaseData;
  final List<CashFlowData> cashFlowData;

  const _ChartCard({
    required this.title,
    required this.isPurchase,
    required this.isMobile,
    required this.salesVsPurchaseData,
    required this.cashFlowData,
  });

  @override
  Widget build(BuildContext context) {
    final hasData =
        isPurchase ? salesVsPurchaseData.isNotEmpty : cashFlowData.isNotEmpty;

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
                ),
              ),
              if (isPurchase)
                _FilterChip(
                  "LAST ${salesVsPurchaseData.length} MONTHS",
                  isMobile: isMobile,
                )
              else
                Row(
                  children: [
                    _LegendDot(Colors.green, "IN", isMobile),
                    SizedBox(width: isMobile ? 8 : 12),
                    _LegendDot(Colors.red, "OUT", isMobile),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          SizedBox(
            height: isMobile ? 200 : 220,
            child:
                hasData
                    ? (isPurchase
                        ? _PurchaseChart(
                          data: salesVsPurchaseData,
                          isMobile: isMobile,
                        )
                        : _CashFlowChart(
                          data: cashFlowData,
                          isMobile: isMobile,
                        ))
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
}

class _PurchaseChart extends StatelessWidget {
  final List<SalesVsPurchaseData> data;
  final bool isMobile;

  const _PurchaseChart({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final maxValue =
        data.isNotEmpty
            ? data.map((e) => e.purchase).reduce((a, b) => a > b ? a : b)
            : 0;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.white, // ✅ replace
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].month}\n₹${rod.toY.toInt()}',
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
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].month,
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
                getTitlesWidget:
                    (value, meta) => Text(
                      '₹${(value / 1000).toStringAsFixed(0)}K',
                      style: TextStyle(fontSize: isMobile ? 10 : 12),
                    ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
              data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.purchase,
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
}

class _CashFlowChart extends StatelessWidget {
  final List<CashFlowData> data;
  final bool isMobile;

  const _CashFlowChart({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final maxValue =
        data.isNotEmpty
            ? data
                .map((e) => e.inAmount > e.outAmount ? e.inAmount : e.outAmount)
                .reduce((a, b) => a > b ? a : b)
            : 0;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      child: LineChart(
        LineChartData(
          /// 🔥 TOUCH TOOLTIP FIXED
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.white, // ✅ NEW तरीका
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < data.length) {
                        final item = data[index];
                        return LineTooltipItem(
                          '${item.day}\nIN: ₹${item.inAmount.toInt()}\nOUT: ₹${item.outAmount.toInt()}',
                          TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        );
                      }
                      return null;
                    })
                    .whereType<LineTooltipItem>()
                    .toList();
              },
            ),
          ),

          /// 🔥 GRID
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue > 0 ? maxValue / 4 : 1000,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),

          /// 🔥 TITLES
          titlesData: FlTitlesData(
            show: true,

            /// Bottom (Days)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].day,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),

            /// Left (Amount)
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

            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),

          /// 🔥 BORDER
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),

          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,

          /// 🔥 LINE DATA
          lineBarsData: [
            /// IN Line
            LineChartBarData(
              spots:
                  data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.inAmount))
                      .toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: isMobile ? 2.5 : 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),

            /// OUT Line
            LineChartBarData(
              spots:
                  data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.outAmount))
                      .toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: isMobile ? 2.5 : 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String text;
  final bool isMobile;
  const _FilterChip(this.text, {required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isMobile;
  const _LegendDot(this.color, this.label, this.isMobile);

  @override
  Widget build(BuildContext context) {
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
