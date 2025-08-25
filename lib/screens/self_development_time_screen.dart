import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/self_development_time_model.dart';
import '../services/api_service.dart';
import 'dart:convert'; // jsonDecode를 사용하기 위해 추가

class SelfDevelopmentTimeScreen extends StatefulWidget {
  const SelfDevelopmentTimeScreen({super.key});

  @override
  State<SelfDevelopmentTimeScreen> createState() => _SelfDevelopmentTimeScreenState();
}

class _SelfDevelopmentTimeScreenState extends State<SelfDevelopmentTimeScreen> {
  final Map<String, List<TimeSlot>> _weeklySchedule = {};
  bool _isLoading = false;
  String _saveStatus = '';

  final List<String> _weekdays = [
    'MONDAY',
    'TUESDAY', 
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];

  final List<String> _weekdayNames = [
    '월요일',
    '화요일',
    '수요일', 
    '목요일',
    '금요일',
    '토요일',
    '일요일'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // 화면이 다시 포커스될 때 스케줄 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 최신 데이터 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduleIfNeeded();
    });
  }

  Future<void> _refreshScheduleIfNeeded() async {
    // 마지막 동기화 시간을 확인하여 필요시 새로고침
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_schedule_sync');
    if (lastSync == null) return;
    
    final lastSyncTime = DateTime.tryParse(lastSync);
    if (lastSyncTime != null && 
        DateTime.now().difference(lastSyncTime).inMinutes > 30) {
      // 30분 이상 지났으면 새로고침
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 먼저 로컬에서 로드
      final prefs = await SharedPreferences.getInstance();
      final scheduleJson = prefs.getString('self_development_schedule');
      
      if (scheduleJson != null) {
        final schedule = SelfDevelopmentTimeModel.fromJson(
          Map<String, dynamic>.from(
            scheduleJson as Map<String, dynamic>
          )
        );
        setState(() {
          _weeklySchedule.clear();
          _weeklySchedule.addAll(schedule.weeklySchedule);
        });
      }

      // 백엔드에서도 로드 시도
      try {
        final response = await ApiService.getSelfDevelopmentTime();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final schedule = SelfDevelopmentTimeModel.fromJson(data);
          setState(() {
            _weeklySchedule.clear();
            _weeklySchedule.addAll(schedule.weeklySchedule);
          });
          
          // 로컬에도 저장
          await prefs.setString('self_development_schedule', schedule.toJson().toString());
          // 마지막 동기화 시간 기록
          await prefs.setString('last_schedule_sync', DateTime.now().toIso8601String());
        } else if (response.statusCode == 404) {
          // 자기개발시간이 설정되지 않은 경우 (404 Not Found)
          print('자기개발시간이 아직 설정되지 않았습니다.');
        } else {
          print('백엔드에서 스케줄 로드 실패: ${response.statusCode}');
        }
      } catch (e) {
        print('백엔드에서 스케줄 로드 실패: $e');
        // 백엔드 로드 실패 시 로컬 데이터 사용
      }
    } catch (e) {
      print('스케줄 로드 중 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() {
      _isLoading = true;
      _saveStatus = '저장 중...';
    });

    try {
      // 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      final schedule = SelfDevelopmentTimeModel(weeklySchedule: _weeklySchedule);
      final scheduleJson = schedule.toJson();
      
      await prefs.setString('self_development_schedule', scheduleJson.toString());
      
      // 백엔드로 전송
      try {
        final response = await ApiService.sendSelfDevelopmentTime(schedule);
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _saveStatus = '저장 완료! (백엔드 동기화 성공)';
          });
          // 성공 시 마지막 동기화 시간 업데이트
          await prefs.setString('last_schedule_sync', DateTime.now().toIso8601String());
        } else if (response.statusCode == 400) {
          setState(() {
            _saveStatus = '저장 실패: 잘못된 데이터 형식입니다.';
          });
        } else if (response.statusCode == 401) {
          setState(() {
            _saveStatus = '저장 실패: 로그인이 필요합니다.';
          });
        } else {
          setState(() {
            _saveStatus = '로컬 저장 완료 (백엔드 동기화 실패: ${response.statusCode})';
          });
        }
      } catch (e) {
        setState(() {
          _saveStatus = '로컬 저장 완료 (백엔드 동기화 실패: $e)';
        });
      }

      // 3초 후 상태 메시지 제거
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _saveStatus = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _saveStatus = '저장 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTimeSlot(String day) {
    setState(() {
      if (!_weeklySchedule.containsKey(day)) {
        _weeklySchedule[day] = [];
      }
      _weeklySchedule[day]!.add(TimeSlot(start: '09:00', end: '10:00'));
    });
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      if (_weeklySchedule.containsKey(day)) {
        _weeklySchedule[day]!.removeAt(index);
        if (_weeklySchedule[day]!.isEmpty) {
          _weeklySchedule.remove(day);
        }
      }
    });
  }

  void _updateTimeSlot(String day, int index, String start, String end) {
    setState(() {
      if (_weeklySchedule.containsKey(day) && index < _weeklySchedule[day]!.length) {
        _weeklySchedule[day]![index] = TimeSlot(start: start, end: end);
      }
    });
  }

  String _formatTimeForDisplay(String time) {
    if (time.isEmpty) return '00:00';
    return time;
  }

  Future<void> _selectTime(BuildContext context, String day, int index, bool isStart) async {
    final currentTime = isStart 
        ? _weeklySchedule[day]![index].start 
        : _weeklySchedule[day]![index].end;
    
    final timeParts = currentTime.split(':');
    final initialHour = int.parse(timeParts[0]);
    final initialMinute = int.parse(timeParts[1]);

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme( 
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF504A),
              onPrimary: Colors.white,
              surface: Color(0xFF212121),
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[900],
              hourMinuteTextColor: Colors.white,
              hourMinuteColor: Colors.grey[800],
              dialBackgroundColor: Colors.grey[800],
              dialHandColor: const Color(0xFFFF504A),
              dialTextColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final newTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      
      if (isStart) {
        _updateTimeSlot(day, index, newTime, _weeklySchedule[day]![index].end);
      } else {
        _updateTimeSlot(day, index, _weeklySchedule[day]![index].start, newTime);
      }
    }
  }

  Widget _buildTimeSlotCard(String day, int index) {
    final timeSlot = _weeklySchedule[day]![index];
    final isValid = timeSlot.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '시간대 ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeTimeSlot(day, index),
                  icon: const Icon(Icons.delete, color: Color(0xFFFF504A)),
                  tooltip: '삭제',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '시작 시간',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, day, index, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isValid ? const Color(0xFF757575) : const Color(0xFFEF5350),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTimeForDisplay(timeSlot.start),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(Icons.access_time, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '종료 시간',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, day, index, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isValid ? const Color(0xFF757575) : const Color(0xFFEF5350),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTimeForDisplay(timeSlot.end),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(Icons.access_time, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isValid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '시작 시간이 종료 시간보다 빨라야 합니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySection(String day, String dayName) {
    final hasTimeSlots = _weeklySchedule.containsKey(day) && _weeklySchedule[day]!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _addTimeSlot(day),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('시간 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF504A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasTimeSlots) ...[
              ...List.generate(
                _weeklySchedule[day]!.length,
                (index) => _buildTimeSlotCard(day, index),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF616161)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '설정된 시간이 없습니다',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '위의 "시간 추가" 버튼을 눌러\n자기개발 시간을 설정해주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '자기개발시간 설정',
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF504A),
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSchedule,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
          IconButton(
            onPressed: _isLoading ? null : _saveSchedule,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF504A),
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: '저장',
          ),
        ],
      ),
      body: Column(
        children: [
          // 설명 카드
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF504A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF504A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFFFF504A), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '자기개발시간 설정',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF504A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '요일별로 자기개발에 집중할 시간대를 설정하세요. ' 
                  '설정된 시간에는 유해앱 사용을 제한하고 알림을 받을 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // 통계 정보 카드
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_weeklySchedule.values.fold(0, (sum, slots) => sum + slots.length)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF504A),
                        ),
                      ),
                      Text(
                        '총 시간대',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[700],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_weeklySchedule.keys.where((day) => _weeklySchedule[day]!.isNotEmpty).length}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF504A),
                        ),
                      ),
                      Text(
                        '활성 요일',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 저장 상태 메시지
          if (_saveStatus.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _saveStatus.contains('실패') 
                    ? Colors.red[900]?.withOpacity(0.2) 
                    : const Color(0xFFFF504A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _saveStatus.contains('실패') 
                      ? Colors.red[700]! 
                      : const Color(0xFFFF504A),
                ),
              ),
              child: Text(
                _saveStatus,
                style: TextStyle(
                  color: _saveStatus.contains('실패') 
                      ? Colors.red[400] 
                      : const Color(0xFFFF504A),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // 요일별 설정 섹션
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF504A),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _weekdays.map((day) {
                      final dayIndex = _weekdays.indexOf(day);
                      return _buildWeekdaySection(day, _weekdayNames[dayIndex]);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
