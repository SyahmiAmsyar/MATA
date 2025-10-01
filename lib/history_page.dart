import 'package:flutter/material.dart';

class HistoryEvent {
  final String time;
  final String event;
  final IconData icon;
  final Color color;

  HistoryEvent({
    required this.time,
    required this.event,
    required this.icon,
    required this.color,
  });
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<HistoryEvent> fullHistory = [
      HistoryEvent(
        time: "11:30 AM",
        event: "Arrived at Supermarket",
        icon: Icons.location_on,
        color: const Color(0xFF0073B1),
      ),
      HistoryEvent(
        time: "09:15 AM",
        event: "Left Home",
        icon: Icons.home,
        color: Colors.green,
      ),
      HistoryEvent(
        time: "08:45 AM",
        event: "Battery charged to 85%",
        icon: Icons.battery_charging_full,
        color: Colors.orange,
      ),
      HistoryEvent(
        time: "Yesterday",
        event: "Device restarted",
        icon: Icons.restart_alt,
        color: Colors.purple,
      ),
      HistoryEvent(
        time: "2 days ago",
        event: "Low battery alert",
        icon: Icons.battery_alert,
        color: Colors.red,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Location History"),
        backgroundColor: const Color(0xFF0073B1),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: fullHistory.length,
          itemBuilder: (context, index) {
            final event = fullHistory[index];
            final isLast = index == fullHistory.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline + Icon
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: CircleAvatar(
                        backgroundColor: event.color.withOpacity(0.15),
                        radius: 22,
                        child: Icon(event.icon, color: event.color, size: 22),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 60,
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),

                // Event details card
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.15),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.event,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: event.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                event.time,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
