// lib/dashbard/orderbook/order_model.dart

class Order {
  final int id;
  final String orderId;
  final DateTime orderDate;
  final String brandName;
  final List<Product> products;

  Order({
    required this.id,
    required this.orderId,
    required this.orderDate,
    required this.brandName,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderId: json['orderId'] as String,
      orderDate: DateTime.parse(json['orderDate'] as String),
      brandName: json['brandName'] as String,
      products:
          (json['products'] as List? ?? [])
              .map((p) => Product.fromJson(p))
              .toList(),
    );
  }
}

class Product {
  final String productName;
  final String size;
  final int quantity;
  final String quality;
  final int? productId;

  Product({
    required this.productName,
    required this.size,
    required this.quantity,
    required this.quality,
    this.productId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['productName'] ?? '',
      size: json['size']?.toString() ?? '',
      quantity:
          json['quantity'] is int
              ? json['quantity']
              : int.tryParse(json['quantity'].toString()) ?? 0,
      quality: json['quality'] ?? '',
      productId: json['productId'] as int?,
    );
  }
}

class Brand {
  final int id;
  final String name;
  final String status;
  final DateTime createdAt;

  Brand({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Brand && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
