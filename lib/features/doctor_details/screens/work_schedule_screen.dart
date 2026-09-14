import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../models/doctor_appointment_models.dart';
import '../models/work_schedule_models.dart';
import '../view_models/work_schedule_cubit.dart';
import '../view_models/work_schedule_state.dart';
import 'weekly_template_editor_screen.dart';

/// شاشة إدارة جدول العمل - مطابقة لتصميم CareFlow (Figma): اختيار عيادة
/// من قائمة منسدلة، شريط تواريخ فعلية، مدة الكشف ووضع الإجازة، وأقسام
/// اليوم الثلاثة (صباح/بعد ظهر/مساء) بأوقاتها الفعلية المولّدة من الباك.
///
/// ⚠️ "Emergency Override" الموجود بتصميم الـ Figma الأصلي ما انضاف هون
/// عمداً - ما في أي endpoint بالباك يدعمها لهلق (راجع Postman collection).
class WorkScheduleScreen extends StatelessWidget {
  final bool embedded;

  const WorkScheduleScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    final body = _WorkScheduleBody(isEn: isEn, isDark: isDark);

    if (embedded) {
      return Directionality(textDirection: isEn ? TextDirection.ltr : TextDirection.rtl, child: body);
    }

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: primaryGreen),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(DoctorStrings.workScheduleManagement(context),
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
        ),
        body: body,
      ),
    );
  }
}

class _WorkScheduleBody extends StatefulWidget {
  final bool isEn;
  final bool isDark;
  const _WorkScheduleBody({required this.isEn, required this.isDark});

  @override
  State<_WorkScheduleBody> createState() => _WorkScheduleBodyState();
}

class _WorkScheduleBodyState extends State<_WorkScheduleBody> {
  late DateTime _stripStart;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _stripStart = DateTime(today.year, today.month, today.day);
  }

  List<DateTime> get _stripDays => List.generate(4, (i) => _stripStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppColors.darkCard : AppColors.white;
    final textColor = widget.isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = widget.isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return BlocConsumer<WorkScheduleCubit, WorkScheduleState>(
      listener: (context, state) {
        if (state.infoMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.infoMessage!), backgroundColor: primaryGreen),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: const Color(0xFFC0392B)),
          );
        }
        // إذا التاريخ المختار (متل بعد ما تختاره من الكاليندر) صار خارج
        // الشريط الظاهر حالياً، منرجع نمركز الشريط حوله.
        final selected = state.selectedDate;
        final visible = _stripDays.any((d) => _isSameDay(d, selected));
        if (!visible) {
          setState(() => _stripStart = DateTime(selected.year, selected.month, selected.day));
        }
      },
      builder: (context, state) {
        final cubit = context.read<WorkScheduleCubit>();

        if (state.clinics.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(DoctorStrings.noClinicsYet(context),
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp)),
            ),
          );
        }

        if (state.status == WorkScheduleStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(child: _ClinicDropdown(state: state, isDark: widget.isDark, onPick: cubit.selectClinic)),
                    SizedBox(width: 8.w),
                    _EditWeeklyHoursButton(
                      isDark: widget.isDark,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(value: cubit, child: const WeeklyTemplateEditorScreen()),
                          ),
                        );
                        cubit.load();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _DateStrip(
                  days: _stripDays,
                  selectedDate: state.selectedDate,
                  isDark: widget.isDark,
                  onPick: cubit.selectDate,
                  onPickFromCalendar: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) cubit.selectDate(picked);
                  },
                ),
                SizedBox(height: 14.h),
                _ActionChipButton(
                  icon: Icons.settings_outlined,
                  label: DoctorStrings.durationMinutes(context, state.schedule?.consultationDuration ?? 30),
                  isDark: widget.isDark,
                  onTap: () => _showDurationSheet(context, cubit, state),
                ),
                SizedBox(height: 10.h),
                _ActionChipButton(
                  icon: Icons.flight_takeoff_rounded,
                  label: DoctorStrings.vacationMode(context),
                  isDark: widget.isDark,
                  highlighted: state.isOnVacation,
                  onTap: () => _showVacationSheet(context, cubit, state),
                ),
                if (state.isOnVacation) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      DoctorStrings.onVacationUntil(context, state.schedule?.vacationEndDate ?? ''),
                      style: TextStyle(color: const Color(0xFFC0392B), fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                // ✅ إضافة: إدارة الأوقات المحجوبة (block time) - كانت
                // الإمكانية الوحيدة الموجودة سابقاً هي حجب Slot واحد من
                // شاشة الأوقات المتاحة مباشرة (blockSlot)، بدون أي طريقة
                // لعرض/حذف الأوقات المحجوبة أو حجب وقت متكرر بيوم أسبوعي.
                _ActionChipButton(
                  icon: Icons.block_rounded,
                  label: DoctorStrings.blockTime(context),
                  isDark: widget.isDark,
                  highlighted: state.blockedTimes.isNotEmpty,
                  onTap: () => _showBlockedTimesSheet(context, cubit, state),
                ),
                SizedBox(height: 18.h),
                if (state.status == WorkScheduleStatus.loading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _DaySectionCard(
                    section: DaySection.morning,
                    icon: Icons.wb_twilight_rounded,
                    label: DoctorStrings.morning(context),
                    state: state,
                    isDark: widget.isDark,
                    cubit: cubit,
                  ),
                  SizedBox(height: 14.h),
                  _DaySectionCard(
                    section: DaySection.afternoon,
                    icon: Icons.wb_sunny_outlined,
                    label: DoctorStrings.afternoon(context),
                    state: state,
                    isDark: widget.isDark,
                    cubit: cubit,
                    showLunchBreak: state.sessionFor(DaySection.morning) != null && (state.schedule?.breakDuration ?? 0) > 0,
                  ),
                  SizedBox(height: 14.h),
                  _DaySectionCard(
                    section: DaySection.evening,
                    icon: Icons.nightlight_round,
                    label: DoctorStrings.evening(context),
                    state: state,
                    isDark: widget.isDark,
                    cubit: cubit,
                  ),
                ],
              ],
            ),
            if (state.status == WorkScheduleStatus.saving)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _showDurationSheet(BuildContext context, WorkScheduleCubit cubit, WorkScheduleState state) {
    int duration = state.schedule?.consultationDuration ?? 30;
    int breakDuration = state.schedule?.breakDuration ?? 10;
    bool buffer = state.schedule?.bufferEnabled ?? true;
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
        final textColor = isDark ? AppColors.darkText : AppColors.textDark;
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.duration(sheetContext),
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                SizedBox(height: 16.h),
                _StepperRow(
                  label: DoctorStrings.durationMinutes(sheetContext, duration),
                  value: duration,
                  min: 10,
                  max: 120,
                  step: 5,
                  textColor: textColor,
                  primaryGreen: primaryGreen,
                  onChanged: (v) => setSheetState(() => duration = v),
                ),
                SizedBox(height: 12.h),
                _StepperRow(
                  label: DoctorStrings.breakDurationMinutes(sheetContext, breakDuration),
                  value: breakDuration,
                  min: 0,
                  max: 60,
                  step: 5,
                  textColor: textColor,
                  primaryGreen: primaryGreen,
                  onChanged: (v) => setSheetState(() => breakDuration = v),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DoctorStrings.bufferEnabled(sheetContext), style: TextStyle(fontSize: 13.sp, color: textColor)),
                    Switch.adaptive(
                      value: buffer,
                      activeTrackColor: primaryGreen,
                      onChanged: (v) => setSheetState(() => buffer = v),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      cubit.updateDuration(consultationDuration: duration, breakDuration: breakDuration, bufferEnabled: buffer);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: Text(DoctorStrings.save(sheetContext), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showVacationSheet(BuildContext context, WorkScheduleCubit cubit, WorkScheduleState state) {
    final isDark = widget.isDark;
    if (state.isOnVacation) {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        builder: (sheetContext) {
          final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      cubit.deactivateVacation();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: Text(DoctorStrings.deactivateVacation(sheetContext),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        DateTime? start;
        DateTime? end;
        final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
        final textColor = isDark ? AppColors.darkText : AppColors.textDark;
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.activateVacation(sheetContext),
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                SizedBox(height: 16.h),
                _DatePickField(
                  label: DoctorStrings.vacationFrom(sheetContext),
                  value: start,
                  textColor: textColor,
                  primaryGreen: primaryGreen,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => start = picked);
                  },
                ),
                SizedBox(height: 10.h),
                _DatePickField(
                  label: DoctorStrings.vacationTo(sheetContext),
                  value: end,
                  textColor: textColor,
                  primaryGreen: primaryGreen,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: start ?? DateTime.now(),
                      firstDate: start ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => end = picked);
                  },
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: (start == null || end == null)
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            cubit.activateVacation(start: start!, end: end!);
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: Text(DoctorStrings.save(sheetContext), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// ✅ إضافة: شيت إدارة الأوقات المحجوبة - عرض اللائحة الحالية (من
  /// getBlockedTimes) مع إمكانية حذف أي عنصر (deleteBlockedTime)، وزر
  /// لإضافة حجب جديد إما بتاريخ محدد مرة وحدة أو متكرر بيوم أسبوعي.
  void _showBlockedTimesSheet(BuildContext context, WorkScheduleCubit cubit, WorkScheduleState state) {
    final isDark = widget.isDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        return BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
          bloc: cubit,
          builder: (context, liveState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h + MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DoctorStrings.blockedTimesTitle(sheetContext),
                          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                        onPressed: () => _showAddBlockedTimeSheet(context, cubit),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (liveState.blockedTimes.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      child: Text(DoctorStrings.noBlockedTimes(sheetContext),
                          style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp)),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 320.h),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: liveState.blockedTimes.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, i) {
                          final bt = liveState.blockedTimes[i];
                          final label = bt.blockDate != null
                              ? bt.blockDate!
                              : DoctorStrings.everyWeekday(
                                  sheetContext,
                                  DoctorStrings.weekdayFull(sheetContext, bt.dayOfWeek == 0 ? 7 : (bt.dayOfWeek ?? 7)),
                                );
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0392B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.block_rounded, size: 18.sp, color: const Color(0xFFC0392B)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '$label  •  ${bt.startTime} - ${bt.endTime}',
                                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => cubit.unblockTime(bt.id),
                                  child: Text(DoctorStrings.unblock(sheetContext), style: const TextStyle(color: Color(0xFFC0392B))),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBlockedTimeSheet(BuildContext context, WorkScheduleCubit cubit) {
    final isDark = widget.isDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        bool recurring = false;
        DateTime? date;
        int weekday = 1; // DateTime convention: 1=Monday
        TimeOfDay? start;
        TimeOfDay? end;
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.addBlockedTime(sheetContext),
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(DoctorStrings.blockByDate(sheetContext), style: TextStyle(fontSize: 11.5.sp)),
                        selected: !recurring,
                        onSelected: (_) => setSheetState(() => recurring = false),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(DoctorStrings.blockByWeekday(sheetContext), style: TextStyle(fontSize: 11.5.sp)),
                        selected: recurring,
                        onSelected: (_) => setSheetState(() => recurring = true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                if (!recurring)
                  _DatePickField(
                    label: DoctorStrings.blockByDate(sheetContext),
                    value: date,
                    textColor: textColor,
                    primaryGreen: primaryGreen,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setSheetState(() => date = picked);
                    },
                  )
                else
                  DropdownButtonFormField<int>(
                    value: weekday,
                    decoration: InputDecoration(
                      labelText: DoctorStrings.selectDay(sheetContext),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    items: List.generate(7, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text(DoctorStrings.weekdayFull(sheetContext, d))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => weekday = v ?? 1),
                  ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: sheetContext, initialTime: start ?? const TimeOfDay(hour: 9, minute: 0));
                          if (picked != null) setSheetState(() => start = picked);
                        },
                        child: Text(start == null ? DoctorStrings.startTime(sheetContext) : start!.format(sheetContext)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: sheetContext, initialTime: end ?? const TimeOfDay(hour: 10, minute: 0));
                          if (picked != null) setSheetState(() => end = picked);
                        },
                        child: Text(end == null ? DoctorStrings.endTime(sheetContext) : end!.format(sheetContext)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: (start == null || end == null || (!recurring && date == null))
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            if (recurring) {
                              // DoctorStrings.weekdayFull بتتوقع اتفاقية DateTime
                              // (1=اثنين..7=أحد) - نحول لاتفاقية الباك (0=أحد..6=سبت)
                              // نفس الطريقة المستخدمة بـ weekly_template_editor_screen.
                              final backendDayOfWeek = weekday % 7;
                              cubit.blockDayOfWeek(dayOfWeek: backendDayOfWeek, start: start!, end: end!);
                            } else {
                              cubit.blockDate(date: date!, start: start!, end: end!);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: Text(DoctorStrings.save(sheetContext), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _EditWeeklyHoursButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _EditWeeklyHoursButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r)),
        child: Icon(Icons.edit_calendar_outlined, color: primaryGreen, size: 20.sp),
      ),
    );
  }
}

class _ClinicDropdown extends StatelessWidget {
  final WorkScheduleState state;
  final bool isDark;
  final ValueChanged<int> onPick;

  const _ClinicDropdown({required this.state, required this.isDark, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: state.clinics.length <= 1
          ? null
          : () => showModalBottomSheet(
                context: context,
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < state.clinics.length; i++)
                        ListTile(
                          title: Text(state.clinics[i].name, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                          trailing: i == state.selectedClinicIndex
                              ? Icon(Icons.check_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                              : null,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onPick(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.selectedClinic?.name ?? '',
                style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state.clinics.length > 1) Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLightGrey),
          ],
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDate;
  final bool isDark;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onPickFromCalendar;

  const _DateStrip({
    required this.days,
    required this.selectedDate,
    required this.isDark,
    required this.onPick,
    required this.onPickFromCalendar,
  });

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SizedBox(
      height: 64.h,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final day = days[index];
                final selected = _isSameDay(day, selectedDate);
                return GestureDetector(
                  onTap: () => onPick(day),
                  child: Container(
                    width: 58.w,
                    decoration: BoxDecoration(
                      color: selected ? primaryGreen : cardBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(weekdayLabels[day.weekday % 7],
                            style: TextStyle(fontSize: 11.sp, color: selected ? Colors.white70 : AppColors.textLightGrey)),
                        SizedBox(height: 2.h),
                        Text('${day.day}',
                            style: TextStyle(
                                fontSize: 15.sp, fontWeight: FontWeight.w800, color: selected ? Colors.white : textColor)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onPickFromCalendar,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(Icons.calendar_month_outlined, color: primaryGreen, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool highlighted;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: highlighted ? primaryGreen.withOpacity(0.12) : cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: highlighted ? Border.all(color: primaryGreen.withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19.sp, color: highlighted ? primaryGreen : textColor),
            SizedBox(width: 12.w),
            Text(label, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: highlighted ? primaryGreen : textColor)),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color textColor;
  final Color primaryGreen;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.textColor,
    required this.primaryGreen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, color: textColor)),
        SizedBox(height: 8.h),
        Row(
          children: [
            _stepBtn(Icons.remove_rounded, () => onChanged((value - step).clamp(min, max))),
            SizedBox(width: 14.w),
            SizedBox(
              width: 40.w,
              child: Text('$value', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
            ),
            SizedBox(width: 14.w),
            _stepBtn(Icons.add_rounded, () => onChanged((value + step).clamp(min, max))),
          ],
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: primaryGreen.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: Icon(icon, size: 18, color: primaryGreen)),
        ),
      ),
    );
  }
}

class _DatePickField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Color textColor;
  final Color primaryGreen;
  final VoidCallback onTap;

  const _DatePickField({
    required this.label,
    required this.value,
    required this.textColor,
    required this.primaryGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16.sp, color: primaryGreen),
            SizedBox(width: 10.w),
            Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
            const Spacer(),
            Text(
              value == null
                  ? '--'
                  : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySectionCard extends StatelessWidget {
  final DaySection section;
  final IconData icon;
  final String label;
  final WorkScheduleState state;
  final bool isDark;
  final WorkScheduleCubit cubit;
  final bool showLunchBreak;

  const _DaySectionCard({
    required this.section,
    required this.icon,
    required this.label,
    required this.state,
    required this.isDark,
    required this.cubit,
    this.showLunchBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    final session = state.sessionFor(section);
    final slots = state.slotsFor(section);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: primaryGreen),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: primaryGreen)),
              const Spacer(),
              if (session != null)
                InkWell(
                  onTap: () => _confirmRemove(context),
                  child: Icon(Icons.close_rounded, size: 18.sp, color: AppColors.textLightGrey),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(height: 1, color: AppColors.borderGrey.withOpacity(0.4)),
          ),
          if (showLunchBreak) ...[
            _StaticGreyRow(icon: Icons.restaurant_outlined, label: DoctorStrings.lunchBreak(context)),
            SizedBox(height: 8.h),
          ],
          if (session == null)
            _EmptySlotBox(label: DoctorStrings.noSlotsConfiguredFor(context, label), onTap: () => _showAddSessionDialog(context))
          else if (slots.isEmpty)
            _EmptySlotBox(label: DoctorStrings.noSlotsConfigured(context), onTap: null)
          else
            Column(
              children: [
                for (final slot in slots) ...[
                  _SlotRow(
                    slot: slot,
                    overlappingAppointment: state.appointmentOverlapping(slot),
                    isDark: isDark,
                    onBlock: () => cubit.blockSlot(slot),
                  ),
                  SizedBox(height: 8.h),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(DoctorStrings.removeSession(dialogContext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.removeSession(section);
            },
            child: Text(DoctorStrings.removeSession(dialogContext), style: const TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    TimeOfDay? start;
    TimeOfDay? end;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DoctorStrings.addSessionFor(sheetContext, label),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: primaryGreen)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: DoctorStrings.startTime(sheetContext),
                        value: start,
                        textColor: textColor,
                        primaryGreen: primaryGreen,
                        onTap: () async {
                          final picked = await showTimePicker(context: sheetContext, initialTime: const TimeOfDay(hour: 9, minute: 0));
                          if (picked != null) setSheetState(() => start = picked);
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _TimeField(
                        label: DoctorStrings.endTime(sheetContext),
                        value: end,
                        textColor: textColor,
                        primaryGreen: primaryGreen,
                        onTap: () async {
                          final picked = await showTimePicker(context: sheetContext, initialTime: const TimeOfDay(hour: 13, minute: 0));
                          if (picked != null) setSheetState(() => end = picked);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: (start == null || end == null)
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            cubit.addSession(section, start!, end!);
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                    child: Text(DoctorStrings.save(sheetContext), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final Color textColor;
  final Color primaryGreen;
  final VoidCallback onTap;

  const _TimeField({required this.label, required this.value, required this.textColor, required this.primaryGreen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(8.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5.sp, color: AppColors.textLightGrey)),
            SizedBox(height: 2.h),
            Text(value == null ? '--:--' : value!.format(context),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _EmptySlotBox extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _EmptySlotBox({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderGrey, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey)),
            if (onTap != null) ...[
              SizedBox(height: 6.h),
              Icon(Icons.add_circle_outline_rounded, size: 18.sp, color: AppColors.textLightGrey),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaticGreyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StaticGreyRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: AppColors.textLightGrey.withOpacity(0.10), borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: AppColors.textLightGrey),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey)),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final AvailabilitySlot slot;
  final DoctorAppointment? overlappingAppointment;
  final bool isDark;
  final VoidCallback onBlock;

  const _SlotRow({required this.slot, required this.overlappingAppointment, required this.isDark, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final timeLabel = '${slot.startsAt.hour.toString().padLeft(2, '0')}:${slot.startsAt.minute.toString().padLeft(2, '0')}';

    if (overlappingAppointment != null) {
      final reason = overlappingAppointment!.reason ?? DoctorStrings.appointment(context);
      return Container(
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border(left: BorderSide(color: primaryGreen, width: 3.w)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeLabel, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: textColor)),
                  SizedBox(height: 2.h),
                  Text(reason, style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 15.r,
              backgroundColor: primaryGreen.withOpacity(0.15),
              child: Icon(Icons.person_outline, size: 15.sp, color: primaryGreen),
            ),
          ],
        ),
      );
    }

    if (!slot.isAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(color: AppColors.textLightGrey.withOpacity(0.10), borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          children: [
            Text(timeLabel, style: TextStyle(fontSize: 13.5.sp, color: AppColors.textLightGrey)),
            const Spacer(),
            Text(DoctorStrings.blocked(context), style: TextStyle(fontSize: 12.sp, color: AppColors.textLightGrey)),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showSlotActions(context),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(color: AppColors.textLightGrey.withOpacity(0.08), borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          children: [
            Text(timeLabel, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
              child: Text(DoctorStrings.available(context), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: primaryGreen)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlotActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: ListTile(
            leading: const Icon(Icons.block_rounded, color: Color(0xFFC0392B)),
            title: Text(DoctorStrings.blockThisSlot(sheetContext)),
            onTap: () {
              Navigator.pop(sheetContext);
              onBlock();
            },
          ),
        ),
      ),
    );
  }
}
