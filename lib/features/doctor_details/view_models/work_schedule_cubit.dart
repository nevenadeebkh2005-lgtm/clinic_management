import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/doctor_appointments_repository.dart';
import '../data/doctor_schedule_repository.dart';
import '../models/doctor_profile_models.dart';
import '../models/work_schedule_models.dart';
import 'work_schedule_state.dart';

class WorkScheduleCubit extends Cubit<WorkScheduleState> {
  final DoctorScheduleRepository _repository;
  final DoctorAppointmentsRepository _appointmentsRepository;
  final int doctorId;

  WorkScheduleCubit({
    required this.doctorId,
    required List<DoctorClinicRef> registeredClinics,
    DoctorScheduleRepository? repository,
    DoctorAppointmentsRepository? appointmentsRepository,
  })  : _repository = repository ?? DoctorScheduleRepository(),
        _appointmentsRepository = appointmentsRepository ?? DoctorAppointmentsRepository(),
        super(WorkScheduleState.initialFor(registeredClinics));

  Future<void> load() async {
    if (state.clinics.isEmpty) return;
    emit(state.copyWith(status: WorkScheduleStatus.loading, clearMessages: true));
    try {
      final clinic = state.selectedClinic!;
      final schedule = await _repository.getSchedule(clinic.id, clinicName: clinic.name);
      final appointments = await _appointmentsRepository.getAppointments();
      final slots = await _fetchAvailabilityWindow(clinic.id);
      final blockedTimes = await _repository.getBlockedTimes(clinic.id);
      emit(state.copyWith(
        status: WorkScheduleStatus.loaded,
        schedule: schedule,
        slots: slots,
        localAppointments: appointments,
        blockedTimes: blockedTimes,
      ));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر تحميل جدول العمل')));
    }
  }

  Future<void> selectClinic(int index) async {
    emit(state.copyWith(selectedClinicIndex: index, clearMessages: true));
    await load();
  }

  /// ⚠️ حسب توضيح الباك: الأوقات المتاحة (availability) تنجاب دايماً
  /// لمدى ثابت (اليوم -> بعد 90 يوم) مرة وحدة، مو طلب جديد لكل تاريخ
  /// يختاره الطبيب - فتغيير التاريخ المختار هلق بس فلترة محلية (بدون
  /// أي نداء شبكة إضافي)، أسرع وأدق.
  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date, clearMessages: true));
  }

  Future<List<AvailabilitySlot>> _fetchAvailabilityWindow(int clinicId) {
    final now = DateTime.now();
    return _repository.getAvailability(
      doctorId: doctorId,
      clinicId: clinicId,
      dateFrom: now,
      dateTo: now.add(const Duration(days: 90)),
    );
  }

  /// يضيف جلسة عمل (Session) جديدة لهالقسم (صباحية/بعد ظهر/مسائية) لليوم
  /// الأسبوعي المطابق للتاريخ المختار حالياً، وبيحفظ الجدول كامل بالباك،
  /// وبعدين بيولّد الـ Slots الفعلية عليه فوراً.
  Future<void> addSession(DaySection section, TimeOfDay start, TimeOfDay end) async {
    final clinic = state.selectedClinic;
    final schedule = state.schedule;
    if (clinic == null || schedule == null) return;

    final weekday = state.selectedWeekday;
    final existingDay = schedule.dayFor(weekday);
    final newSession = ScheduleSession(
      sessionType: section.sessionTypeKey,
      startTime: _fmt(start),
      endTime: _fmt(end),
    );
    final updatedSessions = existingDay.sessions.where((s) => s.sessionType != section.sessionTypeKey).toList()
      ..add(newSession);
    final updatedDay = ScheduleDay(dayOfWeek: weekday, sessions: updatedSessions);

    final updatedDays = List<ScheduleDay>.from(schedule.days)..removeWhere((d) => d.dayOfWeek == weekday);
    updatedDays.add(updatedDay);

    await _saveDaysAndRefresh(clinic.id, schedule, updatedDays);
  }

  /// يشيل الجلسة المرتبطة بهالقسم من اليوم المختار حالياً.
  Future<void> removeSession(DaySection section) async {
    final clinic = state.selectedClinic;
    final schedule = state.schedule;
    if (clinic == null || schedule == null) return;

    final weekday = state.selectedWeekday;
    final existingDay = schedule.dayFor(weekday);
    final updatedSessions = existingDay.sessions.where((s) => s.sessionType != section.sessionTypeKey).toList();
    final updatedDays = List<ScheduleDay>.from(schedule.days)..removeWhere((d) => d.dayOfWeek == weekday);
    if (updatedSessions.isNotEmpty) {
      updatedDays.add(ScheduleDay(dayOfWeek: weekday, sessions: updatedSessions));
    }

    await _saveDaysAndRefresh(clinic.id, schedule, updatedDays);
  }

  /// يحفظ القالب الأسبوعي كامل دفعة وحدة (كل الأيام يلي فعّلها الطبيب
  /// بكل جلساتها: صباح/بعد ظهر/مساء لكل يوم) - يُستخدم من شاشة "تحديد
  /// جدول العمل" (WeeklyTemplateEditorScreen).
  Future<void> saveWeeklyTemplate(
    List<ScheduleDay> days, {
    required int consultationDuration,
    required int breakDuration,
    required bool bufferEnabled,
  }) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    await _saveDaysAndRefresh(
      clinic.id,
      state.schedule ?? ClinicScheduleModel.empty(clinic.id, clinic.name),
      days,
      consultationDurationOverride: consultationDuration,
      breakDurationOverride: breakDuration,
      bufferEnabledOverride: bufferEnabled,
    );
  }

  Future<void> _saveDaysAndRefresh(
    int clinicId,
    ClinicScheduleModel schedule,
    List<ScheduleDay> updatedDays, {
    int? consultationDurationOverride,
    int? breakDurationOverride,
    bool? bufferEnabledOverride,
  }) async {
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      final saved = await _repository.saveWeeklySchedule(
        clinicId,
        consultationDuration: consultationDurationOverride ?? schedule.consultationDuration,
        breakDuration: breakDurationOverride ?? schedule.breakDuration,
        bufferEnabled: bufferEnabledOverride ?? schedule.bufferEnabled,
        days: updatedDays,
      );
      await _repository.generateSlots(
        clinicId,
        dateFrom: DateTime.now(),
        dateTo: DateTime.now().add(const Duration(days: 90)),
      );
      final slots = await _fetchAvailabilityWindow(clinicId);
      emit(state.copyWith(status: WorkScheduleStatus.loaded, schedule: saved, slots: slots, infoMessage: 'تم حفظ الجدول'));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر حفظ الجدول')));
    }
  }

  Future<void> updateDuration({required int consultationDuration, required int breakDuration, required bool bufferEnabled}) async {
    final clinic = state.selectedClinic;
    final schedule = state.schedule;
    if (clinic == null || schedule == null) return;
    await _saveDaysAndRefresh(
      clinic.id,
      schedule,
      schedule.days,
      consultationDurationOverride: consultationDuration,
      breakDurationOverride: breakDuration,
      bufferEnabledOverride: bufferEnabled,
    );
  }

  Future<void> activateVacation({required DateTime start, required DateTime end}) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.setVacation(clinic.id, startDate: start, endDate: end);
      await load();
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر تفعيل وضع الإجازة')));
    }
  }

  Future<void> deactivateVacation() async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.deactivateVacation(clinic.id);
      await load();
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر إلغاء وضع الإجازة')));
    }
  }

  Future<void> blockSlot(AvailabilitySlot slot) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.blockTimeByDate(
        clinic.id,
        date: slot.startsAt,
        startTime: _fmtDateTime(slot.startsAt),
        endTime: _fmtDateTime(slot.endsAt),
      );
      final slots = await _fetchAvailabilityWindow(clinic.id);
      final blockedTimes = await _repository.getBlockedTimes(clinic.id);
      emit(state.copyWith(status: WorkScheduleStatus.loaded, slots: slots, blockedTimes: blockedTimes, infoMessage: 'تم حجب الوقت'));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر حجب هالوقت')));
    }
  }

  /// ✅ إضافة: حجب مدى وقت بتاريخ محدد بشكل حر (بدون الحاجة لاختيار
  /// Slot جاهز من القائمة المولّدة أصلاً - عكس blockSlot).
  Future<void> blockDate({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    String? reason,
  }) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.blockTimeByDate(
        clinic.id,
        date: date,
        startTime: _fmt(start),
        endTime: _fmt(end),
        reason: reason,
      );
      final blockedTimes = await _repository.getBlockedTimes(clinic.id);
      final slots = await _fetchAvailabilityWindow(clinic.id);
      emit(state.copyWith(status: WorkScheduleStatus.loaded, slots: slots, blockedTimes: blockedTimes, infoMessage: 'تم حجب الوقت'));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر حجب هالوقت')));
    }
  }

  /// ✅ إضافة: حجب وقت متكرر بيوم أسبوعي محدد (مثلاً "كل خميس من
  /// 2-4 عصراً") - عكس blockSlot يلي بيحجب Slot محدد بتاريخ وحيد بس.
  Future<void> blockDayOfWeek({
    required int dayOfWeek,
    required TimeOfDay start,
    required TimeOfDay end,
    String? reason,
  }) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.blockTimeByDayOfWeek(
        clinic.id,
        dayOfWeek: dayOfWeek,
        startTime: _fmt(start),
        endTime: _fmt(end),
        reason: reason,
      );
      final blockedTimes = await _repository.getBlockedTimes(clinic.id);
      final slots = await _fetchAvailabilityWindow(clinic.id);
      emit(state.copyWith(status: WorkScheduleStatus.loaded, slots: slots, blockedTimes: blockedTimes, infoMessage: 'تم حجب الوقت'));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر حجب هالوقت')));
    }
  }

  /// ✅ إضافة: إلغاء حجب وقت (سواء كان بتاريخ محدد أو متكرر أسبوعياً).
  Future<void> unblockTime(int blockedTimeId) async {
    final clinic = state.selectedClinic;
    if (clinic == null) return;
    emit(state.copyWith(status: WorkScheduleStatus.saving, clearMessages: true));
    try {
      await _repository.deleteBlockedTime(blockedTimeId);
      final blockedTimes = await _repository.getBlockedTimes(clinic.id);
      final slots = await _fetchAvailabilityWindow(clinic.id);
      emit(state.copyWith(status: WorkScheduleStatus.loaded, slots: slots, blockedTimes: blockedTimes, infoMessage: 'تم إلغاء الحجب'));
    } catch (e) {
      emit(state.copyWith(status: WorkScheduleStatus.failure, errorMessage: _readable(e, 'تعذّر إلغاء الحجب')));
    }
  }

  /// بيرجع رسالة الخطأ الحقيقية القادمة من الباك (ApiException.message)
  /// لو موجودة، بدل رسالة عامة بتخفي شو صار فعلياً - أهم شي وقت
  /// التشخيص/الديباغ.
  String _readable(Object e, String fallback) {
    final text = e.toString();
    return text.isNotEmpty && text != 'Exception' ? text : fallback;
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _fmtDateTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
