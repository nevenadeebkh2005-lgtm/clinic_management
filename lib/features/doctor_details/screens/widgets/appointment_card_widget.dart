import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings_doctor.dart';
import '../../../../core/constants/appointment_status.dart';
import '../../models/doctor_appointment_models.dart';

class AppointmentCardWidget extends StatelessWidget {
  final DoctorAppointment appointment;
  final bool isDark;
  final VoidCallback onTap;

  const AppointmentCardWidget({
    super.key,
    required this.appointment,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    final (badgeBg, badgeText, badgeLabel) = switch (appointment.status) {
      AppointmentApiStatus.scheduled => (
          primaryGreen.withOpacity(0.12),
          primaryGreen,
          DoctorStrings.upcoming(context),
        ),
      AppointmentApiStatus.checkedIn => (
          const Color(0xFF8E44AD).withOpacity(0.12),
          const Color(0xFF8E44AD),
          DoctorStrings.checkedIn(context),
        ),
      AppointmentApiStatus.inProgress => (
          const Color(0xFF2980B9).withOpacity(0.12),
          const Color(0xFF2980B9),
          DoctorStrings.inProgress(context),
        ),
      AppointmentApiStatus.completed => (
          AppColors.textLightGrey.withOpacity(0.15),
          AppColors.textLightGrey,
          DoctorStrings.completed(context),
        ),
      AppointmentApiStatus.noShow => (
          const Color(0xFFE67E22).withOpacity(0.12),
          const Color(0xFFE67E22),
          DoctorStrings.noShow(context),
        ),
      AppointmentApiStatus.cancelled => (
          const Color(0xFFC0392B).withOpacity(0.12),
          const Color(0xFFC0392B),
          DoctorStrings.cancelled(context),
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14.r)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: primaryGreen.withOpacity(0.15),
              backgroundImage: (appointment.patientAvatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(appointment.patientAvatarUrl!)
                  : null,
              child: (appointment.patientAvatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(Icons.person_outline, color: primaryGreen, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(appointment.patientName,
                            style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: textColor),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20.r)),
                        child: Text(badgeLabel,
                            style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: badgeText)),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  if (appointment.clinicName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13.sp, color: AppColors.textLightGrey),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(appointment.clinicName!,
                              style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13.sp, color: AppColors.textLightGrey),
                      SizedBox(width: 4.w),
                      Text(_formatDateTime(appointment.dateTime),
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} • $h:$minute $period';
  }
}
