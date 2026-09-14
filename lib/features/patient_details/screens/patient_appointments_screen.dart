import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/appointment_status.dart';
import '../models/patient_appointment_model.dart';
import '../view_models/patient_appointments_cubit.dart';
import '../view_models/patient_appointments_state.dart';
import 'reschedule_appointment_screen.dart';
import 'widgets/rate_doctor_dialog.dart';

/// ✅ 19/8: شاشة "الحجوزات" الحقيقية للمريض (كانت Placeholder نص بس
/// بـ main_layout_screen.dart) - 3 تبويبات (حالية/سابقة/ملغاة) مربوطة
/// فعلياً بـ GET /patient/appointments، مع إلغاء وتعديل موعد.
class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return BlocConsumer<PatientAppointmentsCubit, PatientAppointmentsState>(
      listener: (context, state) {
        if (state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionErrorMessage!), backgroundColor: const Color(0xFFC0392B)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<PatientAppointmentsCubit>();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(AppStrings.bookings(context), style: TextStyle(color: primaryGreen, fontSize: 20.sp, fontWeight: FontWeight.w800)),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _TabChip(
                      label: AppStrings.upcomingAppointments(context),
                      selected: state.selectedTab == AppointmentTabGroup.upcoming,
                      isDark: isDark,
                      onTap: () => cubit.changeTab(AppointmentTabGroup.upcoming),
                    ),
                    SizedBox(width: 8.w),
                    _TabChip(
                      label: AppStrings.appointmentsHistory(context),
                      selected: state.selectedTab == AppointmentTabGroup.history,
                      isDark: isDark,
                      onTap: () => cubit.changeTab(AppointmentTabGroup.history),
                    ),
                    SizedBox(width: 8.w),
                    _TabChip(
                      label: AppStrings.cancelledAppointments(context),
                      selected: state.selectedTab == AppointmentTabGroup.cancelled,
                      isDark: isDark,
                      onTap: () => cubit.changeTab(AppointmentTabGroup.cancelled),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: state.status == PatientAppointmentsStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.status == PatientAppointmentsStatus.failure && state.all.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 40.sp, color: AppColors.textLightGrey),
                                  SizedBox(height: 12.h),
                                  Text(state.errorMessage ?? '', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 13.sp)),
                                  SizedBox(height: 10.h),
                                  TextButton(onPressed: () => cubit.load(), child: const Text('إعادة المحاولة')),
                                ],
                              ),
                            ),
                          )
                        : state.visible.isEmpty
                            ? Center(
                                child: Text(AppStrings.noAppointmentsHere(context),
                                    style: TextStyle(color: AppColors.textLightGrey, fontSize: 14.sp)),
                              )
                            : RefreshIndicator(
                                onRefresh: () => cubit.load(),
                                child: ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                                  itemCount: state.visible.length,
                                  itemBuilder: (context, index) {
                                    final appointment = state.visible[index];
                                    return _AppointmentCard(
                                      appointment: appointment,
                                      isDark: isDark,
                                      onTap: () => _showDetails(context, appointment, cubit, isDark),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, PatientAppointment appointment, PatientAppointmentsCubit cubit, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        final textColor = isDark ? AppColors.darkText : AppColors.textDark;
        final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. ${appointment.doctorName}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
              SizedBox(height: 16.h),
              if (appointment.clinicName != null) _DetailLine(label: 'Clinic', value: appointment.clinicName!, textColor: textColor),
              _DetailLine(label: 'Time', value: _formatRange(appointment.startsAt, appointment.endsAt), textColor: textColor),
              if (appointment.price != null) _DetailLine(label: 'Price', value: '\$${appointment.price}', textColor: textColor),
              if (appointment.cancellationReason != null)
                _DetailLine(label: 'Cancellation reason', value: appointment.cancellationReason!, textColor: textColor),
              SizedBox(height: 20.h),
              if (appointment.canReschedule) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: RescheduleAppointmentScreen(appointment: appointment),
                          ),
                        ),
                      );
                      if (result == true) cubit.load();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text(AppStrings.rescheduleAppointment(sheetContext), style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              if (appointment.canCancel)
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmCancel(context, appointment, cubit);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC0392B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text(AppStrings.cancelAppointmentAction(sheetContext), style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700)),
                  ),
                ),
              // ✅ الموعد المكتمل بس هو يلي بيفتح إمكانية التقييم (نفس
              // شرط الباك بـ DoctorReviewService: لازم موعد completed
              // واحد على الأقل مع هاد الطبيب).
              if (appointment.status == AppointmentApiStatus.completed && appointment.doctorId != null)
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _openRateDialog(context, appointment);
                    },
                    icon: Icon(Icons.star_rounded, color: Colors.white, size: 18.sp),
                    label: Text(AppStrings.rateDoctorAction(sheetContext), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openRateDialog(BuildContext context, PatientAppointment appointment) async {
    final doctorId = appointment.doctorId;
    if (doctorId == null) return;
    final rated = await showRateDoctorDialog(context, doctorId: doctorId, doctorName: 'Dr. ${appointment.doctorName}');
    if (rated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.reviewSubmittedSuccess(context))));
    }
  }

  /// ⚠️ 19/8: الباك صار يطلب حقل reason إلزامي عند الإلغاء (كان اختياري
  /// قبل - جربنا نرسله فاضي فرجع 422 "The reason field is required").
  /// صار لازم ناخد سبب الإلغاء فعلياً من المريض قبل ما نأكد.
  void _confirmCancel(BuildContext context, PatientAppointment appointment, PatientAppointmentsCubit cubit) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canConfirm = reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(AppStrings.cancelBookingTitle(dialogContext)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.cancelBookingDesc(dialogContext)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: DoctorStrings.cancelReasonHint(dialogContext),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppStrings.keepBooking(dialogContext))),
              TextButton(
                onPressed: !canConfirm
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await cubit.cancel(appointment.id, reason: reasonController.text.trim());
                      },
                child: Text(AppStrings.cancelAppointmentAction(dialogContext), style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$h:$minute $period';
    }
    return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} • ${fmt(start)} - ${fmt(end)}';
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointment appointment;
  final bool isDark;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appointment, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    final (badgeBg, badgeText, badgeLabel) = switch (appointment.status) {
      AppointmentApiStatus.scheduled => (primaryGreen.withOpacity(0.12), primaryGreen, 'Scheduled'),
      AppointmentApiStatus.checkedIn => (const Color(0xFF8E44AD).withOpacity(0.12), const Color(0xFF8E44AD), 'Checked in'),
      AppointmentApiStatus.inProgress => (const Color(0xFF2980B9).withOpacity(0.12), const Color(0xFF2980B9), 'In progress'),
      AppointmentApiStatus.completed => (AppColors.textLightGrey.withOpacity(0.15), AppColors.textLightGrey, 'Completed'),
      AppointmentApiStatus.noShow => (const Color(0xFFE67E22).withOpacity(0.12), const Color(0xFFE67E22), 'Did not attend'),
      AppointmentApiStatus.cancelled => (const Color(0xFFC0392B).withOpacity(0.12), const Color(0xFFC0392B), 'Cancelled'),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Dr. ${appointment.doctorName}',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20.r)),
                  child: Text(badgeLabel, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: badgeText)),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (appointment.clinicName != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13.sp, color: AppColors.textLightGrey),
                  SizedBox(width: 4.w),
                  Expanded(child: Text(appointment.clinicName!, style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey), overflow: TextOverflow.ellipsis)),
                ],
              ),
              SizedBox(height: 4.h),
            ],
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13.sp, color: AppColors.textLightGrey),
                SizedBox(width: 4.w),
                Text(_formatDateTime(appointment.startsAt), style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
              ],
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

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  const _DetailLine({required this.label, required this.value, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90.w, child: Text(label, style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.5.sp))),
          Expanded(child: Text(value, style: TextStyle(color: textColor, fontSize: 13.5.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(color: selected ? primaryGreen : cardBg, borderRadius: BorderRadius.circular(20.r)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 12.5.sp)),
      ),
    );
  }
}
