import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../view_models/doctor_home_cubit.dart';
import '../view_models/doctor_home_state.dart';
import '../view_models/work_schedule_cubit.dart';
import 'doctor_profile_screen.dart';
import 'weekly_template_editor_screen.dart';
import 'widgets/appointment_card_widget.dart';
import 'widgets/doctor_dashboard_widgets.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;

    return BlocBuilder<DoctorHomeCubit, DoctorHomeState>(
      builder: (context, state) {
        final cubit = context.read<DoctorHomeCubit>();

        if (state.status == DoctorHomeStatus.initial || state.status == DoctorHomeStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == DoctorHomeStatus.failure && state.profile.email.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.textLightGrey),
                  SizedBox(height: 12.h),
                  Text(state.errorMessage ?? 'حدث خطأ ما',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp)),
                  SizedBox(height: 16.h),
                  ElevatedButton(onPressed: () => cubit.load(), child: const Text('إعادة المحاولة')),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => cubit.load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              DoctorProfileHeaderCard(
                profile: state.profile,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    // ✅ إصلاح: كان هون بيفتح DoctorProfileScreen مباشرة
                    // بـ MaterialPageRoute عادي بدون تمرير DoctorHomeCubit
                    // معه. الصفحات المفتوحة بـ Navigator.push بتصير أساساً
                    // بفرع تاني من الشجرة (فوق الـ Overlay)، مو حرفياً
                    // "جوا" MultiBlocProvider يلي بـ DoctorMainLayoutScreen
                    // رغم إنها بصرياً فوقها - فأي context.read<DoctorHomeCubit>()
                    // جوا DoctorProfileScreen (زي بعد حفظ التعديل أو
                    // الانضمام لعيادة) كان يطيح بـ ProviderNotFoundException.
                    // الحل: نمرر نفس الكيوبت الموجود صراحة عبر BlocProvider.value.
                    builder: (_) => BlocProvider.value(
                      value: context.read<DoctorHomeCubit>(),
                      child: DoctorProfileScreen(profile: state.profile),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  DoctorStatChip(
                    icon: Icons.event_note_rounded,
                    value: '${state.appointmentsTodayCount}',
                    label: DoctorStrings.appointmentsToday(context),
                    isDark: isDark,
                  ),
                  DoctorStatChip(
                    icon: Icons.hourglass_empty_rounded,
                    value: '${state.pendingAppointmentsCount}',
                    label: DoctorStrings.pending(context),
                    isDark: isDark,
                  ),
                  DoctorStatChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    value: '${state.pendingMessagesCount}',
                    label: DoctorStrings.messages(context),
                    isDark: isDark,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // أول دخول ولسا ما حدد جدول عمله بأي عيادة -> بانر التوجيه
              // بدل عرض خيارات فارغة. بعد ما يحدده، يظهر مكانه ملخص
              // عيادات اليوم الحقيقي.
              if (!state.hasConfiguredSchedule)
                EmptyScheduleBanner(
                  isDark: isDark,
                  onSetup: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => WorkScheduleCubit(
                            doctorId: state.profile.doctorId ?? 0,
                            registeredClinics: state.profile.clinics,
                          )..load(),
                          child: const WeeklyTemplateEditorScreen(),
                        ),
                      ),
                    );
                    cubit.load();
                  },
                )
              else
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => WorkScheduleCubit(
                            doctorId: state.profile.doctorId ?? 0,
                            registeredClinics: state.profile.clinics,
                          )..load(),
                          child: const WeeklyTemplateEditorScreen(),
                        ),
                      ),
                    );
                    cubit.load();
                  },
                  child: TodayClinicsBanner(slots: state.todaySlots, isDark: isDark),
                ),

              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DoctorStrings.nextPatient(context),
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
              SizedBox(height: 12.h),
              if (state.nextAppointment == null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(DoctorStrings.noAppointmentsToday(context),
                        style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp)),
                  ),
                )
              else
                AppointmentCardWidget(appointment: state.nextAppointment!, isDark: isDark, onTap: () {}),
            ],
          ),
        );
      },
    );
  }
}
