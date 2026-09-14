import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import 'package:untitled3/features/patient_details/views/widgets/settings_drawer_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/cubits/medical_record_status_cubit.dart';
import '../../consultations/screens/consultations_inbox_screen.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/view_models/notifications_cubit.dart';
import '../../notifications/view_models/notifications_state.dart';
import '../../midecal_record/patiant_medical_record/views/screens/medical_records_screens/medical_overview_screen.dart';
import '../view_models/patient_appointments_cubit.dart';
import 'patient_appointments_screen.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'doctor_listing_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../models/patient_profile_dummy_data.dart';
import '../view_models/doctor_listing_cubit.dart';
import '../view_models/doctor_listing_state.dart';

class MainLayoutScreen extends StatelessWidget {
  /// user object الحقيقي القادم من data.user برد /auth/login الناجح -
  /// نفس الكائن يلي بينمرر لكل الشاشات التابعة (الرئيسية/السجل الطبي/
  /// البروفايل) حتى تعرض كلها بيانات المريض الحقيقية المدخلة بالريجستر
  /// بدل أي بيانات وهمية.
  final Map<String, dynamic>? currentUserJson;

  const MainLayoutScreen({super.key, this.currentUserJson});

  @override
  Widget build(BuildContext context) {

    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final currentScale = settingsState.fontScale;
    final isDark = settingsState.themeMode == ThemeMode.dark;


    double titleFontSize = 16.sp;
    if (currentScale == FontScale.medium) titleFontSize = 19.sp;
    if (currentScale == FontScale.large) titleFontSize = 22.sp;


    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final appBarBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreenColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final bottomLineColor = isDark ? Colors.white10 : AppColors.backgroundBeige;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => DoctorListingCubit(const [])..loadDoctors()),
          // ✅ حالة أولية من currentUserJson (لحظة تسجيل الدخول)، وبعدين
          // بتتحدث حية بمنتصف الجلسة لما يخلّص المريض تعبئة سجله الطبي -
          // راجع تعليق medical_record_status_cubit.dart.
          BlocProvider(
            create: (context) => MedicalRecordStatusCubit(
              currentUserJson != null &&
                  (currentUserJson!['profile'] is Map) &&
                  (currentUserJson!['profile']['has_medical_data'] == true),
            ),
          ),
          // ⚠️ 19/8: نقلناها لهون (بدل ما تكون محصورة جوا تاب الحجوزات
          // بس) حتى doctor_profile_screen.dart (يلي بيتفتح فوق هالشجرة
          // عبر Navigator.push من doctor_card_widget/home_doctor_tile)
          // يقدر يوصلها بعد الحجز الناجح وينادي load() فوراً - قبل هيك
          // كانت الحجوزات ما بتظهر إلا بعد قفل التطبيق وإعادة فتحه لأنه
          // الكيوبت الوحيد يلي بالتاب كان بيضل نفس الـ instance القديم
          // (IndexedStack ما بيعيد بناء الأولاد).
          BlocProvider(create: (context) => PatientAppointmentsCubit()..load()),
          // ✅ نفس منطق PatientAppointmentsCubit فوق - موفّرة هون حتى تضل
          // حية عبر التابات وتقدر doctor_profile_screen (أو أي شاشة
          // تانية مستقبلاً) توصلها، وحتى شارة العدد عالجرس تضل تتحدث
          // بالـ polling حتى لو المستخدم مو فاتح شاشة الإشعارات حالياً.
          BlocProvider(create: (context) => NotificationsCubit()..load()..startPolling()),
        ],
        child: BlocBuilder<DoctorListingCubit, DoctorListingState>(
          builder: (context, state) {
            final cubit = context.read<DoctorListingCubit>();
            final hasMedicalRecord = context.watch<MedicalRecordStatusCubit>().state;

            return Scaffold(
              backgroundColor: scaffoldBg,

              appBar: AppBar(
                backgroundColor: appBarBg,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 16.w,
                title: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (currentUserJson == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientProfileScreen(
                              profile: PatientProfileModel.fromUserJson(currentUserJson!),
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 18.r,
                        backgroundColor: primaryGreenColor.withOpacity(0.15),
                        child: Icon(Icons.person_outline, color: primaryGreenColor, size: 20.sp),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),

                    if (state.currentIndex == 1) ...[
                      GestureDetector(
                        onTap: () => cubit.toggleShowingAll(),
                        child: Icon(
                          !state.showingAll || state.favCount > 0
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: !state.showingAll || state.favCount > 0
                              ? const Color(0xFFD85A30)
                              : AppColors.textLightGrey,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                    ],
                    GestureDetector(
                      onTap: () {
                        final notificationsCubit = context.read<NotificationsCubit>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: notificationsCubit,
                              child: NotificationsScreen(
                                currentUserId: int.tryParse('${currentUserJson?['id'] ?? 0}') ?? 0,
                                // تاب "My Appointments" هو index 2 بهاي الشاشة.
                                onOpenAppointment: (ctx, notification) {
                                  cubit.changeTab(2);
                                  Navigator.of(ctx).popUntil((route) => route.isFirst);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      child: BlocBuilder<NotificationsCubit, NotificationsState>(
                        builder: (context, notificationsState) {
                          final unread = notificationsState.unreadCount;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.notifications_none_rounded, color: textColor, size: 24.sp),
                              if (unread > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                    constraints: BoxConstraints(minWidth: 14.w),
                                    decoration: const BoxDecoration(color: Color(0xFFD85A30), shape: BoxShape.circle),
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 14.w),
                    GestureDetector(
                      onTap: () {
                        showSettingsDrawer(context);
                      },
                      child: Icon(Icons.more_vert, color: textColor, size: 24.sp),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1.0.h),
                  child: Container(color: bottomLineColor, height: 1.0.h),
                ),
              ),

              bottomNavigationBar: CustomBottomNavBar(
                currentIndex: state.currentIndex,
                onTap: (index) => cubit.changeTab(index),
              ),

              body: IndexedStack(
                index: state.currentIndex,
                children: [
                  PatientHomeScreen(currentUserJson: currentUserJson),
                  const DoctorListingScreen(),
                  // ✅ 19/8: تاب "الحجوزات" كان Placeholder نص بس - صار
                  // شاشة حقيقية مربوطة بـ GET /patient/appointments.
                  // PatientAppointmentsCubit موفّر هلق فوق (بالـ
                  // MultiBlocProvider الرئيسي) مش هون تحديداً، حتى
                  // doctor_profile_screen.dart يقدر يوصله وينادي load()
                  // بعد أي حجز ناجح.
                  const PatientAppointmentsScreen(),
                  ConsultationsInboxScreen(
                    currentUserId: int.tryParse('${currentUserJson?['id'] ?? 0}') ?? 0,
                    embedded: true,
                  ),
                  MedicalOverviewScreen(
                    currentUserJson: currentUserJson,
                    // ✅ هلق بياخد القيمة الحية من MedicalRecordStatusCubit
                    // (مو حساب ثابت مرة وحدة من currentUserJson) - راجع
                    // تعليق الـ Cubit لتفاصيل المشكلة يلي انحلت.
                    hasMedicalRecord: hasMedicalRecord,
                    onEditProfile: currentUserJson == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientProfileScreen(
                                  profile: PatientProfileModel.fromUserJson(currentUserJson!),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
