import 'package:flutter/material.dart';
import '../services/app_usage_service.dart';
import '../services/usage_reporter.dart';

class AppUsageSyncScreen extends StatefulWidget {
  const AppUsageSyncScreen({super.key});

  @override
  State<AppUsageSyncScreen> createState() => _AppUsageSyncScreenState();
}

class _AppUsageSyncScreenState extends State<AppUsageSyncScreen> {
  bool _isSyncing = false;
  String _lastSyncTime = '동기화 기록 없음';
  String _syncStatus = '';
  String _debugLog = '';
  bool _showDebugLog = false;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = await AppUsageService.getLastSyncTime();
    if (lastSync != null) {
      setState(() {
        _lastSyncTime = '${lastSync.year}-${lastSync.month.toString().padLeft(2, '0')}-${lastSync.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _checkCurrentUsage() async {
    setState(() {
      _debugLog = '🔍 현재 앱 사용량 확인 중...\n';
    });

    try {
      // 현재 시간 기준으로 최근 1시간 사용량 확인
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      setState(() {
        _debugLog += '📅 확인 기간: ${oneHourAgo.hour}:${oneHourAgo.minute.toString().padLeft(2, '0')} ~ ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n';
      });

      final usageSummary = await UsageReporter.fetchUsageSummary(
        begin: oneHourAgo,
        end: now,
      );

      setState(() {
        _debugLog += '📊 수집된 앱 개수: ${usageSummary.length}\n\n';
        
        if (usageSummary.isNotEmpty) {
          _debugLog += '📱 앱별 사용량:\n';
          final sortedUsage = usageSummary.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          for (final entry in sortedUsage.take(10)) { // 상위 10개만 표시
            final packageName = entry.key;
            final usageTimeMs = entry.value;
            final usageTimeMinutes = (usageTimeMs / (1000 * 60)).round();
            _debugLog += '  • $packageName: ${usageTimeMinutes}분 (${usageTimeMs}ms)\n';
          }
          
          final totalTime = usageSummary.values.fold<int>(0, (sum, time) => sum + time);
          final totalMinutes = (totalTime / (1000 * 60)).round();
          _debugLog += '\n📈 총 사용 시간: ${totalMinutes}분 (${totalTime}ms)';
        } else {
          _debugLog += '⚠️ 수집된 사용량이 없습니다';
        }
      });
    } catch (e) {
      setState(() {
        _debugLog += '❌ 오류 발생: $e';
      });
    }
  }

  Future<void> _syncTodayUsage() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = '오늘 앱 사용량 동기화 중...';
      _debugLog = '';
    });

    try {
      await AppUsageService.collectAndSendUsage(date: DateTime.now());
      await _loadLastSyncTime();
      
      setState(() {
        _syncStatus = '동기화 완료!';
      });
      
      // 3초 후 상태 메시지 제거
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncStatus = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _syncStatus = '동기화 실패: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _syncYesterdayUsage() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = '어제 앱 사용량 동기화 중...';
      _debugLog = '';
    });

    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await AppUsageService.collectAndSendUsage(date: yesterday);
      
      setState(() {
        _syncStatus = '어제 데이터 동기화 완료!';
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncStatus = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _syncStatus = '동기화 실패: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          '앱 사용량 동기화',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFFFF6B6B),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 카드
            _InfoCard(
              icon: Icons.sync,
              title: '앱 사용량 동기화',
              description: '기기의 앱 사용량(스크린타임) 데이터를 백엔드로 전송합니다. 이 데이터는 디지털 웰빙 분석에 활용됩니다.',
            ),
            
            const SizedBox(height: 24),
            
            // 마지막 동기화 시간
            _StatusCard(
              icon: Icons.access_time,
              title: '마지막 동기화',
              value: _lastSyncTime,
            ),
            
            const SizedBox(height: 24),
            
            // 현재 사용량 확인 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _checkCurrentUsage,
                icon: const Icon(Icons.visibility),
                label: Text(
                  '현재 앱 사용량 확인',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 동기화 버튼들
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncTodayUsage,
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _isSyncing ? '동기화 중...' : '오늘 앱 사용량 동기화',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isSyncing ? null : _syncYesterdayUsage,
                icon: const Icon(Icons.history),
                label: Text(
                  '어제 앱 사용량 동기화',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 상태 메시지
            if (_syncStatus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _syncStatus.contains('실패') 
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _syncStatus.contains('실패') 
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFFFF6B6B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _syncStatus.contains('실패') ? Icons.error_outline : Icons.check_circle,
                      color: _syncStatus.contains('실패') 
                          ? Colors.red 
                          : const Color(0xFFFF6B6B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _syncStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _syncStatus.contains('실패') 
                              ? Colors.red 
                              : const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // 디버그 로그 토글 버튼
            if (_debugLog.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDebugLog = !_showDebugLog;
                    });
                  },
                  icon: Icon(
                    _showDebugLog ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  label: Text(
                    _showDebugLog ? '로그 숨기기' : '상세 로그 보기',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            // 디버그 로그 표시
            if (_debugLog.isNotEmpty && _showDebugLog) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bug_report,
                            color: const Color(0xFFFF6B6B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '디버그 로그',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        _debugLog,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF6B6B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B6B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
