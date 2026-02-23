import 'package:dio/dio.dart';

class PunchAttendanceService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Accept": "application/json"},
    ),
  );

  // ================= FETCH STATUS =================
  Future<String> fetchPunchStatus(int employeeId) async {
    print("🔥 EMPLOYEE ID SENT => $employeeId");
    try {
      final response = await _dio.get('/api/employees/status/$employeeId');

      print("🔥 STATUS API RESPONSE => ${response.data}");

      return _extractStatusFromResponse(response.data);
    } on DioException catch (e) {
      print("❌ STATUS ERROR CODE => ${e.response?.statusCode}");
      print("❌ STATUS ERROR DATA => ${e.response?.data}");

      if (e.response?.statusCode == 404) {
        return await _tryAlternativeStatusEndpoints(employeeId);
      }

      return "READY";
    } catch (e) {
      print("❌ UNKNOWN STATUS ERROR => $e");
      return "READY";
    }
  }

  // ================= STATUS PARSER =================
  String _extractStatusFromResponse(dynamic data) {
    if (data is Map) {
      if (data['status'] != null) {
        return data['status'].toString().toUpperCase().trim();
      }

      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map;
        if (nestedData['status'] != null) {
          return nestedData['status'].toString().toUpperCase().trim();
        }
      }

      if (data['message'] != null) {
        final message = data['message'].toString().toLowerCase();

        if (message.contains('punched in')) {
          return "IN";
        }

        if (message.contains('punched out') || message.contains('completed')) {
          return "COMPLETED";
        }
      }
    }

    if (data is String) {
      return data.toUpperCase().trim();
    }

    return "READY";
  }

  // ================= FALLBACK ENDPOINTS =================
  Future<String> _tryAlternativeStatusEndpoints(int employeeId) async {
    final endpoints = [
      '/api/attendance/status/$employeeId',
      '/api/employees/$employeeId/punch-status',
      '/api/attendance/today/$employeeId',
    ];

    for (var endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);

        if (response.statusCode == 200 &&
            response.data is Map &&
            response.data['status'] != null) {
          return response.data['status'].toString().toUpperCase().trim();
        }
      } catch (e) {
        continue;
      }
    }

    return "READY";
  }

  // ================= PUNCH IN =================
  Future<Map<String, dynamic>> punchIn(int employeeId) async {
    try {
      final response = await _dio.post(
        '/api/employees/punch-in',
        data: {"employeeId": employeeId, "image": null},
      );

      print("🔥 PUNCH IN RESPONSE => ${response.data}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': "✅ Punch In successful",
          'alreadyPunchedIn': false,
        };
      }

      return {
        'success': false,
        'message': "❌ Failed to Punch In",
        'alreadyPunchedIn': false,
      };
    } on DioException catch (e) {
      print("❌ PUNCH IN ERROR => ${e.response?.data}");

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = errorData?['message'] ?? "Already punched in";

        if (errorMessage.toLowerCase().contains('already punched in')) {
          return {
            'success': false,
            'message': "✅ You are already punched in for today",
            'alreadyPunchedIn': true,
          };
        }

        return {
          'success': false,
          'message': "❌ $errorMessage",
          'alreadyPunchedIn': false,
        };
      }

      return {
        'success': false,
        'message': "❌ Failed to Punch In",
        'alreadyPunchedIn': false,
      };
    } catch (e) {
      print("❌ UNKNOWN PUNCH IN ERROR => $e");

      return {
        'success': false,
        'message': "❌ Punch In failed",
        'alreadyPunchedIn': false,
      };
    }
  }

  // ================= PUNCH OUT =================
  Future<Map<String, dynamic>> punchOut(int employeeId) async {
    try {
      final response = await _dio.post(
        '/api/employees/punch-out',
        data: {"employeeId": employeeId, "image": null},
      );

      print("🔥 PUNCH OUT RESPONSE => ${response.data}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': "✅ Punch Out successful",
          'alreadyPunchedOut': false,
        };
      }

      return {
        'success': false,
        'message': "❌ Failed to Punch Out",
        'alreadyPunchedOut': false,
      };
    } on DioException catch (e) {
      print("❌ PUNCH OUT ERROR => ${e.response?.data}");

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = errorData?['message'] ?? "Punch out error";

        if (errorMessage.toLowerCase().contains('already punched out') ||
            errorMessage.toLowerCase().contains('not punched in')) {
          return {
            'success': false,
            'message': "✅ You are already punched out for today",
            'alreadyPunchedOut': true,
          };
        }

        return {
          'success': false,
          'message': "❌ $errorMessage",
          'alreadyPunchedOut': false,
        };
      }

      if (e.response?.statusCode == 404) {
        return {
          'success': false,
          'message': "❌ Punch Out Error: Endpoint not found",
          'alreadyPunchedOut': false,
        };
      }

      return {
        'success': false,
        'message': "❌ Failed to Punch Out",
        'alreadyPunchedOut': false,
      };
    } catch (e) {
      print("❌ UNKNOWN PUNCH OUT ERROR => $e");

      return {
        'success': false,
        'message': "❌ Punch Out failed",
        'alreadyPunchedOut': false,
      };
    }
  }
}
