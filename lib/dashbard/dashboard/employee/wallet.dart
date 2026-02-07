import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model Classes
class WalletResponse {
  bool success;
  String employeeId;
  double currentBalance;
  double advanceBalance;
  String userName;
  List<Transaction> transactions;

  WalletResponse({
    required this.success,
    required this.employeeId,
    required this.currentBalance,
    required this.advanceBalance,
    required this.transactions,
    required this.userName,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      success: json['success'] ?? false,
      employeeId: json['employee_id']?.toString() ?? '',
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      advanceBalance: (json['advance_balance'] ?? 0).toDouble(),
      userName: json['user_name'] ?? '',
      transactions:
          json['transactions'] != null
              ? (json['transactions'] as List)
                  .map((e) => Transaction.fromJson(e))
                  .toList()
              : [],
    );
  }
}

class Transaction {
  int id;
  int employeeId;
  String type;
  String amount;
  String note;
  DateTime createdAt;
  String? billAttachment;

  Transaction({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
    this.billAttachment,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      type: json['type'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      note: json['note'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      billAttachment: json['bill_attachment'],
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  }
}

// Main Widget
class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key, required this.userName}) : super(key: key);
  final String userName;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // Variables
  String _selectedReason = 'Stock Expenses';
  File? _selectedReceipt;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // API Data
  WalletResponse? _walletData;
  final List<String> _reasons = [
    'Stock Expenses',
    'Travel Expenses',
    'Office Supplies',
    'Other',
  ];

  // Dio Instance
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboarduat.theceramicstudio.in/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  @override
  void initState() {
    super.initState();
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.deepPurple,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Fetch wallet data
    _fetchWalletData();
  }

  // API: Fetch Wallet Data
  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _dio.get('/wallet/stock/7');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          setState(() {
            _walletData = WalletResponse.fromJson(data);
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch wallet data';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API: Submit New Entry
  Future<void> _submitEntry() async {
    if (_amountController.text.isEmpty) {
      _showSnackBar('Please enter amount', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      FormData formData = FormData.fromMap({
        'employeeId': '7', // dynamic rakhna ho to variable use kar lena
        'amount': _amountController.text,
        'note': _selectedReason,
      });

      // Add receipt if selected
      if (_selectedReceipt != null) {
        formData.files.add(
          MapEntry(
            'bill_image',
            await MultipartFile.fromFile(_selectedReceipt!.path),
          ),
        );
      }

      // Expense API call
      final response = await _dio.post('/wallet/spend', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          _showSnackBar('Expense recorded successfully!', Colors.green);

          // Clear form on success
          _amountController.clear();
          setState(() {
            _selectedReceipt = null;
          });

          // Refresh wallet
          await _fetchWalletData();
        } else {
          _showSnackBar(data['message'] ?? 'Submission failed', Colors.red);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Server error';
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Pick Receipt Image
  Future<void> _pickReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedReceipt = File(image.path);
      });
    }
  }

  // Helper Methods
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get filtered transactions
  List<Transaction> get _advanceSalaryTransactions {
    if (_walletData == null) return [];
    return _walletData!.transactions
        .where((t) => t.note.toLowerCase().contains('advance salary'))
        .toList();
  }

  List<Transaction> get _expensesTransactions {
    if (_walletData == null) return [];
    return _walletData!.transactions
        .where((t) => !t.note.toLowerCase().contains('advance salary'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Employee Wallet',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _fetchWalletData,
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingScreen()
              : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 20),
          Text('Loading wallet data...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchWalletData,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 232, 88, 5), Color(0xFF7C3AED)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.userName}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'STAFF ID: #${_walletData?.employeeId ?? '006'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Balance Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    title: 'AVAILABLE STOCK\nFOR EXPENSES',
                    amount:
                        '₱${_walletData?.currentBalance.toStringAsFixed(2) ?? '0'}',
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceCard(
                    title: 'TOTAL ADVANCE\nSALARY',
                    amount:
                        '₱${_walletData?.advanceBalance.toStringAsFixed(2) ?? '0'}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // New Entry Form
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW ENTRY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Input
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₱)',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Reason Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      _reasons
                          .map(
                            (reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Upload Receipt Button
                OutlinedButton.icon(
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _selectedReceipt != null
                        ? 'Receipt Selected ✓'
                        : 'Upload Receipt',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                if (_selectedReceipt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _selectedReceipt!.path.split('/').last,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _selectedReason == 'Advance Salary'
                                ? 'REQUEST ADVANCE SALARY'
                                : 'SUBMIT EXPENSE',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),

          // History Sections
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHistorySection(
                  title: 'ADVANCE SALARY HISTORY',
                  icon: Icons.history,
                  transactions: _advanceSalaryTransactions,
                ),
                const SizedBox(height: 24),
                _buildHistorySection(
                  title: 'STOCK / GENERAL EXPENSES',
                  icon: Icons.bar_chart,
                  transactions: _expensesTransactions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection({
    required String title,
    required IconData icon,
    required List<Transaction> transactions,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${transactions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          transactions.isEmpty
              ? Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'NO RECORDS',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children:
                    transactions
                        .map(
                          (transaction) => _buildTransactionCard(transaction),
                        )
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final bool isAdvanceSalary = transaction.note.toLowerCase().contains(
      'advance salary',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₱${transaction.amount}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        transaction.type == 'CREDIT'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        transaction.type == 'CREDIT'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        transaction.type == 'CREDIT'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 12,
                        color:
                            transaction.type == 'CREDIT'
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              transaction.type == 'CREDIT'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isAdvanceSalary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 12,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Advance',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isAdvanceSalary) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transaction.note,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              transaction.formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (transaction.billAttachment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Receipt attached',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _dio.close();
    super.dispose();
  }
}
