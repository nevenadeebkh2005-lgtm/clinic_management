part of 'medical_overview_cubit.dart';

enum MedicalRecordLoadStatus { initial, loading, loaded, failure }

enum MedicationsFilter { active, past }

class MedicalOverviewState {
  final MedicalRecordLoadStatus status;
  final String? errorMessage;
  final int selectedTabIndex;
  final MedicationsFilter medicationsFilter;

  final PatientInfo? patientInfo;
  final List<Allergy> allergies;
  final List<ChronicCondition> chronicConditions;
  final List<Surgery> surgeries;
  final List<FamilyHistoryEntry> familyHistory;
  final List<Medication> medications;
  final List<AttachedFile> attachments;
  final List<Encounter> encounters;

  const MedicalOverviewState({
    this.status = MedicalRecordLoadStatus.initial,
    this.errorMessage,
    this.selectedTabIndex = 0,
    this.medicationsFilter = MedicationsFilter.active,
    this.patientInfo,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.surgeries = const [],
    this.familyHistory = const [],
    this.medications = const [],
    this.attachments = const [],
    this.encounters = const [],
  });

  bool get isLoading => status == MedicalRecordLoadStatus.loading;
  bool get hasError => status == MedicalRecordLoadStatus.failure;
  bool get hasLoaded => status == MedicalRecordLoadStatus.loaded;

  List<Medication> get activeMedications =>
      medications.where((m) => !m.isStopped).toList();

  List<Medication> get pastMedications =>
      medications.where((m) => m.isStopped).toList();

  RecordSummaryData get summary => RecordSummaryData(
        conditionsCount: chronicConditions.length,
        allergiesCount: allergies.length,
        medicationsCount: activeMedications.length,
        attachmentsCount: attachments.length,
      );

  // --- أحدث 3 عناصر عبر كل أقسام السجل، مرتبة حسب created_at/uploaded_at.
  // لا يوجد endpoint مخصص لـ "Recent Activity" بالباك حالياً، فبنيناها من
  // نفس البيانات الحقيقية المحمّلة أصلاً بدل تلقيمها ببيانات وهمية. ---
  List<ActivityItem> get recentActivity {
    final events = <_TimedEvent>[
      ...allergies.map((a) => _TimedEvent(
          a.createdAt, a.allergen, '${a.allergenType} • ${a.severity}', 'allergy')),
      ...chronicConditions.map((c) => _TimedEvent(
          c.createdAt, c.conditionName, 'Diagnosed: ${c.diagnosedAt}', 'condition')),
      ...surgeries.map(
          (s) => _TimedEvent(s.createdAt, s.surgeryName, s.surgeryDate, 'surgery')),
      ...familyHistory.map(
          (f) => _TimedEvent(f.createdAt, f.condition, f.relation, 'family')),
      ...medications.map((m) => _TimedEvent(
          m.createdAt, m.drugName, '${m.dosage} • ${m.frequency}', 'prescription')),
      ...attachments.map((f) =>
          _TimedEvent(f.uploadedAt, f.type, _formatBytes(f.fileSizeBytes), 'lab')),
    ]..removeWhere((e) => e.at == null);

    events.sort((a, b) => b.at!.compareTo(a.at!));

    return events
        .take(3)
        .map((e) => ActivityItem(
              title: e.title,
              subtitle: e.subtitle,
              timestamp: _formatRelative(e.at!),
              iconType: e.iconType,
            ))
        .toList();
  }

  MedicalOverviewState copyWith({
    MedicalRecordLoadStatus? status,
    String? errorMessage,
    int? selectedTabIndex,
    MedicationsFilter? medicationsFilter,
    PatientInfo? patientInfo,
    List<Allergy>? allergies,
    List<ChronicCondition>? chronicConditions,
    List<Surgery>? surgeries,
    List<FamilyHistoryEntry>? familyHistory,
    List<Medication>? medications,
    List<AttachedFile>? attachments,
    List<Encounter>? encounters,
  }) {
    return MedicalOverviewState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      medicationsFilter: medicationsFilter ?? this.medicationsFilter,
      patientInfo: patientInfo ?? this.patientInfo,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      surgeries: surgeries ?? this.surgeries,
      familyHistory: familyHistory ?? this.familyHistory,
      medications: medications ?? this.medications,
      attachments: attachments ?? this.attachments,
      encounters: encounters ?? this.encounters,
    );
  }
}

class _TimedEvent {
  final DateTime? at;
  final String title;
  final String subtitle;
  final String iconType;
  const _TimedEvent(this.at, this.title, this.subtitle, this.iconType);
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _formatRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
