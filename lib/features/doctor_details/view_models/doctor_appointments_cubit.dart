import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/appointment_status.dart';
import '../../../core/network/api_exception.dart';
import '../data/doctor_appointments_repository.dart';
import 'doctor_appointments_state.dart';

class DoctorAppointmentsCubit extends Cubit<DoctorAppointmentsState> {
  final DoctorAppointmentsRepository _repository;

  // Guards against firing a second request for the same appointment action
  // (e.g. double-tapping "Cancel", or reopening the details sheet and
  // tapping it again while the first request is still in flight) - without
  // this, two concurrent cancel requests for the same appointment can both
  // reach the backend before either updates local state.
  final Set<String> _pendingActionKeys = {};

  DoctorAppointmentsCubit({DoctorAppointmentsRepository? repository})
      : _repository = repository ?? DoctorAppointmentsRepository(),
        super(const DoctorAppointmentsState());

  Future<void> load() async {
    emit(state.copyWith(status: DoctorAppointmentsStatus.loading, clearError: true));
    try {
      final all = await _repository.getAppointments();
      emit(state.copyWith(status: DoctorAppointmentsStatus.loaded, all: all));
    } on ApiException catch (e) {
      emit(state.copyWith(status: DoctorAppointmentsStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: DoctorAppointmentsStatus.failure, errorMessage: 'تعذّر تحميل المواعيد'));
    }
  }

  void changeTab(AppointmentTabGroup tab) => emit(state.copyWith(selectedTab: tab, clearActionError: true));

  Future<bool> start(int appointmentId) =>
      _runAction('start:$appointmentId', () => _repository.start(appointmentId));

  Future<bool> complete(int appointmentId) =>
      _runAction('complete:$appointmentId', () => _repository.complete(appointmentId));

  Future<bool> cancel(int appointmentId, {required String reason}) => _runAction(
      'cancel:$appointmentId', () => _repository.cancel(appointmentId, reason: reason));

  Future<bool> markNoShow(int appointmentId) =>
      _runAction('noshow:$appointmentId', () => _repository.markNoShow(appointmentId));

  Future<bool> _runAction(String key, Future<void> Function() action) async {
    if (_pendingActionKeys.contains(key)) return false;
    _pendingActionKeys.add(key);
    try {
      await action();
      await load();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(actionErrorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(actionErrorMessage: 'تعذّر تنفيذ الإجراء'));
      return false;
    } finally {
      _pendingActionKeys.remove(key);
    }
  }
}
