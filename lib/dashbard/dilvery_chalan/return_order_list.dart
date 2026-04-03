import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ===================== MODEL =====================
class ReturnItem {
  final int returnId;
  final int challanId;
  final String name;
  final String size;
  final int returnQty;
  final DateTime createdAt;

  ReturnItem({
    required this.returnId,
    required this.challanId,
    required this.name,
    required this.size,
    required this.returnQty,
    required this.createdAt,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      returnId: json['returnId'] as int,
      challanId: json['challanId'] as int,
      name: json['name'] as String,
      size: json['size'] as String,
      returnQty: json['returnQty'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// ===================== API SERVICE =====================
class ReturnsApiService {
  static const String baseUrl =
      'https://dashboard.theceramicstudio.in/api/Quotation/returns';
  static const int limit = 10;
  static final Dio _dio = Dio();

  static Future<List<ReturnItem>> fetchReturns(int page) async {
    final response = await _dio.get('$baseUrl?page=$page&limit=$limit');
    if (response.statusCode != 200) {
      throw Exception('Failed to load returns');
    }
    final jsonData = response.data as Map<String, dynamic>;
    if (jsonData['success'] != true) {
      throw Exception('API error');
    }
    final List<dynamic> data = jsonData['data'];
    return data.map((e) => ReturnItem.fromJson(e)).toList();
  }

  static Future<int> fetchTotalPages() async {
    final response = await _dio.get('$baseUrl?page=1&limit=$limit');
    if (response.statusCode != 200) return 1;
    final jsonData = response.data;
    final pagination = jsonData['pagination'] as Map<String, dynamic>;
    return pagination['totalPages'] as int;
  }
}

// ===================== MAIN SCREEN =====================
class ReturnsListScreen extends StatefulWidget {
  const ReturnsListScreen({super.key});

  @override
  State<ReturnsListScreen> createState() => _ReturnsListScreenState();
}

class _ReturnsListScreenState extends State<ReturnsListScreen> {
  List<ReturnItem> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final totalPages = await ReturnsApiService.fetchTotalPages();
      final items = await ReturnsApiService.fetchReturns(_currentPage);
      setState(() {
        _items = items;
        _totalPages = totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      _isLoading = true;
    });
    try {
      final items = await ReturnsApiService.fetchReturns(page);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _refresh() {
    _goToPage(_currentPage);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Return Orders'),
        centerTitle: false,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _hasError && _items.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header (optional, just for clarity)
                  SizedBox(height: 15),
                  // List of cards (each card contains all fields in a clean layout)
                  Expanded(
                    child:
                        _isLoading && _items.isEmpty
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Row 1: Return ID and Challan ID
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Text(
                                                    'ID: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.returnId}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Text(
                                                    'Challan: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.challanId}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Row 2: Product Name
                                        Row(
                                          children: [
                                            const Text(
                                              'Product: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Row 3: Size and Quantity
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Text(
                                                    'Size: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      item.size,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Qty: ',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.returnQty}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Row 4: Date
                                        Row(
                                          children: [
                                            const Text(
                                              'Date: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(item.createdAt),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _currentPage > 1
                                  ? () => _goToPage(_currentPage - 1)
                                  : null,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: const Text('Prev'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _currentPage < _totalPages
                                  ? () => _goToPage(_currentPage + 1)
                                  : null,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
