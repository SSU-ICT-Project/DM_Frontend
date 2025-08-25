import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_usage_service.dart';
import '../services/usage_reporter.dart';
import '../utils/slide_page_route.dart';

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '앱 사용량 동기화',
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF504A),
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 카드
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '앱 사용량 동기화',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '기기의 앱 사용량(스크린타임) 데이터를 백엔드로 전송합니다. '
                      '이 데이터는 디지털 웰빙 분석에 활용됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 마지막 동기화 시간
            Card(
              color: Colors.grey[900],
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Color(0xFFFF504A)),
                title: const Text('마지막 동기화', style: TextStyle(color: Colors.white)),
                subtitle: Text(_lastSyncTime, style: const TextStyle(color: Colors.grey)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 현재 사용량 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkCurrentUsage,
                icon: const Icon(Icons.visibility),
                label: const Text('현재 앱 사용량 확인'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 동기화 버튼들
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncTodayUsage,
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? '동기화 중...' : '오늘 앱 사용량 동기화'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF504A),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSyncing ? null : _syncYesterdayUsage,
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text('어제 앱 사용량 동기화', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 상태 메시지
            if (_syncStatus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _syncStatus.contains('실패') 
                      ? Colors.red[900]?.withOpacity(0.2) 
                      : const Color(0xFFFF504A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _syncStatus.contains('실패') 
                        ? Colors.red[700]! 
                        : const Color(0xFFFF504A),
                  ),
                ),
                child: Text(
                  _syncStatus,
                  style: TextStyle(
                    color: _syncStatus.contains('실패') 
                        ? Colors.red[400] 
                        : const Color(0xFFFF504A),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // 디버그 로그 토글 버튼
            if (_debugLog.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
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
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // 디버그 로그 표시
            if (_debugLog.isNotEmpty && _showDebugLog) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Color(0xFFFF504A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '디버그 로그',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF504A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _debugLog,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
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
