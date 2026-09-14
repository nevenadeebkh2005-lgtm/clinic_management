import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/constants/app_strings.dart';
import '../../../../../../doctor_details/models/encounter_models.dart';

/// =============================================
/// تاب "Encounters" بصفحة السجل الطبي عند المريض - نفس روح تصميم
/// "Encounters History" المرجعي (تايم لاين عمودي مع كارد لكل زيارة)،
/// بس مبني بالكامل من بيانات حقيقية (Encounter model، راجع
/// encounter_model.dart) بدل بيانات وهمية. كل حقل هون موجود فعلياً
/// برد الباك (POST .../encounter/submit وGET .../medical-record) -
/// ما في أي حقل مختلق (مثلاً اسم/تخصص الطبيب أو صورته غير متوفرين
/// بجواب الـ encounter نفسه، فما ظهروا هون).
/// =============================================
class EncounterTabView extends StatelessWidget {
  final List<Encounter> encounters;

  const EncounterTabView({super.key, required this.encounters});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    if (encounters.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_information_outlined, size: 40.sp, color: AppColors.textLightGrey),
            SizedBox(height: 12.h),
            Text(AppStrings.noEncountersYet(context),
                style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 6.h),
            Text(AppStrings.noEncountersDesc(context),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.5.sp, height: 1.5)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.encountersHistory(context),
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: textColor)),
        SizedBox(height: 4.h),
        Text(AppStrings.comprehensiveHistory(context),
            style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
        SizedBox(height: 16.h),
        for (int i = 0; i < encounters.length; i++) ...[
          _EncounterTimelineItem(
            encounter: encounters[i],
            isFirst: i == 0,
            isDark: isDarkMode,
            primaryGreen: primaryGreen,
            textColor: textColor,
          ),
        ],
        // نقطة نهاية التايم لاين - نفس التصميم المرجعي
        Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              margin: EdgeInsets.only(left: 5.w, right: 12.w),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textLightGrey, width: 1.5)),
            ),
            Text(AppStrings.endOfRecentHistory(context), style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.sp)),
          ],
        ),
      ],
    );
  }
}

class _EncounterTimelineItem extends StatelessWidget {
  final Encounter encounter;
  final bool isFirst;
  final bool isDark;
  final Color primaryGreen;
  final Color textColor;

  const _EncounterTimelineItem({
    required this.encounter,
    required this.isFirst,
    required this.isDark,
    required this.primaryGreen,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final date = encounter.createdAt;
    final dateLabel = date == null ? '' : '${_month(context, date.month)} ${date.day}, ${date.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? primaryGreen : cardBg,
                    border: Border.all(color: primaryGreen, width: 2.w),
                  ),
                ),
                Expanded(
                  child: Container(width: 2.w, color: primaryGreen.withOpacity(0.25)),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(dateLabel, style: TextStyle(fontSize: 11.5.sp, color: AppColors.textLightGrey, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
                        child: Text(
                          encounter.visitType == 'in_person' || encounter.visitType == null
                              ? AppStrings.visit(context)
                              : encounter.visitType!,
                          style: TextStyle(fontSize: 10.sp, color: primaryGreen, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border(left: BorderSide(color: primaryGreen, width: 3.w)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (encounter.diagnoses.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, size: 15.sp, color: primaryGreen),
                              SizedBox(width: 6.w),
                              Text(AppStrings.diagnosisSummary(context),
                                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: textColor)),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            encounter.diagnoses.map((d) => d.description?.isNotEmpty == true ? '${d.label} — ${d.description}' : d.label).join('\n'),
                            style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey, height: 1.5),
                          ),
                          SizedBox(height: 8.h),
                        ],
                        if (encounter.clinicalNotes.isNotEmpty) ...[
                          Divider(color: isDark ? Colors.white10 : AppColors.borderGrey, height: 1),
                          SizedBox(height: 8.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded, size: 15.sp, color: AppColors.textLightGrey),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  encounter.clinicalNotes.map((n) => n.content).join('\n'),
                                  style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey, height: 1.5, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 8.h),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => _showFullDetails(context, encounter, primaryGreen, textColor, isDark),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text(AppStrings.viewFullDetails(context), style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 12.sp)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _month(BuildContext context, int m) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const ar = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return isEn ? en[m - 1] : ar[m - 1];
  }

  void _showFullDetails(BuildContext context, Encounter encounter, Color primaryGreen, Color textColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.encounterDetails(sheetContext), style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                SizedBox(height: 16.h),
                if (encounter.diagnoses.isNotEmpty) ...[
                  Text(AppStrings.diagnosis(sheetContext), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor)),
                  SizedBox(height: 6.h),
                  for (final d in encounter.diagnoses)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        d.description?.isNotEmpty == true ? '${d.label}\n${d.description}' : d.label,
                        style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey, height: 1.5),
                      ),
                    ),
                  SizedBox(height: 10.h),
                ],
                if (encounter.clinicalNotes.isNotEmpty) ...[
                  Text(AppStrings.clinicalNotes(sheetContext), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor)),
                  SizedBox(height: 6.h),
                  for (final n in encounter.clinicalNotes)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Text('• ${n.content}', style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey, height: 1.5)),
                    ),
                  SizedBox(height: 10.h),
                ],
                if (encounter.prescription != null && encounter.prescription!.items.isNotEmpty) ...[
                  Text(AppStrings.prescriptions(sheetContext), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor)),
                  SizedBox(height: 6.h),
                  for (final item in encounter.prescription!.items)
                    Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.drugName ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor)),
                          if (item.dosage != null || item.frequency != null || item.duration != null)
                            Text(
                              [item.dosage, item.frequency, item.duration].where((e) => e != null && e.isNotEmpty).join(' • '),
                              style: TextStyle(fontSize: 11.5.sp, color: AppColors.textLightGrey),
                            ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(item.notes!, style: TextStyle(fontSize: 11.5.sp, color: AppColors.textLightGrey, fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
