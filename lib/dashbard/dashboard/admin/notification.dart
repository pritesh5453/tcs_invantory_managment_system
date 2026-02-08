import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://dashboard.theceramicstudio.in/api'),
  );

  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _dio.get(
        '/users/GetNotification',
        queryParameters: {'role': 'Admin', 'page': 1, 'limit': 10},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _notifications = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    } catch (e) {
      _isLoading = false;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.orange,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _notifications[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.orange,
                    ),
                    title: Text(
                      item['title'] ?? 'Notification',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item['message'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
    );
  }
}
