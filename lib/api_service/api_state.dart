import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/api_service/urls.dart';
import 'package:tcs_invantory_managment_system/global/utils.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<Response?> getRequest(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParams);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }

  Future<Response?> postRequest(String endpoint, dynamic data) async {
    try {
      return await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }

  Future<Response?> putRequest(String endpoint, dynamic data) async {
    try {
      return await _dio.put(endpoint, data: data);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }

  Future<Response?> deleteRequest(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }

  void _handleDioError(DioException error) {
    if (error.response != null) {
      switch (error.response?.statusCode) {
        case 400:
          print("Bad Request: ${error.response?.data}");
          Utils().showToastMessage('Bad Request: ${error.response?.data}');
          break;
        case 401:
          print("Unauthorized: ${error.response?.data}");
          Utils().showToastMessage('Unauthorized: ${error.response?.data}');
          break;
        case 403:
          print("Forbidden: ${error.response?.data}");
          Utils().showToastMessage('Forbidden: ${error.response?.data}');
          break;
        case 404:
          print("Not Found: ${error.response?.data}");
          Utils().showToastMessage('Not Found: ${error.response?.data}');
          break;
        case 500:
          print("Internal Server Error: ${error.response?.data}");
          Utils().showToastMessage(
            'Internal Server Error: ${error.response?.data}',
          );
          break;
        default:
          print(
            "Received unexpected status code: ${error.response?.statusCode}",
          );
          Utils().showToastMessage(
            'Received unexpected status code: ${error.response?.statusCode}',
          );

          break;
      }
    } else {
      // Error occurred on the client
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          print("Connection timeout occurred.");
          Utils().showToastMessage('Connection timeout occurred.');
          break;
        case DioExceptionType.receiveTimeout:
          print("Receive timeout occurred.");
          Utils().showToastMessage('Receive timeout occurred.');
          break;
        case DioExceptionType.sendTimeout:
          print("Send timeout occurred.");
          Utils().showToastMessage('Send timeout occurred.');
          break;
        case DioExceptionType.cancel:
          print("Request was cancelled.");
          Utils().showToastMessage('Request was cancelled.');
          break;
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            Utils().showToastMessage('Request was cancelled.');
            print("Request was cancelled.");
          } else {
            Utils().showToastMessage('Unexpected error: ${error.message}');
            print("Unexpected error: ${error.message}");
          }
          break;
        default:
          print("Unknown DioError: ${error.message}");
          Utils().showToastMessage('Unknown DioError: ${error.message}');
          break;
      }
    }
  }
}
