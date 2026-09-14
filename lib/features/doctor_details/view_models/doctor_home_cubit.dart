import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/appointment_status.dart';
import '../../../core/network/api_exception.dart';
import '../data/doctor_appointments_repository.dart';
import '../data/doctor_repository.dart';
import '../data/doctor_schedule_repository.dart';
import '../models/doctor_profile_models.dart';
import 'doctor_home_state.dart';

class DoctorHomeCubit extends Cubit<DoctorHomeState> {
  final DoctorRepository _doctorRepository;
  final DoctorScheduleRepository _scheduleRepository;
  final DoctorAppointmentsRepository _appointmentsRepository;

  DoctorHomeCubit({
    DoctorRepository? doctorRepository,
    DoctorScheduleRepository? scheduleRepository,
    DoctorAppointmentsRepository? appointmentsRepository,
    Map<String, dynamic>? initialUserJson,
  })  : _doctorRepository = doctorRepository ?? DoctorRepository(),
        _scheduleRepository = scheduleRepository ?? DoctorScheduleRepository(),
        _appointmentsRepository = appointmentsRepository ?? DoctorAppointmentsRepository(),
        super(DoctorHomeState(
          profile: initialUserJson != null
              ? DoctorProfileInfo.fromLoginUserJson(initialUserJson)
              : DoctorProfileInfo.empty,
        ));

  Future<void> load() async {
    emit(state.copyWith(status: DoctorHomeStatus.loading, errorMessage: null));
    try {
      // 1) بروفايل الطبيب الحقيقي (نداء فعلي GET /doctor/profile) - هو
      // اللي بيرجع عياداته اللي دخلها بالريجستر، لازم نجيبه أول شي
      // حتى نعرف لأي عيادات منحمّل الجدول.
      final profile = await _doctorRepository.getProfile();

      final schedule = await _scheduleRepository.getAllSchedules();
      final appointments = await _appointmentsRepository.getAppointments();

      emit(state.copyWith(
        status: DoctorHomeStatus.loaded,
        profile: profile,
        schedule: schedule,
        upcomingAppointments: appointments.where((a) => a.tabGroup == AppointmentTabGroup.upcoming).toList(),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: DoctorHomeStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: DoctorHomeStatus.failure, errorMessage: null));
    }
  }
}
