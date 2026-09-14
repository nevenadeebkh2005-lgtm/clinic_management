import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/network/api_exception.dart';
import '../data/doctor_medical_record_repository.dart';
import '../models/patient_medical_record_bundle.dart';

/// ✅ 19/8: عرض السجل الطبي لمريض من جهة الطبيب (للقراءة بس - ولا شي
/// قابل للتعديل هون، التعديل حصراً بيد المريض بشاشاته هو). الوصول
/// مسموح فقط عن طريق موعد فعلي بين الطبيب والمريض
/// (GET /doctor/appointments/{id}/medical-record) - نفس فكرة الصورة
/// المرجعية يلي بعتها المستخدم (بطاقة معلومات المريض فوق، وتحتها
/// Allergies بخط أحمر جانبي، Active Problems، Medications،
/// Attachments & Results).
/// ⚠️ ملاحظة: الباك حالياً ما بيرجع بيانات ديموغرافية للمريض (تاريخ
/// ميلاد/جنس/وزن/طول/فصيلة دم) لهالـ endpoint - بس id + name عبر
/// بيانات الموعد. لهيك البطاقة العلوية هون مبنية بس على المتوفر
/// فعلياً، بدون اختلاق بيانات وهمية.
class PatientMedicalRecordViewScreen extends StatefulWidget {
  final int appointmentId;
  final String patientName;

  const PatientMedicalRecordViewScreen({super.key, required this.appointmentId, required this.patientName});

  @override
  State<PatientMedicalRecordViewScreen> createState() => _PatientMedicalRecordViewScreenState();
}

class _PatientMedicalRecordViewScreenState extends State<PatientMedicalRecordViewScreen> {
  final DoctorMedicalRecordRepository _repository = DoctorMedicalRecordRepository();
  bool _isLoading = true;
  String? _errorMessage;
  PatientMedicalRecordBundle? _bundle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bundle = await _repository.getForAppointment(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.statusCode == 403 ? DoctorStrings.medicalRecordAccessRevoked(context) : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحميل السجل الطبي';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(widget.patientName, style: TextStyle(color: textColor, fontSize: 17.sp, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 40.sp, color: AppColors.textLightGrey),
                        SizedBox(height: 12.h),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 13.sp)),
                        SizedBox(height: 10.h),
                        TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    children: [
                      _PatientHeaderCard(name: widget.patientName, cardBg: cardBg, textColor: textColor, primaryGreen: primaryGreen),
                      SizedBox(height: 14.h),
                      _AllergiesCard(bundle: _bundle!, cardBg: cardBg, textColor: textColor),
                      SizedBox(height: 14.h),
                      _ActiveProblemsCard(bundle: _bundle!, cardBg: cardBg, textColor: textColor, primaryGreen: primaryGreen),
                      SizedBox(height: 14.h),
                      _MedicationsCard(bundle: _bundle!, cardBg: cardBg, textColor: textColor, primaryGreen: primaryGreen),
                      SizedBox(height: 14.h),
                      _AttachmentsCard(bundle: _bundle!, cardBg: cardBg, textColor: textColor, primaryGreen: primaryGreen),
                    ],
                  ),
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color cardBg;
  final Widget child;
  const _SectionCard({required this.cardBg, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16.r)),
      child: child,
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  final String name;
  final Color cardBg;
  final Color textColor;
  final Color primaryGreen;
  const _PatientHeaderCard({required this.name, required this.cardBg, required this.textColor, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      cardBg: cardBg,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: primaryGreen.withOpacity(0.15),
            child: Icon(Icons.person_outline, color: primaryGreen, size: 28.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(name, style: TextStyle(color: textColor, fontSize: 17.sp, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _AllergiesCard extends StatelessWidget {
  final PatientMedicalRecordBundle bundle;
  final Color cardBg;
  final Color textColor;
  const _AllergiesCard({required this.bundle, required this.cardBg, required this.textColor});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return const Color(0xFFC0392B);
      case 'moderate':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border(left: BorderSide(color: const Color(0xFFC0392B), width: 4.w)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
              SizedBox(width: 8.w),
              Text(DoctorStrings.allergiesSection(context), style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 10.h),
          if (bundle.allergies.isEmpty)
            Text(DoctorStrings.noEntriesYet(context), style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp))
          else
            ...bundle.allergies.map((a) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.allergen, style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                        decoration: BoxDecoration(color: _severityColor(a.severity).withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
                        child: Text(a.severity, style: TextStyle(color: _severityColor(a.severity), fontSize: 11.sp, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _ActiveProblemsCard extends StatelessWidget {
  final PatientMedicalRecordBundle bundle;
  final Color cardBg;
  final Color textColor;
  final Color primaryGreen;
  const _ActiveProblemsCard({required this.bundle, required this.cardBg, required this.textColor, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      cardBg: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: textColor),
              SizedBox(width: 8.w),
              Text(DoctorStrings.activeProblemsSection(context), style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 10.h),
          if (bundle.chronicConditions.isEmpty)
            Text(DoctorStrings.noEntriesYet(context), style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp))
          else
            for (int i = 0; i < bundle.chronicConditions.length; i++) ...[
              if (i > 0) Divider(height: 20.h, color: Colors.black.withOpacity(0.06)),
              Text(bundle.chronicConditions[i].conditionName, style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 3.h),
              Text('${DoctorStrings.diagnosedLabel(context)}: ${bundle.chronicConditions[i].diagnosedAt}',
                  style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.sp)),
            ],
        ],
      ),
    );
  }
}

class _MedicationsCard extends StatelessWidget {
  final PatientMedicalRecordBundle bundle;
  final Color cardBg;
  final Color textColor;
  final Color primaryGreen;
  const _MedicationsCard({required this.bundle, required this.cardBg, required this.textColor, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    final active = bundle.medications.where((m) => !m.isStopped).toList();
    return _SectionCard(
      cardBg: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: textColor),
              SizedBox(width: 8.w),
              Text(DoctorStrings.medicationsSection(context), style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 10.h),
          if (active.isEmpty)
            Text(DoctorStrings.noEntriesYet(context), style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp))
          else
            for (int i = 0; i < active.length; i++) ...[
              if (i > 0) Divider(height: 20.h, color: Colors.black.withOpacity(0.06)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(active[i].drugName, style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                        SizedBox(height: 3.h),
                        Text('${active[i].strength} • ${active[i].form}', style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.sp)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
                    child: Text(active[i].frequency, style: TextStyle(color: primaryGreen, fontSize: 11.sp, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  final PatientMedicalRecordBundle bundle;
  final Color cardBg;
  final Color textColor;
  final Color primaryGreen;
  const _AttachmentsCard({required this.bundle, required this.cardBg, required this.textColor, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      cardBg: cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_outlined, color: textColor),
              SizedBox(width: 8.w),
              Text(DoctorStrings.attachmentsSection(context), style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 10.h),
          if (bundle.attachments.isEmpty)
            Text(DoctorStrings.noEntriesYet(context), style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp))
          else
            ...bundle.attachments.map((a) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.08)), borderRadius: BorderRadius.circular(10.r)),
                  child: Row(
                    children: [
                      Icon(a.fileType.toString().contains('pdf') ? Icons.description_outlined : Icons.image_outlined, color: primaryGreen, size: 20.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.type, style: TextStyle(color: textColor, fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2.h),
                            Text(
                              a.uploadedAt != null ? '${a.uploadedAt!.year}-${a.uploadedAt!.month.toString().padLeft(2, '0')}-${a.uploadedAt!.day.toString().padLeft(2, '0')}' : '',
                              style: TextStyle(color: AppColors.textLightGrey, fontSize: 11.sp),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
