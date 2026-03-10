// lib/dashbard/orderbook/order_services.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/order_model.dart';

class OrderApiService {
  static const String baseUrl = 'https://dashboard.theceramicstudio.in/api';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // -------------------- Orders --------------------

  static Future<OrdersResponse> fetchOrders({
    required int page,
    required int limit,
    String? search,
    String? date,
    String? brandName,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (brandName != null && brandName.isNotEmpty)
        queryParams['brandName'] = brandName;

      debugPrint(
        '🌐 Fetching orders: $baseUrl/orderBook/list with $queryParams',
      );
      final response = await _dio.get(
        '/orderBook/list',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> ordersJson = data['orders'] ?? [];
          final orders =
              ordersJson.map((json) => Order.fromJson(json)).toList();
          final totalPages = data['totalPages'] as int? ?? 1;
          final total = data['total'] as int? ?? orders.length;

          return OrdersResponse(
            orders: orders,
            totalPages: totalPages,
            total: total,
          );
        }
      }
      return OrdersResponse(orders: [], totalPages: 1, total: 0);
    } on DioException catch (e) {
      debugPrint('❌ DioError in fetchOrders: ${e.message}');
      return OrdersResponse(orders: [], totalPages: 1, total: 0);
    } catch (e) {
      debugPrint('❌ Exception in fetchOrders: $e');
      return OrdersResponse(orders: [], totalPages: 1, total: 0);
    }
  }

  static Future<bool> deleteOrder(String orderId) async {
    try {
      final endpoints = [
        '/orderBook/delete/$orderId',
        '/orderBook/$orderId',
        '/orders/delete/$orderId',
      ];

      for (String endpoint in endpoints) {
        debugPrint('🗑️ Trying delete: $baseUrl$endpoint');
        final response = await _dio.delete(endpoint);
        if (response.statusCode == 200 || response.statusCode == 204) {
          final data = response.data;
          if (data is Map &&
              (data['success'] == true || data['status'] == 'success')) {
            return true;
          }
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ DioError in deleteOrder: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Exception in deleteOrder: $e');
      return false;
    }
  }

  // -------------------- Brands --------------------

  static Future<List<Brand>> fetchBrands() async {
    try {
      debugPrint('🌐 Fetching brands: $baseUrl/brands/GetAlllist');
      final response = await _dio.get('/brands/GetAlllist');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['brands'] != null) {
          final List<dynamic> brandsJson = data['brands'];
          return brandsJson.map((json) => Brand.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ DioError in fetchBrands: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Exception in fetchBrands: $e');
      return [];
    }
  }

  // -------------------- Products Search --------------------

  static Future<List<ProductSuggestion>> searchProducts({
    required String query,
    required String brandName,
  }) async {
    try {
      final queryParams = {'search': query, 'brandName': brandName};
      debugPrint(
        '🔍 Searching products: $baseUrl/product/GetProduct with $queryParams',
      );
      final response = await _dio.get(
        '/product/GetProduct',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['products'] != null) {
          final List<dynamic> productsJson = data['products'];
          return productsJson
              .map((p) => ProductSuggestion.fromJson(p))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('❌ DioError in searchProducts: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Exception in searchProducts: $e');
      return [];
    }
  }

  // -------------------- Create Order --------------------

  static Future<Map<String, dynamic>> createOrder({
    required String brandId,
    required String brandName,
    required String orderDate,
    required List<Map<String, String>> products,
  }) async {
    try {
      final body = {
        'brandId': brandId,
        'brandName': brandName,
        'orderDate': orderDate,
        'products': products,
      };
      debugPrint('📤 Creating order: $body');
      final response = await _dio.post('/orderBook/create', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioError in createOrder: ${e.message}');
      throw Exception('DioError: ${e.message}');
    }
  }

  // -------------------- Update Order --------------------

  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String brandId,
    required String brandName,
    required String orderDate,
    required List<Map<String, String>> products,
  }) async {
    try {
      final body = {
        'brandId': brandId,
        'brandName': brandName,
        'orderDate': orderDate,
        'products': products,
      };
      debugPrint('📤 Updating order $orderId: $body');
      final response = await _dio.put('/orderBook/update/$orderId', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioError in updateOrder: ${e.message}');
      throw Exception('DioError: ${e.message}');
    }
  }
}

// -------------------- Response & Suggestion Models --------------------

class OrdersResponse {
  final List<Order> orders;
  final int totalPages;
  final int total;

  OrdersResponse({
    required this.orders,
    required this.totalPages,
    required this.total,
  });
}

class ProductSuggestion {
  final int id;
  final String name;
  final String size;
  final String quality;
  final String? rate;
  final String? image;

  ProductSuggestion({
    required this.id,
    required this.name,
    required this.size,
    required this.quality,
    this.rate,
    this.image,
  });

  factory ProductSuggestion.fromJson(Map<String, dynamic> json) {
    return ProductSuggestion(
      id: json['id'] as int,
      name: json['name'] as String,
      size: json['size']?.toString() ?? '',
      quality: json['quality'] as String? ?? '',
      rate: json['rate']?.toString(),
      image: json['image_url'] as String?,
    );
  }
}
