import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showCompleteTask = false;
  bool isPunchedIn = false;
  bool isPunchedOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            _dashboardBody(),

            if (showCompleteTask)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() => showCompleteTask = false);
                  },
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

            if (showCompleteTask) Center(child: _completeTaskCard()),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBody() {
    return Column(
      children: [
        // 🔶 TOP ORANGE HEADER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xffFFA34D),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text("Search.."),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 👤 USER CARD
                _userCard(),

                const SizedBox(height: 16),

                // 🧑‍💻 DAILY WORKSPACE
                _dailyWorkspace(),

                const SizedBox(height: 16),

                // 📊 STATS
                _statsRow(),

                const SizedBox(height: 16),

                // 📝 TASKS
                _taskCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          CircleAvatar(radius: 22),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sumit Pathak",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("EMP ID : 13", style: TextStyle(fontSize: 12)),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("sumit@gmail.com", style: TextStyle(fontSize: 12)),
              Text("9876543210", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailyWorkspace() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          /// LEFT TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Daily Workspace",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  "Today is Friday, January 16",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          /// RIGHT BUTTONS
          if (!isPunchedOut)
            Row(
              children: [
                _punchButton(
                  text: "Punch In",
                  color: const Color(0xff2ED11B),
                  icon: Icons.check_circle,
                  onTap:
                      isPunchedIn
                          ? null
                          : () {
                            setState(() {
                              isPunchedIn = true;
                            });
                          },
                ),
                const SizedBox(width: 10),
                _punchButton(
                  text: "Punch Out",
                  color: const Color(0xffE62828),
                  icon: Icons.check_circle,
                  onTap:
                      isPunchedIn
                          ? () {
                            setState(() {
                              isPunchedOut = true;
                            });
                          }
                          : null,
                ),
              ],
            )
          else
            _workFinishedBadge(),
        ],
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
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),

            // 🔥 SHADOW LIKE IMAGE
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statCard("QUOTATIONS", "0"),
        _statCard("FOLLOW UPS", "0"),
        _statCard("ATTENDANCE", "SHIFT ENDED"),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          // 👇 SHADOW
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- HEADER --------
          Row(
            children: [
              const Text(
                "My Assigned Tasks",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFE7C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text("Status:  ", style: TextStyle(fontSize: 10)),
                    const Text(
                      "PENDING",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// -------- TABLE HEADER --------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffFFF6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "TASK DETAILS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DATE ASSIGNED",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "ACTION",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// -------- TASKS --------
          _taskRow(
            title: "Task 1",
            subtitle: "Call Sumit",
            date: "16/01/2026",
            completed: false,
          ),
          _taskDivider(),
          _taskRow(
            title: "Task 2",
            subtitle: "Call Sumit",
            date: "16/01/2026",
            completed: true,
          ),
          _taskDivider(),
          _taskRow(
            title: "Task 3",
            subtitle: "Call Sumit",
            date: "16/01/2026",
            completed: true,
          ),
        ],
      ),
    );
  }

  Widget _taskRow({
    required String title,
    required String subtitle,
    required String date,
    required bool completed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        children: [
          /// TASK DETAILS
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"$subtitle"',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// DATE
          Expanded(
            flex: 2,
            child: Text(date, style: const TextStyle(fontSize: 12)),
          ),

          /// ACTION
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  completed
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "COMPLETED",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              showCompleteTask = true; // 👈 dialog show
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Mark as Done",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskDivider() {
    return Divider(color: Colors.grey.withOpacity(0.25), height: 1);
  }

  Widget _completeTaskCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Complete Task",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showCompleteTask = false;
                  });
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            "Please provide a brief remark on what was done",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 10),

          /// TEXT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type your remark here...",
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// SAVE BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // TODO: API call
                setState(() => showCompleteTask = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
              ),
              child: const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
