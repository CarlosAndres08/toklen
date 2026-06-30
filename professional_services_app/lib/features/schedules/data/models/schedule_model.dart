const dayNames = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

class ScheduleModel {
  const ScheduleModel({
    this.id = '',
    this.dayOfWeek = 0,
    this.startTime = '',
    this.endTime = '',
    this.isActive = true,
  });

  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  String get dayName => dayNames[dayOfWeek.clamp(0, 6)];

  factory ScheduleModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScheduleModel();
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}

class ScheduleCreateRequest {
  const ScheduleCreateRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };
}
