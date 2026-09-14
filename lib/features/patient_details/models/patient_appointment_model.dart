import '../../../core/constants/appointment_status.dart';

/// حجز المريض - نظام حجوزات حقيقي (Postman: Appointment/Patient).
class PatientAppointment {
  final int id;
  final String doctorName;
  final int? doctorId;
  final String? clinicName;
  final int? clinicId;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentApiStatus status;
  final String? notes;
  final String? cancellationReason;
  final num? price;
  final String encounterType;
  final DateTime createdAt;

  const PatientAppointment({
    required this.id,
    required this.doctorName,
    this.doctorId,
    this.clinicName,
    this.clinicId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.notes,
    this.cancellationReason,
    this.price,
    this.encounterType = 'in_person',
    required this.createdAt,
  });

  AppointmentTabGroup get tabGroup => status.tabGroup;

  /// ✅ إمكانية التعديل (Reschedule) بس إذا الموعد لسا ما صار (scheduled)
  /// وما بلّش وقته بعد.
  bool get canReschedule => status == AppointmentApiStatus.scheduled && startsAt.isAfter(DateTime.now());

  bool get canCancel => status == AppointmentApiStatus.scheduled;

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] is Map ? Map<String, dynamic>.from(json['slot']) : const <String, dynamic>{};
    final doctor = json['doctor'] is Map ? Map<String, dynamic>.from(json['doctor']) : const <String, dynamic>{};
    final clinic = json['clinic'] is Map ? Map<String, dynamic>.from(json['clinic']) : const <String, dynamic>{};
    return PatientAppointment(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      doctorName: doctor['name']?.toString() ?? '',
      doctorId: doctor['id'] is int ? doctor['id'] as int : int.tryParse('${doctor['id']}'),
      clinicName: clinic['name']?.toString(),
      clinicId: clinic['id'] is int ? clinic['id'] as int : int.tryParse('${clinic['id']}'),
      startsAt: DateTime.tryParse(slot['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(slot['ends_at']?.toString() ?? '') ?? DateTime.now(),
      status: appointmentApiStatusFromString(json['status']?.toString() ?? 'scheduled'),
      notes: json['notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      price: json['price'] is num ? json['price'] as num : num.tryParse('${json['price']}'),
      encounterType: json['encounter_type']?.toString() ?? 'in_person',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
