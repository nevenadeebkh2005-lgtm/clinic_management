import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../consultations/screens/consultations_inbox_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/view_models/notifications_cubit.dart';
import '../../notifications/view_models/notifications_state.dart';
import '../../patient_details/views/widgets/settings_drawer_widget.dart';
import '../view_models/doctor_appointments_cubit.dart';
import '../view_models/doctor_home_cubit.dart';
import '../view_models/doctor_home_state.dart';
import '../view_models/work_schedule_cubit.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_home_screen.dart';
import 'weekly_template_editor_screen.dart';
import 'widgets/doctor_bottom_nav_bar.dart';

/// شاشة الطبيب الرئيسية بعد تسجيل الدخول - مكافئة MainLayoutScreen
/// تبع المريض بنفس البنية (AppBar + BottomNav + IndexedStack)، بس
/// بأربع تابات: الرئيسية / المواعيد / جدول العمل / شات (ConsultationsInboxScreen،
/// مربوطة بالباك الحقيقي - راجع lib/features/consultations).
class DoctorMainLayoutScreen extends StatefulWidget {
  final Map<String, dynamic> currentUserJson;

  const DoctorMainLayoutScreen({super.key, required this.currentUserJson});

  @override
  State<DoctorMainLayoutScreen> createState() => _DoctorMainLayoutScreenState();
}

class _DoctorMainLayoutScreenState extends State<DoctorMainLayoutScreen> {
  int _currentIndex = 0;
  late final DoctorHomeCubit _homeCubit;
  late final DoctorAppointmentsCubit _appointmentsCubit;
  late final NotificationsCubit _notificationsCubit;

  /// Account/user id (not the doctor profile id) - this is what
  /// consultation messages' `sender_id` is compared against for bubble
  /// alignment.
  int get _currentUserId => int.tryParse('${widget.currentUserJson['id'] ?? 0}') ?? 0;

  @override
  void initState() {
    super.initState();
    _homeCubit = DoctorHomeCubit(initialUserJson: widget.currentUserJson)..load();
    _appointmentsCubit = DoctorAppointmentsCubit()..load();
    // ✅ صار مربوط بالباك الحقيقي (GET /notifications، مشترك مع المريض)
    // بدل DoctorNotificationsCubit يلي كان يخزّن بيانات وهمية محلياً.
    _notificationsCubit = NotificationsCubit()..load()..startPolling();
  }

  @override
  void dispose() {
    _homeCubit.close();
    _appointmentsCubit.close();
    _notificationsCubit.close();
    super.dispose();
  }

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
          BlocProvider.value(value: _homeCubit),
          BlocProvider.value(value: _appointmentsCubit),
          BlocProvider.value(value: _notificationsCubit),
        ],
        child: Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 16.w,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: primaryGreenColor.withOpacity(0.15),
                  child: Icon(Icons.local_hospital_rounded, color: primaryGreenColor, size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Text(AppStrings.appName,
                    style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w700, color: textColor)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: _notificationsCubit,
                        child: NotificationsScreen(
                          currentUserId: _currentUserId,
                          // تاب "المواعيد" هو index 1 بهاي الشاشة.
                          onOpenAppointment: (ctx, notification) {
                            setState(() => _currentIndex = 1);
                            Navigator.of(ctx).popUntil((route) => route.isFirst);
                          },
                        ),
                      ),
                    ),
                  ),
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.notifications_none_rounded, color: textColor, size: 24.sp),
                        if (state.unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                              constraints: BoxConstraints(minWidth: 14.w),
                              decoration: const BoxDecoration(color: Color(0xFFC0392B), shape: BoxShape.circle),
                              child: Text(
                                state.unreadCount > 9 ? '9+' : '${state.unreadCount}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                GestureDetector(
                  onTap: () => showSettingsDrawer(context),
                  child: Icon(Icons.more_vert, color: textColor, size: 24.sp),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1.0.h),
              child: Container(color: bottomLineColor, height: 1.0.h),
            ),
          ),
          bottomNavigationBar: DoctorBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const DoctorHomeScreen(),
              const DoctorAppointmentsScreen(),
              BlocBuilder<DoctorHomeCubit, DoctorHomeState>(
                builder: (context, homeState) {
                  if (homeState.status != DoctorHomeStatus.loaded) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return BlocProvider(
                    create: (_) => WorkScheduleCubit(
                      doctorId: homeState.profile.doctorId ?? 0,
                      registeredClinics: homeState.profile.clinics,
                    )..load(),
                    child: const _EmbeddedWorkSchedule(),
                  );
                },
              ),
              ConsultationsInboxScreen(currentUserId: _currentUserId, embedded: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// تاب "الجدول" بالـ BottomNav بيعرض شاشة تفعيل الأيام (Weekly Template
/// Editor) مباشرة - نفس الأسلوب المتفق عليه (يوم-يوم، وبكل يوم صباح/
/// بعد ظهر/مساء) - مو عرض الأوقات المولّدة (CareFlow day-view)، هاي
/// الأخيرة بتنفتح كخطوة تانية (أيقونة ⌚) من جوا هاي الشاشة نفسها.
class _EmbeddedWorkSchedule extends StatelessWidget {
  const _EmbeddedWorkSchedule();

  @override
  Widget build(BuildContext context) => const WeeklyTemplateEditorScreen(embedded: true);
}
