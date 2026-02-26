import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/global/state_management.dart';

/// Example of how to use the new standardized state management
/// This shows how to update existing screens to use the new system

class ExampleQuotationScreen extends StatefulWidget {
  const ExampleQuotationScreen({super.key});

  @override
  State<ExampleQuotationScreen> createState() => _ExampleQuotationScreenState();
}

class _ExampleQuotationScreenState extends State<ExampleQuotationScreen> with StateManagementMixin<ExampleQuotationScreen> {
  // The mixin automatically provides access to all state managers
  // No need to manually create or manage state instances

  @override
  void initState() {
    super.initState();
    
    // Example: Load initial data using the state managers
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Set loading state
    appState.setLoading(true);

    try {
      // Example: Check if user is authenticated
      if (!authState.isLoggedIn) {
        // Navigate to login
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Example: Load dashboard data
      await _loadDashboardData();
      
      // Example: Initialize form data
      formState.resetForm();
      
    } catch (e) {
      showError('Failed to load data: ${e.toString()}');
    } finally {
      appState.setLoading(false);
    }
  }

  Future<void> _loadDashboardData() async {
    // Example of using dashboard state manager
    dashboardState.setAdminStats({
      'customerCurrentMonthCount': 150,
      'monthlyPurchasesTotal': 500000,
      'monthlyQuestionCount': 45,
      'deliveryChallanCount': 30,
      'architectsCount': 12,
      'productsCount': 200,
    });

    dashboardState.setUserWiseOrders([
      {
        'employeeName': 'John Doe',
        'customerCount': 25,
        'quotationCount': 15,
      },
      {
        'employeeName': 'Jane Smith',
        'customerCount': 30,
        'quotationCount': 20,
      },
    ]);

    dashboardState.setArchitects([
      {
        'id': 1,
        'firstname': 'Architect',
        'lastname': 'One',
      },
      {
        'id': 2,
        'firstname': 'Architect',
        'lastname': 'Two',
      },
    ]);

    dashboardState.setEmployees([
      {
        'id': 1,
        'name': 'Employee One',
      },
      {
        'id': 2,
        'name': 'Employee Two',
      },
    ]);

    dashboardState.setProducts([
      {
        'id': 1,
        'name': 'Product A',
        'size': '12x12',
        'quality': 'Premium',
        'rate': '100',
        'cov': '1.1',
      },
      {
        'id': 2,
        'name': 'Product B',
        'size': '16x16',
        'quality': 'Standard',
        'rate': '80',
        'cov': '1.0',
      },
    ]);
  }

  // Example: Save quotation using form state
  Future<void> _saveQuotation() async {
    if (authState.isLoggedIn) {
      appState.setLoading(true);

      try {
        // Validate form
        if (formState.clientName.isEmpty) {
          showError('Please enter client name');
          return;
        }

        // Calculate totals
        final totalAmount = formState.calculateTotalAmount();
        final grandTotal = formState.calculateGrandTotal();

        // Example API call would go here
        // await _apiService.saveQuotation(formState.productRows);

        showSuccess('Quotation saved successfully!');
        
        // Reset form after successful save
        formState.resetForm();

      } catch (e) {
        showError('Failed to save quotation: ${e.toString()}');
      } finally {
        appState.setLoading(false);
      }
    } else {
      showError('Please login first');
    }
  }

  // Example: Update form data
  void _updateFormData() {
    formState.setClientName('Updated Client Name');
    formState.setContactNumber('+91 9876543210');
    formState.setSiteAddress('Updated Site Address');
    
    // Add a product row
    formState.addProductRow();
    
    // Update the first product row
    if (formState.productRows.isNotEmpty) {
      final firstRow = formState.productRows[0];
      firstRow.productName = 'Updated Product';
      firstRow.size = '12x12';
      firstRow.quality = 'Premium';
      firstRow.rateController.text = '150';
      firstRow.updateTotal();
      
      formState.updateProductRow(0, firstRow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Quotation Screen'),
      ),
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Example: Display authentication status
          Text(
            'Auth Status: ${authState.isLoggedIn ? 'Logged In' : 'Not Logged In'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Example: Display user info
          if (authState.isLoggedIn)
            Text('User: ${authState.userName ?? 'Unknown'}'),
          
          const SizedBox(height: 16),

          // Example: Display form data
          Text('Client Name: ${formState.clientName}'),
          Text('Contact: ${formState.contactNumber}'),
          Text('Site Address: ${formState.siteAddress}'),
          const SizedBox(height: 16),

          // Example: Display calculated totals
          Text('Total Amount: ₹${formState.calculateTotalAmount().toStringAsFixed(2)}'),
          Text('Grand Total: ₹${formState.calculateGrandTotal().toStringAsFixed(2)}'),
          const SizedBox(height: 16),

          // Example: Display dashboard data
          if (dashboardState.adminStats.isNotEmpty)
            Text('Monthly Customers: ${dashboardState.adminStats['customerCurrentMonthCount'] ?? 0}'),

          const SizedBox(height: 20),

          // Example: Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _updateFormData,
                child: const Text('Update Form'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveQuotation,
                child: const Text('Save Quotation'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Example: Toggle authentication
                  if (authState.isLoggedIn) {
                    authState.clearAuthData();
                  } else {
                    authState.setAuthData(
                      isLoggedIn: true,
                      userName: 'Test User',
                      userEmail: 'test@example.com',
                      userPhone: '+91 1234567890',
                    );
                  }
                },
                child: Text(authState.isLoggedIn ? 'Logout' : 'Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Example of how to use state management without the mixin
class ExampleWithoutMixin extends StatefulWidget {
  const ExampleWithoutMixin({super.key});

  @override
  State<ExampleWithoutMixin> createState() => _ExampleWithoutMixinState();
}

class _ExampleWithoutMixinState extends State<ExampleWithoutMixin> {
  late AppStateManager appState;
  late AuthStateManager authState;
  late DashboardStateManager dashboardState;
  late FormStateManager formState;

  @override
  void initState() {
    super.initState();
    
    // Manually initialize state managers
    appState = AppStateManager();
    authState = AuthStateManager();
    dashboardState = DashboardStateManager();
    formState = FormStateManager();
    
    // Add listeners for state changes
    appState.addListener(() {
      if (mounted) setState(() {});
    });
    authState.addListener(() {
      if (mounted) setState(() {});
    });
    dashboardState.addListener(() {
      if (mounted) setState(() {});
    });
    formState.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Without Mixin Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Auth Status: ${authState.isLoggedIn ? 'Logged In' : 'Not Logged In'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                authState.setAuthData(
                  isLoggedIn: true,
                  userName: 'Example User',
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to use persistent auth state
class ExamplePersistentAuth extends StatefulWidget {
  const ExamplePersistentAuth({super.key});

  @override
  State<ExamplePersistentAuth> createState() => _ExamplePersistentAuthState();
}

class _ExamplePersistentAuthState extends State<ExamplePersistentAuth> {
  final persistentAuth = PersistentAuthStateManager();

  @override
  void initState() {
    super.initState();
    
    // The persistent auth manager automatically loads saved data in constructor
    persistentAuth.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _login() async {
    persistentAuth.saveAuthData(
      isLoggedIn: true,
      userName: 'Persistent User',
      userEmail: 'persistent@example.com',
      userPhone: '+91 1234567890',
    );
  }

  Future<void> _logout() async {
    await persistentAuth.clearAuthDataWithPersistence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Auth Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Auth Status: ${persistentAuth.isLoggedIn ? 'Logged In' : 'Not Logged In'}'),
            if (persistentAuth.isLoggedIn) Text('User: ${persistentAuth.userName ?? 'Unknown'}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login (Persistent)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}