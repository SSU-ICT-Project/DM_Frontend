import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';
import '../utils/slide_page_route.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/goal_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  GoalSortOption _sortOption = GoalSortOption.deadlineAsc;
  String? _motivationMessage;

  @override
  void initState() {
    super.initState();
    // 데모 데이터
    _goals.addAll([
      Goal(
        id: 'g1',
        title: '토익 950점 달성',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        deadline: DateTime.now().add(const Duration(days: 30)),
        subGoals: [
          SubGoal(id: 's1', title: '영단어 100개 암기', createdAt: DateTime(2025, 1, 1)),
          SubGoal(id: 's2', title: '리스닝 3회차', createdAt: DateTime(2025, 1, 2)),
        ],
      ),
      Goal(
        id: 'g2',
        title: 'API 명세서 작성',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        deadline: DateTime.now().add(const Duration(days: 7)),
      ),
      Goal(
        id: 'g3',
        title: '피그마 레이아웃 마감 *****',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        deadline: DateTime.now().add(const Duration(days: 2)),
      ),
    ]);
    _applySort();
    _loadMotivationMessage();
  }

  void _loadMotivationMessage() async {
    // TODO: 백엔드 연동 시 실제 메시지로 교체
    setState(() {
      _motivationMessage = '오늘도 한 걸음, 목표에 가까워지고 있어요.';
    });
  }

  void _toggleGoalCompleted(String goalId, bool completed) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      var goal = _goals[index].copyWith(isCompleted: completed);

      // 본 목표 체크 시 하위 목표까지 체크
      final updatedSubs = goal.subGoals
          .map((s) => s.copyWith(isCompleted: completed))
          .toList(growable: false);
      goal = goal.copyWith(subGoals: updatedSubs);

      _goals[index] = goal;
    });
    _applySort();
  }

  void _toggleSubGoalCompleted(String goalId, String subId, bool completed) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      final goal = _goals[index];
      // 상태 업데이트
      final updated = goal.subGoals
          .map((s) => s.id == subId ? s.copyWith(isCompleted: completed) : s)
          .toList(growable: false);
      // 정렬: 미완료 먼저, 완료는 하단으로(기존 상대적 순서 유지)
      final incompletes = updated.where((s) => !s.isCompleted).toList(growable: false);
      final completes = updated.where((s) => s.isCompleted).toList(growable: false);
      final reordered = <SubGoal>[...incompletes, ...completes];
      _goals[index] = goal.copyWith(subGoals: reordered);
    });
  }

  Future<void> _addSubGoal(String goalId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _AddSubGoalDialog(),
    );
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      final goal = _goals[index];
      final updatedSubs = List<SubGoal>.from(goal.subGoals)
        ..add(SubGoal(id: UniqueKey().toString(), title: result.trim(), createdAt: DateTime.now()));
      _goals[index] = goal.copyWith(subGoals: updatedSubs);
    });
  }

  void _toggleExpanded(String goalId) {
    setState(() {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      final g = _goals[index];
      _goals[index] = g.copyWith(isExpanded: !g.isExpanded);
    });
  }

  void _deleteGoal(String goalId) {
    setState(() {
      _goals.removeWhere((g) => g.id == goalId);
      //  ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('"${goal.title}" 목표가 삭제되었습니다.')),
      // );
    });
  }

  void _showGoalOptionsDialog(String goalId) {
    final goal = _goals.firstWhere((g) => g.id == goalId, orElse: () => Goal(id: 'unknown', title: '알 수 없는 목표', createdAt: DateTime.now()));
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

  Future<void> _editGoal(String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;
    final goal = _goals[index];
    final result = await showDialog<_GoalEditResult>(
      context: context,
      builder: (context) => _EditGoalDialog(
        initialTitle: goal.title,
        initialDeadline: goal.deadline,
        initialSubGoals: goal.subGoals,
      ),
    );
    if (result == null) return;
    setState(() {
      _goals[index] = goal.copyWith(title: result.title, deadline: result.deadline, subGoals: result.subGoals);
      _applySort();
    });
  }

  void _addGoal() async {
    final result = await showDialog<_GoalDraft>(
      context: context,
      builder: (context) => const _AddGoalDialog(),
    );
    if (result == null) return;
    setState(() {
      _goals.add(
        Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result.title,
          createdAt: DateTime.now(),
          deadline: result.deadline,
          subGoals: result.subGoals
              .map((t) => SubGoal(
                    id: UniqueKey().toString(),
                    title: t,
                    createdAt: DateTime.now(),
                  ))
              .toList(),
        ),
      );
      _applySort();
    });
  }

  void _applySort() {
    setState(() {
      _goals.sort((a, b) {
        // 완료된 목표는 항상 하단으로
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        // 미완료/완료 그룹 내부에서는 선택된 정렬 기준 적용
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

  TextStyle _subGoalTextStyle(SubGoal sub) {
    final base = GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white);
    if (sub.isCompleted) {
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
      body: ListView.builder(
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
            onLongPress: () => _showGoalOptionsDialog(goal.id), // Changed from onLongPressDelete
            onToggleExpanded: () => _toggleExpanded(goal.id),
            onToggleSubCompleted: (subId, v) => _toggleSubGoalCompleted(goal.id, subId, v),
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
  final VoidCallback onLongPress; // Renamed from onLongPressDelete
  final VoidCallback onToggleExpanded;
  final void Function(String subId, bool value) onToggleSubCompleted;
  final VoidCallback onAddSubGoal;

  const _GoalCard({
    required this.goal,
    required this.dDayLabel,
    required this.onToggleCompleted,
    required this.onLongPress, // Renamed from onLongPressDelete
    required this.onToggleExpanded,
    required this.onToggleSubCompleted,
    required this.onAddSubGoal,
    super.key, // Added super.key
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress, // Used the renamed parameter
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
                          sub.title,
                          style: TextStyle(
                            decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
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
    super.key, // Added super.key
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

// 공통 하단 네비게이션은 widgets/app_bottom_nav.dart 로 이동

class _Header extends StatelessWidget {
  final String dateLabel;
  final String? message;
  const _Header({required this.dateLabel, required this.message, super.key}); // Added super.key

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
  const _AddMainGoalTile({required this.onTap, super.key}); // Added super.key

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

class _AddSubGoalDialog extends StatefulWidget {
  const _AddSubGoalDialog({super.key}); // Added super.key

  @override
  State<_AddSubGoalDialog> createState() => _AddSubGoalDialogState();
}

class _AddSubGoalDialogState extends State<_AddSubGoalDialog> {
  final TextEditingController _controller = TextEditingController();

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
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: '하위 목표 제목', labelStyle: TextStyle(color: Colors.white70)),
        style: const TextStyle(color: Colors.white),
        autofocus: true,
        onSubmitted: (v) => _submit(),
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
    Navigator.pop(context, text);
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
  const _AddGoalDialog({super.key}); // Added super.key

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subController = TextEditingController();
  DateTime? _deadline;
  final List<String> _subs = [];

  @override
  void dispose() {
    _titleController.dispose();
    _subController.dispose();
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
            const Divider(color: Colors.white24),
            TextField(
              controller: _subController,
              decoration: const InputDecoration(labelText: '하위 목표 추가', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                setState(() {
                  _subs.add(v.trim());
                  _subController.clear();
                });
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subs
                  .map((s) => Chip(
                        label: Text(s),
                        onDeleted: () => setState(() => _subs.remove(s)),
                      ))
                  .toList(),
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
            Navigator.pop(context, _GoalDraft(title, _deadline, _subs));
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

class _EditGoalDialog extends StatefulWidget {
  final String initialTitle;
  final DateTime? initialDeadline;
  final List<SubGoal> initialSubGoals;
  const _EditGoalDialog({required this.initialTitle, required this.initialDeadline, required this.initialSubGoals});

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
    _subs = List<SubGoal>.from(widget.initialSubGoals);
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
            const Divider(color: Colors.white24),
            Text('하위 목표', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubController,
                    decoration: const InputDecoration(labelText: '하위 목표 추가', labelStyle: TextStyle(color: Colors.white70)),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (v) => _addSub(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: _addSub,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subs.map((s) => _EditableSubGoalTile(
                  sub: s,
                  onChanged: (text) => _renameSub(s.id, text),
                  onDelete: () => _removeSub(s.id),
                )),
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

  void _addSub() {
    final text = _newSubController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subs.add(SubGoal(id: UniqueKey().toString(), title: text, createdAt: DateTime.now()));
      _newSubController.clear();
    });
  }

  void _renameSub(String id, String text) {
    setState(() {
      _subs = _subs
          .map((s) => s.id == id ? s.copyWith(title: text) : s)
          .toList(growable: false);
    });
  }

  void _removeSub(String id) {
    setState(() {
      _subs.removeWhere((s) => s.id == id);
    });
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
