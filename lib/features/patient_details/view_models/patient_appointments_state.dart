import '../../../core/constants/appointment_status.dart';
import '../models/patient_appointment_model.dart';

enum PatientAppointmentsStatus { initial, loading, loaded, failure }

class PatientAppointmentsState {
  final PatientAppointmentsStatus status;
  final List<PatientAppointment> all;
  final AppointmentTabGroup selectedTab;
  final String? errorMessage;
  final String? actionErrorMessage;
  final bool isBooking;

  const PatientAppointmentsState({
    this.status = PatientAppointmentsStatus.initial,
    this.all = const [],
    this.selectedTab = AppointmentTabGroup.upcoming,
    this.errorMessage,
    this.actionErrorMessage,
    this.isBooking = false,
  });

  List<PatientAppointment> get visible {
    final filtered = all.where((a) => a.tabGroup == selectedTab).toList();
    filtered.sort((a, b) => selectedTab == AppointmentTabGroup.upcoming
        ? a.startsAt.compareTo(b.startsAt)
        : b.startsAt.compareTo(a.startsAt));
    return filtered;
  }

  PatientAppointmentsState copyWith({
    PatientAppointmentsStatus? status,
    List<PatientAppointment>? all,
    AppointmentTabGroup? selectedTab,
    String? errorMessage,
    bool clearError = false,
    String? actionErrorMessage,
    bool clearActionError = false,
    bool? isBooking,
  }) {
    return PatientAppointmentsState(
      status: status ?? this.status,
      all: all ?? this.all,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionError ? null : (actionErrorMessage ?? this.actionErrorMessage),
      isBooking: isBooking ?? this.isBooking,
    );
  }
}
