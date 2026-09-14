import 'package:flutter/material.dart';

/// ⚠️ هاي الموديلات مبنية بالكامل من رد الباك الحقيقي (Postman collection
/// المحدّث - مجلد "Schedule") - GET/PUT /doctor/schedule/{clinic}،
/// generate-slots، vacation، blocked-times، و GET /doctors/{id}/availability.

/// جلسة عمل واحدة جوا يوم أسبوعي (مثلاً: صباحية 09:00-13:00).
class ScheduleSession {
  final int? id;
  final String sessionType; // morning / afternoon / evening
  final String startTime; // "HH:mm" أو "HH:mm:ss"
  final String endTime;

  const ScheduleSession({
    this.id,
    required this.sessionType,
    required this.startTime,
    required this.endTime,
  });

  TimeOfDay get startTimeOfDay => _parseTime(startTime);
  TimeOfDay get endTimeOfDay => _parseTime(endTime);

  static TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  factory ScheduleSession.fromJson(Map<String, dynamic> json) => ScheduleSession(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
        sessionType: json['session_type']?.toString() ?? 'morning',
        startTime: json['start_time']?.toString() ?? '00:00',
        endTime: json['end_time']?.toString() ?? '00:00',
      );

  Map<String, dynamic> toJson() => {
        'session_type': sessionType,
        'start_time': startTime.length >= 5 ? startTime.substring(0, 5) : startTime,
        'end_time': endTime.length >= 5 ? endTime.substring(0, 5) : endTime,
      };
}

/// يوم أسبوعي واحد (day_of_week: 0=الأحد ... 6=السبت - قياسي Laravel/Carbon)
/// وممكن يحتوي أكتر من جلسة (صباحية + مسائية مثلاً).
class ScheduleDay {
  final int? id;
  final int dayOfWeek;
  final List<ScheduleSession> sessions;

  const ScheduleDay({this.id, required this.dayOfWeek, this.sessions = const []});

  factory ScheduleDay.fromJson(Map<String, dynamic> json) => ScheduleDay(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
        dayOfWeek: json['day_of_week'] is int ? json['day_of_week'] as int : int.tryParse('${json['day_of_week']}') ?? 0,
        sessions: json['sessions'] is List
            ? (json['sessions'] as List).map((e) => ScheduleSession.fromJson(e as Map<String, dynamic>)).toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
}

/// جدول عمل الطبيب الكامل بعيادة واحدة - نفس شكل رد GET/PUT
/// /doctor/schedule/{clinic} بالضبط.
class ClinicScheduleModel {
  final int id;
  final int clinicId;
  final String clinicName;
  final int consultationDuration; // بالدقائق
  final int breakDuration; // بالدقائق
  final bool bufferEnabled;
  final int? maxPatients;
  final bool isOnVacation;
  final String? vacationStartDate;
  final String? vacationEndDate;
  final bool isActive;
  final List<ScheduleDay> days;

  const ClinicScheduleModel({
    required this.id,
    required this.clinicId,
    this.clinicName = '',
    this.consultationDuration = 30,
    this.breakDuration = 10,
    this.bufferEnabled = true,
    this.maxPatients,
    this.isOnVacation = false,
    this.vacationStartDate,
    this.vacationEndDate,
    this.isActive = true,
    this.days = const [],
  });

  factory ClinicScheduleModel.empty(int clinicId, String clinicName) => ClinicScheduleModel(
        id: 0,
        clinicId: clinicId,
        clinicName: clinicName,
      );

  bool get hasAnyConfiguredSession => days.any((d) => d.sessions.isNotEmpty);

  ScheduleDay dayFor(int dayOfWeek) => days.firstWhere(
        (d) => d.dayOfWeek == dayOfWeek,
        orElse: () => ScheduleDay(dayOfWeek: dayOfWeek, sessions: const []),
      );

  factory ClinicScheduleModel.fromJson(Map<String, dynamic> json, {String clinicName = ''}) {
    return ClinicScheduleModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      clinicId: json['clinic_id'] is int ? json['clinic_id'] as int : int.tryParse('${json['clinic_id']}') ?? 0,
      clinicName: json['clinic_name']?.toString() ?? clinicName,
      consultationDuration: json['consultation_duration'] is int
          ? json['consultation_duration'] as int
          : int.tryParse('${json['consultation_duration']}') ?? 30,
      breakDuration: json['break_duration'] is int
          ? json['break_duration'] as int
          : int.tryParse('${json['break_duration']}') ?? 10,
      bufferEnabled: json['buffer_enabled'] as bool? ?? true,
      maxPatients: json['max_patients'] is int ? json['max_patients'] as int : int.tryParse('${json['max_patients']}'),
      isOnVacation: (json['is_on_vacation'] ?? json['is_vacation_mode']) as bool? ?? false,
      vacationStartDate: json['vacation_start_date']?.toString(),
      vacationEndDate: json['vacation_end_date']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      days: json['days'] is List
          ? (json['days'] as List).map((e) => ScheduleDay.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  ClinicScheduleModel copyWith({List<ScheduleDay>? days, int? consultationDuration, int? breakDuration, bool? bufferEnabled}) {
    return ClinicScheduleModel(
      id: id,
      clinicId: clinicId,
      clinicName: clinicName,
      consultationDuration: consultationDuration ?? this.consultationDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      bufferEnabled: bufferEnabled ?? this.bufferEnabled,
      maxPatients: maxPatients,
      isOnVacation: isOnVacation,
      vacationStartDate: vacationStartDate,
      vacationEndDate: vacationEndDate,
      isActive: isActive,
      days: days ?? this.days,
    );
  }
}

/// وقت محجوب يدوياً من الطبيب (إما بتاريخ محدد أو بيوم أسبوعي متكرر).
class BlockedTime {
  final int id;
  final String? blockDate; // "yyyy-MM-dd" - لو محدد بتاريخ معين
  final int? dayOfWeek; // 0-6 - لو متكرر كل أسبوع
  final String startTime;
  final String endTime;
  final String? reason;

  const BlockedTime({
    required this.id,
    this.blockDate,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  factory BlockedTime.fromJson(Map<String, dynamic> json) => BlockedTime(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        blockDate: json['block_date']?.toString(),
        dayOfWeek: json['day_of_week'] == null ? null : int.tryParse('${json['day_of_week']}'),
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString() ?? '',
        reason: json['reason']?.toString(),
      );
}

/// موعد فعلي متاح/محجوز (Slot مولّد) - من GET /doctors/{id}/availability.
class AvailabilitySlot {
  final int id;
  final int clinicId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status; // available / booked / blocked ...

  const AvailabilitySlot({
    required this.id,
    required this.clinicId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  bool get isAvailable => status == 'available';

  /// ⚠️ 19/8: تصحيح جوهري (Timezone) - الباك ما عنده أي مفهوم توقيت
  /// حقيقي: هو بس بيخزّن نفس الـ "HH:mm" يلي الطبيب كتبه بشاشة الجدول
  /// (مثلاً "09:00") ويرجعه بنفس اللحظة لكن معلّم بـ "+00:00" (UTC) شكلياً
  /// - يعني "09:00" يلي قصدها الطبيب بتوقيته المحلي هو نفسه، مو 09:00
  /// UTC حقيقي. لما كنا نستخدم .toLocal()، كان دارت عم يزيح الوقت
  /// بفارق توقيت الجهاز فعلياً (مثلاً +3) فتصير 09:00 تظهر 12:00 -
  /// وهيك كل الجلسة الصباحية (يلي أوقاتها المبكرة) كانت عم "تنزاح"
  /// لتطلع بقسم بعد الظهر (>=12)، بينما المسائية (متأخرة أصلاً) تضل
  /// بحدود قسمها رغم الانزياح فما كانت تبين المشكلة فيها. الحل: منستخدم
  /// نفس ساعة/دقيقة القيمة الخام متل ما إجت بدون أي تحويل توقيت.
  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        clinicId: json['clinic_id'] is int ? json['clinic_id'] as int : int.tryParse('${json['clinic_id']}') ?? 0,
        startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ?? DateTime.now(),
        endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ?? DateTime.now(),
        status: json['status']?.toString() ?? 'available',
      );
}

/// عيادة واحدة + وقتها اليوم - يُستخدم لبناء بانر "لازم تكون هون من..
/// لـ.." بلوحة الطبيب الرئيسية (Doctor Home).
class TodayClinicSlot {
  final String clinicName;
  final TimeOfDay start;
  final TimeOfDay end;

  const TodayClinicSlot({required this.clinicName, required this.start, required this.end});

  int get _startMinutes => start.hour * 60 + start.minute;

  static int compare(TodayClinicSlot a, TodayClinicSlot b) => a._startMinutes.compareTo(b._startMinutes);
}
