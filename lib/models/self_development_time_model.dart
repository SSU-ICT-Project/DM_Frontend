class SelfDevelopmentTimeModel {
  final Map<String, List<TimeSlot>> weeklySchedule;

  SelfDevelopmentTimeModel({required this.weeklySchedule});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    weeklySchedule.forEach((day, timeSlots) {
      data[day] = timeSlots.map((slot) => slot.toJson()).toList();
    });
    return data;
  }

  factory SelfDevelopmentTimeModel.fromJson(Map<String, dynamic> json) {
    final Map<String, List<TimeSlot>> schedule = {};
    json.forEach((day, slots) {
      if (slots is List) {
        schedule[day] = slots.map((slot) => TimeSlot.fromJson(slot)).toList();
      }
    });
    return SelfDevelopmentTimeModel(weeklySchedule: schedule);
  }

  // 빈 스케줄인지 확인
  bool get isEmpty => weeklySchedule.isEmpty;
  
  // 전체 시간대 수 반환
  int get totalTimeSlots {
    int total = 0;
    weeklySchedule.values.forEach((slots) => total += slots.length);
    return total;
  }
  
  // 특정 요일에 시간대가 있는지 확인
  bool hasTimeSlotsForDay(String day) {
    return weeklySchedule.containsKey(day) && weeklySchedule[day]!.isNotEmpty;
  }

  @override
  String toString() {
    return 'SelfDevelopmentTimeModel(weeklySchedule: $weeklySchedule)';
  }
}

class TimeSlot {
  final String start;
  final String end;

  TimeSlot({required this.start, required this.end});

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }

  @override
  String toString() {
    return 'TimeSlot(start: $start, end: $end)';
  }

  bool get isValid {
    if (start.isEmpty || end.isEmpty) return false;
    
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');
      
      if (startParts.length != 2 || endParts.length != 2) return false;
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      if (startHour < 0 || startHour > 23 || startMinute < 0 || startMinute > 59 ||
          endHour < 0 || endHour > 23 || endMinute < 0 || endMinute > 59) {
        return false;
      }
      
      // 시작 시간이 종료 시간보다 늦으면 안됨
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;
      
      return startMinutes < endMinutes;
    } catch (e) {
      return false;
    }
  }
}
