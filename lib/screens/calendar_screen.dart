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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          '캘린더',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF6B6B),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFFF6B6B), size: 20),
              onPressed: () => _openEventEditor(context),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B6B),
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // 상단 네비게이션
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.chevron_left,
                    onTap: () => _changeMonth(-1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_visibleMonth.year}년 ${_visibleMonth.month}월',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _NavButton(
                    icon: Icons.chevron_right,
                    onTap: () => _changeMonth(1),
                  ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.15),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFFF6B6B), size: 20),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  labels[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: i == 0 ? const Color(0xFFFF6B6B) : Colors.white70,
                    fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
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
      return const SizedBox(height: 50);
    }
    final date = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
    final selected = selectedDate != null && _isSameDay(selectedDate!, date);
    final has = hasEvents(date);
    final isToday = _isSameDay(date, DateTime.now());
    
    Color circleColor;
    Color textColor;
    double borderWidth = 0;
    
    if (selected) {
      circleColor = const Color(0xFFFF6B6B);
      textColor = Colors.white;
    } else if (isToday) {
      circleColor = Colors.transparent;
      textColor = const Color(0xFFFF6B6B);
      borderWidth = 2;
    } else if (has) {
      circleColor = const Color(0xFFFF6B6B).withOpacity(0.2);
      textColor = Colors.white;
    } else {
      circleColor = Colors.transparent;
      textColor = Colors.white70;
    }

    return InkWell(
      onTap: () => onSelect(date),
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: 50,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: borderWidth > 0 ? Border.all(
                color: const Color(0xFFFF6B6B),
                width: borderWidth,
              ) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: selected || isToday ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
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
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '날짜를 선택해 주세요',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_note_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '일정이 없습니다',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      shrinkWrap: shrinkWrapped,
      physics: shrinkWrapped ? const NeverScrollableScrollPhysics() : null,
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final e = events[i];
        return InkWell(
          onTap: () => onTap(e),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Color(0xFFFF6B6B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timeRangeLabel(e),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      if (e.placeName != null && e.placeName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          e.placeName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                    onPressed: () => onEdit(e),
                  ),
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
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.access_time_rounded, text: _formatDateTimeRange(event.startAt, event.endAt)),
              if (event.placeName != null && event.placeName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.location_on_outlined, text: event.placeName!),
              ],
              if (event.memo != null && event.memo!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.notes_rounded, text: event.memo!),
              ],
              const Divider(color: Colors.white24, height: 48),
              _InfoRow(
                icon: Icons.flag_outlined,
                text: '디데이',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.useDDay ? const Color(0xFFFF6B6B).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.useDDay ? 'On' : 'Off',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: event.useDDay ? const Color(0xFFFF6B6B) : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.notifications_active_outlined,
                text: '자동 시간 계산 알림',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.useAutoTimeNotification ? const Color(0xFFFF6B6B).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.useAutoTimeNotification ? 'On' : 'Off',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: event.useAutoTimeNotification ? const Color(0xFFFF6B6B) : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B6B), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
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
  late TextEditingController _placeName;
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
    _placeName = TextEditingController(text: init?.placeName ?? '');
    _memo = TextEditingController(text: init?.memo ?? '');
    _startAt = initialDateTime;
    _endAt = init?.endAt ?? _startAt.add(const Duration(hours: 1));
    _useDDay = init?.useDDay ?? false;
    _useAutoTime = init?.useAutoTimeNotification ?? false;
    
    // 기존 위치 정보가 있으면 PlaceInfo로 변환
    if (init?.latitude != null && init?.longitude != null) {
      _selectedPlace = PlaceInfo(
        id: 'existing_location',
        name: init?.placeName ?? '',
        address: init?.placeAddress ?? '',
        latitude: init?.latitude,
        longitude: init?.longitude,
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _placeName.dispose();
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
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.initial == null ? Icons.add_circle_outline : Icons.edit_calendar,
                        color: const Color(0xFFFF6B6B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.initial == null ? '새 일정 만들기' : '일정 수정하기',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _DarkInput(
                controller: _title,
                hint: '일정 제목을 입력하세요',
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 16),
              _DarkInput(
                controller: _placeName,
                hint: '위치를 선택하거나 입력하세요',
                readOnly: false,
                onTap: _openLocationPicker,
                prefixIcon: Icons.location_on_outlined,
                suffixIcon: Icons.search,
              ),
              const SizedBox(height: 20),
              Container(
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
                    Text(
                      '알림 설정',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SwitchRow(
                      label: '디데이',
                      value: _useDDay,
                      onChanged: (v) => setState(() => _useDDay = v),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                        onPressed: () => _showDDayInfo(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SwitchRow(
                      label: '자동 시간 계산 알림',
                      value: _useAutoTime,
                      onChanged: (v) => setState(() => _useAutoTime = v),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                        onPressed: _showAutoTimeInfo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                    Text(
                      '시간 설정',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DateTimePicker(
                      label: '시작',
                      value: _startAt,
                      onChanged: (v) => setState(() => _startAt = v),
                    ),
                    const SizedBox(height: 16),
                    _DateTimePicker(
                      label: '종료',
                      value: _endAt,
                      onChanged: (v) => setState(() => _endAt = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DarkInput(
                controller: _memo,
                hint: '메모를 입력하세요 (선택사항)',
                maxLines: 4,
                prefixIcon: Icons.note,
              ),
              const SizedBox(height: 24),
              if (widget.initial != null) ...[
                Container(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    label: const Text('일정 삭제'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                  ),
                  onPressed: _save,
                  child: Text(
                    '저장',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDDayInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '디데이',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '목표와 연동하여 디데이를 표시합니다. 목표 화면에서 설정한 마감일을 기준으로 남은 일수를 계산하여 보여줍니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoTimeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '자동 시간 계산 알림',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '이 기능을 켜면 위치/일정에 따라 소요 시간을 예측해 시작 전 알림을 드립니다. 교통 상황과 거리를 고려하여 정확한 출발 시간을 제안합니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
        initialLocation: _placeName.text.trim().isEmpty ? null : _placeName.text,
      ),
    );
    if (picked != null) {
      setState(() {
        _placeName.text = picked.name;
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

    // 기존 일정인지 새 일정인지 확인
    final isExistingEvent = widget.initial != null;
    final eventId = isExistingEvent ? widget.initial!.id : 'new';
    
    print('💾 일정 저장 시작');
    print('   🆔 이벤트 ID: $eventId');
    print('   📝 기존 일정 여부: $isExistingEvent');
    if (isExistingEvent) {
      print('   📋 기존 일정 정보: ${widget.initial!.toJson()}');
    }

    final event = EventItem(
      id: eventId,
      title: _title.text.trim(),
      startAt: _startAt,
      endAt: _endAt,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      useDDay: _useDDay,
      useAutoTimeNotification: _useAutoTime,
      location: _selectedPlace?.toLocationInfo(),
    );
    
    print('   ✅ 생성된 EventItem: ${event.toJson()}');
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
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  const _DarkInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: maxLines == 1 ? 56 : null,
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                prefixIcon,
                color: const Color(0xFFFF6B6B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              textAlign: TextAlign.start,
              textAlignVertical: maxLines == 1 ? TextAlignVertical.center : null,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white60,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.transparent,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                suffixIcon,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFFF6B6B),
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
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF6B6B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '위치 선택',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '일정에 맞는 위치를 검색하고 선택하세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LocationSearchWidget(
                  initialLocation: widget.initialLocation,
                  onLocationSelected: (place) {
                    Navigator.of(context).pop(place);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}