import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/slide_page_route.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _serviceNotification = true;
  bool _nightPush = false;
  bool _calendarNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('알림 설정', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFFF504A))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _SwitchTile(
            title: '서비스 알림',
            subtitle: '앱 서비스 관련 주요 소식을 받아요',
            value: _serviceNotification,
            onChanged: (v) => setState(() => _serviceNotification = v),
          ),
          const _Divider(),
          _SwitchTile(
            title: '야간 푸시 알림',
            subtitle: '야간 시간대에도 푸시 알림을 받아요',
            value: _nightPush,
            onChanged: (v) => setState(() => _nightPush = v),
          ),
          const _Divider(),
          _SwitchTile(
            title: '캘린더 알림',
            subtitle: '일정 및 목표가 캘린더에 반영될 때 알려줘요',
            value: _calendarNotification,
            onChanged: (v) => setState(() => _calendarNotification = v),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      activeColor: const Color(0xFFFF504A),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}


