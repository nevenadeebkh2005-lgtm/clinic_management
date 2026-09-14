import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cubits/medical_record_status_cubit.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../consultations/screens/chat_thread_screen.dart';
import '../../doctor_details/data/doctor_schedule_repository.dart';
import '../../doctor_details/models/work_schedule_models.dart';
import '../data/patient_appointments_repository.dart';
import '../data/doctor_engagement_repository.dart';
import '../models/doctor_dummy_data.dart';
import '../models/doctor_engagement_models.dart';
import '../models/patient_appointment_model.dart';
import '../view_models/doctor_listing_cubit.dart';
import '../view_models/patient_appointments_cubit.dart';
import 'widgets/report_doctor_dialog.dart';
import '../../payments/screens/booking_payment_sheet.dart';

/// ✅ 17/8: هاي الشاشة كانت بالكامل بيانات وهمية ثابتة (تواريخ/أوقات
/// مكتوبة يدوياً بالكود). صارت هلق تجيب فعلياً جدول الطبيب الحقيقي يلي
/// هو نفسه دخله من جهته (عبر GET /doctors/{id}/availability - نفس
/// الـ endpoint الحقيقي المستخدم أصلاً بجهة الطبيب لعرض جدوله).
class DoctorProfileScreen extends StatefulWidget {
  final DoctorListingModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorScheduleRepository _repository = DoctorScheduleRepository();
  // ⚠️ 19/8: نداء حجز مباشر (مو عبر Cubit موفّر بشجرة Provider) عمداً -
  // هاي الشاشة بتتفتح من أكتر من مكان (doctor_card_widget/home_doctor_tile)
  // وشفنا قبل هيك كتير مشاكل ProviderNotFoundException لما نعتمد على
  // context.read لكيوبت موفّر بمكان تاني بعيد. الحجز نفسه إجراء واحد
  // بسيط (POST) فما في داعي لكيوبت أصلاً هون.
  final PatientAppointmentsRepository _appointmentsRepository =
      PatientAppointmentsRepository();
  final DoctorEngagementRepository _engagementRepository =
      DoctorEngagementRepository();
  final AuthRepository _authRepository = AuthRepository();
  bool _isBooking = false;
  bool _isOpeningChat = false;

  // ✅ مفضلة/تقييم حقيقيين (Favorites + Reviews - DoctorEngagement module).
  late bool _isFavourite = widget.doctor.isFavourite;
  bool _isTogglingFavorite = false;
  DoctorRatingSummary? _ratingSummary;

  late final List<DateTime> _days;
  late DateTime _selectedDate;
  int _selectedClinicIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  List<AvailabilitySlot> _slots = [];
  AvailabilitySlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // ⚠️ 19/8: كان محدود بـ 7 أيام بس، رغم إنه _loadAvailability() أصلاً
    // كان يجيب سلوتس لـ 90 يوم قدام من الباك (دورة الشريط هاي كانت هي
    // الاختناق الحقيقي يلي مانع المريض يحجز إلا لأسبوع قدام بس).
    _days = List.generate(
      90,
      (i) =>
          DateTime(today.year, today.month, today.day).add(Duration(days: i)),
    );
    _selectedDate = _days.first;
    _loadAvailability();
    _loadRatingSummary();
  }

  /// ✅ ملخص التقييمات العام (متوسط + عدد) من endpoint عام (public) -
  /// هيك التقييمات يلي بيضيفها المرضى عبر نافذة "قيّم الطبيب" بعد
  /// الموعد المكتمل بتظهر فعلياً هون لكل الزوار، مو بس رقم ثابت جاي
  /// من لائحة الأطباء.
  Future<void> _loadRatingSummary() async {
    final doctorId = _doctorId;
    if (doctorId == null) return;
    try {
      final summary = await _engagementRepository.getRatingSummary(doctorId);
      if (!mounted) return;
      setState(() => _ratingSummary = summary);
    } catch (_) {
      // ✅ فشل جلب الملخص مش خطأ حرج - بنضل عارضين قيمة doctor.rating
      // الافتراضية (لو موجودة) بدل ما نكسر الشاشة كلها.
    }
  }

  Future<void> _toggleFavorite() async {
    final doctorId = _doctorId;
    if (doctorId == null || _isTogglingFavorite) return;
    setState(() => _isTogglingFavorite = true);
    try {
      final isFavorite = await _engagementRepository.toggleFavorite(doctorId);
      if (!mounted) return;
      setState(() {
        _isFavourite = isFavorite;
        _isTogglingFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? AppStrings.favoriteAdded(context)
                : AppStrings.favoriteRemoved(context),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTogglingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.unexpectedError(context)),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  Future<void> _openReportDialog() async {
    final doctorId = _doctorId;
    if (doctorId == null) return;
    final reported = await showReportDoctorDialog(context, doctorId: doctorId);
    if (reported == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.reportSubmittedSuccess(context))),
      );
    }
  }

  /// بتفتح محادثة مع هاد الطبيب. الشات بالباك مربوط بموعد (appointment)
  /// مو بطبيب مباشرة (ما في endpoint لـ"ابدأ محادثة مع أي طبيب") - فلازم
  /// نلاقي أول موعد حقيقي بين المريض وهاد الطبيب ونفتح محادثته، وإذا ما
  /// في أي موعد نطلب من المريض يحجز أول.
  Future<void> _openChatWithDoctor() async {
    final doctorId = _doctorId;
    if (doctorId == null || _isOpeningChat) return;

    setState(() => _isOpeningChat = true);
    try {
      final results = await Future.wait([
        _appointmentsRepository.getAppointments(),
        _authRepository.me(),
      ]);
      final appointments = results[0] as List<PatientAppointment>;
      final me = results[1] as Map<String, dynamic>;
      final currentUserId = int.tryParse('${me['id']}');

      final withDoctor =
          appointments.where((a) => a.doctorId == doctorId).toList()
            // أحدث موعد أولاً (سواء قادم أو ماضي) - أي موعد فعلي بيكفي لفتح
            // المحادثة، الباك بس بيتحقق إنو المريض طرف بهاد الموعد.
            ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

      if (!mounted) return;

      if (currentUserId == null) {
        // فشلنا نجيب هوية المستخدم الحالي (نادراً، متل توكن منتهي) - هاد
        // خطأ حقيقي، مختلف عن "ما في موعد بعد" يلي هي حالة متوقعة.
        setState(() => _isOpeningChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.unexpectedError(context)),
            backgroundColor: const Color(0xFFC0392B),
          ),
        );
        return;
      }

      if (withDoctor.isEmpty) {
        setState(() => _isOpeningChat = false);
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              AppStrings.messageDoctorRequiresAppointmentTitle(dialogContext),
            ),
            content: Text(
              AppStrings.messageDoctorRequiresAppointmentBody(dialogContext),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppStrings.ok(dialogContext)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() => _isOpeningChat = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            appointmentId: withDoctor.first.id,
            otherPartyName: widget.doctor.fullName,
            currentUserId: currentUserId,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isOpeningChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOpeningChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.unexpectedError(context)),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  int? get _doctorId => int.tryParse(widget.doctor.id);

  int? get _selectedClinicId {
    if (widget.doctor.clinicRefs.isEmpty) return null;
    return widget
        .doctor
        .clinicRefs[_selectedClinicIndex.clamp(
          0,
          widget.doctor.clinicRefs.length - 1,
        )]
        .id;
  }

  Future<void> _loadAvailability() async {
    final doctorId = _doctorId;
    final clinicId = _selectedClinicId;
    if (doctorId == null || clinicId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedSlot = null;
    });
    try {
      final slots = await _repository.getAvailability(
        doctorId: doctorId,
        clinicId: clinicId,
        dateFrom: DateTime.now(),
        dateTo: DateTime.now().add(const Duration(days: 90)),
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slots = [];
        _isLoading = false;
        _errorMessage = '$e';
      });
    }
  }

  // ⚠️ 20/8: تصحيح - كان الفلترة هون بس على اليوم (سنة/شهر/يوم) بدون
  // أي مقارنة بالوقت الحالي، فلما يكون اليوم المختار هو اليوم الحالي
  // فعلياً، كانت سلوتس الصباح يلي فاتت (مثلاً 9:00 صباحاً والوقت هلق
  // 1:00 ظهراً) تضل طالعة وتقدر تنضغط وكأنها متاحة، رغم إنها فعلياً
  // فاتت. الباك نفسه ما بيفلترها (راجع ملاحظة المستخدم)، فصار لازم
  // نستثنيها هون بالواجهة: أي سلوت starts_at قبل اللحظة الحالية.
  List<AvailabilitySlot> _slotsForSelectedDate() {
    // مطابقةً لنفس منطق AvailabilitySlot.fromJson (راجع تعليقه): startsAt
    // محفوظ كـ"خام" (ساعة/دقيقة محلية فعلية لكن معلّم isUtc) بدون أي
    // تحويل توقيت - فلازم نقارنه بـ"الآن" بنفس الشكل الخام، مو بـ
    // DateTime.now() مباشرة (يلي هو local وممكن يعطي فرق غلط بمقدار
    // فارق توقيت الجهاز عن UTC ويفلتر/يبين سلوتس غلط).
    final now = DateTime.now();
    final nowRaw = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    return _slots
        .where(
          (s) =>
              s.startsAt.year == _selectedDate.year &&
              s.startsAt.month == _selectedDate.month &&
              s.startsAt.day == _selectedDate.day &&
              s.startsAt.isAfter(nowRaw),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final settingsState = context.watch<SettingsCubit>().state;
    final currentScale = settingsState.fontScale;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    // ✅ حي عبر Cubit مشترك (راجع core/cubits/medical_record_status_cubit.dart)
    // - مو حساب ثابت، فبيتحدث فوراً لو المريض عبّى سجله بمنتصف نفس الجلسة.
    final hasMedicalRecord = context.watch<MedicalRecordStatusCubit>().state;

    double nameSize = 20.sp;
    double specialtySize = 14.sp;
    double sectionTitleSize = 16.sp;
    double bodyTextSize = 13.sp;
    double feeSize = 18.sp;

    if (currentScale == FontScale.medium) {
      nameSize = 23.sp;
      specialtySize = 16.sp;
      sectionTitleSize = 18.sp;
      bodyTextSize = 15.sp;
      feeSize = 21.sp;
    } else if (currentScale == FontScale.large) {
      nameSize = 26.sp;
      specialtySize = 18.sp;
      sectionTitleSize = 20.sp;
      bodyTextSize = 17.sp;
      feeSize = 24.sp;
    }

    final scaffoldBg = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundBeige;
    final cardBgColor = isDark ? AppColors.darkCard : AppColors.white;
    final doctorCardBg = isDark
        ? const Color(0xFF23392E)
        : const Color(0xFFC4D7C5);
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreenColor = isDark
        ? AppColors.darkPrimaryGreen
        : AppColors.primaryGreen;
    final borderColor = isDark ? Colors.white10 : AppColors.borderGrey;

    // ⚠️ 19/8: صارت 3 فترات (صباح/بعد ظهر/مساء) بدل فترتين بس، بنفس
    // الحدود يلي الطبيب عم يستخدمها فعلياً بواجهته (weekly_template_editor_screen:
    // صباح قبل الظهر، بعد ظهر من الظهر لحوالي 5، مساء من حوالي 5 ونص).
    // الباك ما بيرجع session_type مع كل Slot (GET /doctors/{id}/availability
    // ما فيها هيك حقل)، فما فينا نطابق حدود كل يوم بالضبط متل ما حددها
    // الطبيب تماماً - بس هالحدود (12:00 / 17:00) بتغطي أي إعداد طبيعي
    // للفترات الثلاث بشكل صحيح عملياً.
    final daySlots = _slotsForSelectedDate();
    final morningSlots = daySlots.where((s) => s.startsAt.hour < 12).toList();
    final afternoonSlots = daySlots
        .where((s) => s.startsAt.hour >= 12 && s.startsAt.hour < 17)
        .toList();
    final eveningSlots = daySlots.where((s) => s.startsAt.hour >= 17).toList();

    final displayFee = widget.doctor.clinicRefs.isNotEmpty
        ? (widget
                  .doctor
                  .clinicRefs[_selectedClinicIndex.clamp(
                    0,
                    widget.doctor.clinicRefs.length - 1,
                  )]
                  .consultationFee ??
              doctor.consultationFee)
        : doctor.consultationFee;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.reportDoctorAction(context),
            icon: Icon(Icons.flag_outlined, color: textColor, size: 22.sp),
            onPressed: _openReportDialog,
          ),
          IconButton(
            icon: _isTogglingFavorite
                ? SizedBox(
                    width: 20.sp,
                    height: 20.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Icon(
                    _isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavourite ? const Color(0xFFD85A30) : textColor,
                    size: 24.sp,
                  ),
            onPressed: _isTogglingFavorite ? null : _toggleFavorite,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: doctorCardBg,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ الأولوية لملخص التقييمات الحقيقي (public
                              // GET /doctors/{id}/reviews/summary) - يعكس
                              // فعلياً كل تقييمات "قيّم الطبيب" المرسلة من
                              // المرضى. لو ما وصل بعد (تحميل/فشل) منرجع
                              // لقيمة doctor.rating الجاهزة كـ fallback.
                              if ((_ratingSummary?.averageRating ??
                                      doctor.rating) >
                                  0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark
                                                ? AppColors.darkCard
                                                : AppColors.white)
                                            .withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: const Color(0xFFFBBF24),
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        (_ratingSummary?.averageRating ??
                                                doctor.rating)
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      if ((_ratingSummary?.totalReviews ??
                                              doctor.reviewCount) >
                                          0) ...[
                                        SizedBox(width: 4.w),
                                        Text(
                                          '(${_ratingSummary?.totalReviews ?? doctor.reviewCount})',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              SizedBox(height: 16.h),
                              Text(
                                doctor.fullName,
                                style: TextStyle(
                                  fontSize: nameSize,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                doctor.department,
                                style: TextStyle(
                                  fontSize: specialtySize,
                                  color: textColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Row(
                                children: [
                                  _buildQuickActionIcon(
                                    Icons.phone,
                                    cardBgColor,
                                    primaryGreenColor,
                                  ),
                                  SizedBox(width: 12.w),
                                  _buildQuickActionIcon(
                                    Icons.videocam_rounded,
                                    cardBgColor,
                                    primaryGreenColor,
                                  ),
                                  SizedBox(width: 12.w),
                                  _buildQuickActionIcon(
                                    Icons.location_on_rounded,
                                    cardBgColor,
                                    primaryGreenColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 85.w,
                              height: 95.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: cardBgColor,
                                image:
                                    doctor.profileImageUrl != null &&
                                        doctor.profileImageUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          doctor.profileImageUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : const DecorationImage(
                                        image: AssetImage(
                                          'assets/images/doctor_placeholder.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    if (widget.doctor.clinicRefs.length > 1) ...[
                      SizedBox(
                        height: 40.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.doctor.clinicRefs.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedClinicIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedClinicIndex = index);
                                _loadAvailability();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryGreenColor
                                      : cardBgColor,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  widget.doctor.clinicRefs[index].name,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    Text(
                      AppStrings.about(context),
                      style: TextStyle(
                        fontSize: sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: primaryGreenColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // ✅ إصلاح: كان هون نص عام ثابت (hardcoded) دايماً - ما
                    // كان في أصلاً حقل biography بالموديل، فمهما كتب
                    // الطبيب بنبذته من بروفايله ما كانت تطلع عند المريض.
                    // هلق منعرض doctor.biography الحقيقية، وإذا فاضية
                    // منرجع لنفس نص "لسا ما في نبذة" يلي الطبيب شايفه
                    // بصفحته هو (DoctorStrings.noBiographyYet) بدل النص
                    // الإنجليزي الثابت القديم.
                    Text(
                      (doctor.biography != null &&
                              doctor.biography!.trim().isNotEmpty)
                          ? doctor.biography!.trim()
                          : DoctorStrings.noBiographyYet(context),
                      style: TextStyle(
                        fontSize: bodyTextSize,
                        color: isDark
                            ? AppColors.darkText.withOpacity(0.7)
                            : AppColors.textLightGrey,
                        height: 1.5,
                      ),
                    ),
                    if (doctor.experienceYears != null &&
                        doctor.experienceYears!.trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.work_history_outlined,
                            size: 16.sp,
                            color: primaryGreenColor,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${doctor.experienceYears} ${AppStrings.experienceYearsLabel(context)}',
                            style: TextStyle(
                              fontSize: bodyTextSize,
                              fontWeight: FontWeight.w600,
                              color: primaryGreenColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 24.h),

                    Text(
                      AppStrings.availableSchedule(context),
                      style: TextStyle(
                        fontSize: sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: primaryGreenColor,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    SizedBox(
                      height: 65.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _days.length,
                        separatorBuilder: (_, __) => SizedBox(width: 10.w),
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final isSelected =
                              day.year == _selectedDate.year &&
                              day.month == _selectedDate.month &&
                              day.day == _selectedDate.day;
                          const weekdayLabels = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDate = day),
                            child: _buildDayCard(
                              weekdayLabels[day.weekday - 1],
                              '${day.day}',
                              primaryGreenColor,
                              isDark
                                  ? const Color(0xFF2C3E35)
                                  : const Color(0xFFD2DDD5),
                              textColor,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFC0392B),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // ⚠️ 19/8: كل فترة (صباح/بعد ظهر/مساء) صارت تظهر
                      // دايماً بعنوانها - إذا ما في سلوتس فيها لهاليوم
                      // (يعني الطبيب ما حددها أصلاً بهاليوم)، بيظهر
                      // تحتها "لا يوجد مواعيد متاحة" بدل ما تختفي الفترة
                      // كلياً أو يظهر مسج عام واحد للصفحة كلها.
                      _buildPeriodSection(
                        AppStrings.morning(context),
                        morningSlots,
                        cardBgColor,
                        borderColor,
                        textColor,
                        primaryGreenColor,
                        doctorCardBg,
                        bodyTextSize,
                        isDark,
                      ),
                      SizedBox(height: 16.h),
                      _buildPeriodSection(
                        AppStrings.afternoon(context),
                        afternoonSlots,
                        cardBgColor,
                        borderColor,
                        textColor,
                        primaryGreenColor,
                        doctorCardBg,
                        bodyTextSize,
                        isDark,
                      ),
                      SizedBox(height: 16.h),
                      _buildPeriodSection(
                        AppStrings.evening(context),
                        eveningSlots,
                        cardBgColor,
                        borderColor,
                        textColor,
                        primaryGreenColor,
                        doctorCardBg,
                        bodyTextSize,
                        isDark,
                      ),
                    ],
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: cardBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.consultationFeeLabel(context),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textLightGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '\$${displayFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: feeSize,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // ✅ زر "مراسلة" - بيفتح محادثة على أول موعد حقيقي بين
                  // المريض وهاد الطبيب (الشات بالباك مربوط بموعد مو
                  // بطبيب مباشرة)، أو بيطلب من المريض يحجز أول لو ما
                  // عندو أي موعد معه - راجع _openChatWithDoctor.
                  SizedBox(
                    width: 46.w,
                    height: 46.h,
                    child: OutlinedButton(
                      onPressed: _isOpeningChat ? null : _openChatWithDoctor,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: primaryGreenColor, width: 1.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: _isOpeningChat
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryGreenColor,
                              ),
                            )
                          : Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: primaryGreenColor,
                              size: 20.sp,
                            ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 150.w,
                    height: 46.h,
                    child: ElevatedButton(
                      // ✅ 18/8: لو المريض ما عبّى سجله الطبي بعد، الزر
                      // بيضل يبين كأنه معطّل بصرياً (لون باهت)، بس لسا
                      // قابل للضغط - الضغطة بتوجّهه مباشرة لتعبئة سجله
                      // الطبي بدل ما يضل غير مفعّل بصمت بلا تفسير.
                      // ✅ 19/8: نظام الحجوزات صار مربوط فعلياً - ضغط
                      // الزر (بعد التأكد من وجود سجل طبي + اختيار وقت)
                      // بيفتح نافذة تأكيد بسيطة، وبعد "نعم" بيحجز فعلياً
                      // (بدون دفع لسا - البند هاد لسا ما جاهز بالباك).
                      onPressed: _isBooking
                          ? null
                          : !hasMedicalRecord
                          ? () => _showMedicalRecordRequiredDialog(
                              context,
                              isDark,
                              primaryGreenColor,
                            )
                          : (_selectedSlot == null
                                ? null
                                : () => _onBookPressed(
                                    isDark,
                                    primaryGreenColor,
                                    displayFee,
                                  )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasMedicalRecord
                            ? primaryGreenColor
                            : primaryGreenColor.withOpacity(0.4),
                        disabledBackgroundColor: primaryGreenColor.withOpacity(
                          0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isBooking
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    AppStrings.bookAppointment(context),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkBackground
                                          : AppColors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.arrow_forward,
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.white,
                                  size: 16.sp,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ لما يضغط المريض على "احجز الآن" وهو لسا ما عبّى سجله الطبي -
  /// بنوريه ليش الزر "معطّل" وبنوجّهه مباشرة لتاب السجل الطبي بنفس
  /// MainLayoutScreen (عبر DoctorListingCubit.changeTab) بدل ما يترك
  /// يدور بنفسه.
  void _showMedicalRecordRequiredDialog(
    BuildContext context,
    bool isDark,
    Color primaryGreenColor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لازم تعبّي سجلك الطبي أولاً'),
        content: const Text(
          'حتى تقدر تحجز موعد، لازم تعبّي سجلك الطبي مرة وحدة قبل هيك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('لاحقاً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // تاب السجل الطبي هو index 4 بـ MainLayoutScreen.
              context.read<DoctorListingCubit>().changeTab(4);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'عبّيه هلق',
              style: TextStyle(
                color: primaryGreenColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 22/8: تدفق الحجز الكامل - نافذة تأكيد بسيطة ("هل تريد تأكيد
  /// الحجز؟")، بعدها شيت اختيار طريقة الدفع (showBookingPaymentSheet -
  /// بيجيب فعلياً خيارات الدفع المسموحة للمريض حسب سجل غياباته + رصيد
  /// محفظته)، وبعد اختيار طريقة الدفع منادي POST /patient/appointments
  /// فعلياً مع payment_method (الحجز والدفع صاروا عملية واحدة ذرية -
  /// ما في حجز بدون دفع ناجح أول). لو المريض رجع من شيت الدفع بدون ما
  /// يختار (ألغى)، منوقف التدفق بدون ما نحجز. لو السلوت انحجز من حدا
  /// تاني أول (409) منعرض رسالة واضحة ومنحدّث الجدول تلقائياً.
  Future<void> _onBookPressed(
    bool isDark,
    Color primaryGreenColor,
    double fee,
  ) async {
    final slot = _selectedSlot;
    if (slot == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.confirmBookingTitle(dialogContext)),
        content: Text(AppStrings.confirmBookingDesc(dialogContext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.confirmNo(dialogContext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              AppStrings.confirmYes(dialogContext),
              style: TextStyle(
                color: primaryGreenColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final paymentMethod = await showBookingPaymentSheet(context, price: fee);
    if (paymentMethod == null || !mounted) return;

    setState(() => _isBooking = true);
    try {
      await _appointmentsRepository.book(
        slotId: slot.id,
        encounterType: 'in_person',
        paymentMethod: paymentMethod,
      );
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _selectedSlot = null;
      });
      // ⚠️ 19/8: بدون هالسطر، تاب "الحجوزات" كان بيضل عارض بيانات
      // قديمة لحد ما تسكّر التطبيق وتفتحه من جديد (لأنه IndexedStack ما
      // بيعيد بناء الأولاد، فالـ cubit القديم كان يضل نفسه بلا تحديث).
      context.read<PatientAppointmentsCubit>().load();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.bookingSuccessTitle(dialogContext)),
          content: Text(AppStrings.bookingSuccessDesc(dialogContext)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // تاب الحجوزات (Bookings) هو index 2 بـ MainLayoutScreen.
                context.read<DoctorListingCubit>().changeTab(2);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                AppStrings.confirmYes(dialogContext),
                style: TextStyle(
                  color: primaryGreenColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      _loadAvailability();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final isConflict = e.statusCode == 409;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConflict ? AppStrings.slotNoLongerAvailable(context) : e.message,
          ),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
      if (isConflict) _loadAvailability();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.slotNoLongerAvailable(context)),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  Widget _buildQuickActionIcon(IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20.sp),
    );
  }

  Widget _buildDayCard(
    String day,
    String date,
    Color selectedColor,
    Color unselectedColor,
    Color textColor, {
    bool isSelected = false,
  }) {
    return Container(
      width: 52.w,
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 11.sp,
              color: isSelected ? Colors.white : AppColors.textLightGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            date,
            style: TextStyle(
              fontSize: 15.sp,
              color: isSelected ? Colors.white : textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ 19/8: عنصر مشترك لكل فترة (صباح/بعد ظهر/مساء) - بيعرض عنوان
  /// الفترة دايماً، وتحته إما شرائح الأوقات (إذا في)، أو نص "لا يوجد
  /// مواعيد متاحة" (إذا الطبيب ما حدد هالفترة بهاليوم المختار).
  Widget _buildPeriodSection(
    String title,
    List<AvailabilitySlot> slots,
    Color cardBg,
    Color border,
    Color textColor,
    Color primaryGreenColor,
    Color selectedBg,
    double bodyTextSize,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkText.withOpacity(0.6)
                : AppColors.textLightGrey,
          ),
        ),
        SizedBox(height: 8.h),
        if (slots.isEmpty)
          Text(
            AppStrings.noSlotsForPeriod(context),
            style: TextStyle(
              fontSize: bodyTextSize - 1,
              color: AppColors.textLightGrey.withOpacity(0.7),
            ),
          )
        else
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: slots
                .map(
                  (s) => _buildTimeSlot(
                    s,
                    cardBg,
                    border,
                    textColor,
                    primaryGreenColor,
                    selectedBg,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTimeSlot(
    AvailabilitySlot slot,
    Color cardBg,
    Color border,
    Color text,
    Color primary,
    Color selectedBg,
  ) {
    final isSelected = _selectedSlot != null && _selectedSlot!.id == slot.id;
    final isDisabled = !slot.isAvailable;
    final label =
        '${slot.startsAt.hour.toString().padLeft(2, '0')}:${slot.startsAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedSlot = slot),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBg
              : (isDisabled ? Colors.black.withOpacity(0.05) : cardBg),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDisabled ? Colors.transparent : border),
            width: 1.w,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDisabled ? AppColors.textLightGrey.withOpacity(0.4) : text,
          ),
        ),
      ),
    );
  }
}
