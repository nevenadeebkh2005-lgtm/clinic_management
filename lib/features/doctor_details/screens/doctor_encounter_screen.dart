
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../models/doctor_appointment_models.dart';
import '../models/encounter_models.dart';
import '../data/doctor_encounter_repository.dart';
import '../data/doctor_appointments_repository.dart';
import '../view_models/doctor_encounter_cubit.dart';
import '../view_models/doctor_encounter_state.dart';

/// شاشة توثيق الزيارة السريرية (Encounter) - جهة الطبيب.
/// تُفتح فقط بعد appointment.start() (checked_in -> in_progress، صارت
/// من شاشة المواعيد قبل الـpush مباشرة). زر "إنهاء الزيارة" بالأسفل
/// بيعمل submit (لو في مسودة) ثم complete على الموعد (-> completed)
/// ويرجّع true للشاشة السابقة حتى تعمل refresh.
///
/// ⚠️ لا يوجد قسم مرفقات هون عمداً - الباك ما بيدعم رفع مرفقات ضمن
/// الـEncounter إطلاقاً (راجع ملاحظة encounter_models.dart). أي مرفق
/// (نتيجة تحليل مثلاً) لازم يترفع من مسار السجل الطبي العادي.
class DoctorEncounterScreen extends StatelessWidget {
  final DoctorAppointment appointment;

  const DoctorEncounterScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DoctorEncounterCubit(
        appointmentId: appointment.id,
        encounterRepository: DoctorEncounterRepository(),
        appointmentsRepository: DoctorAppointmentsRepository(),
      )..load(),
      child: _DoctorEncounterView(appointment: appointment),
    );
  }
}

class _DoctorEncounterView extends StatefulWidget {
  final DoctorAppointment appointment;
  const _DoctorEncounterView({required this.appointment});

  @override
  State<_DoctorEncounterView> createState() => _DoctorEncounterViewState();
}

class _DoctorEncounterViewState extends State<_DoctorEncounterView> {
  final _noteController = TextEditingController();
  final _diagnosisLabelController = TextEditingController();
  final _diagnosisDescController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _diagnosisLabelController.dispose();
    _diagnosisDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return BlocConsumer<DoctorEncounterCubit, DoctorEncounterState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFC0392B),
            ));
        }
        if (state.isFinished) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<DoctorEncounterCubit>();

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            foregroundColor: textColor,
            title: Text('CareFlow', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen)),
            centerTitle: true,
          ),
          body: state.status == DoctorEncounterStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context, isDark, textColor, primaryGreen),
                              SizedBox(height: 18.h),
                              _sectionCard(
                                isDark: isDark,
                                cardColor: cardColor,
                                icon: Icons.local_hospital_outlined,
                                title: DoctorStrings.clinicalNotes(context),
                                textColor: textColor,
                                primaryGreen: primaryGreen,
                                child: _notesSection(context, state, cubit, isDark, textColor, primaryGreen),
                              ),
                              SizedBox(height: 14.h),
                              _sectionCard(
                                isDark: isDark,
                                cardColor: cardColor,
                                icon: Icons.medical_information_outlined,
                                title: DoctorStrings.diagnosis(context),
                                textColor: textColor,
                                primaryGreen: primaryGreen,
                                child: _diagnosesSection(context, state, cubit, isDark, textColor, primaryGreen),
                              ),
                              SizedBox(height: 14.h),
                              _sectionCard(
                                isDark: isDark,
                                cardColor: cardColor,
                                icon: Icons.receipt_long_outlined,
                                title: DoctorStrings.prescriptions(context),
                                textColor: textColor,
                                primaryGreen: primaryGreen,
                                child: _prescriptionsSection(context, state, cubit, isDark, textColor, primaryGreen),
                              ),
                              SizedBox(height: 90.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  onPressed: state.isSubmitting ? null : () => _confirmFinalize(context, cubit),
                  child: state.isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          DoctorStrings.finalizeEncounter(context),
                          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor, Color primaryGreen) {
    final appointment = widget.appointment;
    final time =
        '${appointment.startsAt.hour.toString().padLeft(2, '0')}:${appointment.startsAt.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  DoctorStrings.inProgressBadge(context),
                  style: TextStyle(color: primaryGreen, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              SizedBox(height: 10.h),
              Text(appointment.patientName,
                  style: TextStyle(color: textColor, fontSize: 22.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 2.h),
              Text(DoctorStrings.encounterTitle(context),
                  style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 13)),
      ],
    );
  }

  Widget _sectionCard({
    required bool isDark,
    required Color cardColor,
    required IconData icon,
    required String title,
    required Color textColor,
    required Color primaryGreen,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: primaryGreen),
              SizedBox(width: 8.w),
              Text(title, style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F2ED),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  // --- Clinical Notes ---
  Widget _notesSection(BuildContext context, DoctorEncounterState state, DoctorEncounterCubit cubit,
      bool isDark, Color textColor, Color primaryGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _noteController,
          maxLines: 4,
          style: TextStyle(color: textColor, fontSize: 13.sp),
          decoration: _fieldDecoration(context, DoctorStrings.clinicalNotesHint(context), isDark),
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () {
              cubit.addNote(_noteController.text);
              _noteController.clear();
            },
            icon: Icon(Icons.add, size: 16.sp, color: primaryGreen),
            label: Text(DoctorStrings.addNote(context), style: TextStyle(color: primaryGreen, fontSize: 12.sp)),
          ),
        ),
        ...state.draftNotes.asMap().entries.map((entry) => _chipTile(
              text: entry.value.content,
              isDark: isDark,
              textColor: textColor,
              onDelete: () => cubit.removeNoteAt(entry.key),
            )),
      ],
    );
  }

  // --- Diagnoses ---
  Widget _diagnosesSection(BuildContext context, DoctorEncounterState state, DoctorEncounterCubit cubit,
      bool isDark, Color textColor, Color primaryGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _diagnosisLabelController,
          style: TextStyle(color: textColor, fontSize: 13.sp),
          decoration: _fieldDecoration(context, DoctorStrings.diagnosisHint(context), isDark),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _diagnosisDescController,
          maxLines: 2,
          style: TextStyle(color: textColor, fontSize: 13.sp),
          decoration: _fieldDecoration(context, DoctorStrings.diagnosisDescriptionHint(context), isDark),
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () {
              cubit.addDiagnosis(_diagnosisLabelController.text, _diagnosisDescController.text);
              _diagnosisLabelController.clear();
              _diagnosisDescController.clear();
            },
            icon: Icon(Icons.add, size: 16.sp, color: primaryGreen),
            label: Text(DoctorStrings.addDiagnosis(context), style: TextStyle(color: primaryGreen, fontSize: 12.sp)),
          ),
        ),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: state.draftDiagnoses.asMap().entries.map((entry) {
            return Chip(
              backgroundColor: primaryGreen.withOpacity(0.12),
              label: Text(entry.value.label, style: TextStyle(color: primaryGreen, fontSize: 12.sp, fontWeight: FontWeight.w600)),
              deleteIcon: Icon(Icons.close, size: 15.sp, color: primaryGreen),
              onDeleted: () => cubit.removeDiagnosisAt(entry.key),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Prescriptions ---
  Widget _prescriptionsSection(BuildContext context, DoctorEncounterState state, DoctorEncounterCubit cubit,
      bool isDark, Color textColor, Color primaryGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...state.draftItems.asMap().entries.map((entry) {
          final item = entry.value;
          final subtitle = [item.dosage, item.frequency, item.duration].where((e) => e != null && e.isNotEmpty).join(' • ');
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F2ED),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.drugName, style: TextStyle(color: textColor, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                        if (subtitle.isNotEmpty)
                          Text(subtitle, style: const TextStyle(color: AppColors.textLightGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => cubit.removePrescriptionItemAt(entry.key),
                    icon: Icon(Icons.delete_outline, size: 18.sp, color: const Color(0xFFC0392B)),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddMedicationSheet(context, cubit, isDark, textColor, primaryGreen),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: Icon(Icons.add, size: 16.sp, color: primaryGreen),
            label: Text(DoctorStrings.addMedication(context), style: TextStyle(color: primaryGreen, fontSize: 13.sp, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _showAddMedicationSheet(
      BuildContext context, DoctorEncounterCubit cubit, bool isDark, Color textColor, Color primaryGreen) {
    final drugController = TextEditingController();
    final formController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(sheetContext).viewInsets.bottom + 20.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.addMedication(context),
                    style: TextStyle(color: textColor, fontSize: 16.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 14.h),
                TextField(
                  controller: drugController,
                  style: TextStyle(color: textColor, fontSize: 13.sp),
                  decoration: _fieldDecoration(context, DoctorStrings.drugName(context), isDark),
                ),
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: dosageController,
                      style: TextStyle(color: textColor, fontSize: 13.sp),
                      decoration: _fieldDecoration(context, DoctorStrings.dosage(context), isDark),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: frequencyController,
                      style: TextStyle(color: textColor, fontSize: 13.sp),
                      decoration: _fieldDecoration(context, DoctorStrings.frequency(context), isDark),
                    ),
                  ),
                ]),
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      style: TextStyle(color: textColor, fontSize: 13.sp),
                      decoration: _fieldDecoration(context, DoctorStrings.duration(context), isDark),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: formController,
                      style: TextStyle(color: textColor, fontSize: 13.sp),
                      decoration: _fieldDecoration(context, 'Form', isDark),
                    ),
                  ),
                ]),
                SizedBox(height: 8.h),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 13.sp),
                  decoration: _fieldDecoration(context, DoctorStrings.clinicalNotesHint(context), isDark),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    onPressed: () {
                      if (drugController.text.trim().isEmpty) return;
                      cubit.addPrescriptionItem(DraftPrescriptionItem(
                        drugName: drugController.text.trim(),
                        form: formController.text.trim().isEmpty ? null : formController.text.trim(),
                        dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
                        frequency: frequencyController.text.trim().isEmpty ? null : frequencyController.text.trim(),
                        duration: durationController.text.trim().isEmpty ? null : durationController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        // ⚠️ route مقصود تركه فاضي من هالفورم - قيمته لازم
                        // تطابق حرفياً MedicationRoute::values() بالباك ومو
                        // معروفة عندي، فبدل ما أخمّن وأخلي الطلب يفشل 422،
                        // بتركها null (nullable أصلاً بالـRequest).
                      ));
                      Navigator.pop(sheetContext);
                    },
                    child: Text(DoctorStrings.addMedication(context),
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chipTile({
    required String text,
    required bool isDark,
    required Color textColor,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F2ED),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(text, style: TextStyle(color: textColor, fontSize: 13.sp))),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 16.sp, color: const Color(0xFFC0392B)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmFinalize(BuildContext context, DoctorEncounterCubit cubit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        title: Text(DoctorStrings.finalizeEncounter(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(BlocProvider.of<SettingsCubit>(context).state.locale.languageCode == 'en' ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.finalizeEncounter();
            },
            child: Text(DoctorStrings.finalizeEncounter(context), style: const TextStyle(color: Color(0xFF2D533E))),
          ),
        ],
      ),
    );
  }
}
