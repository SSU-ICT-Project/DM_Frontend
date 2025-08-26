import 'package:flutter/material.dart';
import 'package:frontend/models/notification_model.dart'; // Import the model
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dummy data for now
  final List<NotificationModel> _notifications = [
    NotificationModel(
      title: '목표 달성!',
      body: "'아침 조깅하기' 목표를 달성했습니다.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.goal,
    ),
    NotificationModel(
      title: '스크린 타임 경고',
      body: "오늘 유튜브를 2시간 사용했습니다. 설정된 시간을 초과했습니다.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.screenTime,
    ),
    NotificationModel(
      title: '새로운 목표 추천',
      body: "이번 주에는 '독서 30분' 목표를 세워보는 건 어떠세요?",
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.goal,
    ),
    NotificationModel(
      title: '앱 사용량 보고서',
      body: "주간 앱 사용량 보고서가 도착했습니다. 확인해보세요.",
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.screenTime,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set Scaffold background to black
      appBar: AppBar(
        backgroundColor: Colors.black, // Set AppBar background to black
        title: Text(
          '알림 목록',
          style: GoogleFonts.inter( // Apply GoogleFonts style
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF504A), // Set title color
          ),
        ),
        centerTitle: true,
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                '알림이 없습니다.',
                style: TextStyle(color: Colors.white70), // Text color for no notifications
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  color: Colors.grey[900], // Set Card background to dark grey
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(
                      notification.type == NotificationType.goal
                          ? Icons.emoji_events
                          : Icons.phone_android,
                      color: notification.type == NotificationType.goal
                          ? Colors.amber // Keep existing icon colors
                          : Colors.blue,
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(color: Colors.white), // Set title text color
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.body,
                          style: const TextStyle(color: Colors.white70), // Set body text color
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54), // Set timestamp text color
                        ),
                      ],
                    ),
                    onTap: () {
                      // Handle notification tap, e.g., navigate to detail screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${notification.title} 탭됨'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.year}.${timestamp.month}.${timestamp.day}';
    }
  }
}