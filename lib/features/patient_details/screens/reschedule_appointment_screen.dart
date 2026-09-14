import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../doctor_details/data/doctor_schedule_repository.dart';
import '../../doctor_details/models/work_schedule_models.dart';
import '../models/patient_appointment_model.dart';
import '../view_models/patient_appointments_cubit.dart';

/// ✅ 19/8: شاشة اختيار موعد جديد لنفس الطبيب/العيادة لتعديل حجز موجود
/// (POST /patient/appointments/{id}/reschedule) - نفس منطق شريط الأيام
/// وشرائح الأوقات المستخدم بشاشة بروفايل الطبيب، بس هون الهدف تبديل
/// slot_id لحجز موجود بدل إنشاء حجز جديد.
class RescheduleAppointmentScreen extends StatefulWidget {
  final PatientAppointment appointment;
  const RescheduleAppointmentScreen({super.key, required this.appointment});

  @override
  State<RescheduleAppointmentScreen> createState() => _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState extends State<RescheduleAppointmentScreen> {
  final DoctorScheduleRepository _scheduleRepository = DoctorScheduleRepository();
  late final List<DateTime> _days;
  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;
  List<AvailabilitySlot> _slots = [];
  AvailabilitySlot? _selectedSlot;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(90, (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i)));
    _selectedDate = _days.first;
    _load();
  }

  Future<void> _load() async {
    final doctorId = widget.appointment.doctorId;
    final clinicId = widget.appointment.clinicId;
    if (doctorId == null || clinicId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحديد الطبيب/العيادة لهالحجز';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final slots = await _scheduleRepository.getAvailability(
        doctorId: doctorId,
        clinicId: clinicId,
        dateFrom: DateTime.now(),
        dateTo: DateTime.now().add(const Duration(days: 90)),
      );
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحميل الأوقات المتاحة';
      });
    }
  }

  List<AvailabilitySlot> get _daySlots => _slots
      .where((s) =>
          s.startsAt.year == _selectedDate.year &&
          s.startsAt.month == _selectedDate.month &&
          s.startsAt.day == _selectedDate.day)
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  Future<void> _confirm() async {
    if (_selectedSlot == null) return;
    setState(() => _isSubmitting = true);
    final cubit = context.read<PatientAppointmentsCubit>();
    final updated = await cubit.reschedule(appointmentId: widget.appointment.id, newSlotId: _selectedSlot!.id);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (updated != null) {
      Navigator.pop(context, true);
    } else {
      final msg = cubit.state.actionErrorMessage ?? AppStrings.slotNoLongerAvailable(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFC0392B)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final border = isDark ? Colors.white24 : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
        elevation: 0,
        title: Text(AppStrings.rescheduleAppointment(context), style: TextStyle(color: textColor, fontSize: 16.sp, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: textColor)))
              : Column(
                  children: [
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(AppStrings.selectNewSlot(context),
                            style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 64.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _days.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final isSelected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedDate = day;
                              _selectedSlot = null;
                            }),
                            child: Container(
                              width: 52.w,
                              decoration: BoxDecoration(
                                color: isSelected ? primaryGreen : cardBg,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: isSelected ? primaryGreen : border),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${day.day}', style: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.w700, fontSize: 14.sp)),
                                  Text(_weekdayShort(day.weekday), style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textLightGrey, fontSize: 10.sp)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: _daySlots.isEmpty
                          ? Center(child: Text(AppStrings.noSlotsForPeriod(context), style: TextStyle(color: AppColors.textLightGrey)))
                          : SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Wrap(
                                spacing: 10.w,
                                runSpacing: 10.h,
                                children: _daySlots.map((slot) {
                                  final isSelected = _selectedSlot?.id == slot.id;
                                  final isDisabled = !slot.isAvailable;
                                  final label = '${slot.startsAt.hour.toString().padLeft(2, '0')}:${slot.startsAt.minute.toString().padLeft(2, '0')}';
                                  return GestureDetector(
                                    onTap: isDisabled ? null : () => setState(() => _selectedSlot = slot),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryGreen : (isDisabled ? Colors.black.withOpacity(0.05) : cardBg),
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(color: isSelected ? primaryGreen : (isDisabled ? Colors.transparent : border)),
                                      ),
                                      child: Text(label,
                                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDisabled ? AppColors.textLightGrey.withOpacity(0.4) : (isSelected ? Colors.white : textColor))),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: (_selectedSlot == null || _isSubmitting) ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            disabledBackgroundColor: primaryGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(AppStrings.confirmYes(context), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _weekdayShort(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }
}
