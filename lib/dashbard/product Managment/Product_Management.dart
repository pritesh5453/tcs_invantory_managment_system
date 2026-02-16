import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/add%20product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/edit_product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/product_view_screen.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';

/// ================= DEBOUNCER CLASS =================
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// ================= SEARCH BAR WIDGET =================
class ProductSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;

  const ProductSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
  });

  @override
  State<ProductSearchBarWidget> createState() => _ProductSearchBarWidgetState();
}

class _ProductSearchBarWidgetState extends State<ProductSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ProductSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _searchController.text) {
      _searchController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      widget.onSearchChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search products by name...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                widget.onSearchChanged('');
                _searchFocusNode.requestFocus();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// ================= PRODUCT MODEL =================
class Product {
  final int id;
  final String name;
  final String size;
  final String brand;
  final String category;
  final String quality;
  final String rate;
  final String cov;
  final String godown;
  final String image;
  final String imageUrl;
  final int qty;
  final List<dynamic> batches;

  int get availableQuantity {
    if (batches.isEmpty) {
      return 0;
    }

    int total = 0;
    for (var batch in batches) {
      if (batch is Map<String, dynamic>) {
        final batchQty = batch['qty'];
        if (batchQty != null) {
          if (batchQty is int) {
            total += batchQty;
          } else if (batchQty is String) {
            total += int.tryParse(batchQty) ?? 0;
          } else if (batchQty is double) {
            total += batchQty.toInt();
          } else if (batchQty is num) {
            total += batchQty.toInt();
          }
        }
      }
    }
    return total;
  }

  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.brand,
    required this.category,
    required this.quality,
    required this.rate,
    required this.cov,
    required this.godown,
    required this.image,
    required this.imageUrl,
    required this.qty,
    required this.batches,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final batches = json['batches'] ?? [];

    List<dynamic> batchesList = [];
    if (batches is List) {
      batchesList = batches;
    } else if (batches is String) {
      try {
        batchesList = jsonDecode(batches) ?? [];
      } catch (e) {
        print('Error parsing batches string: $e');
      }
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      size: json['size'] ?? "",
      brand: json['brand'] ?? "",
      category: json['category'] ?? "",
      quality: json['quality'] ?? "",
      rate: json['rate']?.toString() ?? "0",
      cov: json['cov'] ?? "",
      godown: json['godown']?.toString() ?? "",
      image: json['image'] ?? "default-product.jpg",
      imageUrl: json['image_url'] ?? "",
      qty: json['qty'] ?? json['availQty'] ?? 0,
      batches: batchesList,
    );
  }
}

/// ================= SCREEN =================
class ProductRegistrationScreen extends StatefulWidget {
  const ProductRegistrationScreen({super.key});

  @override
  State<ProductRegistrationScreen> createState() =>
      _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  late bool canViewProduct;
  late bool canAddProduct;
  late bool canEditProduct;
  late bool canDeleteProduct;

  late Dio _dio;
  final ScrollController _scrollController = ScrollController();

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;

  int page = 1;
  String searchQuery = '';
  List<Product> products = [];

  @override
  void initState() {
    super.initState();

    canAddProduct = PermissionManager.hasPermission("Product Registration_Add");
    canEditProduct = PermissionManager.hasPermission(
      "Product Registration_Edit",
    );
    canDeleteProduct = PermissionManager.hasPermission(
      "Product Registration_Delete",
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: "https://dashboard.theceramicstudio.in/api",
        headers: {"Accept": "application/json"},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !loadingMore &&
          hasMore) {
        fetchMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= FIRST LOAD / REFRESH =================
  Future<void> fetchProducts() async {
    setState(() {
      page = 1;
      hasMore = true;
      products.clear();
      loading = true;
    });

    try {
      await fetchMoreProducts();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// ================= LOAD MORE =================
  Future<void> fetchMoreProducts() async {
    if (!hasMore || loadingMore) return;

    setState(() => loadingMore = true);

    try {
      final Map<String, dynamic> queryParams = {"page": page};
      if (searchQuery.isNotEmpty) {
        queryParams["search"] = searchQuery;
      }

      print('Fetching products with query: $queryParams');

      final res = await _dio.get("/product/list", queryParameters: queryParams);

      if (res.data != null && res.data['products'] != null) {
        final List list = res.data['products'];
        final pagination = res.data['pagination'];

        print('Fetched ${list.length} products for search: $searchQuery');

        final newProducts = <Product>[];
        for (var i = 0; i < list.length; i++) {
          try {
            final product = Product.fromJson(list[i]);
            newProducts.add(product);
          } catch (e) {
            print('Error parsing product at index $i: $e');
          }
        }

        if (mounted) {
          setState(() {
            page++;
            products.addAll(newProducts);

            if (page > pagination['totalPages']) {
              hasMore = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("PAGINATION ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load products: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => loadingMore = false);
    }
  }

  /// ================= SEARCH PRODUCTS =================
  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      page = 1;
      hasMore = true;
      products.clear();
    });
    fetchProducts();
  }

  /// ================= DELETE PRODUCT =================
  Future<void> deleteProduct(int productId) async {
    try {
      final res = await _dio.delete("/product/delete/$productId");

      if (res.data['success'] == true) {
        if (mounted) {
          setState(() {
            products.removeWhere((p) => p.id == productId);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Product deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delete failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, int productId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Product"),
            content: const Text(
              "Are you sure you want to delete this product?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteProduct(productId);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
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
        backgroundColor: const Color(0xffF6F6F6),
        body: SafeArea(
          child: Column(
            children: [
              /// TOP BAR WITH SEARCH
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ProductSearchBarWidget(
                        onSearchChanged: onSearchChanged,
                        initialValue: searchQuery,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap:
                          canAddProduct
                              ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => const AddProductSheet(),
                                );
                              }
                              : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You don't have permission to add product.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                      child: Opacity(
                        opacity: canAddProduct ? 1 : 0.4,
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// LIST
              Expanded(
                child:
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () async {
                            await fetchProducts();
                          },
                          child:
                              products.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount:
                                        products.length + (hasMore ? 1 : 0),
                                    itemBuilder: (_, i) {
                                      if (i < products.length) {
                                        return ProductCard(
                                          product: products[i],
                                          canEdit: canEditProduct,
                                          canDelete: canDeleteProduct,
                                          onDelete:
                                              (id) => _showDeleteDialog(
                                                context,
                                                id,
                                              ),
                                          onEdit: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              builder:
                                                  (_) => EditProductSheet(
                                                    productId: products[i].id,
                                                    product: products[i],
                                                  ),
                                            );
                                          },
                                          onView: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ProductViewScreen(
                                                      productId: products[i].id,
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child:
                                                loadingMore
                                                    ? const CircularProgressIndicator()
                                                    : const SizedBox(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No products found for '$searchQuery'",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text("No products found", style: TextStyle(color: Colors.grey)),
    );
  }
}

/// ================= PRODUCT CARD =================
class ProductCard extends StatelessWidget {
  final Product product;
  final bool canEdit;
  final bool canDelete;
  final Function(int) onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const ProductCard({
    super.key,
    required this.product,
    required this.canEdit,
    required this.canDelete,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final availableQty = product.availableQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      availableQty > 0
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  availableQty > 0 ? "In Stock" : "Out of Stock",
                  style: TextStyle(
                    fontSize: 12,
                    color: availableQty > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    onView();
                  } else if (value == 'edit') {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to edit product.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    onEdit();
                  } else if (value == 'delete') {
                    if (!canDelete) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You don't have permission to delete product.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    onDelete(product.id);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text("View"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text("Edit"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// IMAGE + DETAILS
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child:
                    product.imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        )
                        : const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${product.id}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Category: ${product.category}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Quality: ${product.quality}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Rate: ₹${product.rate}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            "Batches: ${product.batches.length} | Available Qty: $availableQty",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
