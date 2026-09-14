import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/constants/appointment_status.dart';
import '../models/doctor_appointment_models.dart';
import '../view_models/doctor_appointments_cubit.dart';
import '../view_models/doctor_appointments_state.dart';
import 'patient_medical_record_view_screen.dart';
import 'doctor_encounter_screen.dart';
import 'widgets/appointment_card_widget.dart';

/// شاشة مواعيد الطبيب - حسب المرضى الحاجزين عبر زر "احجز الآن"، مقسّمة
/// إلى ثلاث تبويبات (قادمة/سابقة/ملغاة) مع تفاصيل كل حجز وإدارة حالته
/// الفعلية (بدء الكشف / إنهاءه / لم يحضر / إلغاء) - كل هالإجراءات
/// مربوطة فعلياً بالباك (Postman: Appointment/Doctor).
class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return BlocConsumer<DoctorAppointmentsCubit, DoctorAppointmentsState>(
      listener: (context, state) {
        if (state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionErrorMessage!), backgroundColor: const Color(0xFFC0392B)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<DoctorAppointmentsCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(DoctorStrings.doctorAppointments(context),
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _TabChip(
                    label: DoctorStrings.upcoming(context),
                    selected: state.selectedTab == AppointmentTabGroup.upcoming,
                    isDark: isDark,
                    onTap: () => cubit.changeTab(AppointmentTabGroup.upcoming),
                  ),
                  SizedBox(width: 8.w),
                  _TabChip(
                    label: DoctorStrings.history(context),
                    selected: state.selectedTab == AppointmentTabGroup.history,
                    isDark: isDark,
                    onTap: () => cubit.changeTab(AppointmentTabGroup.history),
                  ),
                  SizedBox(width: 8.w),
                  _TabChip(
                    label: DoctorStrings.cancelled(context),
                    selected: state.selectedTab == AppointmentTabGroup.cancelled,
                    isDark: isDark,
                    onTap: () => cubit.changeTab(AppointmentTabGroup.cancelled),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: state.status == DoctorAppointmentsStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == DoctorAppointmentsStatus.failure && state.all.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 40.sp, color: AppColors.textLightGrey),
                                SizedBox(height: 12.h),
                                Text(state.errorMessage ?? 'تعذّر تحميل المواعيد',
                                    textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 13.sp)),
                                SizedBox(height: 10.h),
                                TextButton(onPressed: () => cubit.load(), child: const Text('إعادة المحاولة')),
                              ],
                            ),
                          ),
                        )
                      : state.visible.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_note_outlined, size: 40.sp, color: AppColors.textLightGrey),
                                    SizedBox(height: 12.h),
                                    Text(DoctorStrings.noAppointmentsYet(context),
                                        style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 6.h),
                                    Text(DoctorStrings.noAppointmentsHint(context),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.5.sp, height: 1.5)),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => cubit.load(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                                itemCount: state.visible.length,
                                itemBuilder: (context, index) {
                                  final appointment = state.visible[index];
                                  return AppointmentCardWidget(
                                    appointment: appointment,
                                    isDark: isDark,
                                    onTap: () => _showDetails(context, appointment, cubit, isDark),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }

  void _showDetails(
    BuildContext context,
    DoctorAppointment appointment,
    DoctorAppointmentsCubit cubit,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        final textColor = isDark ? AppColors.darkText : AppColors.textDark;
        final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

        // ⚠️ 20/8: تصحيح RenderFlex overflow - الـColumn كان بمينمم حجمه
        // (mainAxisSize.min) بس محتواه (تفاصيل + أزرار) ممكن يتجاوز
        // ارتفاع البوتوم شيت المتاح خصوصاً بالشاشات الصغيرة/لما في نص
        // طويل بسبب الحجز أو الإلغاء، فكان عم يفيض 29 بكسل. الحل: نلفه
        // بـSingleChildScrollView (Padding+Column ضلوا متل ما هنن).
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DoctorStrings.appointmentDetails(sheetContext),
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
              SizedBox(height: 16.h),
              _DetailLine(label: 'Patient', value: appointment.patientName, textColor: textColor),
              if (appointment.clinicName != null)
                _DetailLine(label: 'Clinic', value: appointment.clinicName!, textColor: textColor),
              _DetailLine(label: 'Time', value: _formatRange(appointment.startsAt, appointment.endsAt), textColor: textColor),
              if (appointment.price != null)
                _DetailLine(label: 'Price', value: '\$${appointment.price}', textColor: textColor),
              _DetailLine(
                  label: DoctorStrings.reasonForVisit(sheetContext),
                  value: (appointment.notes?.isNotEmpty ?? false) ? appointment.notes! : '-',
                  textColor: textColor),
              if (appointment.cancellationReason != null)
                _DetailLine(label: 'Cancellation reason', value: appointment.cancellationReason!, textColor: textColor),
              _DetailLine(
                  label: DoctorStrings.bookedOn(sheetContext),
                  value: appointment.createdAt.toString().split('.').first,
                  textColor: textColor),
              SizedBox(height: 20.h),
              // ✅ 19/8: صلاحية الطبيب برؤية السجل الطبي - محصورة بموعد
              // فعلي (نفس هالموعد)، متل ما طلب المستخدم بالضبط.
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientMedicalRecordViewScreen(
                          appointmentId: appointment.id,
                          patientName: appointment.patientName,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.folder_shared_outlined, color: primaryGreen, size: 18.sp),
                  label: Text(DoctorStrings.viewMedicalRecord(sheetContext), style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              ..._buildActions(context, sheetContext, appointment, cubit, primaryGreen),
            ],
            ),
          ),
        );
      },
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

  /// ✅ 19/8: الأزرار المتاحة صارت مرتبطة بالحالة الفعلية للموعد (مو
  /// بس "قادم/مو قادم" متل قبل) - كل حالة إلها الإجراءات المنطقية إلها
  /// فقط.
  List<Widget> _buildActions(
    BuildContext context,
    BuildContext sheetContext,
    DoctorAppointment appointment,
    DoctorAppointmentsCubit cubit,
    Color primaryGreen,
  ) {
    switch (appointment.status) {
      // ⚠️ 20/8: كانت هاي case وحدة (scheduled) بتغطي زر "ابدأ الكشف"،
      // بس الباك ما بيسمح بـstart إلا من حالة checked_in فعلياً (مو
      // scheduled) - فكان الزر عم يظهر بدري بمرحلة scheduled وبيطلع
      // 422 لما يضغط الطبيب عليه. هلق: scheduled = لسا ما انسجل وصول
      // المريض، فقط إلغاء متاح. checked_in = المريض وصل، هون فقط
      // بيصير يظهر "ابدأ الكشف".
      case AppointmentApiStatus.scheduled:
        return [
          _ActionButton(
            label: DoctorStrings.cancelAppointment(sheetContext),
            color: const Color(0xFFC0392B),
            filled: false,
            onPressed: () => _confirmCancel(context, sheetContext, appointment, cubit),
          ),
        ];
      case AppointmentApiStatus.checkedIn:
        return [
          _ActionButton(
            label: DoctorStrings.startConsultation(sheetContext),
            color: primaryGreen,
            filled: true,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final started = await cubit.start(appointment.id);
              if (started && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorEncounterScreen(appointment: appointment),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 10.h),
          _ActionButton(
            label: DoctorStrings.cancelAppointment(sheetContext),
            color: const Color(0xFFC0392B),
            filled: false,
            onPressed: () => _confirmCancel(context, sheetContext, appointment, cubit),
          ),
        ];
      case AppointmentApiStatus.inProgress:
        return [
          _ActionButton(
            label: DoctorStrings.openEncounter(sheetContext),
            color: primaryGreen,
            filled: true,
            onPressed: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorEncounterScreen(appointment: appointment),
                ),
              );
            },
          ),
          SizedBox(height: 10.h),
          _ActionButton(
            label: DoctorStrings.markCompleted(sheetContext),
            color: primaryGreen,
            filled: false,
            onPressed: () async {
              Navigator.pop(sheetContext);
              await cubit.complete(appointment.id);
            },
          ),
          SizedBox(height: 10.h),
          _ActionButton(
            label: DoctorStrings.markNoShow(sheetContext),
            color: const Color(0xFFE67E22),
            filled: false,
            onPressed: () async {
              Navigator.pop(sheetContext);
              await cubit.markNoShow(appointment.id);
            },
          ),
        ];
      case AppointmentApiStatus.completed:
      case AppointmentApiStatus.cancelled:
      case AppointmentApiStatus.noShow:
        return const [];
    }
  }

  /// ⚠️ 19/8: reason إلزامي هلق بالباك - لازم ناخده فعلياً من الطبيب.
  void _confirmCancel(BuildContext context, BuildContext sheetContext, DoctorAppointment appointment, DoctorAppointmentsCubit cubit) {
    Navigator.pop(sheetContext);
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canConfirm = reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(DoctorStrings.cancelAppointment(dialogContext)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.cancelAppointmentConfirm(dialogContext)),
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
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('رجوع')),
              TextButton(
                onPressed: !canConfirm
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await cubit.cancel(appointment.id, reason: reasonController.text.trim());
                      },
                child: Text(DoctorStrings.cancelAppointment(dialogContext), style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onPressed;
  const _ActionButton({required this.label, required this.color, required this.filled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ),
    );
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
          SizedBox(
            width: 90.w,
            child: Text(label, style: TextStyle(color: AppColors.textLightGrey, fontSize: 12.5.sp)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor, fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
          ),
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
        decoration: BoxDecoration(
          color: selected ? primaryGreen : cardBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 12.5.sp)),
      ),
    );
  }
}
