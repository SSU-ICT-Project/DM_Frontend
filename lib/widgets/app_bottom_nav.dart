import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: '캘린더'),
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
      ],
    );
  }
}


