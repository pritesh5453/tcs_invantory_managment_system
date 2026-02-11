import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/employee/services/punchInService.dart';

class PunchAttendanceWidget extends StatefulWidget {
  final int employeeId;
  final Function onPunchSuccess;
  final Function(String) showSnackBar;

  const PunchAttendanceWidget({
    Key? key,
    required this.employeeId,
    required this.onPunchSuccess,
    required this.showSnackBar,
  }) : super(key: key);

  @override
  State<PunchAttendanceWidget> createState() => _PunchAttendanceWidgetState();
}

class _PunchAttendanceWidgetState extends State<PunchAttendanceWidget> {
  bool isPunchLoading = false;
  String? punchStatus;

  final PunchAttendanceService _punchService = PunchAttendanceService();

  @override
  void initState() {
    super.initState();
    _fetchPunchStatus();
  }

  /// ================= FETCH STATUS =================
  Future<void> _fetchPunchStatus() async {
    final status = await _punchService.fetchPunchStatus(widget.employeeId);
    if (mounted) {
      setState(() => punchStatus = status);
    }
  }

  /// ================= WIFI + OFFICE IP CHECK =================
  Future<bool> _isOnOfficeWifi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.wifi) {
        widget.showSnackBar("Please connect to Office WiFi");
        return false;
      }

      // 🔥 Get device IPv4 address
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            debugPrint("Device IP: $ip");

            // ✅ Office WiFi Range Check
            if (ip.startsWith("192.168.1.")) {
              return true;
            }
          }
        }
      }

      widget.showSnackBar("Not connected to Office Network");
      return false;
    } catch (e) {
      debugPrint("Connectivity error: $e");
      widget.showSnackBar("Network check failed");
      return false;
    }
  }

  /// ================= PUNCH IN =================
  Future<void> _punchIn() async {
    final allowed = await _isOnOfficeWifi();
    if (!allowed) return;

    setState(() => isPunchLoading = true);

    final result = await _punchService.punchIn(widget.employeeId);

    if (mounted) {
      setState(() => isPunchLoading = false);
    }

    widget.showSnackBar(result['message']);

    await _fetchPunchStatus();
    widget.onPunchSuccess();
  }

  /// ================= PUNCH OUT =================
  Future<void> _punchOut() async {
    final allowed = await _isOnOfficeWifi();
    if (!allowed) return;

    setState(() => isPunchLoading = true);

    final result = await _punchService.punchOut(widget.employeeId);

    if (mounted) {
      setState(() => isPunchLoading = false);
    }

    widget.showSnackBar(result['message']);

    await _fetchPunchStatus();
    widget.onPunchSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (isPunchLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (punchStatus == null) {
      return _refreshButton();
    }

    final status = punchStatus!.toUpperCase().trim();

    if (status.contains("OUT") || status.contains("COMPLETE")) {
      return _workFinishedBadge();
    }

    if (status.contains("IN")) {
      return Row(
        children: [
          _punchButton(
            text: "Punch In",
            color: Colors.grey,
            onTap: null,
            disabled: true,
          ),
          const SizedBox(width: 10),
          _punchButton(
            text: "Punch Out",
            color: Colors.red,
            onTap: _punchOut,
            disabled: false,
          ),
        ],
      );
    }

    return Row(
      children: [
        _punchButton(
          text: "Punch In",
          color: Colors.green,
          onTap: _punchIn,
          disabled: false,
        ),
        const SizedBox(width: 10),
        _punchButton(
          text: "Punch Out",
          color: Colors.grey,
          onTap: null,
          disabled: true,
        ),
      ],
    );
  }

  /// ================= UI HELPERS =================

  Widget _refreshButton() {
    return ElevatedButton(
      onPressed: _fetchPunchStatus,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "Refresh",
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _workFinishedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 6),
          Text("Work Finished for Today", style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _punchButton({
    required String text,
    required Color color,
    required VoidCallback? onTap,
    required bool disabled,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow:
                disabled
                    ? []
                    : [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
