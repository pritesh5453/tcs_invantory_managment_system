import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
  String currentStatus = 'READY'; // READY, IN, LUNCH_OUT, COMPLETED
  bool lunchTaken = false;

  final PunchAttendanceService _punchService = PunchAttendanceService();
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != 0) {
      _fetchAttendanceStatus();
    }
  }

  @override
  void didUpdateWidget(covariant PunchAttendanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employeeId != oldWidget.employeeId && widget.employeeId != 0) {
      _fetchAttendanceStatus();
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    final currentMonth = DateTime.now().toString().substring(0, 7);
    try {
      final data = await _punchService.fetchAttendanceSummary(
        widget.employeeId,
        currentMonth,
      );
      if (mounted) {
        setState(() {
          currentStatus = data['currentStatus'] ?? 'READY';
          lunchTaken = data['lunchTaken'] ?? false;
        });
      }
    } catch (e) {
      widget.showSnackBar('Failed to fetch status: $e');
    }
  }

  Future<bool> _isOnOfficeWifi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      String? wifiIP = await _networkInfo.getWifiIP();
      debugPrint("📡 Connectivity result: $connectivityResult, IP: $wifiIP");

      if (wifiIP != null && _isOfficeNetworkIp(wifiIP)) {
        debugPrint("✅ Connected to office network (IP: $wifiIP)");
        return true;
      }

      // Fallback: check all interfaces
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith("127.") &&
              !addr.address.startsWith("169.254.") &&
              _isOfficeNetworkIp(addr.address)) {
            debugPrint("✅ Fallback: found office IP ${addr.address}");
            return true;
          }
        }
      }
      widget.showSnackBar("Please connect to office Wi-Fi.");
      return false;
    } catch (e) {
      debugPrint("Connectivity error: $e");
      widget.showSnackBar("Network check failed: $e");
      return false;
    }
  }

  bool _isOfficeNetworkIp(String address) {
    if (address.startsWith('192.168.')) return true;
    if (address.startsWith('10.')) return true;
    final parts = address.split('.');
    if (parts.length == 4) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      if (first == 172 && second != null && second >= 16 && second <= 31) {
        return true;
      }
    }
    return false;
  }

  void _updateLocalStatusAfterAction(
    String actionType,
    Map<String, dynamic> result,
  ) {
    if (!mounted) return;
    if (actionType == "IN") {
      setState(() => currentStatus = "IN");
    } else if (actionType == "LUNCH_OUT") {
      if (result['success'] == true || result['alreadyOnBreak'] == true) {
        setState(() => currentStatus = "LUNCH_OUT");
      }
    } else if (actionType == "LUNCH_IN") {
      if (result['success'] == true || result['alreadyResumed'] == true) {
        setState(() => currentStatus = "IN");
      }
    } else if (actionType == "OUT") {
      if (result['success'] == true) {
        setState(() => currentStatus = "COMPLETED");
      }
    }
    _fetchAttendanceStatus();
  }

  Future<void> _punchIn() async {
    if (!await _isOnOfficeWifi()) return;
    setState(() => isPunchLoading = true);
    final result = await _punchService.punchIn(widget.employeeId);
    if (mounted) setState(() => isPunchLoading = false);
    widget.showSnackBar(result['message'] ?? "");
    _updateLocalStatusAfterAction("IN", result);
    if (result['success'] == true) widget.onPunchSuccess();
  }

  Future<void> _lunchOut() async {
    if (!await _isOnOfficeWifi()) return;
    setState(() => isPunchLoading = true);
    final result = await _punchService.lunchOut(widget.employeeId);
    if (mounted) setState(() => isPunchLoading = false);
    widget.showSnackBar(result['message'] ?? "");
    _updateLocalStatusAfterAction("LUNCH_OUT", result);
    if (result['success'] == true || result['alreadyOnBreak'] == true) {
      widget.onPunchSuccess();
    }
  }

  Future<void> _lunchIn() async {
    if (!await _isOnOfficeWifi()) return;
    setState(() => isPunchLoading = true);
    final result = await _punchService.lunchIn(widget.employeeId);
    if (mounted) setState(() => isPunchLoading = false);
    widget.showSnackBar(result['message'] ?? "");
    _updateLocalStatusAfterAction("LUNCH_IN", result);
    if (result['success'] == true || result['alreadyResumed'] == true) {
      widget.onPunchSuccess();
    }
  }

  Future<void> _punchOut() async {
    if (!await _isOnOfficeWifi()) return;
    setState(() => isPunchLoading = true);
    final result = await _punchService.punchOut(widget.employeeId);
    if (mounted) setState(() => isPunchLoading = false);
    widget.showSnackBar(result['message'] ?? "");
    _updateLocalStatusAfterAction("OUT", result);
    if (result['success'] == true) widget.onPunchSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (isPunchLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Work finished badge
    if (currentStatus == "COMPLETED") {
      return _workFinishedBadge();
    }

    // Determine which buttons should be enabled
    final bool punchInEnabled = currentStatus == "READY";
    final bool lunchBreakEnabled = (currentStatus == "IN" && !lunchTaken);
    final bool resumeWorkEnabled = currentStatus == "LUNCH_OUT";
    final bool punchOutEnabled = (currentStatus == "IN" && lunchTaken);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio:
              MediaQuery.of(context).size.width < 360 ? 1.05 : 1.2,
          children: [
            _gridButton(
              text: "Punch In",
              icon: Icons.login,
              color: Colors.green,
              enabled: punchInEnabled,
              onTap: _punchIn,
            ),
            _gridButton(
              text: "Lunch Break",
              icon: Icons.restaurant,
              color: Colors.orange,
              enabled: lunchBreakEnabled,
              onTap: _lunchOut,
            ),
            _gridButton(
              text: "Resume Work",
              icon: Icons.work,
              color: Colors.blue,
              enabled: resumeWorkEnabled,
              onTap: _lunchIn,
            ),
            _gridButton(
              text: "Punch Out",
              icon: Icons.logout,
              color: Colors.red,
              enabled: punchOutEnabled,
              onTap: _punchOut,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getStatusMessage(),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  String _getStatusMessage() {
    if (currentStatus == "IN" && !lunchTaken)
      return "Punched in – take lunch break?";
    if (currentStatus == "IN" && lunchTaken)
      return "Working – you can punch out";
    if (currentStatus == "LUNCH_OUT")
      return "On lunch break – resume when back";
    if (currentStatus == "READY") return "Ready to punch in";
    return "Work finished for today";
  }

  Widget _workFinishedBadge() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.035,
            vertical: MediaQuery.of(context).size.height * 0.014,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              SizedBox(width: MediaQuery.of(context).size.width * 0.03),

              Expanded(
                child: Text(
                  "Work Finished for Today 🎉",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.036,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gridButton({
    required String text,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final Color bgColor = enabled ? color : Colors.grey.shade400;
    final Color iconColor = enabled ? Colors.white : Colors.grey.shade600;
    final Color textColor = enabled ? Colors.white : Colors.grey.shade600;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: MediaQuery.of(context).size.width * 0.032,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
