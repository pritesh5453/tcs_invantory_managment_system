import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

/// ================= SINGLETON STATE MANAGEMENT =================

/// Global App State Manager
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  
  factory AppStateManager() => _instance;
  
  AppStateManager._internal();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<VoidCallback> _listeners = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  void setLoading(bool loading) {
    _isLoading = loading;
    _notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    _notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _notifyListeners();
  }

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

/// User Authentication State Manager
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  
  factory AuthStateManager() => _instance;
  
  AuthStateManager._internal();

  bool _isLoggedIn = false;
  String? _token;
  String? _role;
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _profilePhoto;
  List<VoidCallback> _listeners = [];

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get profilePhoto => _profilePhoto;

  void setAuthData({
    required bool isLoggedIn,
    String? token,
    String? role,
    int? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? profilePhoto,
  }) {
    _isLoggedIn = isLoggedIn;
    _token = token;
    _role = role;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _userPhone = userPhone;
    _profilePhoto = profilePhoto;
    _notifyListeners();
  }

  void clearAuthData() {
    _isLoggedIn = false;
    _token = null;
    _role = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _profilePhoto = null;
    _notifyListeners();
  }

  bool get isEmployee => _role == 'employee';
  bool get isAdmin => _role == 'admin';

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

/// Dashboard State Manager
class DashboardStateManager {
  static final DashboardStateManager _instance = DashboardStateManager._internal();
  
  factory DashboardStateManager() => _instance;
  
  DashboardStateManager._internal();

  // Admin Dashboard State
  Map<String, dynamic> _adminStats = {};
  List<dynamic> _userWiseOrders = [];
  List<dynamic> _architects = [];
  List<dynamic> _employees = [];
  List<dynamic> _products = [];

  // Employee Dashboard State
  List<dynamic> _employeeTasks = [];
  Map<String, dynamic> _employeeStats = {};
  Map<String, dynamic> _attendanceSummary = {};

  // Common State
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showMonthText = true;
  List<VoidCallback> _listeners = [];

  // Getters
  Map<String, dynamic> get adminStats => _adminStats;
  List<dynamic> get userWiseOrders => _userWiseOrders;
  List<dynamic> get architects => _architects;
  List<dynamic> get employees => _employees;
  List<dynamic> get products => _products;
  List<dynamic> get employeeTasks => _employeeTasks;
  Map<String, dynamic> get employeeStats => _employeeStats;
  Map<String, dynamic> get attendanceSummary => _attendanceSummary;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  bool get showMonthText => _showMonthText;

  // Admin Dashboard Setters
  void setAdminStats(Map<String, dynamic> stats) {
    _adminStats = stats;
    _notifyListeners();
  }

  void setUserWiseOrders(List<dynamic> orders) {
    _userWiseOrders = orders;
    _notifyListeners();
  }

  void setArchitects(List<dynamic> architects) {
    _architects = architects;
    _notifyListeners();
  }

  void setEmployees(List<dynamic> employees) {
    _employees = employees;
    _notifyListeners();
  }

  void setProducts(List<dynamic> products) {
    _products = products;
    _notifyListeners();
  }

  // Employee Dashboard Setters
  void setEmployeeTasks(List<dynamic> tasks) {
    _employeeTasks = tasks;
    _notifyListeners();
  }

  void setEmployeeStats(Map<String, dynamic> stats) {
    _employeeStats = stats;
    _notifyListeners();
  }

  void setAttendanceSummary(Map<String, dynamic> summary) {
    _attendanceSummary = summary;
    _notifyListeners();
  }

  // Common Setters
  void setFromDate(DateTime? date) {
    _fromDate = date;
    _notifyListeners();
  }

  void setToDate(DateTime? date) {
    _toDate = date;
    _notifyListeners();
  }

  void setShowMonthText(bool show) {
    _showMonthText = show;
    _notifyListeners();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _showMonthText = true;
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

/// Form State Manager for Complex Forms
class FormStateManager {
  static final FormStateManager _instance = FormStateManager._internal();
  
  factory FormStateManager() => _instance;
  
  FormStateManager._internal();

  // Quotation Form State
  String _clientName = '';
  String _clientGst = '';
  String _contactNumber = '';
  String _altNumber = '';
  String _siteAddress = '';
  String _email = '';
  String _additionalDiscount = '0';
  String? _selectedArchitectId;
  String? _selectedEmployeeId;
  int? _selectedClientId;
  List<ProductRowState> _productRows = [ProductRowState()];
  List<VoidCallback> _listeners = [];

  // Getters
  String get clientName => _clientName;
  String get clientGst => _clientGst;
  String get contactNumber => _contactNumber;
  String get altNumber => _altNumber;
  String get siteAddress => _siteAddress;
  String get email => _email;
  String get additionalDiscount => _additionalDiscount;
  String? get selectedArchitectId => _selectedArchitectId;
  String? get selectedEmployeeId => _selectedEmployeeId;
  int? get selectedClientId => _selectedClientId;
  List<ProductRowState> get productRows => _productRows;

  // Setters
  void setClientName(String name) {
    _clientName = name;
    _notifyListeners();
  }

  void setClientGst(String gst) {
    _clientGst = gst;
    _notifyListeners();
  }

  void setContactNumber(String number) {
    _contactNumber = number;
    _notifyListeners();
  }

  void setAltNumber(String number) {
    _altNumber = number;
    _notifyListeners();
  }

  void setSiteAddress(String address) {
    _siteAddress = address;
    _notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _notifyListeners();
  }

  void setAdditionalDiscount(String discount) {
    _additionalDiscount = discount;
    _notifyListeners();
  }

  void setSelectedArchitectId(String? id) {
    _selectedArchitectId = id;
    _notifyListeners();
  }

  void setSelectedEmployeeId(String? id) {
    _selectedEmployeeId = id;
    _notifyListeners();
  }

  void setSelectedClientId(int? id) {
    _selectedClientId = id;
    _notifyListeners();
  }

  void setProductRows(List<ProductRowState> rows) {
    _productRows = rows;
    _notifyListeners();
  }

  void addProductRow() {
    _productRows.add(ProductRowState());
    _notifyListeners();
  }

  void removeProductRow(int index) {
    if (_productRows.length > 1) {
      _productRows.removeAt(index);
      _notifyListeners();
    }
  }

  void updateProductRow(int index, ProductRowState row) {
    if (index >= 0 && index < _productRows.length) {
      _productRows[index] = row;
      _notifyListeners();
    }
  }

  double calculateTotalAmount() {
    double total = 0;
    for (var row in _productRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  double calculateGrandTotal() {
    double subtotal = calculateTotalAmount();
    double additionalDiscount = double.tryParse(_additionalDiscount) ?? 0;
    if (additionalDiscount > 0) {
      double discountAmount = subtotal * (additionalDiscount / 100);
      return subtotal - discountAmount;
    }
    return subtotal;
  }

  void resetForm() {
    _clientName = '';
    _clientGst = '';
    _contactNumber = '';
    _altNumber = '';
    _siteAddress = '';
    _email = '';
    _additionalDiscount = '0';
    _selectedArchitectId = null;
    _selectedEmployeeId = null;
    _selectedClientId = null;
    _productRows = [ProductRowState()];
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

/// Product Row State for Form Management
class ProductRowState {
  String productName = '';
  String size = '';
  String quality = '';
  String godown = 'KKW';
  bool showProductDropdown = false;
  int? productId;
  Map<String, dynamic>? selectedProductDetails;

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController covController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController twgtController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  void updateTWGT() {
    try {
      final weight = double.tryParse(weightController.text) ?? 0;
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final twgt = weight * quantity;
      twgtController.text = twgt.toStringAsFixed(2);
      updateTotal();
    } catch (e) {
      twgtController.text = '0';
      amountController.text = '0';
    }
  }

  void updateTotal() {
    try {
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final rate = double.tryParse(rateController.text) ?? 0;
      final cov = double.tryParse(covController.text) ?? 0;
      final discount = double.tryParse(discountController.text) ?? 0;

      final baseAmount = rate * quantity;
      final covAmount = baseAmount * cov;
      final amountAfterCov = covAmount;
      final discountAmount = amountAfterCov * (discount / 100);
      final finalAmount = amountAfterCov - discountAmount;

      amountController.text = finalAmount.toStringAsFixed(2);
    } catch (e) {
      amountController.text = '0';
    }
  }

  double getTotalAmount() {
    return double.tryParse(amountController.text) ?? 0;
  }

  void dispose() {
    productSearchController.dispose();
    rateController.dispose();
    covController.dispose();
    areaController.dispose();
    weightController.dispose();
    twgtController.dispose();
    quantityController.dispose();
    amountController.dispose();
    discountController.dispose();
  }
}

/// ================= MIXIN CLASSES =================

/// Base State Management Mixin for Widgets
mixin StateManagementMixin<T extends StatefulWidget> on State<T> {
  AppStateManager? _appState;
  AuthStateManager? _authState;
  DashboardStateManager? _dashboardState;
  FormStateManager? _formState;

  AppStateManager get appState => _appState!;
  AuthStateManager get authState => _authState!;
  DashboardStateManager get dashboardState => _dashboardState!;
  FormStateManager get formState => _formState!;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    _appState = AppStateManager();
    _authState = AuthStateManager();
    _dashboardState = DashboardStateManager();
    _formState = FormStateManager();
    
    // Add listeners to trigger rebuilds
    _appState!.addListener(() {
      if (mounted) setState(() {});
    });
    _authState!.addListener(() {
      if (mounted) setState(() {});
    });
    _dashboardState!.addListener(() {
      if (mounted) setState(() {});
    });
    _formState!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Safe state update with mounted check
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Show error message with state management
  void showError(String message) {
    appState.setErrorMessage(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success message
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Clear error message
  void clearError() {
    appState.clearError();
  }
}

/// ================= PERSISTENCE UTILITIES =================

/// Enhanced Auth State with Persistence
class PersistentAuthStateManager {
  static const String _keyLoggedIn = 'isLoggedIn';
  static const String _keyToken = 'token';
  static const String _keyRole = 'role';
  static const String _keyUserId = 'userId';
  static const String _keyUserName = 'userName';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserPhone = 'userPhone';
  static const String _keyProfilePhoto = 'profilePhoto';

  final AuthStateManager _authState = AuthStateManager();

  PersistentAuthStateManager() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (isLoggedIn) {
      _authState.setAuthData(
        isLoggedIn: isLoggedIn,
        token: prefs.getString(_keyToken),
        role: prefs.getString(_keyRole),
        userId: prefs.getInt(_keyUserId),
        userName: prefs.getString(_keyUserName),
        userEmail: prefs.getString(_keyUserEmail),
        userPhone: prefs.getString(_keyUserPhone),
        profilePhoto: prefs.getString(_keyProfilePhoto),
      );
    }
  }

  Future<void> saveAuthData({
    required bool isLoggedIn,
    String? token,
    String? role,
    int? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? profilePhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_keyLoggedIn, isLoggedIn);
    if (token != null) await prefs.setString(_keyToken, token);
    if (role != null) await prefs.setString(_keyRole, role);
    if (userId != null) await prefs.setInt(_keyUserId, userId);
    if (userName != null) await prefs.setString(_keyUserName, userName);
    if (userEmail != null) await prefs.setString(_keyUserEmail, userEmail);
    if (userPhone != null) await prefs.setString(_keyUserPhone, userPhone);
    if (profilePhoto != null) await prefs.setString(_keyProfilePhoto, profilePhoto);
  }

  Future<void> clearAuthDataWithPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _authState.clearAuthData();
  }

  // Delegate all getters to the internal AuthStateManager
  bool get isLoggedIn => _authState.isLoggedIn;
  String? get token => _authState.token;
  String? get role => _authState.role;
  int? get userId => _authState.userId;
  String? get userName => _authState.userName;
  String? get userEmail => _authState.userEmail;
  String? get userPhone => _authState.userPhone;
  String? get profilePhoto => _authState.profilePhoto;
  bool get isEmployee => _authState.isEmployee;
  bool get isAdmin => _authState.isAdmin;

  // Delegate all setters to the internal AuthStateManager
  void setAuthData({
    required bool isLoggedIn,
    String? token,
    String? role,
    int? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? profilePhoto,
  }) {
    _authState.setAuthData(
      isLoggedIn: isLoggedIn,
      token: token,
      role: role,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      profilePhoto: profilePhoto,
    );
  }

  void clearAuthData() {
    _authState.clearAuthData();
  }

  void addListener(VoidCallback listener) {
    _authState.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    _authState.removeListener(listener);
  }
}

/// Enhanced Dashboard State with Caching
class CachedDashboardStateManager {
  static const String _keyAdminStats = 'adminStats';
  static const String _keyUserWiseOrders = 'userWiseOrders';
  static const String _keyArchitects = 'architects';
  static const String _keyEmployees = 'employees';
  static const String _keyProducts = 'products';

  final DashboardStateManager _dashboardState = DashboardStateManager();

  CachedDashboardStateManager() {
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final adminStatsJson = prefs.getString(_keyAdminStats);
      if (adminStatsJson != null) {
        _dashboardState.setAdminStats(Map<String, dynamic>.from(jsonDecode(adminStatsJson)));
      }

      final userWiseOrdersJson = prefs.getString(_keyUserWiseOrders);
      if (userWiseOrdersJson != null) {
        _dashboardState.setUserWiseOrders(List<dynamic>.from(jsonDecode(userWiseOrdersJson)));
      }

      final architectsJson = prefs.getString(_keyArchitects);
      if (architectsJson != null) {
        _dashboardState.setArchitects(List<dynamic>.from(jsonDecode(architectsJson)));
      }

      final employeesJson = prefs.getString(_keyEmployees);
      if (employeesJson != null) {
        _dashboardState.setEmployees(List<dynamic>.from(jsonDecode(employeesJson)));
      }

      final productsJson = prefs.getString(_keyProducts);
      if (productsJson != null) {
        _dashboardState.setProducts(List<dynamic>.from(jsonDecode(productsJson)));
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> cacheAdminStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdminStats, jsonEncode(stats));
  }

  Future<void> cacheUserWiseOrders(List<dynamic> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserWiseOrders, jsonEncode(orders));
  }

  Future<void> cacheArchitects(List<dynamic> architects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyArchitects, jsonEncode(architects));
  }

  Future<void> cacheEmployees(List<dynamic> employees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmployees, jsonEncode(employees));
  }

  Future<void> cacheProducts(List<dynamic> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProducts, jsonEncode(products));
  }

  // Delegate all getters to the internal DashboardStateManager
  Map<String, dynamic> get adminStats => _dashboardState.adminStats;
  List<dynamic> get userWiseOrders => _dashboardState.userWiseOrders;
  List<dynamic> get architects => _dashboardState.architects;
  List<dynamic> get employees => _dashboardState.employees;
  List<dynamic> get products => _dashboardState.products;
  List<dynamic> get employeeTasks => _dashboardState.employeeTasks;
  Map<String, dynamic> get employeeStats => _dashboardState.employeeStats;
  Map<String, dynamic> get attendanceSummary => _dashboardState.attendanceSummary;
  DateTime? get fromDate => _dashboardState.fromDate;
  DateTime? get toDate => _dashboardState.toDate;
  bool get showMonthText => _dashboardState.showMonthText;

  // Delegate all setters to the internal DashboardStateManager
  void setAdminStats(Map<String, dynamic> stats) => _dashboardState.setAdminStats(stats);
  void setUserWiseOrders(List<dynamic> orders) => _dashboardState.setUserWiseOrders(orders);
  void setArchitects(List<dynamic> architects) => _dashboardState.setArchitects(architects);
  void setEmployees(List<dynamic> employees) => _dashboardState.setEmployees(employees);
  void setProducts(List<dynamic> products) => _dashboardState.setProducts(products);
  void setEmployeeTasks(List<dynamic> tasks) => _dashboardState.setEmployeeTasks(tasks);
  void setEmployeeStats(Map<String, dynamic> stats) => _dashboardState.setEmployeeStats(stats);
  void setAttendanceSummary(Map<String, dynamic> summary) => _dashboardState.setAttendanceSummary(summary);
  void setFromDate(DateTime? date) => _dashboardState.setFromDate(date);
  void setToDate(DateTime? date) => _dashboardState.setToDate(date);
  void setShowMonthText(bool show) => _dashboardState.setShowMonthText(show);
  void resetToCurrentMonth() => _dashboardState.resetToCurrentMonth();

  void addListener(VoidCallback listener) => _dashboardState.addListener(listener);
  void removeListener(VoidCallback listener) => _dashboardState.removeListener(listener);
}

/// ================= UTILITIES =================

/// Error handling utilities
class StateErrorUtils {
  static void handleNetworkError(BuildContext context, dynamic error) {
    if (error is DioException) {
      String message = 'Network error occurred';
      if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message = 'Server response timeout.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'No internet connection. Please check your network.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}