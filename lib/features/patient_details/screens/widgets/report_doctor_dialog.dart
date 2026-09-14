import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/appointment_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../midecal_record/data/medical_record_repository.dart';
import '../../data/doctor_engagement_repository.dart';
import '../../data/patient_appointments_repository.dart';
import '../../models/doctor_engagement_models.dart';

/// نافذة منبثقة بسيطة للإبلاغ عن طبيب من صفحة بروفايله - فئة (category)
/// + وصف (description)، بنفس ألوان/شكل تطبيقنا. بترجع true لو انبعت
/// البلاغ فعلاً.
Future<bool?> showReportDoctorDialog(BuildContext context, {required int doctorId}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ReportDoctorDialog(doctorId: doctorId),
  );
}

class _ReportDoctorDialog extends StatefulWidget {
  final int doctorId;
  const _ReportDoctorDialog({required this.doctorId});

  @override
  State<_ReportDoctorDialog> createState() => _ReportDoctorDialogState();
}

class _ReportDoctorDialogState extends State<_ReportDoctorDialog> {
  final DoctorEngagementRepository _repository = DoctorEngagementRepository();
  final PatientAppointmentsRepository _appointmentsRepository = PatientAppointmentsRepository();
  final MedicalRecordRepository _medicalRecordRepository = MedicalRecordRepository();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = ReportCategories.values.first;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ⚠️ الباك (DoctorReportService::submit) بيشتق clinic_id إلزامياً من
  // encounter_id (encounter->appointment->clinic_id) - doctor_reports.clinic_id
  // NOT NULL بقاعدة البيانات. بدون encounter_id صالح كان عم يبعت clinic_id
  // فاضي فيفشل الإدراج بـ "clinic id cannot be null". هون منجيب تلقائياً
  // آخر encounter مكتمل فعلي مع هاد الطبيب (بلا ما نطلب من المستخدم يختاره).
  bool _isResolvingEncounter = true;
  int? _encounterId;
  bool _noEligibleEncounter = false;

  @override
  void initState() {
    super.initState();
    _resolveEncounterId();
  }

  Future<void> _resolveEncounterId() async {
    try {
      final appointments = await _appointmentsRepository.getAppointments();
      final completedAppointmentIds = appointments
          .where((a) => a.doctorId == widget.doctorId && a.status == AppointmentApiStatus.completed)
          .toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

      if (completedAppointmentIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isResolvingEncounter = false;
          _noEligibleEncounter = true;
        });
        return;
      }

      final record = await _medicalRecordRepository.getFullMedicalRecord();
      final encounters = (record['encounters'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      int? matchedEncounterId;
      for (final appointment in completedAppointmentIds) {
        final match = encounters.firstWhere(
          (e) => e['appointment_id'] == appointment.id,
          orElse: () => const {},
        );
        if (match.isNotEmpty && match['id'] != null) {
          matchedEncounterId = match['id'] is int ? match['id'] as int : int.tryParse('${match['id']}');
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _isResolvingEncounter = false;
        _encounterId = matchedEncounterId;
        _noEligibleEncounter = matchedEncounterId == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResolvingEncounter = false;
        _noEligibleEncounter = true;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _categoryLabel(BuildContext context, String category) {
    final isEn = BlocProvider.of<SettingsCubit>(context).state.locale.languageCode == 'en';
    switch (category) {
      case ReportCategories.misconduct:
        return isEn ? 'Misconduct' : 'سوء سلوك';
      case ReportCategories.negligence:
        return isEn ? 'Negligence' : 'إهمال';
      case ReportCategories.fraud:
        return isEn ? 'Fraud' : 'احتيال';
      case ReportCategories.verbalAbuse:
        return isEn ? 'Verbal abuse' : 'إساءة لفظية';
      case ReportCategories.privacyViolation:
        return isEn ? 'Privacy violation' : 'انتهاك خصوصية';
      case ReportCategories.other:
      default:
        return isEn ? 'Other' : 'سبب آخر';
    }
  }

  Future<void> _submit() async {
    if (_noEligibleEncounter || _encounterId == null) {
      setState(() => _errorMessage = AppStrings.reportRequiresCompletedVisit(context));
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = AppStrings.reportDescriptionRequired(context));
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _repository.submitReport(
        doctorId: widget.doctorId,
        category: _selectedCategory,
        description: description,
        encounterId: _encounterId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppStrings.unexpectedError(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    const dangerColor = Color(0xFFC0392B);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(color: dangerColor.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.flag_rounded, color: dangerColor, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      AppStrings.reportDoctorTitle(context),
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: textColor),
                    ),
                  ),
                ],
              ),
              if (_noEligibleEncounter) ...[
                SizedBox(height: 12.h),
                Text(
                  AppStrings.reportRequiresCompletedVisit(context),
                  style: TextStyle(color: dangerColor, fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                AppStrings.reportCategoryLabel(context),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: ReportCategories.values.map((category) {
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : (isDark ? AppColors.darkBackground : AppColors.backgroundBeige),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: isSelected ? primaryGreen : AppColors.borderGrey, width: 1.w),
                      ),
                      child: Text(
                        _categoryLabel(context, category),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),
              Text(
                AppStrings.reportDescriptionLabel(context),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                style: TextStyle(fontSize: 13.5.sp, color: textColor),
                decoration: InputDecoration(
                  hintText: AppStrings.reportDescriptionHint(context),
                  hintStyle: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 8.h),
                Text(_errorMessage!, style: TextStyle(color: dangerColor, fontSize: 12.sp)),
              ],
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46.h,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderGrey, width: 1.w),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text(AppStrings.confirmNo(context), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: SizedBox(
                      height: 46.h,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _isResolvingEncounter || _noEligibleEncounter) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dangerColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: (_isSubmitting || _isResolvingEncounter)
                            ? SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : Text(AppStrings.reportSubmitAction(context), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
