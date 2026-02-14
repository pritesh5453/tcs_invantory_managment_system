import 'package:dio/dio.dart';

class DashboardApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboard.theceramicstudio.in',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<List<dynamic>?> fetchTasks(int employeeId) async {
    try {
      final response = await _dio.get('/api/tasks/employee/$employeeId');
      if (response.statusCode == 200) {
        return response.data['tasks'] ?? [];
      }
    } catch (e) {
      print("💥 Error fetching tasks: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchDashboardStats(int employeeId) async {
    try {
      final response = await _dio.get(
        '/api/users/employee-dashboard/$employeeId',
      );
      if (response.statusCode == 200) {
        return response.data['counts'] ?? {};
      }
    } catch (e) {
      print("💥 Error fetching dashboard stats: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchAttendanceSummary(int employeeId) async {
    try {
      final response = await _dio.get(
        '/api/employees/attendance-summary/$employeeId',
      );
      if (response.statusCode == 200) {
        return {
          'daysPresent': response.data['daysPresent'] ?? 0,
          'avgHours': response.data['avgHours']?.toString() ?? "0",
        };
      }
    } catch (e) {
      print("💥 Error fetching attendance: $e");
    }
    return null;
  }

  Future<bool> updateTaskStatus(
    int taskId,
    String status,
    String remark,
  ) async {
    try {
      final response = await _dio.put(
        '/api/tasks/update/$taskId',
        data: {
          "status": status.toLowerCase() == "done" ? "Done" : "Pending",
          "remark": remark,
        },
      );

      return response.statusCode == 200 && response.data["success"] == true;
    } on DioException catch (e) {
      print("❌ DIO ERROR updating task");
      print("Status : ${e.response?.statusCode}");
      print("Data   : ${e.response?.data}");
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>?> fetchNotifications({
    required String role,
    required int employeeId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/users/GetNotification',
        queryParameters: {
          'role': role,
          'employeeId': employeeId,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
    } catch (e) {
      print("💥 Error fetching notifications: $e");
    }
    return null;
  }
}
