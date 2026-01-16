import 'package:flutter/material.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  String? selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: const [
                    Icon(Icons.credit_card, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Settlement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _amountBox(
                      title: "Paid Amount",
                      value: "00.00",
                      valueColor: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    _amountBox(
                      title: "Due Amount",
                      value: "₹ 90,000",
                      valueColor: Colors.black,
                    ),
                  ],
                ),
            
                const SizedBox(height: 16),
                
                const Text(
                  "Select Payment Method",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Select Payment method"),
                  items: const [
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(value: "UPI", child: Text("UPI")),
                    DropdownMenuItem(value: "Bank", child: Text("Bank Transfer")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMethod = value;
                    });
                  },
                ),
            
                const SizedBox(height: 12),
            
                /// Amount
                const Text(
                  "Amount",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Enter Amount"),
                ),
            
                const SizedBox(height: 12),
            
                /// Remark
                const Text(
                  "Remark",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: _inputDecoration("E.g - Received by Hand"),
                ),
            
                const SizedBox(height: 20),
            
                /// Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA9C42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Save Payment",
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
        ),
      ),
    );
  }
  
  Widget _amountBox({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
    );
  }
}