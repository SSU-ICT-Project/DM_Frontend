import 'package:flutter/material.dart';

enum NotificationType {
  goal,
  screenTime,
  // Add more types as needed
}

class NotificationModel {
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;

  NotificationModel({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
  });
}