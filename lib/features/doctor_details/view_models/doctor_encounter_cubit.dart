
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../data/doctor_appointments_repository.dart';
import '../data/doctor_encounter_repository.dart';
import '../models/encounter_models.dart';
import 'doctor_encounter_state.dart';

/// ⚠️ الترتيب هون مهم: appointment.start() (checked_in -> in_progress)
/// لازم يكون صار *قبل* ما توصل هالشاشة أصلاً - EncounterService.
/// ensureCanWrite() برفض أي كتابة (note/diagnosis/prescription) إلا
/// إذا appointment.status == in_progress. فـstart() منعملها من شاشة
/// المواعيد قبل الـNavigator.push مباشرة (راجع doctor_appointments_screen).
class DoctorEncounterCubit extends Cubit<DoctorEncounterState> {
  final int appointmentId;
  final DoctorEncounterRepository _encounterRepository;
  final DoctorAppointmentsRepository _appointmentsRepository;

  DoctorEncounterCubit({
    required this.appointmentId,
    DoctorEncounterRepository? encounterRepository,
    DoctorAppointmentsRepository? appointmentsRepository,
  })  : _encounterRepository = encounterRepository ?? DoctorEncounterRepository(),
        _appointmentsRepository = appointmentsRepository ?? DoctorAppointmentsRepository(),
        super(const DoctorEncounterState());

  /// يحمّل أي توثيق سابق محفوظ فعلاً (لو الطبيب سكّر الشاشة ورجعلها
  /// بعدين وقت لسا الموعد in_progress) - المسودة الجديدة تبلش فاضية
  /// بكل الأحوال؛ هاي بس لعرض "آخر ما تحفظ" فوق. ⚠️ ما منعطّل الفورم
  /// لو فشل التحميل (مثلاً لو endpoint الـshow مش مفعّل بعد بالباك) -
  /// أهم شي الطبيب يقدر يعبّي ويسلّم، حتى لو ما قدرنا نعرض "آخر نسخة".
  Future<void> load() async {
    emit(state.copyWith(status: DoctorEncounterStatus.loading, clearError: true));
    try {
      final encounter = await _encounterRepository.show(appointmentId);
      emit(state.copyWith(status: DoctorEncounterStatus.loaded, savedEncounter: encounter));
    } catch (_) {
      emit(state.copyWith(status: DoctorEncounterStatus.loaded));
    }
  }

  void addNote(String content) {
    if (content.trim().isEmpty) return;
    emit(state.copyWith(draftNotes: [...state.draftNotes, DraftNote(content.trim())]));
  }

  void removeNoteAt(int index) {
    final updated = [...state.draftNotes]..removeAt(index);
    emit(state.copyWith(draftNotes: updated));
  }

  void addDiagnosis(String label, String? description) {
    if (label.trim().isEmpty) return;
    emit(state.copyWith(draftDiagnoses: [
      ...state.draftDiagnoses,
      DraftDiagnosis(label.trim(), description?.trim().isEmpty ?? true ? null : description!.trim()),
    ]));
  }

  void removeDiagnosisAt(int index) {
    final updated = [...state.draftDiagnoses]..removeAt(index);
    emit(state.copyWith(draftDiagnoses: updated));
  }

  void addPrescriptionItem(DraftPrescriptionItem item) {
    if (item.drugName.trim().isEmpty) return;
    emit(state.copyWith(draftItems: [...state.draftItems, item]));
  }

  void removePrescriptionItemAt(int index) {
    final updated = [...state.draftItems]..removeAt(index);
    emit(state.copyWith(draftItems: updated));
  }

  /// إنهاء الزيارة: submit (بس إذا في شي بالمسودة فعلاً - الباك برفض
  /// submit فاضي تماماً) ثم complete على الموعد نفسه (in_progress ->
  /// completed). لو ما ضاف الطبيب ولا شي، منكتفي بـcomplete لحالها.
  Future<bool> finalizeEncounter() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      if (state.hasAnyDraft) {
        final saved = await _encounterRepository.submit(
          appointmentId,
          notes: state.draftNotes,
          diagnoses: state.draftDiagnoses,
          prescriptionItems: state.draftItems,
        );
        emit(state.copyWith(savedEncounter: saved));
      }
      await _appointmentsRepository.complete(appointmentId);
      emit(state.copyWith(isSubmitting: false, isFinished: true));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, errorMessage: 'تعذّر حفظ الزيارة'));
      return false;
    }
  }
}
