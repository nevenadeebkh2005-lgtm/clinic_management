import '../models/doctor_appointment_models.dart';
import '../models/doctor_profile_models.dart';
import '../models/work_schedule_models.dart';

enum DoctorHomeStatus { initial, loading, loaded, failure }

class DoctorHomeState {
  final DoctorHomeStatus status;
  final DoctorProfileInfo profile;
  final List<ClinicScheduleModel> schedule;
  final List<DoctorAppointment> upcomingAppointments;
  final int pendingMessagesCount;
  final String? errorMessage;

  const DoctorHomeState({
    this.status = DoctorHomeStatus.initial,
    this.profile = DoctorProfileInfo.empty,
    this.schedule = const [],
    this.upcomingAppointments = const [],
    this.pendingMessagesCount = 0,
    this.errorMessage,
  });

  /// هل الطبيب حدد جدول عمله بأي عيادة من عياداته؟ إذا لأ (أول دخول)،
  /// الشاشة الرئيسية بتعرض بانر "لم تقم بتحديد جدول عملك بعد" بدل
  /// خيارات فارغة.
  bool get hasConfiguredSchedule => schedule.any((s) => s.hasAnyConfiguredSession);

  /// عيادات اليوم وجلساتها (ممكن أكتر من جلسة باليوم الواحد - صباحية
  /// ومسائية مثلاً) مرتبة حسب وقت البدء - لبانر "لازم تكون هون من..
  /// لـ..".
  List<TodayClinicSlot> get todaySlots {
    final weekday = DateTime.now().weekday % 7; // DateTime: 1=Mon..7=Sun -> 0=Sun..6=Sat
    final slots = <TodayClinicSlot>[];
    for (final clinic in schedule) {
      final day = clinic.dayFor(weekday);
      for (final session in day.sessions) {
        slots.add(TodayClinicSlot(clinicName: clinic.clinicName, start: session.startTimeOfDay, end: session.endTimeOfDay));
      }
    }
    slots.sort(TodayClinicSlot.compare);
    return slots;
  }

  int get appointmentsTodayCount {
    final now = DateTime.now();
    return upcomingAppointments
        .where((a) =>
            a.dateTime.year == now.year &&
            a.dateTime.month == now.month &&
            a.dateTime.day == now.day)
        .length;
  }

  int get pendingAppointmentsCount => upcomingAppointments.length;

  DoctorAppointment? get nextAppointment {
    final upcoming = upcomingAppointments.where((a) => a.dateTime.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  DoctorHomeState copyWith({
    DoctorHomeStatus? status,
    DoctorProfileInfo? profile,
    List<ClinicScheduleModel>? schedule,
    List<DoctorAppointment>? upcomingAppointments,
    int? pendingMessagesCount,
    String? errorMessage,
  }) {
    return DoctorHomeState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      schedule: schedule ?? this.schedule,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      pendingMessagesCount: pendingMessagesCount ?? this.pendingMessagesCount,
      errorMessage: errorMessage,
    );
  }
}
