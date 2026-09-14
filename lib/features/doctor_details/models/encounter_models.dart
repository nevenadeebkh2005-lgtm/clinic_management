// =============================================
// نماذج الـEncounter (توثيق الزيارة السريرية) - جهة الطبيب.
// مطابقة حرفياً لـ EncounterResource / ClinicalNoteResource /
// DiagnosisResource / PrescriptionResource (Modules/Encounters/Resources).
//
// ⚠️ ملاحظات مهمة بنيت عليها هالملف:
// - الباك أكّد: نقطة الحفظ الوحيدة المعتمدة هي submit (طلب واحد يجمع
//   notes/diagnoses/prescription_items) - endpoints الفردية
//   (storeNote/storeDiagnosis/storePrescriptionItem) موجودة بالراوت بس
//   مو المطلوب استخدامها من الواجهة.
// - لا يوجد أي دعم لمرفقات (attachments) داخل الـEncounter إطلاقاً - لا
//   بـSubmitEncounterRequest ولا بـEncounterService. فالمرفقات يلي
//   بيضيفها الطبيب لازم تمر من نفس مسار المريض العادي
//   (medical-record/attachments)، مش من هون.
// - Diagnosis.label نص حر بدون أي قيد ICD-10 حقيقي على مستوى الباك.
// =============================================

class ClinicalNote {
  final int id;
  final String content;
  final int? doctorId;
  final DateTime? createdAt;

  const ClinicalNote({
    required this.id,
    required this.content,
    this.doctorId,
    this.createdAt,
  });

  factory ClinicalNote.fromJson(Map<String, dynamic> json) => ClinicalNote(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        content: json['content']?.toString() ?? '',
        doctorId: json['doctor_id'] is int ? json['doctor_id'] as int : int.tryParse('${json['doctor_id']}'),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class Diagnosis {
  final int id;
  final String label;
  final String? description;
  final int? doctorId;
  final DateTime? createdAt;

  const Diagnosis({
    required this.id,
    required this.label,
    this.description,
    this.doctorId,
    this.createdAt,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) => Diagnosis(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        label: json['label']?.toString() ?? '',
        description: json['description']?.toString(),
        doctorId: json['doctor_id'] is int ? json['doctor_id'] as int : int.tryParse('${json['doctor_id']}'),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class PrescriptionItem {
  final int id;
  final String? drugName; // PrescriptionResource بيرجعها كنص (item.drug?.name) مو object
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? notes;

  const PrescriptionItem({
    required this.id,
    this.drugName,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.notes,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) => PrescriptionItem(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        drugName: json['drug']?.toString(),
        dosage: json['dosage']?.toString(),
        frequency: json['frequency']?.toString(),
        duration: json['duration']?.toString(),
        route: json['route']?.toString(),
        notes: json['notes']?.toString(),
      );
}

class Prescription {
  final int id;
  final String? notes;
  final List<PrescriptionItem> items;

  const Prescription({required this.id, this.notes, this.items = const []});

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        notes: json['notes']?.toString(),
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => PrescriptionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class Encounter {
  final int id;
  final int appointmentId;
  final String? visitType;
  final List<ClinicalNote> clinicalNotes;
  final List<Diagnosis> diagnoses;
  final Prescription? prescription;
  final DateTime? createdAt;

  const Encounter({
    required this.id,
    required this.appointmentId,
    this.visitType,
    this.clinicalNotes = const [],
    this.diagnoses = const [],
    this.prescription,
    this.createdAt,
  });

  bool get isEmpty =>
      clinicalNotes.isEmpty && diagnoses.isEmpty && (prescription?.items.isEmpty ?? true);

  /// ✅ إضافة: ملخص التشخيص المعروض بأعلى كل كارد بتاب/شاشة الـ
  /// Encounters (متل "Diagnosis Summary" بالتصميم المرجعي).
  String get diagnosisSummary {
    if (diagnoses.isEmpty) return '';
    return diagnoses.map((d) => d.label).join(' • ');
  }

  factory Encounter.fromJson(Map<String, dynamic> json) => Encounter(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        appointmentId: json['appointment_id'] is int
            ? json['appointment_id'] as int
            : int.tryParse('${json['appointment_id']}') ?? 0,
        visitType: json['visit_type']?.toString(),
        clinicalNotes: (json['clinical_notes'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ClinicalNote.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        diagnoses: (json['diagnoses'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Diagnosis.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        prescription: json['prescription'] is Map
            ? Prescription.fromJson(Map<String, dynamic>.from(json['prescription']))
            : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

// =============================================
// مسودات محلية (Draft) - قبل الإرسال بـsubmit واحد. مو من الباك،
// فقط حالة الواجهة أثناء تعبئة الطبيب للفورم.
// =============================================
class DraftNote {
  final String content;
  const DraftNote(this.content);
  Map<String, dynamic> toJson() => {'content': content};
}

class DraftDiagnosis {
  final String label;
  final String? description;
  const DraftDiagnosis(this.label, [this.description]);
  Map<String, dynamic> toJson() => {
        'label': label,
        if (description != null && description!.trim().isNotEmpty) 'description': description,
      };
}

class DraftPrescriptionItem {
  final String drugName;
  final String? form;
  final String? strength;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route; // ⚠️ لازم يطابق حرفياً إحدى قيم MedicationRoute::values() بالباك
  final String? notes;

  const DraftPrescriptionItem({
    required this.drugName,
    this.form,
    this.strength,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'drug_name': drugName,
        if (form != null && form!.isNotEmpty) 'form': form,
        if (strength != null && strength!.isNotEmpty) 'strength': strength,
        if (dosage != null && dosage!.isNotEmpty) 'dosage': dosage,
        if (frequency != null && frequency!.isNotEmpty) 'frequency': frequency,
        if (duration != null && duration!.isNotEmpty) 'duration': duration,
        if (route != null && route!.isNotEmpty) 'route': route,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
