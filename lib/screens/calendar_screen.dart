// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../widgets/app_bottom_nav.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../widgets/location_search_widget.dart';
import '../services/location_service.dart';
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
  bool _isLoading = true;
  Timer? _prefetchTimer;
  final Set<String> _fetchedMonths = {};

  @override
  void initState() {
    super.initState();
    _fetchEventsForMonth(showLoading: true);
  }

  @override
  void dispose() {
    _prefetchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEventsForMonth({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final yearMonth = '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}';

    if (_fetchedMonths.contains(yearMonth)) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _triggerPrefetch();
      return;
    }

    try {
      final events = await ApiService.getSchedulesByMonth(yearMonth);
      _updateEventsMap(_visibleMonth, events);
      _fetchedMonths.add(yearMonth);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정을 불러오는 데 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
      _triggerPrefetch();
    }
  }

  void _triggerPrefetch() {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(const Duration(milliseconds: 500), () {
      _prefetchMonth(_visibleMonth.month - 1, _visibleMonth.year);
      _prefetchMonth(_visibleMonth.month + 1, _visibleMonth.year);
    });
  }

  Future<void> _prefetchMonth(int month, int year) async {
    final prefetchDate = DateTime(year, month);
    final yearMonth = '${prefetchDate.year}-${prefetchDate.month.toString().padLeft(2, '0')}';

    if (_fetchedMonths.contains(yearMonth)) {
      return;
    }

    try {
      print('Prefetching $yearMonth...');
      final events = await ApiService.getSchedulesByMonth(yearMonth);
      _updateEventsMap(prefetchDate, events);
      _fetchedMonths.add(yearMonth);
    } catch (e) {
      print('Prefetch failed for $yearMonth: $e');
    }
  }

  void _updateEventsMap(DateTime month, List<EventItem> events) {
    _eventsByDate.removeWhere((key, value) => key.year == month.year && key.month == month.month);

    for (var event in events) {
      final key = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
      _eventsByDate.putIfAbsent(key, () => []).add(event);
    }
  }

  List<EventItem> _eventsOf(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final events = List<EventItem>.from(_eventsByDate[key] ?? []);
    events.sort((a, b) => a.startAt.compareTo(b.startAt));
    return events;
  }

  void _changeMonth(int diff) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + diff);
      _selectedDate = null;
    });
    _fetchEventsForMonth(showLoading: true);
  }

  void _addEventOptimistic(EventItem event) {
    final key = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
    setState(() {
      _eventsByDate.putIfAbsent(key, () => []).add(event);
    });
  }

  void _removeEventOptimistic(EventItem event) {
    final key = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
    setState(() {
      _eventsByDate[key]?.removeWhere((e) => e.id == event.id);
    });
  }

  void _updateEventOptimistic(EventItem oldEvent, EventItem newEvent) {
    final oldKey = DateTime(oldEvent.startAt.year, oldEvent.startAt.month, oldEvent.startAt.day);
    setState(() {
      _eventsByDate[oldKey]?.removeWhere((e) => e.id == oldEvent.id);
    });

    final newKey = DateTime(newEvent.startAt.year, newEvent.startAt.month, newEvent.startAt.day);
    setState(() {
      _eventsByDate.putIfAbsent(newKey, () => []).add(newEvent);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF504A)))
          : SingleChildScrollView(
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
              onTap: (e) => _openEventViewer(context, event: e),
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
              PageRouteBuilder(pageBuilder: (_, __, ___) => const GoalsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero),
                  (route) => false,
            );
          }
          if (i == 2) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(pageBuilder: (_, __, ___) => const SettingsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero),
                  (route) => false,
            );
          }
        },
      ),
    );
  }

  Future<void> _openEventViewer(BuildContext context, {required EventItem event}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EventViewerSheet(event: event),
    );
  }

  Future<void> _openEventEditor(BuildContext context, {EventItem? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EventEditorSheet(
        initial: existing,
        selectedDate: _selectedDate ?? DateTime.now(),
      ),
    );

    if (result == null || !mounted) return;

    final action = result['action'];
    final event = result['event'] as EventItem?;

    if (action == 'save' && event != null) {
      if (existing == null) {
        final tempEvent = event.copyWith(id: 'temp_${DateTime.now().millisecondsSinceEpoch}');
        _addEventOptimistic(tempEvent);
        try {
          await ApiService.createSchedule(event);
          final yearMonth = '${event.startAt.year}-${event.startAt.month.toString().padLeft(2, '0')}';
          _fetchedMonths.remove(yearMonth);
          await _fetchEventsForMonth();
        } catch (e) {
          _removeEventOptimistic(tempEvent);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('일정 추가 실패: $e')));
        }
      } else {
        final oldYearMonth = '${existing.startAt.year}-${existing.startAt.month.toString().padLeft(2, '0')}';
        final newYearMonth = '${event.startAt.year}-${event.startAt.month.toString().padLeft(2, '0')}';
        _fetchedMonths.remove(oldYearMonth);
        _fetchedMonths.remove(newYearMonth);

        _updateEventOptimistic(existing, event);
        try {
          await ApiService.updateSchedule(event);
          await _fetchEventsForMonth();
        } catch (e) {
          _updateEventOptimistic(event, existing);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('일정 수정 실패: $e')));
        }
      }
    } else if (action == 'delete' && existing != null) {
      _removeEventOptimistic(existing);
      try {
        await ApiService.deleteSchedule(existing.id);
      } catch (e) {
        _addEventOptimistic(existing);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('일정 삭제 실패: $e')));
      }
    }
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
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8)),
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
                child: Text(labels[i],
                    style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
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
    final firstWeekday = firstDayOfMonth.weekday % 7;
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
  final int firstWeekday;
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
  final void Function(EventItem e) onTap;
  final void Function(EventItem e) onEdit;
  final bool shrinkWrapped;

  const _EventList({
    required this.date,
    required this.events,
    required this.onTap,
    required this.onEdit,
    this.shrinkWrapped = false,
  });

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Center(
          child: Text('날짜를 선택해 주세요',
              style: GoogleFonts.inter(color: Colors.white54)));
    }
    if (events.isEmpty) {
      return Center(
          child: Text('일정이 없습니다',
              style: GoogleFonts.inter(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shrinkWrap: shrinkWrapped,
      physics: shrinkWrapped ? const NeverScrollableScrollPhysics() : null,
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = events[i];
        return InkWell(
          onTap: () => onTap(e),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_timeRangeLabel(e),
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(e.title,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      if (e.location != null && e.location!.isNotEmpty)
                        Text(e.location!,
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () => onEdit(e),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeRangeLabel(EventItem e) {
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${hhmm(e.startAt)} - ${hhmm(e.endAt)}';
  }
}

class _EventViewerSheet extends StatelessWidget {
  final EventItem event;
  const _EventViewerSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Center(
                child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Text(
                  event.title,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)
              ),
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.access_time_rounded, text: _formatDateTimeRange(event.startAt, event.endAt)),
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.location_on_outlined, text: event.location!),
              ],
              if (event.memo != null && event.memo!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.notes_rounded, text: event.memo!),
              ],
              const Divider(color: Colors.white24, height: 48),
              _InfoRow(icon: Icons.flag_outlined, text: '디데이', trailing: Text(event.useDDay ? 'On' : 'Off', style: GoogleFonts.inter(color: Colors.white))),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.notifications_active_outlined, text: '자동 시간 계산 알림', trailing: Text(event.useAutoTimeNotification ? 'On' : 'Off', style: GoogleFonts.inter(color: Colors.white))),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTimeRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    String datePart(DateTime d) => '${d.year}.${two(d.month)}.${two(d.day)}';
    String timePart(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${datePart(start)}\n${timePart(start)} - ${timePart(end)}';
    } else {
      return '${datePart(start)} ${timePart(start)}\n-\n${datePart(end)} ${timePart(end)}';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
              text,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5)
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EventEditorSheet extends StatefulWidget {
  final EventItem? initial;
  final DateTime selectedDate;

  const _EventEditorSheet({this.initial, required this.selectedDate});

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
  PlaceInfo? _selectedPlace;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    final now = DateTime.now();
    final initialDateTime = init?.startAt ??
        DateTime(widget.selectedDate.year, widget.selectedDate.month,
            widget.selectedDate.day, now.hour, 0);

    _title = TextEditingController(text: init?.title ?? '');
    _location = TextEditingController(text: init?.location ?? '');
    _memo = TextEditingController(text: init?.memo ?? '');
    _startAt = initialDateTime;
    _endAt = init?.endAt ?? _startAt.add(const Duration(hours: 1));
    _useDDay = init?.useDDay ?? false;
    _useAutoTime = init?.useAutoTimeNotification ?? false;
    
    // 기존 위치 정보가 있으면 PlaceInfo로 변환
    if (init?.latitude != null && init?.longitude != null) {
      _selectedPlace = PlaceInfo(
        id: 'existing_location',
        name: init?.placeName ?? init?.location ?? '',
        address: init?.placeAddress ?? init?.location ?? '',
        latitude: init?.latitude,
        longitude: init?.longitude,
      );
    }
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
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
            children: [
              Center(
                child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 12),
              Text(widget.initial == null ? '일정' : '일정',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
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
              _DateTimePicker(
                  label: '시작',
                  value: _startAt,
                  onChanged: (v) => setState(() => _startAt = v)),
              const SizedBox(height: 12),
              _DateTimePicker(
                  label: '종료',
                  value: _endAt,
                  onChanged: (v) => setState(() => _endAt = v)),
              const SizedBox(height: 12),
              _DarkInput(controller: _memo, hint: '메모', maxLines: 6),
              const SizedBox(height: 20),
              if (widget.initial != null)
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('일정 삭제'),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF504A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
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
        content: const Text(
            '이 기능을 켜면 위치/일정에 따라 소요 시간을 예측해 시작 전 알림을 드립니다.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인'))
        ],
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final picked = await showModalBottomSheet<PlaceInfo?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(
        initialLocation: _location.text.trim().isEmpty ? null : _location.text,
      ),
    );
    if (picked != null) {
      setState(() {
        _location.text = '${picked.name} (${picked.address})';
        _selectedPlace = picked;
      });
    }
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }

    final event = EventItem(
      id: widget.initial?.id ?? 'new',
      title: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      startAt: _startAt,
      endAt: _endAt,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      useDDay: _useDDay,
      useAutoTimeNotification: _useAutoTime,
      latitude: _selectedPlace?.latitude,
      longitude: _selectedPlace?.longitude,
      placeName: _selectedPlace?.name,
      placeAddress: _selectedPlace?.address,
    );
    Navigator.of(context).pop({'action': 'save', 'event': event});
  }

  void _delete() {
    Navigator.of(context).pop({'action': 'delete', 'event': widget.initial});
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
      decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(12)),
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9E9E9E)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: const Color(0xFF2B2B2B),
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
  const _SwitchRow(
      {required this.label,
        required this.value,
        required this.onChanged,
        this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600))),
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

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateTimePicker(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(value.year - 5),
          lastDate: DateTime(value.year + 5),
        );
        if (date == null) return;
        if (!context.mounted) return;
        final time = await showTimePicker(
            context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onChanged(
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(_fmt(value),
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
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
  final String? initialLocation;
  
  const _LocationPickerSheet({this.initialLocation});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('위치 선택',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  LocationSearchWidget(
                    initialLocation: widget.initialLocation,
                    onLocationSelected: (place) {
                      Navigator.of(context).pop(place);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}