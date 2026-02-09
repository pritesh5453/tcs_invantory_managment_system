import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EmployeeTransactionList extends StatefulWidget {
  const EmployeeTransactionList({super.key});

  @override
  State<EmployeeTransactionList> createState() =>
      _EmployeeTransactionListState();
}

class _EmployeeTransactionListState extends State<EmployeeTransactionList> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  // Employee search state
  List<Map<String, dynamic>> _employeeList = [];
  bool _isLoadingEmployees = false;
  Map<String, dynamic>? _selectedEmployee;

  // Wallet history state for selected employee
  List<dynamic> _walletHistory = [];
  String _currentBalance = '0';
  bool _isLoadingHistory = false;
  bool _showHistory = false;

  // Pagination for wallet history
  int _currentHistoryPage = 1;
  int _totalHistoryPages = 1;
  int _totalHistoryRecords = 0;

  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Fetch employees from API
  Future<void> _fetchEmployees(String query) async {
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoadingEmployees = true;
      });

      try {
        final response = await _dio.get(
          "/employees/list?page=1&limit=10&search=$query",
        );

        if (response.data['success'] == true) {
          setState(() {
            _employeeList = List<Map<String, dynamic>>.from(
              response.data['employees'],
            );
          });
        }
      } catch (e) {
        debugPrint("Error fetching employees: $e");
      } finally {
        setState(() {
          _isLoadingEmployees = false;
        });
      }
    });
  }

  // Fetch employee wallet history
  Future<void> _fetchEmployeeWalletHistory(
    int employeeId, [
    int page = 1,
  ]) async {
    setState(() {
      _isLoadingHistory = true;
      _currentHistoryPage = page;
    });

    try {
      final response = await _dio.get(
        "/Wallet/employee-history/$employeeId?page=$page",
      );

      if (response.data['success'] == true) {
        final data = response.data;
        setState(() {
          _walletHistory = data['data'] ?? [];
          _currentBalance = data['current_balance']?.toString() ?? '0';
          _totalHistoryRecords = data['count'] ?? 0;
          // Calculate total pages (assuming 10 records per page)
          _totalHistoryPages = (_totalHistoryRecords / 10).ceil();
          _showHistory = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee wallet history: $e");
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  // Handle employee selection
  void _onEmployeeSelected(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployee = employee;
      _searchController.text = employee['name'];
      _employeeList.clear();
    });

    // Fetch wallet history for selected employee
    _fetchEmployeeWalletHistory(employee['id']);
  }

  // Handle search text change
  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _employeeList.clear();
        _selectedEmployee = null;
        _showHistory = false;
      });
      return;
    }

    _fetchEmployees(value);
  }

  // Clear selection
  void _clearSelection() {
    setState(() {
      _selectedEmployee = null;
      _searchController.clear();
      _employeeList.clear();
      _walletHistory.clear();
      _currentBalance = '0';
      _showHistory = false;
    });
  }

  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Open bill image
  void _openBillImage(String? billUrl) {
    if (billUrl == null || billUrl.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bill Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Image.network(
                    billUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Failed to load image'));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Check Individual Employee Spend List'),
        const SizedBox(height: 8),

        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search employee to see their history...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon:
                        _selectedEmployee != null
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSelection,
                            )
                            : null,
                  ),
                ),
              ),
              if (_isLoadingEmployees)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),

        // Employee dropdown list
        if (_employeeList.isNotEmpty && _selectedEmployee == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade300),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _employeeList.length,
              itemBuilder: (context, index) {
                final employee = _employeeList[index];
                return ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  title: Text(
                    employee['name'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle:
                      employee['phone'] != null
                          ? Text(
                            'Phone: ${employee['phone']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                          : null,
                  trailing: Text(
                    _formatCurrency.format(
                      double.tryParse(employee['salary']?.toString() ?? '0') ??
                          0,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  onTap: () => _onEmployeeSelected(employee),
                );
              },
            ),
          ),

        // Selected employee wallet history
        if (_selectedEmployee != null && _showHistory) ...[
          const SizedBox(height: 16),

          // Employee card with wallet balance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee name
                Text(
                  _selectedEmployee!['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Current wallet balance - Updated to use API's current_balance
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CURRENT WALLET BALANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatCurrency.format(
                        double.tryParse(_currentBalance) ?? 0,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Wallet history table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'DATE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'REMARK/NOTE',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'PAYMENT IMAGES',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading state
                if (_isLoadingHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                // Empty state
                else if (_walletHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: Text(
                        'No wallet history found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                // Table rows
                else ...[
                  ..._walletHistory.map((transaction) {
                    final amount =
                        double.tryParse(
                          transaction['amount']?.toString() ?? '0',
                        ) ??
                        0;
                    final isCredit = transaction['type'] == 'CREDIT';
                    final hasBill =
                        transaction['bill_url'] != null &&
                        transaction['bill_url'].toString().isNotEmpty;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              _formatDate(
                                transaction['created_at']?.toString() ?? '',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                transaction['note']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child:
                                hasBill
                                    ? GestureDetector(
                                      onTap:
                                          () => _openBillImage(
                                            transaction['bill_url']?.toString(),
                                          ),
                                      child: const Text(
                                        'VIEW BILL',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    )
                                    : const Text(
                                      'NO ATTACHMENT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${isCredit ? '+' : '-'}${_formatCurrency.format(amount)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Pagination
                  if (_totalHistoryPages > 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed:
                                _currentHistoryPage > 1
                                    ? () {
                                      _fetchEmployeeWalletHistory(
                                        _selectedEmployee!['id'],
                                        _currentHistoryPage - 1,
                                      );
                                    }
                                    : null,
                          ),
                          Text(
                            'Page $_currentHistoryPage of $_totalHistoryPages',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed:
                                _currentHistoryPage < _totalHistoryPages
                                    ? () {
                                      _fetchEmployeeWalletHistory(
                                        _selectedEmployee!['id'],
                                        _currentHistoryPage + 1,
                                      );
                                    }
                                    : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
