import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class NewEntrySection extends StatefulWidget {
  final String selectedEntryType;
  final Function(String?)? onEntryTypeChanged;
  final VoidCallback? onSavePressed;
  final Function(Map<String, dynamic>)? onTransactionData;

  const NewEntrySection({
    super.key,
    required this.selectedEntryType,
    this.onEntryTypeChanged,
    this.onSavePressed,
    this.onTransactionData,
  });

  @override
  State<NewEntrySection> createState() => _NewEntrySectionState();
}

class _NewEntrySectionState extends State<NewEntrySection> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  // Recipient related state
  String _selectedRecipient = '';
  int? _selectedEmployeeId;
  List<Map<String, dynamic>> _employeeList = [];
  bool _isLoadingEmployees = false;
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final FocusNode _recipientFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _recipientFocusNode.addListener(_onRecipientFocusChanged);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    _recipientFocusNode.dispose();
    super.dispose();
  }

  void _onRecipientFocusChanged() {
    if (_recipientFocusNode.hasFocus && _recipientController.text.isEmpty) {
      _fetchEmployees('');
    }
  }

  // Fetch employees from API
  Future<void> _fetchEmployees(String query) async {
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
  }

  // Handle recipient text change
  void _onRecipientChanged(String value) {
    setState(() {
      _selectedRecipient = value;
      _selectedEmployeeId = null;
    });

    // Fetch employees based on search
    _fetchEmployees(value);

    // Update transaction data
    if (widget.onTransactionData != null) {
      widget.onTransactionData!({
        'name': value,
        'employee_id': null,
        'amount': _amountController.text,
        'remark': _remarkController.text,
      });
    }
  }

  // Handle employee selection from dropdown
  void _onEmployeeSelected(Map<String, dynamic> employee) {
    setState(() {
      _selectedRecipient = employee['name'];
      _selectedEmployeeId = employee['id'];
      _recipientController.text = employee['name'];
    });

    // Clear employee list after selection
    setState(() {
      _employeeList = [];
    });

    // Update transaction data
    if (widget.onTransactionData != null) {
      widget.onTransactionData!({
        'name': employee['name'],
        'employee_id': employee['id'],
        'amount': _amountController.text,
        'remark': _remarkController.text,
      });
    }
  }

  // Handle amount change
  void _onAmountChanged(String value) {
    if (widget.onTransactionData != null) {
      widget.onTransactionData!({
        'name': _selectedRecipient,
        'employee_id': _selectedEmployeeId,
        'amount': value,
        'remark': _remarkController.text,
      });
    }
  }

  // Handle remark change
  void _onRemarkChanged(String value) {
    if (widget.onTransactionData != null) {
      widget.onTransactionData!({
        'name': _selectedRecipient,
        'employee_id': _selectedEmployeeId,
        'amount': _amountController.text,
        'remark': value,
      });
    }
  }

  // Clear form after save
  void _clearForm() {
    setState(() {
      _selectedRecipient = '';
      _selectedEmployeeId = null;
      _recipientController.clear();
      _amountController.clear();
      _remarkController.clear();
      _employeeList.clear();
    });

    // Clear transaction data in parent
    if (widget.onTransactionData != null) {
      widget.onTransactionData!({
        'name': '',
        'employee_id': null,
        'amount': '',
        'remark': '',
      });
    }
  }

  // Handle save button press
  void _handleSavePressed() {
    if (widget.onSavePressed != null) {
      // Call parent's save function
      widget.onSavePressed!();

      // Clear form after successful save
      Future.delayed(const Duration(milliseconds: 300), () {
        _clearForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('New Entry'),
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
              /// 🔽 ENTRY TYPE DROPDOWN (Expense / Credit / Salary / Home)
              DropdownButtonFormField<String>(
                value: widget.selectedEntryType,
                items: const [
                  DropdownMenuItem(
                    value: "Expense (Debit)",
                    child: Text("Expense (Debit)"),
                  ),
                  DropdownMenuItem(
                    value: "Stock/Add (Credit)",
                    child: Text("Stock/Add (Credit)"),
                  ),
                  DropdownMenuItem(value: "Salary", child: Text("Salary")),
                  DropdownMenuItem(value: "Home", child: Text("Home")),
                ],
                onChanged: widget.onEntryTypeChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.swap_vert),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recipient/Name Field (Updated with Search + Dropdown)
              const Text(
                'Recipient / Name',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: Column(
                  children: [
                    // Text Field for manual input
                    TextField(
                      controller: _recipientController,
                      focusNode: _recipientFocusNode,
                      onChanged: _onRecipientChanged,
                      decoration: InputDecoration(
                        hintText: 'Search employee or type name...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        suffixIcon:
                            _isLoadingEmployees
                                ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),

                    // Dropdown list for search results
                    if (_employeeList.isNotEmpty)
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
                              onTap: () => _onEmployeeSelected(employee),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              const Text(
                'Amount (₹)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: _onAmountChanged,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remark Field
              const Text(
                'Remark',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _remarkController,
                maxLines: 3,
                onChanged: _onRemarkChanged,
                textInputAction:
                    TextInputAction.done, // 👈 DONE button show karega
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus(); // 👈 keyboard band karega
                },
                decoration: InputDecoration(
                  hintText: 'Enter remark for this transaction',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button (always enabled for all types)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSavePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
