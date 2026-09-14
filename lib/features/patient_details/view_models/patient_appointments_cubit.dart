import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/appointment_status.dart';
import '../../../core/network/api_exception.dart';
import '../data/patient_appointments_repository.dart';
import '../models/patient_appointment_model.dart';
import 'patient_appointments_state.dart';

class PatientAppointmentsCubit extends Cubit<PatientAppointmentsState> {
  final PatientAppointmentsRepository _repository;

  // Guards against firing a second cancel request for the same appointment
  // (double-tapping "Cancel", or reopening the details sheet and tapping it
  // again while the first request is still in flight) - without this, two
  // concurrent cancel requests for the same appointment can both reach the
  // backend before either updates local state.
  final Set<int> _pendingCancelIds = {};

  PatientAppointmentsCubit({PatientAppointmentsRepository? repository})
      : _repository = repository ?? PatientAppointmentsRepository(),
        super(const PatientAppointmentsState());

  Future<void> load() async {
    emit(state.copyWith(status: PatientAppointmentsStatus.loading, clearError: true));
    try {
      final all = await _repository.getAppointments();
      emit(state.copyWith(status: PatientAppointmentsStatus.loaded, all: all));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PatientAppointmentsStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: PatientAppointmentsStatus.failure, errorMessage: 'تعذّر تحميل الحجوزات'));
    }
  }

  void changeTab(AppointmentTabGroup tab) => emit(state.copyWith(selectedTab: tab, clearActionError: true));

  Future<bool> cancel(int appointmentId, {required String reason}) async {
    if (_pendingCancelIds.contains(appointmentId)) return false;
    _pendingCancelIds.add(appointmentId);
    try {
      await _repository.cancel(appointmentId, reason: reason);
      await load();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(actionErrorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(actionErrorMessage: 'تعذّر إلغاء الموعد'));
      return false;
    } finally {
      _pendingCancelIds.remove(appointmentId);
    }
  }

  Future<PatientAppointment?> reschedule({required int appointmentId, required int newSlotId}) async {
    try {
      final updated = await _repository.reschedule(appointmentId: appointmentId, newSlotId: newSlotId);
      await load();
      return updated;
    } on ApiException catch (e) {
      emit(state.copyWith(actionErrorMessage: e.message));
      return null;
    } catch (_) {
      emit(state.copyWith(actionErrorMessage: 'تعذّر تعديل الموعد'));
      return null;
    }
  }
}
