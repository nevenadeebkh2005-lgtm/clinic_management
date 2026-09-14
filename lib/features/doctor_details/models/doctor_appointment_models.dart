import '../../../core/constants/appointment_status.dart';

/// موعد محجوز من طرف مريض عبر زر "احجز الآن" - نظام الحجوزات الحقيقي
/// (Postman: Appointment/Doctor). ما عاد وهمي/محلي، صار مربوط بالباك
/// فعلياً (GET /doctor/appointments وباقي إجراءات start/complete/cancel/
/// no-show).
class DoctorAppointment {
  final int id;
  final String patientName;
  final int? patientId;
  final String? patientAvatarUrl;
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

  const DoctorAppointment({
    required this.id,
    required this.patientName,
    this.patientId,
    this.patientAvatarUrl,
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

  /// ✅ للتوافق مع الكود القديم يلي كان بيستخدم dateTime كاسم موحّد.
  DateTime get dateTime => startsAt;

  /// ✅ للتوافق مع الكود القديم يلي كان بيستخدم reason - صار notes
  /// فعلياً بالباك.
  String? get reason => notes;

  /// ✅ للتوافق مع الكود القديم - createdAt هو نفسه "تاريخ الحجز".
  DateTime get bookedAt => createdAt;

  AppointmentTabGroup get tabGroup => status.tabGroup;

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] is Map ? Map<String, dynamic>.from(json['slot']) : const <String, dynamic>{};
    final patient = json['patient'] is Map ? Map<String, dynamic>.from(json['patient']) : const <String, dynamic>{};
    final clinic = json['clinic'] is Map ? Map<String, dynamic>.from(json['clinic']) : const <String, dynamic>{};
    return DoctorAppointment(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      patientName: patient['name']?.toString() ?? '',
      patientId: patient['id'] is int ? patient['id'] as int : int.tryParse('${patient['id']}'),
      patientAvatarUrl: patient['avatar_url']?.toString(),
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
