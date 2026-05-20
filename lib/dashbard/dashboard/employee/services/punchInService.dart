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

  // ================= NEW: FETCH ATTENDANCE SUMMARY (status + lunchTaken) =================
  Future<Map<String, dynamic>> fetchAttendanceSummary(int employeeId, String month) async {
    try {
      final response = await _dio.get(
        '/api/employees/attendance-summary/$employeeId',
        queryParameters: {'month': month},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'currentStatus': response.data['currentStatus'] ?? 'READY',
          'lunchTaken': response.data['lunchTaken'] ?? false,
        };
      }
      throw Exception('Failed to load attendance summary');
    } on DioException catch (e) {
      print('❌ Attendance summary error: ${e.response?.data}');
      throw Exception('Error fetching status: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ================= LEGACY: FETCH PUNCH STATUS (kept for compatibility) =================
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

  // ================= STATUS PARSER (legacy) =================
  String _extractStatusFromResponse(dynamic data) {
    if (data is Map) {
      // Direct status field
      if (data['status'] != null) {
        String status = data['status'].toString().toUpperCase().trim();
        // Map possible variations
        if (status == 'LUNCH_OUT' || status == 'LUNCH_OUT') return "LUNCH_OUT";
        if (status == 'IN' || status == 'PUNCHED_IN') return "IN";
        if (status == 'COMPLETED' || status == 'OUT') return "COMPLETED";
        return status;
      }

      // Nested inside 'data'
      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map;
        if (nestedData['status'] != null) {
          String status = nestedData['status'].toString().toUpperCase().trim();
          if (status == 'LUNCH_OUT') return "LUNCH_OUT";
          if (status == 'IN') return "IN";
          if (status == 'COMPLETED') return "COMPLETED";
          return status;
        }
      }

      // Fallback: parse message
      if (data['message'] != null) {
        final message = data['message'].toString().toLowerCase();
        if (message.contains('lunch out')) return "LUNCH_OUT";
        if (message.contains('punched in') || message.contains('resume'))
          return "IN";
        if (message.contains('completed') || message.contains('punched out'))
          return "COMPLETED";
      }
    }

    if (data is String) {
      String status = data.toUpperCase().trim();
      if (status == 'LUNCH_OUT') return "LUNCH_OUT";
      if (status == 'IN') return "IN";
      if (status == 'COMPLETED') return "COMPLETED";
      return status;
    }

    return "READY";
  }

  // ================= FALLBACK ENDPOINTS (legacy) =================
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

  // ================= LUNCH OUT (Break) =================
  Future<Map<String, dynamic>> lunchOut(int employeeId) async {
    try {
      final response = await _dio.post(
        '/api/employees/lunch-out',
        data: {"employeeId": employeeId, "image": null},
      );
      print("🔥 LUNCH OUT RESPONSE => ${response.data}");
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': "✅ Lunch break started",
          'alreadyOnBreak': false,
        };
      }
      return {
        'success': false,
        'message': "❌ Failed to start lunch break",
        'alreadyOnBreak': false,
      };
    } on DioException catch (e) {
      print("❌ LUNCH OUT ERROR => ${e.response?.data}");
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = errorData?['message'] ?? "Already on break";
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('already on break') ||
            lowerError.contains('already in lunch') ||
            lowerError.contains('lunch already started') ||
            lowerError.contains('already started')) {
          return {
            'success': false,
            'message': "✅ You are already on lunch break",
            'alreadyOnBreak': true,
          };
        }
        return {
          'success': false,
          'message': "❌ $errorMessage",
          'alreadyOnBreak': false,
        };
      }
      return {
        'success': false,
        'message': "❌ Lunch break failed",
        'alreadyOnBreak': false,
      };
    } catch (e) {
      print("❌ UNKNOWN LUNCH OUT ERROR => $e");
      return {
        'success': false,
        'message': "❌ Lunch break failed",
        'alreadyOnBreak': false,
      };
    }
  }

  // ================= LUNCH IN (Resume Work) =================
  Future<Map<String, dynamic>> lunchIn(int employeeId) async {
    try {
      final response = await _dio.post(
        '/api/employees/lunch-in',
        data: {"employeeId": employeeId, "image": null},
      );
      print("🔥 LUNCH IN RESPONSE => ${response.data}");
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': "✅ Resumed work successfully",
          'alreadyResumed': false,
        };
      }
      return {
        'success': false,
        'message': "❌ Failed to resume work",
        'alreadyResumed': false,
      };
    } on DioException catch (e) {
      print("❌ LUNCH IN ERROR => ${e.response?.data}");
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = errorData?['message'] ?? "Already resumed";
        if (errorMessage.toLowerCase().contains('already resumed') ||
            errorMessage.toLowerCase().contains('not on break')) {
          return {
            'success': false,
            'message': "✅ You are already at work",
            'alreadyResumed': true,
          };
        }
        return {
          'success': false,
          'message': "❌ $errorMessage",
          'alreadyResumed': false,
        };
      }
      return {
        'success': false,
        'message': "❌ Resume work failed",
        'alreadyResumed': false,
      };
    } catch (e) {
      print("❌ UNKNOWN LUNCH IN ERROR => $e");
      return {
        'success': false,
        'message': "❌ Resume work failed",
        'alreadyResumed': false,
      };
    }
  }
}