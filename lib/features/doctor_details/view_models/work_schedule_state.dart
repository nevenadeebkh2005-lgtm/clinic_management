import '../../../core/constants/appointment_status.dart';
import '../models/doctor_appointment_models.dart';
import '../models/doctor_profile_models.dart';
import '../models/work_schedule_models.dart';

enum WorkScheduleStatus { initial, loading, loaded, saving, failure }

/// أقسام اليوم الثلاثة يلي عم تعرضها الشاشة (Morning/Afternoon/Evening) -
/// تجميع محلي بحت (بالفرونت) حسب وقت كل Slot مولّد، لأنه رد
/// GET /doctors/{id}/availability ما بيرجع session_type مباشرة.
enum DaySection { morning, afternoon, evening }

extension DaySectionX on DaySection {
  String get sessionTypeKey {
    switch (this) {
      case DaySection.morning:
        return 'morning';
      case DaySection.afternoon:
        return 'afternoon';
      case DaySection.evening:
        return 'evening';
    }
  }
}

class WorkScheduleState {
  final WorkScheduleStatus status;
  final List<DoctorClinicRef> clinics;
  final int selectedClinicIndex;
  final ClinicScheduleModel? schedule;
  final DateTime selectedDate;
  final List<AvailabilitySlot> slots;
  final List<DoctorAppointment> localAppointments;
  // ✅ إضافة: لائحة الأوقات المحجوبة (block time) - كانت البيانات
  // موجودة بالباك (getBlockedTimes) بس ما كانت محمّلة ولا معروضة
  // بالحالة إطلاقاً.
  final List<BlockedTime> blockedTimes;
  final String? errorMessage;
  final String? infoMessage;

  const WorkScheduleState({
    this.status = WorkScheduleStatus.initial,
    this.clinics = const [],
    this.selectedClinicIndex = 0,
    this.schedule,
    required this.selectedDate,
    this.slots = const [],
    this.localAppointments = const [],
    this.blockedTimes = const [],
    this.errorMessage,
    this.infoMessage,
  });

  factory WorkScheduleState.initialFor(List<DoctorClinicRef> clinics) => WorkScheduleState(
        clinics: clinics,
        selectedDate: DateTime.now(),
      );

  DoctorClinicRef? get selectedClinic =>
      clinics.isEmpty ? null : clinics[selectedClinicIndex.clamp(0, clinics.length - 1)];

  bool get isOnVacation => schedule?.isOnVacation ?? false;

  /// اليوم الأسبوعي (0=أحد..6=سبت) المطابق للتاريخ المختار حالياً.
  int get selectedWeekday => selectedDate.weekday % 7; // DateTime: 1=Mon..7=Sun -> 0=Sun..6=Sat

  ScheduleDay? get selectedScheduleDay => schedule?.dayFor(selectedWeekday);

  ScheduleSession? sessionFor(DaySection section) {
    final day = selectedScheduleDay;
    if (day == null) return null;
    for (final s in day.sessions) {
      if (s.sessionType == section.sessionTypeKey) return s;
    }
    return null;
  }

  /// ⚠️ بما إنه slots هلق بتنجاب دفعة وحدة لمدى 90 يوم (راجع ملاحظة
  /// WorkScheduleCubit.load) بدل يوم واحد بس، لازم نفلتر هون حسب
  /// selectedDate كمان (مو بس حسب الفترة/القسم) قبل ما نعرضهم.
  List<AvailabilitySlot> slotsFor(DaySection section) {
    return slots.where((slot) {
      final sameDay = slot.startsAt.year == selectedDate.year &&
          slot.startsAt.month == selectedDate.month &&
          slot.startsAt.day == selectedDate.day;
      if (!sameDay) return false;
      final hour = slot.startsAt.hour;
      switch (section) {
        case DaySection.morning:
          return hour < 12;
        case DaySection.afternoon:
          return hour >= 12 && hour < 17;
        case DaySection.evening:
          return hour >= 17;
      }
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// يلاقي حجز محلي (Local-only - راجع ملاحظة DoctorAppointmentsRepository)
  /// يتقاطع وقته مع الـ Slot، لعرضه بشكل "محجوز" بدل "متاح".
  DoctorAppointment? appointmentOverlapping(AvailabilitySlot slot) {
    for (final a in localAppointments) {
      if (a.tabGroup != AppointmentTabGroup.upcoming) continue;
      final sameDay = a.dateTime.year == slot.startsAt.year &&
          a.dateTime.month == slot.startsAt.month &&
          a.dateTime.day == slot.startsAt.day;
      if (!sameDay) continue;
      final withinSlot = !a.dateTime.isBefore(slot.startsAt) && a.dateTime.isBefore(slot.endsAt);
      if (withinSlot) return a;
    }
    return null;
  }

  WorkScheduleState copyWith({
    WorkScheduleStatus? status,
    List<DoctorClinicRef>? clinics,
    int? selectedClinicIndex,
    ClinicScheduleModel? schedule,
    DateTime? selectedDate,
    List<AvailabilitySlot>? slots,
    List<DoctorAppointment>? localAppointments,
    List<BlockedTime>? blockedTimes,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return WorkScheduleState(
      status: status ?? this.status,
      clinics: clinics ?? this.clinics,
      selectedClinicIndex: selectedClinicIndex ?? this.selectedClinicIndex,
      schedule: schedule ?? this.schedule,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      localAppointments: localAppointments ?? this.localAppointments,
      blockedTimes: blockedTimes ?? this.blockedTimes,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearMessages ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
