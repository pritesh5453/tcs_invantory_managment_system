import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  final FocusNode _searchFocusNode = FocusNode(); // 🔥 Add focus node

  bool _isLoading = false;
  bool _showCustomerDetails = false;
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _customerDetails;
  List<dynamic> _challans = [];
  List<dynamic> _payments = [];

  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // 🔥 Dispose focus node
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showCustomerDetails = false;
        _selectedCustomer = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/users/list',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _searchResults = response.data['customers'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch customers';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCustomerDetails(int customerId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showCustomerDetails = false;
    });

    try {
      print('🔍 Fetching details for customer ID: $customerId');

      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/users/customer-data',
        queryParameters: {'customerId': customerId},
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['customer'] != null) {
          setState(() {
            _customerDetails = response.data['customer'];
            _challans = response.data['challans'] ?? [];
            _payments = response.data['payments'] ?? [];
            _showCustomerDetails = true;
            _isLoading = false;
            _searchResults = [];
            _searchController.clear();
          });

          // 🔥 Unfocus keyboard after customer selection
          _searchFocusNode.unfocus();

          print('✅ Customer details loaded successfully');
          print('   Wallet: ${_customerDetails?['wallet_amount']}');
          print('   Challans: ${_challans.length}');
          print('   Payments: ${_payments.length}');
        } else {
          setState(() {
            _errorMessage = 'Customer details not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch customer details (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching customer details: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    print('✅ Customer selected: ${customer['name']} (ID: ${customer['id']})');
    setState(() {
      _selectedCustomer = customer;
    });
    _fetchCustomerDetails(customer['id']);
  }

  double _getWalletAmount() {
    if (_customerDetails != null &&
        _customerDetails!['wallet_amount'] != null) {
      return double.tryParse(_customerDetails!['wallet_amount'].toString()) ??
          0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: GestureDetector(
          // 🔥 Add GestureDetector to dismiss keyboard on tap outside
          onTap: () {
            _searchFocusNode.unfocus();
          },
          child: Column(
            children: [
              // Search Bar Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Label
                    const Text(
                      'Search Customer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        focusNode: _searchFocusNode, // 🔥 Add focus node
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or mobile...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey,
                          ),
                          suffixIcon:
                              _isLoading
                                  ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xffFFA54A),
                                      ),
                                    ),
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: _searchCustomers,
                      ),
                    ),

                    // Search Results Dropdown
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final customer = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xffFFA54A,
                                ).withOpacity(0.1),
                                child: Text(
                                  customer['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xffFFA54A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                customer['phone'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onTap: () => _selectCustomer(customer),
                            );
                          },
                        ),
                      ),

                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Loading Indicator for details
              if (_isLoading && _searchResults.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xffFFA54A)),
                  ),
                ),

              // Customer Details Section (shows when customer is selected)
              if (_showCustomerDetails && _customerDetails != null) ...[
                // Currently Viewing Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF5E7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffFFA54A).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFA54A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility,
                          size: 20,
                          color: Color(0xffFFA54A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENTLY VIEWING',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _customerDetails!['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Customer ID: ${_customerDetails!['id']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.receipt_long,
                          label: 'Delivery Challans (${_challans.length})',
                          color: Colors.blue,
                          onTap: () {
                            _searchFocusNode.unfocus(); // 🔥 Close keyboard
                            _showChallansDialog();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.payment,
                          label: 'Payments (${_payments.length})',
                          color: Colors.green,
                          onTap: () {
                            _searchFocusNode.unfocus(); // 🔥 Close keyboard
                            _showPaymentsDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Wallet Balance Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Wallet Balance Label
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 24,
                            color: Color(0xffFFA54A),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AVAILABLE WALLET BALANCE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Balance Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹ ${_getWalletAmount().abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getWalletAmount() < 0
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),

                          // Credit Limit
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Balance Status
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getWalletAmount() < 0
                              ? 'Negative Balance'
                              : 'Positive Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _getWalletAmount() < 0
                                    ? Colors.red
                                    : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Account Info Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Account Holder Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account Holder',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            _customerDetails!['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),

                      // Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCustomer?['status'] ?? 'Active',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Phone Number Row
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // View Details Button
              ] else if (!_isLoading &&
                  _searchController.text.isEmpty &&
                  !_showCustomerDetails) ...[
                // Empty State - No Customer Selected
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for a customer',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter name or mobile number to search',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 IMPROVED: Better UI for Challans Dialog with SingleChildScrollView
  // 🔥 IMPROVED: Better UI for Challans Dialog with SingleChildScrollView
  void _showChallansDialog() {
    if (_challans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No delivery challans found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xffFFA54A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delivery Challans (${_challans.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content - SingleChildScrollView for many records
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children:
                            _challans.map((challan) {
                              // 🔥 Check if it's a black challan
                              final isBlackChallan =
                                  challan['isBlackChallan'] == 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isBlackChallan
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.blue.withOpacity(0.3),
                                    width: isBlackChallan ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          isBlackChallan
                                              ? Colors.red.withOpacity(0.05)
                                              : Colors.blue.withOpacity(0.05),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isBlackChallan
                                                    ? Icons
                                                        .warning_amber_rounded
                                                    : Icons.receipt,
                                                size: 20,
                                                color:
                                                    isBlackChallan
                                                        ? Colors.red
                                                        : Colors.blue,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Challan #${challan['challan_id']}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isBlackChallan
                                                          ? Colors.red
                                                          : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isBlackChallan)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'RED',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.currency_rupee,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Amount: ₹${double.parse(challan['amount'].toString()).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isBlackChallan
                                                      ? Colors.red
                                                      : Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (challan['deliveryBoy'] != null &&
                                          challan['deliveryBoy']
                                              .toString()
                                              .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delivery_dining,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Delivery Boy: ${challan['deliveryBoy']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (challan['quotationId'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.description,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Quotation #${challan['quotationId']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 🔥 IMPROVED: Better UI for Payments Dialog with SingleChildScrollView
  void _showPaymentsDialog() {
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payments found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xffFFA54A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Payments (${_payments.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content - SingleChildScrollView for many records
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(_payments.length, (index) {
                          final payment = _payments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.payment,
                                            size: 20,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Payment #${payment['id'] ?? index + 1}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (payment['createdAt'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(
                                              DateTime.parse(
                                                payment['createdAt'],
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Amount: ₹${payment['amount']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (payment['mode'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.payment,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Mode: ${payment['mode']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
