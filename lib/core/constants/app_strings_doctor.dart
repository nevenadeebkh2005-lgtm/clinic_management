import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled3/core/constants/setting.dart';

/// نصوص خاصة بواجهات الطبيب (Doctor Home / Work Schedule / Appointments /
/// Notifications / Doctor Profile). موجودة بملف منفصل عن [AppStrings] الأصلي
/// (بدل ما تنضاف داخله مباشرة) حتى نتجنب أي تعارض دمج على ملف ضخم مشترك
/// بين عدة أشخاص عم يشتغلوا عليه بنفس الوقت - نفس آلية الترجمة
/// (BuildContext -> نص عربي/إنكليزي) بس بجدول منفصل.
class DoctorStrings {
  static bool _isEn(BuildContext context) {
    return BlocProvider.of<SettingsCubit>(context).state.locale.languageCode ==
        'en';
  }

  // --- Home Dashboard ---
  static String doctorHome(BuildContext context) =>
      _isEn(context) ? 'Home' : 'الرئيسية';
  static String todaysSummary(BuildContext context) =>
      _isEn(context) ? "Today's Summary" : 'ملخص اليوم';
  static String todaysClinics(BuildContext context) =>
      _isEn(context) ? "Today's Clinics" : 'عيادات اليوم';
  static String appointmentsToday(BuildContext context) =>
      _isEn(context) ? 'Appointments' : 'مواعيد اليوم';
  static String pending(BuildContext context) =>
      _isEn(context) ? 'Pending' : 'قيد الانتظار';
  static String messages(BuildContext context) =>
      _isEn(context) ? 'Messages' : 'رسائل';
  static String nextPatient(BuildContext context) =>
      _isEn(context) ? 'Next Patient' : 'المريض التالي';
  static String noAppointmentsToday(BuildContext context) => _isEn(context)
      ? 'No appointments scheduled for today'
      : 'لا توجد مواعيد مجدولة اليوم';
  static String youShouldBeAt(BuildContext context) =>
      _isEn(context) ? 'You should be at' : 'يفترض أن تكون في';
  static String from(BuildContext context) => _isEn(context) ? 'from' : 'من';
  static String to(BuildContext context) => _isEn(context) ? 'to' : 'إلى';

  // --- Schedule not configured yet (initial state) ---
  static String scheduleNotSetTitle(BuildContext context) => _isEn(context)
      ? "You haven't set your working schedule yet"
      : 'لم تقم بتحديد جدول عملك بعد';
  static String scheduleNotSetDesc(BuildContext context) => _isEn(context)
      ? 'Set your clinic hours so patients and your dashboard know when you are available.'
      : 'حدد أوقات دوامك في كل عيادة حتى يعرف المرضى ولوحتك الرئيسية متى تكون متاحاً.';
  static String setUpSchedule(BuildContext context) =>
      _isEn(context) ? 'Set up schedule' : 'تحديد الجدول';

  // --- Work Schedule Management ---
  static String workScheduleManagement(BuildContext context) =>
      _isEn(context) ? 'Work Schedule Management' : 'إدارة جدول العمل';
  static String selectClinic(BuildContext context) =>
      _isEn(context) ? 'Clinic' : 'العيادة';
  static String noClinicsYet(BuildContext context) => _isEn(context)
      ? 'No workplaces linked to your account yet. Add one from Profile > Clinics.'
      : 'لا يوجد أماكن عمل مرتبطة بحسابك بعد. أضف واحداً من الملف الشخصي > العيادات.';
  static String dayOff(BuildContext context) =>
      _isEn(context) ? 'Day off' : 'يوم إجازة';
  static String startTime(BuildContext context) =>
      _isEn(context) ? 'Start time' : 'وقت البدء';
  static String endTime(BuildContext context) =>
      _isEn(context) ? 'End time' : 'وقت الانتهاء';
  static String saveSchedule(BuildContext context) =>
      _isEn(context) ? 'Save Schedule' : 'حفظ الجدول';
  static String scheduleSaved(BuildContext context) =>
      _isEn(context) ? 'Schedule saved' : 'تم حفظ الجدول';
  static String editSchedule(BuildContext context) =>
      _isEn(context) ? 'Edit schedule' : 'تعديل الجدول';
  static String vacationMode(BuildContext context) =>
      _isEn(context) ? 'Vacation Mode' : 'وضع الإجازة';
  static String noSlotsConfigured(BuildContext context) =>
      _isEn(context) ? 'No slots configured' : 'لا توجد أوقات محددة';
  static String noSlotsConfiguredFor(BuildContext context, String period) => _isEn(context)
      ? 'No slots configured for $period'
      : 'لا توجد أوقات محددة لفترة $period';

  // --- شاشة الجدول (تصميم CareFlow الجديد) ---
  static String morning(BuildContext context) => _isEn(context) ? 'Morning' : 'الصباح';
  static String afternoon(BuildContext context) => _isEn(context) ? 'Afternoon' : 'بعد الظهر';
  static String evening(BuildContext context) => _isEn(context) ? 'Evening' : 'المساء';
  static String available(BuildContext context) => _isEn(context) ? 'Available' : 'متاح';
  static String blocked(BuildContext context) => _isEn(context) ? 'Blocked' : 'محجوب';
  // ✅ إضافة: كارد "Encounters" السابقة بشاشة السجل الطبي عند الطبيب
  static String previousEncounters(BuildContext context) =>
      _isEn(context) ? 'Previous Encounters' : 'الزيارات السابقة';
  // ✅ إضافة: نصوص شاشة DoctorEncounterScreen (توثيق الزيارة السريرية)
  static String clinicalNotes(BuildContext context) => _isEn(context) ? 'Clinical Notes' : 'الملاحظات السريرية';
  static String diagnosis(BuildContext context) => _isEn(context) ? 'Diagnosis' : 'التشخيص';
  static String prescriptions(BuildContext context) => _isEn(context) ? 'Prescriptions' : 'الوصفات الطبية';
  static String inProgressBadge(BuildContext context) => _isEn(context) ? 'IN PROGRESS' : 'قيد الكشف';
  static String encounterTitle(BuildContext context) =>
      _isEn(context) ? 'Encounter Details & Clinical Record' : 'تفاصيل الزيارة والسجل السريري';
  static String clinicalNotesHint(BuildContext context) => _isEn(context)
      ? 'Document patient history, examination findings, and clinical reasoning...'
      : 'وثّق تاريخ المريض، نتائج الفحص، والتحليل السريري...';
  static String addNote(BuildContext context) => _isEn(context) ? 'Add Note' : 'إضافة ملاحظة';
  static String diagnosisHint(BuildContext context) => _isEn(context) ? 'Diagnosis (e.g., Acute sinusitis)' : 'التشخيص (مثلاً: التهاب الجيوب الحاد)';
  static String diagnosisDescriptionHint(BuildContext context) =>
      _isEn(context) ? 'Description (optional)' : 'وصف إضافي (اختياري)';
  static String addDiagnosis(BuildContext context) => _isEn(context) ? 'Add Diagnosis' : 'إضافة تشخيص';
  static String addMedication(BuildContext context) => _isEn(context) ? 'Add Medication' : 'إضافة دواء';
  static String drugName(BuildContext context) => _isEn(context) ? 'Drug Name' : 'اسم الدواء';
  static String dosage(BuildContext context) => _isEn(context) ? 'Dosage' : 'الجرعة';
  static String frequency(BuildContext context) => _isEn(context) ? 'Frequency' : 'عدد المرات';
  static String finalizeEncounter(BuildContext context) => _isEn(context) ? 'FINALIZE ENCOUNTER' : 'إنهاء الزيارة';
  static String medicationNotes(BuildContext context) => _isEn(context) ? 'Notes (optional)' : 'ملاحظات (اختياري)';
  static String encounterButton(BuildContext context) => _isEn(context) ? 'Encounter' : 'بدء الكشف';
  static String continueEncounter(BuildContext context) => _isEn(context) ? 'Continue Encounter' : 'متابعة الكشف';
  // ✅ إضافة: عرض عمر/جنس المريض ببطاقة السجل الطبي عند الطبيب
  static String yearsOld(BuildContext context) => _isEn(context) ? 'yrs' : 'سنة';
  static String genderLabel(BuildContext context, String raw) {
    final isEn = _isEn(context);
    switch (raw.toLowerCase()) {
      case 'male':
        return isEn ? 'Male' : 'ذكر';
      case 'female':
        return isEn ? 'Female' : 'أنثى';
      default:
        return raw;
    }
  }
  static String lunchBreak(BuildContext context) => _isEn(context) ? 'Lunch Break' : 'استراحة غداء';
  static String duration(BuildContext context) => _isEn(context) ? 'Duration' : 'مدة الكشف';
  static String durationMinutes(BuildContext context, int minutes) =>
      _isEn(context) ? 'Duration: $minutes min' : 'مدة الكشف: $minutes د';
  static String breakDurationMinutes(BuildContext context, int minutes) =>
      _isEn(context) ? 'Break between sessions: $minutes min' : 'استراحة بين الفترات: $minutes د';
  static String breakBetweenSlots(BuildContext context) =>
      _isEn(context) ? 'Break between slots (min)' : 'استراحة بين المواعيد (دقيقة)';
  static String bufferEnabled(BuildContext context) =>
      _isEn(context) ? 'Buffer time enabled' : 'تفعيل وقت فاصل';
  static String addSessionFor(BuildContext context, String period) =>
      _isEn(context) ? 'Add $period hours' : 'إضافة أوقات $period';
  static String removeSession(BuildContext context) => _isEn(context) ? 'Remove session' : 'حذف الفترة';
  static String activateVacation(BuildContext context) =>
      _isEn(context) ? 'Activate vacation mode' : 'تفعيل وضع الإجازة';
  static String deactivateVacation(BuildContext context) =>
      _isEn(context) ? 'End vacation mode' : 'إنهاء وضع الإجازة';
  static String vacationFrom(BuildContext context) => _isEn(context) ? 'From' : 'من';
  static String vacationTo(BuildContext context) => _isEn(context) ? 'To' : 'إلى';
  static String onVacationUntil(BuildContext context, String date) =>
      _isEn(context) ? 'On vacation until $date' : 'بإجازة لحد $date';
  static String blockThisSlot(BuildContext context) => _isEn(context) ? 'Block this slot' : 'حجب هالوقت';
  static String slotBlocked(BuildContext context) => _isEn(context) ? 'Slot blocked' : 'تم حجب الوقت';
  // ✅ إضافة: سلسلة نصوص إدارة الأوقات المحجوبة (block time management)
  static String blockTime(BuildContext context) => _isEn(context) ? 'Block Time' : 'حجب أوقات';
  static String blockedTimesTitle(BuildContext context) => _isEn(context) ? 'Blocked Times' : 'الأوقات المحجوبة';
  static String noBlockedTimes(BuildContext context) => _isEn(context) ? 'No blocked times yet' : 'ما في أوقات محجوبة لهلق';
  static String addBlockedTime(BuildContext context) => _isEn(context) ? 'Add blocked time' : 'إضافة وقت محجوب';
  static String blockByDate(BuildContext context) => _isEn(context) ? 'One-time (specific date)' : 'مرّة وحدة (تاريخ محدد)';
  static String blockByWeekday(BuildContext context) => _isEn(context) ? 'Recurring (every week)' : 'متكرر (كل أسبوع)';
  static String selectDay(BuildContext context) => _isEn(context) ? 'Day' : 'اليوم';
  static String everyWeekday(BuildContext context, String day) =>
      _isEn(context) ? 'Every $day' : 'كل $day';
  static String unblock(BuildContext context) => _isEn(context) ? 'Unblock' : 'إلغاء الحجب';
  static String save(BuildContext context) => _isEn(context) ? 'Save' : 'حفظ';
  static String appointment(BuildContext context) => _isEn(context) ? 'Appointment' : 'موعد';

  static String weekdayShort(BuildContext context, int weekday) {
    // weekday: 1=Monday ... 7=Sunday (DateTime convention)
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ar = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    final list = _isEn(context) ? en : ar;
    return list[(weekday - 1).clamp(0, 6)];
  }

  static String weekdayFull(BuildContext context, int weekday) {
    const en = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const ar = [
      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
    ];
    final list = _isEn(context) ? en : ar;
    return list[(weekday - 1).clamp(0, 6)];
  }

  // --- Doctor Appointments ---
  static String doctorAppointments(BuildContext context) =>
      _isEn(context) ? 'Appointments' : 'المواعيد';
  static String upcoming(BuildContext context) =>
      _isEn(context) ? 'Upcoming' : 'قادمة';
  static String history(BuildContext context) =>
      _isEn(context) ? 'History' : 'السابقة';
  static String checkedIn(BuildContext context) =>
      _isEn(context) ? 'checkedIn' : 'حضر';
  static String completed(BuildContext context) =>
      _isEn(context) ? 'Completed' : 'مكتملة';
  static String cancelled(BuildContext context) =>
      _isEn(context) ? 'Cancelled' : 'ملغاة';
  static String inProgress(BuildContext context) =>
      _isEn(context) ? 'In progress' : 'جارية الآن';
  static String noShow(BuildContext context) =>
      _isEn(context) ? 'Did not attend' : 'لم يحضر';
  static String startConsultation(BuildContext context) =>
      _isEn(context) ? 'Start consultation' : 'ابدأ الكشف';
  static String markNoShow(BuildContext context) =>
      _isEn(context) ? 'Mark as no-show' : 'تحديد كـ لم يحضر';
  static String cancelReasonHint(BuildContext context) =>
      _isEn(context) ? 'Cancellation reason (optional)' : 'سبب الإلغاء (اختياري)';
  static String patientMedicalRecord(BuildContext context) =>
      _isEn(context) ? 'Medical Record' : 'السجل الطبي';
  static String allergiesSection(BuildContext context) =>
      _isEn(context) ? 'Allergies' : 'الحساسية';
  static String activeProblemsSection(BuildContext context) =>
      _isEn(context) ? 'Active Problems' : 'المشاكل الحالية';
  static String medicationsSection(BuildContext context) =>
      _isEn(context) ? 'Medications' : 'الأدوية';
  static String attachmentsSection(BuildContext context) =>
      _isEn(context) ? 'Attachments & Results' : 'المرفقات والنتائج';
  static String noEntriesYet(BuildContext context) =>
      _isEn(context) ? 'None recorded' : 'لا يوجد';
  static String diagnosedLabel(BuildContext context) =>
      _isEn(context) ? 'Diagnosed' : 'تاريخ التشخيص';
  static String medicalRecordAccessRevoked(BuildContext context) => _isEn(context)
      ? 'The patient has revoked access to their medical record for this appointment.'
      : 'المريض سحب صلاحية الاطلاع على سجله الطبي لهالموعد.';
  static String viewMedicalRecord(BuildContext context) =>
      _isEn(context) ? 'View medical record' : 'عرض السجل الطبي';
  static String noAppointmentsYet(BuildContext context) => _isEn(context)
      ? 'No appointments here yet'
      : 'لا يوجد مواعيد هنا حتى الآن';
  static String noAppointmentsHint(BuildContext context) => _isEn(context)
      ? "New bookings made by patients through 'Book' will show up here."
      : 'الحجوزات الجديدة التي يقوم بها المرضى عبر زر "حجز" ستظهر هنا.';
  static String markCompleted(BuildContext context) =>
      _isEn(context) ? 'Mark as completed' : 'تحديد كمكتمل';
  static String openEncounter(BuildContext context) =>
      _isEn(context) ? 'Open encounter' : 'فتح الزيارة';
  static String cancelAppointment(BuildContext context) =>
      _isEn(context) ? 'Cancel appointment' : 'إلغاء الموعد';
  static String cancelAppointmentConfirm(BuildContext context) => _isEn(context)
      ? 'Are you sure you want to cancel this appointment?'
      : 'هل أنت متأكد من إلغاء هذا الموعد؟';
  static String appointmentDetails(BuildContext context) =>
      _isEn(context) ? 'Appointment Details' : 'تفاصيل الموعد';
  static String bookedOn(BuildContext context) =>
      _isEn(context) ? 'Booked on' : 'تم الحجز في';
  static String reasonForVisit(BuildContext context) =>
      _isEn(context) ? 'Reason for visit' : 'سبب الزيارة';

  // --- Notifications ---
  static String doctorNotifications(BuildContext context) =>
      _isEn(context) ? 'Notifications' : 'الإشعارات';
  static String markAllRead(BuildContext context) =>
      _isEn(context) ? 'Mark all as read' : 'تحديد الكل كمقروء';
  static String noNotificationsYet(BuildContext context) =>
      _isEn(context) ? 'No notifications yet' : 'لا توجد إشعارات بعد';
  static String newAppointmentRequest(BuildContext context) =>
      _isEn(context) ? 'New appointment request' : 'طلب حجز جديد';

  // --- Doctor Profile ---
  static String doctorProfile(BuildContext context) =>
      _isEn(context) ? 'Doctor Profile' : 'الملف الشخصي للطبيب';
  static String careerInfo(BuildContext context) =>
      _isEn(context) ? 'Career' : 'المسيرة المهنية';
  static String practiceStartDate(BuildContext context) =>
      _isEn(context) ? 'Practice start date' : 'تاريخ بدء الممارسة';
  static String selectDate(BuildContext context) =>
      _isEn(context) ? 'Select date' : 'اختر التاريخ';
  static String yearsOfExperience(BuildContext context) =>
      _isEn(context) ? 'Years of experience' : 'سنوات الخبرة';
  static String verificationStatus(BuildContext context) =>
      _isEn(context) ? 'Verification status' : 'حالة التوثيق';
  static String verified(BuildContext context) =>
      _isEn(context) ? 'Verified' : 'موثّق';
  static String underReview(BuildContext context) =>
      _isEn(context) ? 'Under review' : 'قيد المراجعة';
  static String departmentsSpecialties(BuildContext context) =>
      _isEn(context) ? 'Departments' : 'الأقسام';
  static String clinicsWorkplaces(BuildContext context) =>
      _isEn(context) ? 'Clinics & Workplaces' : 'العيادات وأماكن العمل';
  static String consultationFeeLabel(BuildContext context) =>
      _isEn(context) ? 'Consultation Fee' : 'رسوم الاستشارة';
  static String biography(BuildContext context) =>
      _isEn(context) ? 'Biography' : 'نبذة تعريفية';
  static String noBiographyYet(BuildContext context) =>
      _isEn(context) ? 'No biography added yet' : 'لم تتم إضافة نبذة بعد';

  // --- Join Clinic ---
  static String joinClinic(BuildContext context) => _isEn(context) ? 'Join a Clinic' : 'الانضمام لعيادة';
  static String selectDepartmentAt(BuildContext context, String clinicName) => _isEn(context)
      ? 'Select your department at $clinicName'
      : 'اختر قسمك بعيادة $clinicName';
  static String noDepartmentsAtClinic(BuildContext context) => _isEn(context)
      ? 'This clinic has no departments defined yet'
      : 'ما في أقسام معرّفة بهاي العيادة بعد';
  static String noClinicsAvailable(BuildContext context) =>
      _isEn(context) ? 'No active clinics available right now' : 'لا توجد عيادات فعّالة متاحة حالياً';
  static String joinedClinicSuccess(BuildContext context) =>
      _isEn(context) ? 'Joined the clinic successfully' : 'تم الانضمام للعيادة بنجاح';
  static String confirmJoin(BuildContext context) => _isEn(context) ? 'Join' : 'انضمام';
  static String alreadyJoinedThisClinic(BuildContext context) =>
      _isEn(context) ? 'You are already linked to this clinic' : 'أنت مرتبط بهاي العيادة أصلاً';
  // ⚠️ 19/8: الباك عدّل مصطلح الحقل من "Clinic ID" لـ "Clinic Code"
  // (نفس القيمة رقم العيادة، بس صار اسمه/تسميته بواجهة المستخدم "كود
  // العيادة" مطابقةً لاسم الحقل clinic_code يلي صار الباك يطلبه).
  static String clinicIdLabel(BuildContext context) => _isEn(context) ? 'Clinic Code' : 'كود العيادة';
  static String enterClinicIdHint(BuildContext context) =>
      _isEn(context) ? 'Enter the clinic code' : 'أدخل كود العيادة';
  static String clinicIdTempNote(BuildContext context) => _isEn(context)
      ? 'Ask the clinic admin for its code.'
      : 'اطلب كود العيادة من إدارتها.';
  static String lookUpClinic(BuildContext context) => _isEn(context) ? 'Look up clinic' : 'البحث عن العيادة';
  static String clinicNotFound(BuildContext context) =>
      _isEn(context) ? 'No active clinic found with this code' : 'ما في عيادة فعّالة بهاد الكود';
  static String createNewClinicMode(BuildContext context) => _isEn(context) ? 'Create Clinic' : 'إنشاء عيادة';
  static String joinExistingClinicMode(BuildContext context) => _isEn(context) ? 'Join Clinic' : 'الانضمام لعيادة';
  static String createClinicNotAvailableYet(BuildContext context) => _isEn(context)
      ? "Creating a new clinic from an existing account isn't available yet - this currently only works during initial doctor registration. Ask your backend team to add a dedicated endpoint for this."
      : 'إنشاء عيادة جديدة من حساب موجود أصلاً لسا مو متاح - هلق هاد الخيار متوفر بس أثناء تسجيل حساب الطبيب لأول مرة. اطلب من فريق الباك إضافة endpoint مخصص لهالحالة.';

  // --- Empty chat (doctor side) ---
  static String noConversationsYet(BuildContext context) =>
      _isEn(context) ? 'No conversations yet' : 'لا توجد محادثات بعد';
  static String noConversationsHint(BuildContext context) => _isEn(context)
      ? 'Messages from your patients will appear here.'
      : 'ستظهر رسائل مرضاك هنا.';
}
