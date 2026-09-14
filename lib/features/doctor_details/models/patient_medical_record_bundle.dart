import '../../midecal_record/initial_medical_records/models/attached_model.dart';
import '../../midecal_record/initial_medical_records/models/medical_history_models.dart';
import '../../midecal_record/initial_medical_records/models/medication_model.dart';

/// ✅ 19/8: السجل الطبي الكامل للمريض متل ما بيشوفه الطبيب (للقراءة
/// بس) - نفس شكل جواب GET /doctor/appointments/{id}/medical-record
/// (مطابق تماماً لجواب GET /patient/medical-record عند المريض نفسه،
/// فبنعيد استخدام نفس الموديلات - allergies/chronic_conditions/
/// surgeries/family_history/medications/attachments).
class PatientMedicalRecordBundle {
  final int? patientRecordId;
  final DateTime? recordedAt;
  final List<Allergy> allergies;
  final List<ChronicCondition> chronicConditions;
  final List<Surgery> surgeries;
  final List<FamilyHistoryEntry> familyHistory;
  final List<Medication> medications;
  final List<AttachedFile> attachments;

  const PatientMedicalRecordBundle({
    this.patientRecordId,
    this.recordedAt,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.surgeries = const [],
    this.familyHistory = const [],
    this.medications = const [],
    this.attachments = const [],
  });

  factory PatientMedicalRecordBundle.fromJson(Map<String, dynamic> json) {
    final history = json['medical_history'] is Map ? Map<String, dynamic>.from(json['medical_history']) : const <String, dynamic>{};
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return PatientMedicalRecordBundle(
      patientRecordId: json['patient_record_id'] is int ? json['patient_record_id'] as int : int.tryParse('${json['patient_record_id']}'),
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? ''),
      allergies: parseList(history['allergies'], Allergy.fromJson),
      chronicConditions: parseList(history['chronic_conditions'], ChronicCondition.fromJson),
      surgeries: parseList(history['surgeries'], Surgery.fromJson),
      familyHistory: parseList(history['family_history'], FamilyHistoryEntry.fromJson),
      medications: parseList(json['medications'], Medication.fromJson),
      attachments: parseList(json['attachments'], AttachedFile.fromJson),
    );
  }
}
