import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/api_service/urls.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/PreferencesKey.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/app_preference.dart';
import 'package:tcs_invantory_managment_system/global/utils.dart';

class ApiService {
  String? tokena = AppPreference().getString(PreferencesKey.token).toString();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${AppPreference().getString(PreferencesKey.token).toString()}', // Avoids null and removes the extra }
      },
    ),
  );

  Future<Response?> getRequest(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    print(AppPreference().getString(PreferencesKey.token).toString());
    try {
      return await _dio.get(endpoint, queryParameters: queryParams);
    } on DioException catch (e) {
      _handleDioError(e);
      //Utils().showToastMessage("$e");
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
      print(e);
      print("data");
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
          print("${error.response?.data['message']}");
          Utils().showToastMessage("${error.response?.data['message']}");
          break;
        case 401:
          Utils().showToastMessage("${error.response?.data['message']}");
          break;
        case 403:
          Utils().showToastMessage("${error.response?.data['message']}");
          break;
        case 404:
          Utils().showToastMessage("${error.response?.data['message']}");
          break;
        case 500:
          Utils().showToastMessage("dshsjdhsjdhsdhjh");
          break;
        default:
          Utils().showToastMessage("${error.response?.data['message']}");
          break;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          print("Connection timeout occurred.");
          Utils().showToastMessage("Connection timeout occurred.");
          break;
        case DioExceptionType.receiveTimeout:
          print("Receive timeout occurred.");
          Utils().showToastMessage("Receive timeout occurred.");
          break;
        case DioExceptionType.sendTimeout:
          print("Send timeout occurred.");
          Utils().showToastMessage("Send timeout occurred.");
          break;
        case DioExceptionType.cancel:
          print("Request was cancelled.");
          Utils().showToastMessage("Request was cancelled.");
          break;
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            print("No Internet connection. Please check your network.");
            Utils().showToastMessage(
              "No Internet connection. Please check your network.",
            );
          } else {
            print("Unexpected error: ${error.message}");
            Utils().showToastMessage("Unexpected error: ${error.message}");
          }
          break;
        default:
          print("Unknown DioError: ${error.message}");
          Utils().showToastMessage("Unknown DioError: ${error.message}");
          break;
      }
    }
  }
}
