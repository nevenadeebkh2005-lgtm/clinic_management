import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/doctor_dummy_data.dart';
import '../../view_models/doctor_listing_cubit.dart';
import '../../view_models/patient_appointments_cubit.dart';
import '../../../../core/cubits/medical_record_status_cubit.dart';
import '../doctor_profile_screen.dart';

class DoctorCardWidget extends StatelessWidget {
  final DoctorListingModel doc;
  final VoidCallback onToggleFav;

  const DoctorCardWidget({super.key, required this.doc, required this.onToggleFav});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final currentScale = settingsState.fontScale;
    final isDark = settingsState.themeMode == ThemeMode.dark;

    // موازنة الخطوط الفردية للبطاقة لتطابق الصورة بنسبة 100% وتدعم التكبير
    double nameSize = 16.sp;
    double subSize = 13.sp;
    double badgeSize = 12.sp;

    if (currentScale == FontScale.medium) {
      nameSize = 18.sp; subSize = 15.sp; badgeSize = 14.sp;
    } else if (currentScale == FontScale.large) {
      nameSize = 20.sp; subSize = 17.sp; badgeSize = 16.sp;
    }

    // تحديد الألوان ديناميكياً بناءً على وضع المظهر (Dark / Light)
    final cardBgColor = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreenColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final borderColor = isDark ? Colors.transparent : AppColors.borderGrey;
    final badgeBgColor = isDark ? AppColors.darkPrimaryGreen.withOpacity(0.15) : const Color(0xFFE8ECE9);
    final buttonBgColor = isDark ? AppColors.darkPrimaryGreen.withOpacity(0.25) : const Color(0xFFC2D1C6);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.w),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: isDark ? Colors.black26 : AppColors.backgroundBeige,
                child: Text(
                  doc.initials,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: primaryGreenColor),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.fullName,
                      style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w700, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      doc.department,
                      style: TextStyle(fontSize: subSize, color: AppColors.textLightGrey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: const Color(0xFFFBBF24), size: 18.sp),
                        SizedBox(width: 2.w),
                        Text(
                          '${doc.rating}',
                          style: TextStyle(fontSize: badgeSize, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '(${doc.reviewCount} reviews)',
                            style: TextStyle(fontSize: badgeSize, color: AppColors.textLightGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleFav,
                child: Icon(
                  doc.isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: doc.isFavourite ? const Color(0xFFD85A30) : AppColors.textLightGrey,
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Available ${doc.availabilityStatus ?? ''}',
                  style: TextStyle(color: primaryGreenColor, fontSize: badgeSize, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '\$${doc.consultationFee.toInt()} / visit',
                style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 38.h,
            child: ElevatedButton(
              onPressed: () {
                // ⚠️ 19/8: DoctorProfileScreen بيحتاج MedicalRecordStatusCubit
                // و DoctorListingCubit و PatientAppointmentsCubit (متوفرين
                // فقط جوا MainLayoutScreen عبر MultiBlocProvider) - لو
                // فتحناها بـ Navigator.push عادي بتصير الشاشة الجديدة برّا
                // شجرة الـ Provider هاي وبيصير ProviderNotFoundException
                // فوراً. الحل: نمرر نفس الكيوبتس الموجودة بالـ context
                // الحالي عبر BlocProvider.value. (PatientAppointmentsCubit
                // ضروري هون تحديداً حتى بعد نجاح الحجز نقدر ننادي load()
                // فوراً - راجع _onBookPressed بـ doctor_profile_screen.dart).
                final doctorListingCubit = context.read<DoctorListingCubit>();
                final medicalRecordStatusCubit = context.read<MedicalRecordStatusCubit>();
                final appointmentsCubit = context.read<PatientAppointmentsCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: doctorListingCubit),
                        BlocProvider.value(value: medicalRecordStatusCubit),
                        BlocProvider.value(value: appointmentsCubit),
                      ],
                      child: DoctorProfileScreen(doctor: doc),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBgColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(
                AppStrings.viewProfile(context),
                style: TextStyle(color: primaryGreenColor, fontWeight: FontWeight.w700, fontSize: subSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
