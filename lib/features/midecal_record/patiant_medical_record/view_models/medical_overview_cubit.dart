import 'package:bloc/bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/medical_record_repository.dart';
import '../../initial_medical_records/models/medical_history_models.dart';
import '../../initial_medical_records/models/medication_model.dart';
import '../../initial_medical_records/models/attached_model.dart';
import '../models/medical_record_models/dashboard_overview_models.dart';
import '../../../doctor_details/models/encounter_models.dart';

part 'medical_overview_state.dart';

// =============================================
// MedicalOverviewCubit
// المسؤول عن تغذية شاشة "Patient Medical Record" بالكامل (Overview +
// History + Medications + Attachments) بنداء واحد فقط لـ
// GET /patient/medical-record بدل نداء منفصل لكل تاب - بالضبط نفس
// أسلوب ReviewSubmitCubit بموديول initial_medical_records.
//
// ⚠️ ملاحظة مهمة: بيانات المريض الأساسية (الاسم/تاريخ الميلاد/فصيلة
// الدم...) مو من هون - ما في endpoint حالياً يرجعها لوحدها (بس تجي
// جوا user object وقت /auth/login أو /auth/complete-profile). مرر
// قيمتها الابتدائية عبر initialPatientInfo، أو نادِ setPatientInfo()
// فور ما توصلك من الـ Auth/User Cubit الموجود عندك بالتطبيق.
// =============================================
class MedicalOverviewCubit extends Cubit<MedicalOverviewState> {
  final MedicalRecordRepository _repository;

  MedicalOverviewCubit({
    MedicalRecordRepository? repository,
    PatientInfo? initialPatientInfo,
  })  : _repository = repository ?? MedicalRecordRepository(),
        super(MedicalOverviewState(patientInfo: initialPatientInfo));

  // --- تحميل/تحديث السجل الطبي كامل ---
  // silent=true تُستخدم بعد أي عملية تعديل (stop/delete) حتى ما تصير
  // شاشة تحميل كاملة مزعجة - بس تحديث هادئ بالخلفية.
  Future<void> loadMedicalRecord({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: MedicalRecordLoadStatus.loading, errorMessage: null));
    }
    try {
      final record = await _repository.getFullMedicalRecord();
      final medicalHistory = record['medical_history'] as Map<String, dynamic>? ?? {};

      List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
        return ((raw as List?) ?? [])
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }

      emit(state.copyWith(
        status: MedicalRecordLoadStatus.loaded,
        allergies: parseList(medicalHistory['allergies'], Allergy.fromJson),
        chronicConditions:
            parseList(medicalHistory['chronic_conditions'], ChronicCondition.fromJson),
        surgeries: parseList(medicalHistory['surgeries'], Surgery.fromJson),
        familyHistory: parseList(medicalHistory['family_history'], FamilyHistoryEntry.fromJson),
        medications: parseList(record['medications'], Medication.fromJson),
        attachments: parseList(record['attachments'], AttachedFile.fromJson),
        encounters: parseList(record['encounters'], Encounter.fromJson),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MedicalRecordLoadStatus.failure, errorMessage: e.message));
    }
  }

  // --- التبديل بين التابات: Overview / History / Medications / Attachments
  // هذا هو أساس التنقل الجديد بدل Navigator.push بين شاشات منفصلة ---
  void changeTab(int index) => emit(state.copyWith(selectedTabIndex: index));

  void setMedicationsFilter(MedicationsFilter filter) =>
      emit(state.copyWith(medicationsFilter: filter));

  // --- نادِها من main_layout_screen (أو أي مكان عندك بيوصلك منه
  // المستخدم المسجّل دخوله) فور ما تتوفر بياناته، مثال:
  // context.read<MedicalOverviewCubit>().setPatientInfo(
  //   PatientInfo.fromUserJson(authState.user),
  // ); ---
  void setPatientInfo(PatientInfo info) => emit(state.copyWith(patientInfo: info));

  Future<void> stopMedication(int id, {String? reason}) async {
    try {
      await _repository.stopMedication(id, reason: reason);
      await loadMedicalRecord(silent: true);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _repository.deleteMedication(id);
      await loadMedicalRecord(silent: true);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  // --- إرجاع bytes الملف عبر الطلب المصادق (Bearer token) بدل فتح
  // download_url مباشرة بمتصفح خارجي (اللي رح يفشل بدون التوكن).
  // الطبقة اللي فوق (UI) هي المسؤولة عن حفظ/فتح الملف محلياً. ---
  Future<List<int>?> downloadAttachment(int id) async {
    try {
      return await _repository.downloadAttachmentBytes(id);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return null;
    }
  }

  Future<void> deleteAttachment(int id) async {
    try {
      await _repository.deleteAttachment(id);
      await loadMedicalRecord(silent: true);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
