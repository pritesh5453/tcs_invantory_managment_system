# State Management Migration Guide

This guide explains how to migrate existing Flutter screens to use the new standardized state management system.

## Overview

The new state management system provides:
- **Centralized state management** using singleton pattern
- **Type-safe state access** with dedicated managers
- **Automatic persistence** for authentication and dashboard data
- **Built-in error handling** and utilities
- **Mixin support** for easy integration

## State Managers Available

### 1. AppStateManager
Manages global application state:
- Loading states
- Error messages
- Initialization status

```dart
// Access
final appState = AppStateManager();

// Usage
appState.setLoading(true);
appState.setErrorMessage('Something went wrong');
appState.clearError();
```

### 2. AuthStateManager
Manages user authentication state:
- Login/logout status
- User information
- Role-based access

```dart
// Access
final authState = AuthStateManager();

// Usage
authState.setAuthData(
  isLoggedIn: true,
  userName: 'John Doe',
  role: 'admin',
);

authState.clearAuthData();
```

### 3. DashboardStateManager
Manages dashboard-related data:
- Admin stats
- User-wise orders
- Employee/architect lists
- Product catalogs

```dart
// Access
final dashboardState = DashboardStateManager();

// Usage
dashboardState.setAdminStats({'customerCount': 100});
dashboardState.setUserWiseOrders([...]);
```

### 4. FormStateManager
Manages complex form state (especially for quotations):
- Client information
- Product rows
- Calculations

```dart
// Access
final formState = FormStateManager();

// Usage
formState.setClientName('Client Name');
formState.addProductRow();
formState.calculateGrandTotal();
```

## Migration Steps

### Step 1: Add State Management Import

Add to your screen file:
```dart
import 'package:tcs_invantory_managment_system/global/state_management.dart';
```

### Step 2: Choose Integration Method

#### Option A: Using StateManagementMixin (Recommended)

Replace your existing `StatefulWidget` with the mixin:

```dart
// Before
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Your existing state management
}

// After
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with StateManagementMixin<MyScreen> {
  // The mixin provides: appState, authState, dashboardState, formState
  // No need to manually initialize state managers
}
```

#### Option B: Manual Integration

If you can't use the mixin, manually initialize state managers:

```dart
class _MyScreenState extends State<MyScreen> {
  late AppStateManager appState;
  late AuthStateManager authState;
  late DashboardStateManager dashboardState;
  late FormStateManager formState;

  @override
  void initState() {
    super.initState();
    
    // Initialize state managers
    appState = AppStateManager();
    authState = AuthStateManager();
    dashboardState = DashboardStateManager();
    formState = FormStateManager();
    
    // Add listeners for state changes
    appState.addListener(() {
      if (mounted) setState(() {});
    });
    // Add listeners for other state managers as needed
  }
}
```

### Step 3: Replace Existing State Management

#### Replace Loading States

```dart
// Before
bool _isLoading = false;
setState(() => _isLoading = true);

// After (with mixin)
appState.setLoading(true);

// After (manual)
appState.setLoading(true);
```

#### Replace Authentication Logic

```dart
// Before
bool _isLoggedIn = false;
String? _userName;

// After (with mixin)
if (authState.isLoggedIn) {
  // User is logged in
  String? userName = authState.userName;
}

// Login
authState.setAuthData(
  isLoggedIn: true,
  userName: 'John Doe',
  userEmail: 'john@example.com',
);

// Logout
authState.clearAuthData();
```

#### Replace Form Management

```dart
// Before
String _clientName = '';
List<ProductRow> _productRows = [];

// After (with mixin)
formState.setClientName('Client Name');
formState.addProductRow();
formState.removeProductRow(index);

// Calculations
double total = formState.calculateTotalAmount();
double grandTotal = formState.calculateGrandTotal();
```

### Step 4: Update UI to Use New State

```dart
// Before
Text(_clientName);
Text('Loading: $_isLoading');

// After (with mixin)
Text(formState.clientName);
appState.isLoading ? CircularProgressIndicator() : YourContent();
```

### Step 5: Add Error Handling

```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error occurred')),
);

// After (with mixin)
showError('Error occurred'); // Uses appState internally
showSuccess('Success!');    // Built-in success message
```

## Screen-Specific Migration Examples

### Quotation Screens

#### add_quotation.dart Migration

```dart
// Replace existing state management with:
class AddQuotationSheet extends StatefulWidget {
  @override
  _AddQuotationSheetState createState() => _AddQuotationSheetState();
}

class _AddQuotationSheetState extends State<AddQuotationSheet> with StateManagementMixin<AddQuotationSheet> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    appState.setLoading(true);
    
    try {
      // Load data using dashboard state
      await _fetchArchitects();
      await _fetchEmployees('');
      await _fetchProducts(search: '');
      
      // Initialize form
      formState.resetForm();
    } catch (e) {
      showError('Failed to load data: ${e.toString()}');
    } finally {
      appState.setLoading(false);
    }
  }

  // Replace existing form handling methods
  void _addProductRow() {
    formState.addProductRow();
  }

  void _removeProductRow(int index) {
    formState.removeProductRow(index);
  }

  // Replace save method
  Future<void> _saveQuotation() async {
    if (!authState.isLoggedIn) {
      showError('Please login first');
      return;
    }

    appState.setLoading(true);
    
    try {
      // Validate form
      if (formState.clientName.isEmpty) {
        showError('Please enter client name');
        return;
      }

      // Save logic here
      showSuccess('Quotation saved successfully!');
      formState.resetForm();
    } catch (e) {
      showError('Failed to save quotation');
    } finally {
      appState.setLoading(false);
    }
  }
}
```

### Dashboard Screens

#### admin_dash.dart Migration

```dart
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with StateManagementMixin<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    appState.setLoading(true);
    
    try {
      // Fetch and set data using dashboard state
      await _fetchDashboardStats();
      await _fetchUserWiseOrders();
      
      // Set date range
      final now = DateTime.now();
      dashboardState.setFromDate(DateTime(now.year, now.month, 1));
      dashboardState.setToDate(now);
    } catch (e) {
      showError('Failed to load dashboard data');
    } finally {
      appState.setLoading(false);
    }
  }

  Future<void> _fetchDashboardStats() async {
    // API call logic
    final stats = await _apiService.getDashboardStats();
    dashboardState.setAdminStats(stats);
  }

  Future<void> _fetchUserWiseOrders() async {
    final orders = await _apiService.getUserWiseOrders();
    dashboardState.setUserWiseOrders(orders);
  }
}
```

### Authentication Screens

#### login_screen.dart Migration

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with StateManagementMixin<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Check if already logged in
    if (authState.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
      );
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showError('Please enter email and password');
      return;
    }

    appState.setLoading(true);
    
    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response.success) {
        // Save auth data
        authState.setAuthData(
          isLoggedIn: true,
          token: response.token,
          userName: response.user.name,
          userEmail: response.user.email,
          userPhone: response.user.phone,
          profilePhoto: response.user.profilePhoto,
        );

        showSuccess('Login successful!');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
        );
      } else {
        showError(response.message ?? 'Login failed');
      }
    } catch (e) {
      showError('Login failed: ${e.toString()}');
    } finally {
      appState.setLoading(false);
    }
  }
}
```

## Best Practices

### 1. Use the Mixin When Possible
The `StateManagementMixin` provides automatic state management and cleanup.

### 2. Handle Loading States
Always use `appState.setLoading()` for async operations.

### 3. Use Error Handling
Use `showError()` and `showSuccess()` methods for consistent error handling.

### 4. Validate Before Actions
Always validate form data before API calls.

### 5. Clean Up Resources
The mixin handles cleanup automatically. For manual integration, ensure you remove listeners in `dispose()`.

### 6. Use Type-Safe Access
Use the dedicated getters and setters provided by each state manager.

## Common Migration Patterns

### Pattern 1: Form Validation
```dart
// Before
bool _validateForm() {
  if (_clientName.isEmpty) return false;
  return true;
}

// After
bool _validateForm() {
  if (formState.clientName.isEmpty) {
    showError('Please enter client name');
    return false;
  }
  return true;
}
```

### Pattern 2: API Error Handling
```dart
// Before
try {
  await apiCall();
} catch (e) {
  setState(() => _errorMessage = e.toString());
}

// After
try {
  await apiCall();
} catch (e) {
  showError('API call failed: ${e.toString()}');
}
```

### Pattern 3: State Updates
```dart
// Before
setState(() {
  _isLoading = false;
  _data = newData;
});

// After
appState.setLoading(false);
dashboardState.setAdminStats(newData);
```

## Testing the Migration

1. **Verify State Persistence**: Test that authentication state persists across app restarts.
2. **Check Form State**: Ensure form data is properly managed and calculations work.
3. **Test Error Handling**: Verify error messages display correctly.
4. **Validate Loading States**: Confirm loading indicators appear and disappear correctly.
5. **Check Navigation**: Ensure navigation works with the new state management.

## Troubleshooting

### Issue: State not updating UI
**Solution**: Ensure you're using the mixin or manually adding listeners.

### Issue: Memory leaks
**Solution**: The mixin handles cleanup automatically. For manual integration, remove listeners in `dispose()`.

### Issue: State not persisting
**Solution**: Use `PersistentAuthStateManager` for authentication data that needs to persist.

### Issue: Complex form state not working
**Solution**: Use `FormStateManager` for complex forms with multiple fields and calculations.

## Next Steps

After migrating to the new state management system:

1. **Remove old state management code** from migrated screens
2. **Update any remaining screens** that still use old patterns
3. **Test thoroughly** to ensure all functionality works correctly
4. **Consider adding unit tests** for the new state management logic

This migration will result in:
- More maintainable code
- Better separation of concerns
- Improved error handling
- Consistent state management across the app