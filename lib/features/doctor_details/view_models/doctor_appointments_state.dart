import '../../../core/constants/appointment_status.dart';
import '../models/doctor_appointment_models.dart';

enum DoctorAppointmentsStatus { initial, loading, loaded, failure }

class DoctorAppointmentsState {
  final DoctorAppointmentsStatus status;
  final List<DoctorAppointment> all;
  final AppointmentTabGroup selectedTab;
  final String? errorMessage;
  final String? actionErrorMessage;

  const DoctorAppointmentsState({
    this.status = DoctorAppointmentsStatus.initial,
    this.all = const [],
    this.selectedTab = AppointmentTabGroup.upcoming,
    this.errorMessage,
    this.actionErrorMessage,
  });

  List<DoctorAppointment> get visible {
    final filtered = all.where((a) => a.tabGroup == selectedTab).toList();
    filtered.sort((a, b) => selectedTab == AppointmentTabGroup.upcoming
        ? a.startsAt.compareTo(b.startsAt)
        : b.startsAt.compareTo(a.startsAt));
    return filtered;
  }

  DoctorAppointmentsState copyWith({
    DoctorAppointmentsStatus? status,
    List<DoctorAppointment>? all,
    AppointmentTabGroup? selectedTab,
    String? errorMessage,
    bool clearError = false,
    String? actionErrorMessage,
    bool clearActionError = false,
  }) {
    return DoctorAppointmentsState(
      status: status ?? this.status,
      all: all ?? this.all,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionError ? null : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }
}
