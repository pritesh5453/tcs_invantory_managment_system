import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/color/color.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  _TermsAndConditionsScreenState createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final bool _isChecked = false; // Checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: AppBar(
        title: Text("Terms and Conditions"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    """Welcome to our app! By using our services, you agree to these Terms and Conditions.

1. **Use of Services**: You must be at least 18 years old to use this app. Unauthorized access or misuse is strictly prohibited.

2. **Privacy Policy**: Your personal data is collected and used in accordance with our Privacy Policy.

3. **Payments & Transactions**: We process payments securely, but we are not responsible for transaction failures.

4. **Limitation of Liability**: We are not liable for any damages, losses, or service interruptions.

5. **Changes to Terms**: We reserve the right to update these terms at any time. Continued use of the app constitutes acceptance of any changes.

By proceeding, you agree to abide by these Terms and Conditions.""",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                // Checkbox(
                //   value: _isChecked,
                //   onChanged: (bool? value) {
                //     setState(() {
                //       _isChecked = value ?? false;
                //     });
                //   },
                // ),
                // Expanded(
                //   child: Text(
                //     "I agree to the Terms and Conditions",
                //     style: TextStyle(fontSize: 16),
                //   ),
                // ),
              ],
            ),
            // SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: _isChecked ? () {
            //     // Proceed to the next step
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(content: Text("Terms Accepted!")),
            //     );
            //   } : null, // Disable button if not checked
            //   child: Text("Accept & Continue"),
            // ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: TermsAndConditionsScreen()));
}
