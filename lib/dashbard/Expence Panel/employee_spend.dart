import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EmployeeTransactionRecordsSection extends StatefulWidget {
  const EmployeeTransactionRecordsSection({
    super.key,
    required List<dynamic> employeeList,
  });

  @override
  State<EmployeeTransactionRecordsSection> createState() =>
      _EmployeeTransactionRecordsSectionState();
}

class _EmployeeTransactionRecordsSectionState
    extends State<EmployeeTransactionRecordsSection> {
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

  // Transaction history state for selected employee
  List<dynamic> _selectedEmployeeTransactions = [];
  bool _isLoadingSelectedHistory = false;
  bool _showSelectedHistory = false;

  // Pagination for selected employee history
  int _currentSelectedPage = 1;
  int _totalSelectedPages = 1;
  int _totalSelectedRecords = 0;

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

  // Fetch employee salary history
  Future<void> _fetchEmployeeSalaryHistory(
    int employeeId, [
    int page = 1,
  ]) async {
    setState(() {
      _isLoadingSelectedHistory = true;
      _currentSelectedPage = page;
    });

    try {
      final response = await _dio.get(
        "/transactions/salary/history/$employeeId?page=$page",
      );

      if (response.data['success'] == true) {
        final data = response.data;
        setState(() {
          _selectedEmployeeTransactions = data['data'] ?? [];
          _totalSelectedPages = data['pagination']['totalPages'] ?? 1;
          _totalSelectedRecords = data['pagination']['totalRecords'] ?? 0;
          _showSelectedHistory = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee salary history: $e");
    } finally {
      setState(() {
        _isLoadingSelectedHistory = false;
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

    // Fetch salary history for selected employee
    _fetchEmployeeSalaryHistory(employee['id']);
  }

  // Handle search text change
  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _employeeList.clear();
        _selectedEmployee = null;
        _showSelectedHistory = false;
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
      _selectedEmployeeTransactions.clear();
      _showSelectedHistory = false;
    });
  }

  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d/M/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Employee Transaction Records'),
        const SizedBox(height: 12),

        // Search bar
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
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
                          hintText: 'Type employee name...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
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
                  margin: const EdgeInsets.only(top: 8),
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
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
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
                            double.tryParse(
                                  employee['salary']?.toString() ?? '0',
                                ) ??
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
            ],
          ),
        ),

        // Selected employee salary history
        if (_selectedEmployee != null && _showSelectedHistory) ...[
          const SizedBox(height: 16),

          // Selected employee name
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedEmployee!['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Salary history table
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
                            'REMARK',
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

                // Loading state
                if (_isLoadingSelectedHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                // Empty state
                else if (_selectedEmployeeTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: Text(
                        'No salary transactions found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                // Table rows
                else ...[
                  ..._selectedEmployeeTransactions.map((transaction) {
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
                            width: 100,
                            child: Text(
                              _formatDate(
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
                                transaction['note']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              _formatCurrency.format(amount),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Pagination
                  if (_totalSelectedPages > 1)
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
                                _currentSelectedPage > 1
                                    ? () {
                                      _fetchEmployeeSalaryHistory(
                                        _selectedEmployee!['id'],
                                        _currentSelectedPage - 1,
                                      );
                                    }
                                    : null,
                          ),
                          Text(
                            'Page $_currentSelectedPage of $_totalSelectedPages',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed:
                                _currentSelectedPage < _totalSelectedPages
                                    ? () {
                                      _fetchEmployeeSalaryHistory(
                                        _selectedEmployee!['id'],
                                        _currentSelectedPage + 1,
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
