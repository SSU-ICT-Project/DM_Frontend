import 'dart:async';
import 'package:flutter/services.dart';

typedef ForegroundAppListener = void Function(String packageName);
typedef UsageSummaryListener = void Function(Map<String, int> msByPackage);

class UsageReporter {
  static const _ch = MethodChannel('app.usage/access');
  Timer? _timer;
  String? _last;
  final Duration interval;
  final Set<String> targets;
  final ForegroundAppListener onTargetDetected;
  final UsageSummaryListener? onSummary;

  UsageReporter({
    required this.interval,
    required this.targets,
    required this.onTargetDetected,
    this.onSummary,
  });

  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      try {
        final pkg = await _ch.invokeMethod<String>('getForegroundApp');
        if (pkg == null || pkg == _last) return;
        _last = pkg;
        if (targets.contains(pkg)) {
          onTargetDetected(pkg);
        }
      } catch (_) {}
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static const _summaryCh = MethodChannel('app.usage/access');
  static Future<Map<String, int>> fetchUsageSummary({
    required DateTime begin,
    required DateTime end,
    Set<String>? packages,
  }) async {
    final args = <String, dynamic>{
      'begin': begin.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      if (packages != null) 'packages': packages.toList(),
    };
    final map = await _summaryCh.invokeMethod<Map>('getUsageSummary', args);
    final out = <String, int>{};
    if (map != null) {
      map.forEach((k, v) {
        if (k is String && v is int) out[k] = v;
      });
    }
    return out;
  }

  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _summaryCh.invokeMethod('getInstalledApps');
      return result.map((app) => Map<String, String>.from(app)).toList();
    } catch (e) {
      print('설치된 앱 목록 가져오기 실패: $e');
      return [];
    }
  }
}


