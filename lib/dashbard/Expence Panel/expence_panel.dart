import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:tcs_invantory_managment_system/dashbard/Expence%20Panel/employee_spend.dart';
import 'package:tcs_invantory_managment_system/dashbard/Expence%20Panel/new_entry_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/Expence%20Panel/spend_list.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class ExpenseStockManagementScreen extends StatefulWidget {
  const ExpenseStockManagementScreen({super.key});

  @override
  State<ExpenseStockManagementScreen> createState() =>
      _ExpenseStockManagementScreenState();
}

class _ExpenseStockManagementScreenState
    extends State<ExpenseStockManagementScreen> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  // API Data States
  Map<String, dynamic> _summaryData = {};
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _isTransactionsLoading = true;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;

  // Entry type
  String _selectedEntryType = "Expense (Debit)";

  // Transaction data for API
  Map<String, dynamic> _transactionData = {
    'name': '',
    'amount': '',
    'remark': '',
    'type': 'debit',
    'employee_id': null,
  };

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
    _fetchTransactions(_currentPage);
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  /// ================= FETCH SUMMARY DATA =================
  Future<void> _fetchSummaryData() async {
    try {
      final response = await _dio.get(
        "/transactions/GetAllTransaction?page=1&limit=1",
      );

      if (response.data['success'] == true) {
        setState(() {
          _summaryData = response.data['summary'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ================= FETCH TRANSACTIONS =================
  Future<void> _fetchTransactions(int page) async {
    setState(() => _isTransactionsLoading = true);

    try {
      final response = await _dio.get(
        "/transactions/GetAllTransaction?page=$page&limit=10&search=",
      );

      if (response.data['success'] == true) {
        final data = response.data;
        setState(() {
          _transactions = data['data'] ?? [];
          _totalItems = data['pagination']['totalItems'] ?? 0;
          _totalPages = data['pagination']['totalPages'] ?? 1;
          _currentPage = data['pagination']['currentPage'] ?? 1;
          _itemsPerPage = data['pagination']['itemsPerPage'] ?? 10;
          _isTransactionsLoading = false;
        });
      } else {
        setState(() => _isTransactionsLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      setState(() => _isTransactionsLoading = false);
    }
  }

  /// ================= SAVE TRANSACTION =================
  Future<void> _saveTransaction() async {
    // Validate required fields
    if (_transactionData['name'] == null || _transactionData['name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient name')),
      );
      return;
    }

    if (_transactionData['amount'] == null ||
        _transactionData['amount'].isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    try {
      // Convert type based on selected entry type
      String apiType = 'debit';
      if (_selectedEntryType == 'Stock/Add (Credit)') {
        apiType = 'credit';
      } else if (_selectedEntryType == 'Salary') {
        apiType = 'salary';
      }

      final response = await _dio.post(
        "/transactions/createTransaction",
        data: {
          "name": _transactionData['name'],
          "amount": _transactionData['amount'],
          "remark": _transactionData['remark'],
          "type": apiType,
          "employee_id": _transactionData['employee_id'],
        },
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Transaction saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear transaction data
        setState(() {
          _transactionData = {
            'name': '',
            'amount': '',
            'remark': '',
            'type': 'debit',
            'employee_id': null,
          };
        });

        // Refresh data
        _fetchSummaryData();
        _fetchTransactions(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Failed to save transaction',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= UPDATE TRANSACTION DATA =================
  void _updateTransactionData(Map<String, dynamic> data) {
    setState(() {
      _transactionData['name'] = data['name'] ?? '';
      _transactionData['employee_id'] = data['employee_id'];
      _transactionData['amount'] = data['amount'] ?? '';
      _transactionData['remark'] = data['remark'] ?? '';
    });
  }

  /// ================= REFRESH ALL DATA =================
  Future<void> _refreshData() async {
    await _fetchSummaryData();
    await _fetchTransactions(1);
  }

  /// ================= FORMAT DATE =================
  String _formatApiDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d/M/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

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
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money_rounded,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Expense & Stock Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Balance Cards (API Data)
                    if (_isLoading)
                      _buildLoadingBalanceCards()
                    else
                      _buildBalanceCards(formatCurrency),
                    const SizedBox(height: 24),

                    // Check Individual Employee Spend List Section
                    const EmployeeTransactionList(),
                    const SizedBox(height: 24),

                    // New Entry Section
                    NewEntrySection(
                      selectedEntryType: _selectedEntryType,
                      onEntryTypeChanged: (val) {
                        setState(() {
                          _selectedEntryType = val!;
                        });
                      },
                      onSavePressed: _saveTransaction,
                      onTransactionData: _updateTransactionData,
                    ),

                    const SizedBox(height: 24),

                    // Admin Ledger (API Data)
                    _buildAdminLedgerSection(formatCurrency),
                    const SizedBox(height: 16),

                    // Pagination
                    _buildPagination(),
                    const SizedBox(height: 24),

                    // Employee Transaction Records Section
                    const EmployeeTransactionRecordsSection(employeeList: []),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBalanceCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSkeletonBalanceCard(width: 150),
          const SizedBox(width: 12),
          _buildSkeletonBalanceCard(width: 150),
          const SizedBox(width: 12),
          _buildSkeletonBalanceCard(width: 170),
        ],
      ),
    );
  }

  Widget _buildSkeletonBalanceCard({required double width}) {
    return Container(
      width: width,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards(NumberFormat formatCurrency) {
    final currentBalance =
        double.tryParse(_summaryData['current_balance']?.toString() ?? '0') ??
        0;
    final totalAdded =
        double.tryParse(_summaryData['total_added']?.toString() ?? '0') ?? 0;
    final totalExpenses =
        double.tryParse(_summaryData['total_expenses']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Main Balance
          Container(
            width: 150,
            child: _buildBalanceCard(
              title: 'MAIN BALANCE',
              amount: currentBalance,
              color: Colors.green,
              icon: Icons.account_balance_wallet,
              formatCurrency: formatCurrency,
            ),
          ),
          const SizedBox(width: 12),
          // Total Added
          Container(
            width: 150,
            child: _buildBalanceCard(
              title: 'TOTAL ADDED',
              amount: totalAdded,
              color: Colors.blue,
              icon: Icons.add_circle_outline,
              formatCurrency: formatCurrency,
            ),
          ),
          const SizedBox(width: 12),
          // Total Expenses
          Container(
            width: 170,
            child: _buildBalanceCard(
              title: 'TOTAL EXPENSES',
              amount: totalExpenses,
              color: Colors.red,
              icon: Icons.remove_circle_outline,
              formatCurrency: formatCurrency,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required NumberFormat formatCurrency,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLedgerSection(NumberFormat formatCurrency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Admin Ledger'),
        const SizedBox(height: 12),
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
              // Table Header
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
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'NAME',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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

              // Loading State
              if (_isTransactionsLoading)
                Container(
                  height: 200,
                  child: const Center(child: CircularProgressIndicator()),
                )
              // Empty State
              else if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              // Table Rows (API Data)
              else
                ..._transactions.map((transaction) {
                  final isDebit = transaction['type'] == 'debit';
                  final amount =
                      double.tryParse(
                        transaction['amount']?.toString() ?? '0',
                      ) ??
                      0;

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
                          width: 80,
                          child: Text(
                            _formatApiDate(
                              transaction['date']?.toString() ?? '',
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
                              transaction['name']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            isDebit
                                ? '-${formatCurrency.format(amount.abs())}'
                                : '+${formatCurrency.format(amount)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDebit ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              _currentPage > 1
                  ? () {
                    _fetchTransactions(_currentPage - 1);
                  }
                  : null,
        ),
        Text(
          'Page $_currentPage of $_totalPages',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              _currentPage < _totalPages
                  ? () {
                    _fetchTransactions(_currentPage + 1);
                  }
                  : null,
        ),
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
