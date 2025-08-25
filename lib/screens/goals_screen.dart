import 'package:flutter/material.dart';
import 'package:frontend/screens/signup_step1_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';
import '../utils/slide_page_route.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/goal_model.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:io';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  GoalSortOption _sortOption = GoalSortOption.deadlineAsc;
  String? _motivationMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadMotivationMessage();
  }

  // 메인 목표 목록을 API에서 불러오는 메서드
  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('목표 목록 GET 요청 시작...');
      final response = await ApiService.getMainGoals(page: 0, size: 20);

      print(' 목표 목록 GET 응답 상태 코드: ${response.statusCode}');
      print(' 목표 목록 GET 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          print(' JSON 파싱 성공!');

          //  'mainGoalPage'를 'dmPage'로 수정하고, 데이터 구조에 맞게 접근합니다.
          final dmPage = responseBody['dmPage'];
          if (dmPage != null && dmPage.containsKey('contents')) {
            final List<dynamic> data = dmPage['contents'] ?? [];

            //  contents 안의 각 항목이 {"mainGoal": {}, "subGoals": []} 구조이므로, 'mainGoal'을 추출해야 합니다.
            final List<dynamic> mainGoalItems = data.map((item) => item['mainGoal']).where((item) => item != null).toList();

            print(' "dmPage"와 "contents" 필드 확인됨. 목표 목록 크기: ${mainGoalItems.length}');

            setState(() {
              _goals.clear();
              //  data 전체를 Goal.fromJson으로 전달
              _goals.addAll(data.map((item) => Goal.fromJson(item as Map<String, dynamic>)).toList());


              print(' goals 리스트 상태 확인:');
              _goals.forEach((goal) {
                print('  - 제목: ${goal.title}, D-Day: ${goal.dDay}, 하위 목표 수: ${goal.subGoals.length}');
              });
              _applySort();
            });
            print(' 목표 목록 업데이트 완료!');
          } else {
            print(' "dmPage" 또는 "contents" 필드가 응답에 없습니다.');
            setState(() => _goals.clear());
          }
        } catch (e) {
          print(' JSON 파싱 중 오류 발생: $e');
          setState(() => _goals.clear());
        }
      } else {
        //  401 Unauthorized 등 실패 로직
        print(' 목표 목록 로드 실패: ${response.statusCode}');

        //  여기에 로그아웃 로직 추가
        if (response.statusCode == 401) {
          // 1. SharedPreferences에서 토큰 삭제
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('accessToken');
          await prefs.remove('refreshToken');

          // 2. 로그인 화면으로 이동 및 이전 화면 스택 제거
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignupStep1Screen()), // LoginScreen으로 변경 필요
                (Route<dynamic> route) => false,
          );
        } else {
          // 다른 실패 상태 코드에 대한 처리
          setState(() => _goals.clear());
        }
      }
    } catch (e) {
      print(' 네트워크 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 메인 목표 추가
  // goals_screen.dart 파일의 _addGoal 메서드 수정
  void _addGoal() async {
    final result = await showDialog<_GoalDraft>(
      context: context,
      builder: (context) => const _AddGoalDialog(),
    );

    if (result == null || result.title.trim().isEmpty) return;

    final newGoalData = {
      'content': result.title.trim(),
      'deadline': result.deadline?.toIso8601String(),
      'checked': false,
    };

    try {
      print('목표 추가 요청 시작...');
      print('요청 본문: ${jsonEncode(newGoalData)}');

      final response = await ApiService.createMainGoal(newGoalData);

      print('HTTP 응답 상태 코드: ${response.statusCode}');
      print('HTTP 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        //  목표 생성에 성공했으므로, 목표 목록을 다시 불러옵니다.
        await _loadGoals();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 목표가 성공적으로 추가되었습니다.')),
        );
      } else {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = responseBody['message'] ?? '목표 추가에 실패했습니다. (코드: ${response.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print(' 목표 추가 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  // 메인 목표 수정
  Future<void> _editGoal(int goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;
    final goal = _goals[index];
    final result = await showDialog<_GoalEditResult>(
      context: context,
      builder: (context) => _EditGoalDialog(
        initialTitle: goal.title,
        initialDeadline: goal.computedDeadline,
        initialSubGoals: goal.subGoals,
        mainGoalId: goal.id,
      ),
    );
    if (result == null) return;

    final updatedMainGoalData = {
      'content': result.title,
      'deadline': result.deadline?.toIso8601String(),
    };

    try {
      final response = await ApiService.updateMainGoal(goalId.toString(), updatedMainGoalData);
      if (response.statusCode == 200) {
        await _loadGoals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표 수정 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  // 메인 목표 삭제
  void _deleteGoal(int goalId) async {
    try {
      final response = await ApiService.deleteMainGoal(goalId.toString());

      if (response.statusCode == 200) {
        setState(() {
          _goals.removeWhere((g) => g.id == goalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표가 삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표 삭제에 실패했습니다. (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  // 메인 목표 완료 토글 메서드 수정
  void _toggleGoalCompleted(int goalId, bool completed) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final updatedGoalData = {
      'checked': completed,
      'title': goal.title,     //  기존 제목을 함께 보냅니다.
      'dday': goal.dDay,       //  기존 디데이도 함께 보냅니다.
    };

    //  디버깅 코드 추가: 백엔드로 보내는 데이터를 출력합니다.
    print(' 백엔드에 전송될 데이터: $updatedGoalData');

    try {
      //  디버깅 코드 추가: API 요청 시작을 알립니다.
      print(' 목표 상태 업데이트 PUT 요청 시작...');
      final response = await ApiService.updateMainGoal(goalId.toString(), updatedGoalData);
      //  디버깅 코드 추가: 백엔드 응답을 출력합니다.
      print(' 목표 상태 업데이트 PUT 응답 상태 코드: ${response.statusCode}');
      print(' 목표 상태 업데이트 PUT 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        //  목표 목록을 다시 불러오는 대신, 로컬 리스트만 업데이트합니다.
        setState(() {
          final index = _goals.indexWhere((g) => g.id == goalId);
          if (index != -1) {
            // `copyWith` 메서드를 사용하여 해당 목표의 완료 상태만 변경
            _goals[index] = _goals[index].copyWith(isCompleted: completed);

            // 완료된 목표를 리스트 맨 아래로 정렬하여 시각적으로 구분
            _applySort();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(completed ? '목표가 완료되었습니다!' : '목표 완료가 취소되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 업데이트 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  // 하위 목표 완료 토글 메서드 수정
  void _toggleSubGoalCompleted(int subId, bool completed) async {
    final updatedSubGoalData = {
      'checked': completed,
    };

    try {
      final response = await ApiService.updateSubGoal(subId.toString(), updatedSubGoalData);
      if (response.statusCode == 200) {
        setState(() {
          //  로컬 리스트에서 하위 목표만 찾아 상태 변경
          final mainGoalIndex = _goals.indexWhere((g) => g.subGoals.any((s) => s.id == subId));
          if (mainGoalIndex != -1) {
            final subGoals = _goals[mainGoalIndex].subGoals.map((s) => s.id == subId ? s.copyWith(isCompleted: completed) : s).toList();
            _goals[mainGoalIndex] = _goals[mainGoalIndex].copyWith(subGoals: subGoals);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하위 목표 상태 업데이트 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  // 하위 목표 추가 메서드 수정
  Future<void> _addSubGoal(int mainGoalId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddSubGoalDialog(),
    );
    if (result == null || result['title'].trim().isEmpty) return;

    final newSubGoalData = {
      'mainGoalId': mainGoalId,
      'content': result['title'].trim(),
      'deadline': result['deadline']?.toIso8601String(),
      'checked': false,
    };

    try {
      final response = await ApiService.createSubGoal(newSubGoalData);
      if (response.statusCode == 200) {
        await _loadGoals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하위 목표 추가 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  void _toggleExpanded(int goalId) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      final g = _goals[index];
      _goals[index] = g.copyWith(isExpanded: !g.isExpanded);
    });
  }


  void _showGoalOptionsDialog(int goalId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => Goal(id: -1, title: '알 수 없는 목표', createdAt: DateTime.now()));
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('목표 관리', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          content: Text('"${goal.title}" 목표를 수정하거나 삭제하시겠습니까?', style: GoogleFonts.notoSans(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('수정', style: TextStyle(color: Colors.blueAccent[100])),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _editGoal(goalId);
              },
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.redAccent[100])),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteGoal(goalId);
              },
            ),
            TextButton(
              child: Text('취소', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadMotivationMessage() async {
    setState(() {
      _motivationMessage = '오늘도 한 걸음, 목표에 가까워지고 있어요.';
    });
  }

  void _applySort() {
    setState(() {
      _goals.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        switch (_sortOption) {
          case GoalSortOption.deadlineAsc:
            final ad = a.dDay ?? 1 << 30;
            final bd = b.dDay ?? 1 << 30;
            return ad.compareTo(bd);
          case GoalSortOption.deadlineDesc:
            final ad = a.dDay ?? -1 << 30;
            final bd = b.dDay ?? -1 << 30;
            return bd.compareTo(ad);
          case GoalSortOption.newest:
            return b.createdAt.compareTo(a.createdAt);
          case GoalSortOption.oldest:
            return a.createdAt.compareTo(b.createdAt);
          case GoalSortOption.name:
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
      });
    });
  }

  String _dDayLabel(Goal goal) {
    final d = goal.dDay;
    if (d == null) return 'D-?';
    if (d == 0) return 'D-DAY';
    return d > 0 ? 'D-$d' : 'D+${-d}';
  }

  TextStyle _goalTextStyle(Goal goal) {
    final base = GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);
    if (goal.isCompleted) {
      return base.copyWith(decoration: TextDecoration.lineThrough, color: Colors.white70);
    }
    return base;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('목표', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.w500, color: const Color(0xFFFF504A))),
        actions: [
          PopupMenuButton<GoalSortOption>(
            icon: const Icon(Icons.sort, color: Colors.white),
            color: Colors.grey[900],
            onSelected: (v) {
              _sortOption = v;
              _applySort();
            },
            itemBuilder: (context) => [
              _menuItem('마감일 순(가까운 순)', GoalSortOption.deadlineAsc),
              _menuItem('마감일 순(먼 순)', GoalSortOption.deadlineDesc),
              _menuItem('최신순', GoalSortOption.newest),
              _menuItem('오래된순', GoalSortOption.oldest),
              _menuItem('이름순', GoalSortOption.name),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _goals.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Header(dateLabel: _todayLabel(), message: _motivationMessage);
          }
          if (index == _goals.length + 1) {
            return _AddMainGoalTile(onTap: _addGoal);
          }
          final goal = _goals[index - 1];
          return _GoalCard(
            goal: goal,
            dDayLabel: _dDayLabel(goal),
            onToggleCompleted: (v) => _toggleGoalCompleted(goal.id, v),
            onLongPress: () => _showGoalOptionsDialog(goal.id),
            onToggleExpanded: () => _toggleExpanded(goal.id),
            onToggleSubCompleted: (subId, v) => _toggleSubGoalCompleted(subId, v),
            onAddSubGoal: () => _addSubGoal(goal.id),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: (i) {
        if (i == 2) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SettingsScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
                (route) => false,
          );
        }
        if (i == 0) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const CalendarScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
                (route) => false,
          );
        }
      }),
    );
  }

  PopupMenuItem<GoalSortOption> _menuItem(String label, GoalSortOption v) => PopupMenuItem(
    value: v,
    child: Text(label, style: GoogleFonts.notoSans(color: Colors.white)),
  );
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final String dDayLabel;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onLongPress;
  final VoidCallback onToggleExpanded;
  final void Function(int subId, bool value) onToggleSubCompleted;
  final VoidCallback onAddSubGoal;

  const _GoalCard({
    required this.goal,
    required this.dDayLabel,
    required this.onToggleCompleted,
    required this.onLongPress,
    required this.onToggleExpanded,
    required this.onToggleSubCompleted,
    required this.onAddSubGoal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SquareCheckbox(
                  value: goal.isCompleted,
                  onChanged: (v) => onToggleCompleted(v ?? false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$dDayLabel | ${goal.title}',
                    style: TextStyle(
                      decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(goal.isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                  onPressed: onToggleExpanded,
                ),
              ],
            ),
            if (goal.isExpanded) ...[
              const SizedBox(height: 8),
              for (final sub in goal.subGoals)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
                  child: Row(
                    children: [
                      _SquareCheckbox(
                        value: sub.isCompleted,
                        onChanged: (v) => onToggleSubCompleted(sub.id, v ?? false),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _subGoalDDayLabel(sub).isNotEmpty
                              ? '${_subGoalDDayLabel(sub)} | ${sub.title}'
                              : sub.title,
                          style: _subGoalTextStyle(sub),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: TextButton.icon(
                  onPressed: onAddSubGoal,
                  icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                  label: const Text('하위 목표 추가', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SquareCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final double size;

  const _SquareCheckbox({
    required this.value,
    required this.onChanged,
    this.size = 23,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFF504A) : Colors.transparent,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String dateLabel;
  final String? message;
  const _Header({required this.dateLabel, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(dateLabel, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              message ?? '동기부여 메시지 불러오는 중... (연동 예정)',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AddMainGoalTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMainGoalTile({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white70),
              SizedBox(width: 6),
              Text('목표 추가', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
String _subGoalDDayLabel(SubGoal sub) {
  final d = sub.dDay;
  if (d == null) return '';
  if (d == 0) return 'D-DAY';
  return d > 0 ? 'D-$d' : 'D+${-d}';
}

TextStyle _subGoalTextStyle(SubGoal sub) {
  final base = GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white);
  if (sub.isCompleted) {
    return base.copyWith(decoration: TextDecoration.lineThrough, color: Colors.white70);
  }
  return base;
}

class _AddSubGoalDialog extends StatefulWidget {
  const _AddSubGoalDialog({super.key});

  @override
  State<_AddSubGoalDialog> createState() => _AddSubGoalDialogState();
}

class _AddSubGoalDialogState extends State<_AddSubGoalDialog> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('하위 목표 추가', style: GoogleFonts.inter(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: '하위 목표 제목', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              onSubmitted: (v) => _submit(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null ? '마감일 없음' : '마감일: ${_deadline!.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) setState(() => _deadline = picked);
                  },
                  child: const Text('마감일 선택'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white70))),
        FilledButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, {'title': text, 'deadline': _deadline});
  }
}

String _todayLabel() {
  final now = DateTime.now();
  return '${now.month}월${now.day}일';
}

class _GoalDraft {
  final String title;
  final DateTime? deadline;
  final List<String> subGoals;
  const _GoalDraft(this.title, this.deadline, this.subGoals);
}

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog({super.key});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subController = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('목표 추가', style: GoogleFonts.inter(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '목표 제목', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null ? '마감일 없음' : '마감일: ${_deadline!.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) setState(() => _deadline = picked);
                  },
                  child: const Text('마감일 선택'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white70))),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(context, _GoalDraft(title, _deadline, []));
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _GoalEditResult {
  final String title;
  final DateTime? deadline;
  final List<SubGoal> subGoals;
  const _GoalEditResult(this.title, this.deadline, this.subGoals);
}

// 메인 목표 수정 UI
class _EditGoalDialog extends StatefulWidget {
  final String initialTitle;
  final DateTime? initialDeadline;
  final List<SubGoal> initialSubGoals;
  final int mainGoalId;

  const _EditGoalDialog({
    required this.initialTitle,
    required this.initialDeadline,
    required this.initialSubGoals,
    required this.mainGoalId,
  });

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late TextEditingController _titleController;
  DateTime? _deadline;
  late List<SubGoal> _subs;
  final TextEditingController _newSubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _deadline = widget.initialDeadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _newSubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('목표 수정', style: GoogleFonts.inter(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '목표 제목', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null ? '마감일 없음' : '마감일: ${_deadline!.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) setState(() => _deadline = picked);
                  },
                  child: const Text('마감일 선택'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white70))),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(context, _GoalEditResult(title, _deadline, _subs));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  void _addSub() async {
    final text = _newSubController.text.trim();
    if (text.isEmpty) return;

    final newSubGoalData = {
      'mainGoalId': widget.mainGoalId,
      'content': text,
      'checked': false,
    };

    try {
      final response = await ApiService.createSubGoal(newSubGoalData);
      if (response.statusCode == 200) {
        final newSubGoalJson = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        setState(() {
          _subs.add(SubGoal.fromJson(newSubGoalJson));
          _newSubController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하위 목표 추가 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  void _renameSub(int id, String text) async {
    final updateData = {
      'content': text,
    };
    try {
      final response = await ApiService.updateSubGoal(id.toString(), updateData);
      if (response.statusCode == 200) {
        setState(() {
          _subs = _subs.map((s) => s.id == id ? s.copyWith(title: text) : s).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하위 목표 이름 변경 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  void _removeSub(int id) async {
    try {
      final response = await ApiService.deleteSubGoal(id.toString());
      if (response.statusCode == 200) {
        setState(() {
          _subs.removeWhere((s) => s.id == id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하위 목표 삭제 실패: (코드: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }
}

class _EditableSubGoalTile extends StatelessWidget {
  final SubGoal sub;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  const _EditableSubGoalTile({required this.sub, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: sub.title);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '하위 목표 제목',
                labelStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}