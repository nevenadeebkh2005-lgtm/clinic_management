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

/// A compact doctor row for the Home screen — lighter than
/// [DoctorCardWidget], matching the Figma "Doctors Near You" list (avatar,
/// name/specialty/workplace, rating, favourite, call + book actions).
class HomeDoctorTile extends StatelessWidget {
  final DoctorListingModel doc;
  final VoidCallback onToggleFav;
  final VoidCallback onBook;

  const HomeDoctorTile({
    super.key,
    required this.doc,
    required this.onToggleFav,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final currentScale = settingsState.fontScale;

    double nameSize = 15.sp;
    double subSize = 12.sp;
    if (currentScale == FontScale.medium) { nameSize = 17.sp; subSize = 14.sp; }
    if (currentScale == FontScale.large) { nameSize = 19.sp; subSize = 16.sp; }

    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final borderColor = isDark ? Colors.transparent : AppColors.borderGrey;

    return GestureDetector(
      onTap: () {
        // ⚠️ 19/8: نفس مشكلة doctor_card_widget - لازم نمرر
        // MedicalRecordStatusCubit و DoctorListingCubit و
        // PatientAppointmentsCubit للشاشة المفتوحة (راجع تعليق مشابه
        // هناك) وإلا بيصير ProviderNotFoundException.
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
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.w),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: isDark ? Colors.black26 : AppColors.backgroundBeige,
                  child: Text(doc.initials, style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.fullName, style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis),
                      Text(doc.department, style: TextStyle(fontSize: subSize, color: AppColors.textLightGrey), overflow: TextOverflow.ellipsis),
                      if (doc.workplaceNames.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13.sp, color: AppColors.textLightGrey),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(doc.workplaceNames.first, style: TextStyle(fontSize: subSize, color: AppColors.textLightGrey), overflow: TextOverflow.ellipsis),
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
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.star_rounded, color: const Color(0xFFFBBF24), size: 16.sp),
                SizedBox(width: 2.w),
                Text('${doc.rating}', style: TextStyle(fontSize: subSize, fontWeight: FontWeight.w700, color: textColor)),
                const Spacer(),
                _RoundIconButton(icon: Icons.call_outlined, color: primaryGreen, onTap: () {}),
                SizedBox(width: 8.w),
                _BookButton(label: AppStrings.book(context), color: primaryGreen, textColor: isDark ? AppColors.darkBackground : AppColors.white, onTap: onBook),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.2.w)),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _BookButton({required this.label, required this.color, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20.r)),
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12.sp)),
      ),
    );
  }
}
