import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/event_model.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  final Map<DateTime, List<EventItem>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    // 데모 이벤트
    _addDemoEvents();
  }

  void _addDemoEvents() {
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day, 9);
    final d2 = DateTime(now.year, now.month, now.day + 2, 14);
    final d3 = DateTime(now.year, now.month, now.day + 2, 19);
    _addEvent(EventItem(id: 'e1', title: '팀 스탠드업', location: '온라인', startAt: d1, endAt: d1.add(const Duration(hours: 1))));
    _addEvent(EventItem(id: 'e2', title: '헬스', location: 'XX 피트니스', startAt: d2, endAt: d2.add(const Duration(hours: 1))));
    _addEvent(EventItem(id: 'e3', title: '저녁 약속', location: '강남역', startAt: d3, endAt: d3.add(const Duration(hours: 2))));
  }

  void _addEvent(EventItem e) {
    final key = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
    _eventsByDate.putIfAbsent(key, () => []);
    _eventsByDate[key]!.add(e);
  }

  List<EventItem> _eventsOf(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final list = _eventsByDate[key] ?? const [];
    final sorted = [...list]..sort((a, b) => a.startAt.compareTo(b.startAt));
    return sorted;
  }

  void _changeMonth(int diff) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + diff);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_visibleMonth.year}.${_visibleMonth.month.toString().padLeft(2, '0')}';
    final selectedEvents = _selectedDate == null ? const <EventItem>[] : _eventsOf(_selectedDate!);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('캘린더', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.w500, color: const Color(0xFFFF504A))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _openEventEditor(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(monthLabel, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  _NavButton(icon: Icons.chevron_left, onTap: () => _changeMonth(-1)),
                  const SizedBox(width: 8),
                  _NavButton(icon: Icons.chevron_right, onTap: () => _changeMonth(1)),
                ],
              ),
            ),
            const _WeekdayHeader(),
            const SizedBox(height: 8),
            _MonthGrid(
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              hasEvents: (day) => _eventsOf(day).isNotEmpty,
              onSelect: (day) => setState(() => _selectedDate = day),
            ),
            const SizedBox(height: 12),
            _EventList(
              date: _selectedDate,
              events: selectedEvents,
              onEdit: (e) => _openEventEditor(context, existing: e),
              shrinkWrapped: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const GoalsScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
              (route) => false,
            );
          }
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
        },
      ),
    );
  }

  Future<void> _openEventEditor(BuildContext context, {EventItem? existing}) async {
    final updated = await showModalBottomSheet<EventItem?> (
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EventEditorSheet(
        initial: existing,
        onDelete: existing == null ? null : () {
          final key = DateTime(existing.startAt.year, existing.startAt.month, existing.startAt.day);
          setState(() { _eventsByDate[key]?.removeWhere((x) => x.id == existing.id); });
          Navigator.of(ctx).pop(null);
        },
      ),
    );
    if (updated == null) return;
    setState(() {
      if (existing != null) {
        final oldKey = DateTime(existing.startAt.year, existing.startAt.month, existing.startAt.day);
        _eventsByDate[oldKey]?.removeWhere((x) => x.id == existing.id);
      }
      _addEvent(updated);
    });
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(labels[i], style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final bool Function(DateTime day) hasEvents;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.hasEvents,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sun=0 .. Sat=6
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (int r = 0; r < totalCells / 7; r++)
            Row(
              children: [
                for (int c = 0; c < 7; c++)
                  Expanded(
                    child: _DayCell(
                      index: r * 7 + c,
                      firstWeekday: firstWeekday,
                      daysInMonth: daysInMonth,
                      visibleMonth: visibleMonth,
                      selectedDate: selectedDate,
                      hasEvents: hasEvents,
                      onSelect: onSelect,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int index;
  final int firstWeekday; // 0..6 Sun..Sat
  final int daysInMonth;
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final bool Function(DateTime day) hasEvents;
  final ValueChanged<DateTime> onSelect;

  const _DayCell({
    required this.index,
    required this.firstWeekday,
    required this.daysInMonth,
    required this.visibleMonth,
    required this.selectedDate,
    required this.hasEvents,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dayNum = index - firstWeekday + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 46);
    }
    final date = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
    final selected = selectedDate != null && _isSameDay(selectedDate!, date);
    final has = hasEvents(date);
    final circleColor = selected
        ? const Color(0xFFFF504A)
        : (has ? Colors.white24 : Colors.transparent);
    final textColor = selected ? Colors.white : Colors.white;

    return InkWell(
      onTap: () => onSelect(date),
      child: SizedBox(
        height: 46,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$dayNum', style: GoogleFonts.inter(color: textColor)),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EventList extends StatelessWidget {
  final DateTime? date;
  final List<EventItem> events;
  final void Function(EventItem e) onEdit;
  final bool shrinkWrapped;

  const _EventList({required this.date, required this.events, required this.onEdit, this.shrinkWrapped = false});

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Center(child: Text('날짜를 선택해 주세요', style: GoogleFonts.inter(color: Colors.white54)));
    }
    if (events.isEmpty) {
      return Center(child: Text('일정이 없습니다', style: GoogleFonts.inter(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shrinkWrap: shrinkWrapped,
      physics: shrinkWrapped ? const NeverScrollableScrollPhysics() : null,
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = events[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_timeRangeLabel(e), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(e.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (e.location != null && e.location!.isNotEmpty)
                      Text(e.location!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: () => onEdit(e),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeRangeLabel(EventItem e) {
    String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${hhmm(e.startAt)} - ${hhmm(e.endAt)}';
  }
}

class _EventEditorSheet extends StatefulWidget {
  final EventItem? initial;
  final VoidCallback? onDelete;

  const _EventEditorSheet({this.initial, this.onDelete});

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _location;
  late TextEditingController _memo;
  late DateTime _startAt;
  late DateTime _endAt;
  bool _useDDay = false;
  bool _useAutoTime = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initial;
    _title = TextEditingController(text: init?.title ?? '');
    _location = TextEditingController(text: init?.location ?? '');
    _memo = TextEditingController(text: init?.memo ?? '');
    _startAt = init?.startAt ?? DateTime(now.year, now.month, now.day, now.hour, 0);
    _endAt = init?.endAt ?? _startAt.add(const Duration(hours: 1));
    _useDDay = init?.useDDay ?? false;
    _useAutoTime = init?.useAutoTimeNotification ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 12),
              Text(widget.initial == null ? '일정' : '일정', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _DarkInput(controller: _title, hint: '제목'),
              const SizedBox(height: 12),
              _DarkInput(
                controller: _location,
                hint: '위치',
                readOnly: true,
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 16),
              _SwitchRow(
                label: '디데이',
                value: _useDDay,
                onChanged: (v) => setState(() => _useDDay = v),
              ),
              const SizedBox(height: 12),
              _SwitchRow(
                label: '자동 시간 계산 알림',
                value: _useAutoTime,
                onChanged: (v) => setState(() => _useAutoTime = v),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  onPressed: _showAutoTimeInfo,
                ),
              ),
              const SizedBox(height: 12),
              _DateTimePicker(label: '시작', value: _startAt, onChanged: (v) => setState(() => _startAt = v)),
              const SizedBox(height: 12),
              _DateTimePicker(label: '종료', value: _endAt, onChanged: (v) => setState(() => _endAt = v)),
              const SizedBox(height: 12),
              _DarkInput(controller: _memo, hint: '메모', maxLines: 6),
              const SizedBox(height: 20),
              if (widget.initial != null)
                TextButton(
                  onPressed: widget.onDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('일정 삭제'),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF504A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _save,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAutoTimeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('자동 시간 계산 알림', style: TextStyle(color: Colors.white)),
        content: const Text('이 기능을 켜면 위치/일정에 따라 소요 시간을 예측해 시작 전 알림을 드립니다.', style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LocationPickerSheet(),
    );
    if (picked != null) setState(() => _location.text = picked);
  }

  Future<void> _save() async {
    final id = widget.initial?.id ?? UniqueKey().toString();
    final event = EventItem(
      id: id,
      title: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      startAt: _startAt,
      endAt: _endAt,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      useDDay: _useDDay,
      useAutoTimeNotification: _useAutoTime,
    );
    Navigator.of(context).pop(event);
  }
}

class _GrayField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _GrayField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: const Color(0xFF717171))),
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  const _DarkInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: maxLines == 1 ? 56 : null,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          textAlign: TextAlign.start,
          textAlignVertical: maxLines == 1 ? TextAlignVertical.center : null,
          decoration: InputDecoration.collapsed(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFF9E9E9E)),
          ),
          style: GoogleFonts.inter(fontSize: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;
  const _SwitchRow({required this.label, required this.value, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing!,
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFFF504A),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPick;
  const _LocationField({required this.controller, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _GrayField(controller: controller, hint: '위치 검색')),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF504A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: onPick,
            child: const Text('검색'),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleChip({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        height: 44,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFF504A) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateTimePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(value.year - 1),
          lastDate: DateTime(value.year + 5),
        );
        if (date == null) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(_fmt(value), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _query = TextEditingController();
  final List<String> _results = [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('위치', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _DarkInput(controller: _query, hint: '장소 검색')),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF504A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _search,
                          child: const Text('검색'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final item = _results[i];
                  return ListTile(
                    title: Text(item, style: GoogleFonts.inter(color: Colors.white)),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search() {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _results
        ..clear()
        ..addAll(List.generate(6, (i) => '$q 장소 결과 ${i + 1}'));
    });
  }
}


