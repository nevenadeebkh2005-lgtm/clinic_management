import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/cubits/medical_record_status_cubit.dart';
import '../../../models/medical_record_models/dashboard_overview_models.dart';
import '../../../view_models/medical_overview_cubit.dart';
import '../../widgets/medical_records_widgets/dashboard_overview_widgets/overview_cards.dart';
import '../../widgets/medical_records_widgets/dashboard_overview_widgets/overview_tabs_bar.dart';
import '../../widgets/medical_records_widgets/dashboard_overview_widgets/patient_info_card.dart';
import '../../widgets/medical_records_widgets/dashboard_overview_widgets/recent_activity_card.dart';
import '../../widgets/medical_records_widgets/comprehensive_history_widgets/history_tab_view.dart';
import '../../widgets/medical_records_widgets/medications_widgets/medications_tab_view.dart';
import '../../widgets/medical_records_widgets/medical_attachments_widgets/attachments_tab_view.dart';
import '../../widgets/medical_records_widgets/encounter_widgets/encounter_tab_view.dart';
import '../../../../initial_medical_records/views/screens/medical_profile_screens/medical_history_screen.dart';

// =============================================
// MedicalOverviewScreen - الشاشة الأم لسجل المريض الطبي (Patient
// Medical Record)
//
// ⚠️ التغيير الأساسي المطلوب: بدل ما كانت History/Medications/
// Attachments كل وحدة منهن Scaffold منفصل يُفتح عبر Navigator.push
// (AppBar + BottomNav خاصين فيها لحالها)، صارت الأربع تابات مجرد
// محتوى يترسم تحت نفس كارد المريض وشريط التابات الثابتين، ويتبدّل
// بالضغط فقط - نفس سلوك Overview/History/Medications بالتصميم
// المرجعي (تنقّل بمكانه، مش صفحات).
//
// ⚠️ بيانات المريض بالكارد العلوي: ما في endpoint حالياً يرجع بروفايل
// المريض لحاله - القيم (الاسم/تاريخ الميلاد/فصيلة الدم...) بترجع فقط
// جوا user object وقت /auth/login أو /auth/complete-profile. مرّري
// currentUserJson لما تستخدمي الشاشة من main_layout_screen، مثال:
//   MedicalOverviewScreen(currentUserJson: authState.user)
// إذا ما انمرر شي، الكارد بيعرض دعوة لإكمال البروفايل بدل بيانات وهمية.
//
// ⚠️ hasMedicalRecord: هاد الفلاغ اللي المفروض يجي مع رد /auth/login
// (true/false) - لسا الباك ما ضافه، فحالياً قيمته الافتراضية false
// يدوياً حتى تقدروا تجربوا شكل حالة "لسا ما في سجل طبي" بدون ما
// تنتظروا الباك. لما يضيفه الباك فعلياً، بس بدّلوا القيمة اللي
// بتمرّروها من main_layout_screen لتصير:
//   MedicalOverviewScreen(hasMedicalRecord: authState.hasMedicalRecord)
// بدل ما تتركوها فاضية (بترجع للـ false الافتراضي القديم).
// =============================================
class MedicalOverviewScreen extends StatelessWidget {
  final Map<String, dynamic>? currentUserJson;
  final VoidCallback? onEditProfile;
  final bool hasMedicalRecord; // TODO: بدّلوها لقيمة حقيقية من الباك لما تجهز
  // اختياري - إذا ما انمرر، الزر بيروح افتراضياً على MedicalHistoryScreen
  // (أول خطوة بمعالج initial_medical_records). مرّريه بس إذا بدك سلوك
  // مخصص (مثلاً تمرير بيانات إضافية أو route مختلف).
  final VoidCallback? onStartMedicalRecord;

  const MedicalOverviewScreen({
    super.key,
    this.currentUserJson,
    this.onEditProfile,
    this.hasMedicalRecord = false,
    this.onStartMedicalRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMedicalRecord) {
      return NoMedicalRecordScreen(onStart: onStartMedicalRecord);
    }

    return BlocProvider(
      create: (context) => MedicalOverviewCubit(
        initialPatientInfo:
            currentUserJson != null ? PatientInfo.fromUserJson(currentUserJson!) : null,
      )..loadMedicalRecord(),
      child: _MedicalOverviewView(onEditProfile: onEditProfile),
    );
  }
}

// =============================================
// شاشة "لسا ما في سجل طبي" - بتظهر لما hasMedicalRecord = false.
// بديل احترافي بدل ما نحاول نجيب سجل مش موجود أصلاً (وبنفس الوقت
// بنتفادى استدعاء endpoint السجل الطبي بالكامل لمجرد التحقق).
// =============================================
class NoMedicalRecordScreen extends StatelessWidget {
  final VoidCallback? onStart;

  const NoMedicalRecordScreen({super.key, this.onStart});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.textDark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.backgroundBeige,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72.w,
                  height: 72.h,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.folder_open_outlined, size: 34.sp, color: primaryGreen),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppStrings.noMedicalRecordYetTitle(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.noMedicalRecordYetDesc(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp, height: 1.5),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    // إذا ما انمرر onStart مخصص من برا، الزر بيروح افتراضياً
                    // على أول خطوة بمعالج الإدخال (MedicalHistoryScreen).
                    // ⚠️ 19/8: نفس مشكلة DoctorProfileScreen (راجع
                    // doctor_card_widget.dart) - MedicalRecordStatusCubit
                    // موفّر بس جوا MainLayoutScreen، وكل خطوة من هالمعالج
                    // (History/Medications/Attachments/Review) بتنفتح
                    // بـ Navigator.push جديد بيطلعها خارج شجرة الـ Provider
                    // هاي. لازم نمرر الكيوبت يدوياً بكل قفزة عبر
                    // BlocProvider.value (نفس الشي لازم ينعمل بباقي
                    // الشاشات بالمعالج - راجع تعليق مماثل فيهن).
                    onPressed: onStart ??
                        () {
                          final medicalRecordStatusCubit =
                              context.read<MedicalRecordStatusCubit>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: medicalRecordStatusCubit,
                                child: const MedicalHistoryScreen(),
                              ),
                            ),
                          );
                        },
                    child: Text(
                      AppStrings.startMedicalRecord(context),
                      style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicalOverviewView extends StatelessWidget {
  final VoidCallback? onEditProfile;

  const _MedicalOverviewView({this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MedicalOverviewCubit, MedicalOverviewState>(
      builder: (context, state) {
        final cubit = context.read<MedicalOverviewCubit>();

        return Scaffold(
          backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.backgroundBeige,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: PatientInfoCard(
                    patient: state.patientInfo,
                    isLoading: state.status == MedicalRecordLoadStatus.initial,
                    onEditProfile: onEditProfile,
                  ),
                ),

                // شريط الأقسام الأفقي - نفس الـ Cubit اللي بيحمّل البيانات
                OverviewTabsBar(
                  selectedIndex: state.selectedTabIndex,
                  onTabSelected: cubit.changeTab,
                  onRefresh: () => cubit.loadMedicalRecord(),
                  // ✅ إصلاح "الميديكال ريكورد غير قابل للتعديل": قبل
                  // هيك، بعد أول تعبئة للسجل ما كان في ولا زر يرجّع
                  // المريض لمعالج الإدخال (History/Medications/
                  // Attachments) - بس Refresh. هلق منفتح نفس المعالج
                  // (MedicalHistoryScreen وما بعدها) ومعه MedicalRecordStatusCubit
                  // (نفس الطريقة المستخدمة بـ NoMedicalRecordScreen تحت)،
                  // وبعد الرجوع منعمل loadMedicalRecord() حتى ينعكس أي
                  // تعديل فوراً بالـ Dashboard.
                  onEdit: () async {
                    final medicalRecordStatusCubit = context.read<MedicalRecordStatusCubit>();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: medicalRecordStatusCubit,
                          child: const MedicalHistoryScreen(),
                        ),
                      ),
                    );
                    if (context.mounted) cubit.loadMedicalRecord();
                  },
                ),

                Divider(height: 1, color: isDarkMode ? Colors.white10 : AppColors.borderGrey),

                Expanded(child: _buildBody(context, state, cubit)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MedicalOverviewState state, MedicalOverviewCubit cubit) {
    if (state.status == MedicalRecordLoadStatus.initial ||
        state.status == MedicalRecordLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == MedicalRecordLoadStatus.failure) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.textLightGrey),
              SizedBox(height: 12.h),
              Text(
                state.errorMessage ?? AppStrings.somethingWentWrong(context),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => cubit.loadMedicalRecord(),
                child: Text(AppStrings.retry(context)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.loadMedicalRecord(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: _buildTabContent(context, state, cubit),
      ),
    );
  }

  // --- محتوى التاب المحدد فقط (بدون IndexedStack) حتى الـ
  // SingleChildScrollView ياخد ارتفاع التاب الحالي فعلياً، مش أطول تاب
  // بينهم كلهم. تبديل التاب بيصفّر مكان التمرير - تنازل بسيط مقبول. ---
  Widget _buildTabContent(BuildContext context, MedicalOverviewState state, MedicalOverviewCubit cubit) {
    switch (state.selectedTabIndex) {
      case 1:
        return HistoryTabView(
          allergies: state.allergies,
          chronicConditions: state.chronicConditions,
          surgeries: state.surgeries,
          familyHistory: state.familyHistory,
        );
      case 2:
        return MedicationsTabView(state: state);
      case 3:
        return AttachmentsTabView(state: state);
      case 4:
        return EncounterTabView(encounters: state.encounters);
      default:
        return _buildOverviewTab(context, state, cubit);
    }
  }

  Widget _buildOverviewTab(BuildContext context, MedicalOverviewState state, MedicalOverviewCubit cubit) {
    return Column(
      children: [
        if (state.recentActivity.isNotEmpty) ...[
          RecentActivityCard(
            activities: state.recentActivity,
            onViewAll: () => cubit.changeTab(1),
          ),
          SizedBox(height: 16.h),
        ],
        ActiveMedicationsCard(
          data: ActiveMedicationsData(
            count: state.activeMedications.length,
            label: AppStrings.currentPrescriptions(context),
          ),
          onManage: () => cubit.changeTab(2),
        ),
        SizedBox(height: 16.h),
        RecordSummaryCard(data: state.summary),
      ],
    );
  }
}
