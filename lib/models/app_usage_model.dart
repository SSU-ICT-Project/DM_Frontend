class AppUsageModel {
  final String userId;
  final DateTime date;
  final List<AppUsageData> appUsages;
  final int totalScreenTime; // 총 스크린타임 (분 단위)

  AppUsageModel({
    required this.userId,
    required this.date,
    required this.appUsages,
    required this.totalScreenTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'appUsages': appUsages.map((usage) => usage.toJson()).toList(),
      'totalScreenTime': totalScreenTime,
    };
  }

  factory AppUsageModel.fromJson(Map<String, dynamic> json) {
    return AppUsageModel(
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date']),
      appUsages: (json['appUsages'] as List?)
          ?.map((usage) => AppUsageData.fromJson(usage))
          .toList() ?? [],
      totalScreenTime: json['totalScreenTime'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'AppUsageModel(userId: $userId, date: $date, appUsages: $appUsages, totalScreenTime: $totalScreenTime)';
  }
}

class AppUsageData {
  final String packageName;
  final String appName;
  final int usageTimeMinutes; // 사용 시간 (분 단위)
  final DateTime lastUsed;

  AppUsageData({
    required this.packageName,
    required this.appName,
    required this.usageTimeMinutes,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'usageTimeMinutes': usageTimeMinutes,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory AppUsageData.fromJson(Map<String, dynamic> json) {
    return AppUsageData(
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      usageTimeMinutes: json['usageTimeMinutes'] ?? 0,
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }

  @override
  String toString() {
    return 'AppUsageData(packageName: $packageName, appName: $appName, usageTimeMinutes: $usageTimeMinutes, lastUsed: $lastUsed)';
  }
}
