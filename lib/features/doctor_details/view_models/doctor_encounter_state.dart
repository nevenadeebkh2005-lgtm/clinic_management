import '../models/encounter_models.dart';

enum DoctorEncounterStatus { initial, loading, loaded, failure }

class DoctorEncounterState {
  final DoctorEncounterStatus status;
  final Encounter? savedEncounter; // آخر نسخة محفوظة فعلياً بالباك (من show أو submit)
  final List<DraftNote> draftNotes;
  final List<DraftDiagnosis> draftDiagnoses;
  final List<DraftPrescriptionItem> draftItems;
  final bool isSubmitting;
  final bool isFinished; // خلص submit + complete بنجاح
  final String? errorMessage;

  const DoctorEncounterState({
    this.status = DoctorEncounterStatus.initial,
    this.savedEncounter,
    this.draftNotes = const [],
    this.draftDiagnoses = const [],
    this.draftItems = const [],
    this.isSubmitting = false,
    this.isFinished = false,
    this.errorMessage,
  });

  bool get hasAnyDraft =>
      draftNotes.isNotEmpty || draftDiagnoses.isNotEmpty || draftItems.isNotEmpty;

  DoctorEncounterState copyWith({
    DoctorEncounterStatus? status,
    Encounter? savedEncounter,
    List<DraftNote>? draftNotes,
    List<DraftDiagnosis>? draftDiagnoses,
    List<DraftPrescriptionItem>? draftItems,
    bool? isSubmitting,
    bool? isFinished,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DoctorEncounterState(
      status: status ?? this.status,
      savedEncounter: savedEncounter ?? this.savedEncounter,
      draftNotes: draftNotes ?? this.draftNotes,
      draftDiagnoses: draftDiagnoses ?? this.draftDiagnoses,
      draftItems: draftItems ?? this.draftItems,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFinished: isFinished ?? this.isFinished,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
