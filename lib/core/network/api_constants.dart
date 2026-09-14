class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:8000/api/v1';

  // --- Auth ---
  static const String register = '/auth/register';
  static const String verifyEmailCode = '/auth/email/verify-code';
  static const String resendCode = '/auth/email/resend-code';
  static const String completeProfile = '/auth/complete-profile';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  // بيرجع {data: {user, dashboard}} لصاحب الـ token الحالي - مستخدم هون
  // بس لما ما عنا currentUserJson جاهز بالشجرة (متل doctor_profile_screen
  // المفتوحة من أكتر من مكان) ولازم نعرف id المستخدم الحالي لحاجة عابرة
  // بسيطة (فتح محادثة) بدل ما نمرر currentUserJson لكل الشاشات الوسيطة.
  static const String authMe = '/auth/me';

  // --- Push notifications (FCM device registration) ---
  static const String deviceTokens = '/device-tokens';
  static const String passwordConfirmationKey = 'password confirmation';

  // --- Patient / Medical Record ---
  // مضافة: كل نقاط النهاية الخاصة بالسجل الطبي للمريض (شوهدت بالـ Postman
  // collection تحت Patient/Medical Record).
  static const String medicalRecordBase = '/patient/medical-record';
  static const String medicalRecordAllergies = '$medicalRecordBase/allergies';
  static const String medicalRecordChronicConditions =
      '$medicalRecordBase/chronic-conditions';
  static const String medicalRecordSurgeries = '$medicalRecordBase/surgeries';
  static const String medicalRecordFamilyHistory =
      '$medicalRecordBase/family-history';
  static const String medicalRecordMedications =
      '$medicalRecordBase/medications';
  static const String medicalRecordAttachments =
      '$medicalRecordBase/attachments';

  // --- Patient / Profile ---
  // ⚠️ مضافة بنفس نمط /doctor/profile و /doctor/profile/photo (يلي
  // شغالين فعلياً بالباك) - ما كان عنا تأكيد صريح من الـ Postman
  // collection على هاد المسار بالذات لجهة المريض وقت ما ضفناه. لازم
  // تتأكد منه (أو تصححه) مقابل الكولكشن الحقيقي قبل ما تعتمد عليه.
  static const String patientProfile = '/patient/profile';
  static const String patientProfilePhoto = '/patient/profile/photo';

  // --- Doctor ---
  static const String doctorProfile = '/doctor/profile';
  static const String doctorProfilePhoto = '/doctor/profile/photo';  // ✅ تصحيح 16/8 حسب الكولكشن الأحدث: "الانضمام لعيادة" ما عاد يحتاج
  // قسم (department_id) - صار clinic_id + consultation_fee بس (التخصص
  // صار مستقل عن العيادة، بينحدد مرة وحدة بالريجستر). "مغادرة قسم" لسا
  // تحت المسار القديم /departments/leave (ما تغيّر بالكولكشن).
  static const String doctorJoinClinic = '/doctor/profile/clinics/join';
  static const String doctorCreateClinic = '/doctor/profile/clinics/create';
  static String doctorUpdateClinicFee(int clinicId) =>
      '/doctor/profile/clinics/$clinicId/fee';
  static const String doctorLeaveDepartment =
      '/doctor/profile/departments/leave';
  static String doctorEncounter(int appointmentId) => '$doctorAppointments/$appointmentId/encounter';
  static String doctorEncounterSubmit(int appointmentId) => '$doctorAppointments/$appointmentId/encounter/submit';

  // --- Doctor / Schedule (✅ حقيقية بالكامل - راجع Postman collection
  // المحدّث: مجلد "Schedule"). كل هالنقاط تحت /doctor/schedule تخص
  // الطبيب المسجّل دخوله حالياً (self) لعيادة محددة بالـ clinicId.
  static const String doctorScheduleBase = '/doctor/schedule';
  static String doctorAllSchedules() => doctorScheduleBase;
  static String doctorSchedule(int clinicId) => '$doctorScheduleBase/$clinicId';
  static String doctorGenerateSlots(int clinicId) =>
      '$doctorScheduleBase/$clinicId/generate-slots';
  static String doctorVacation(int clinicId) =>
      '$doctorScheduleBase/$clinicId/vacation';
  static String doctorBlockedTimes(int clinicId) =>
      '$doctorScheduleBase/$clinicId/blocked-times';
  static String doctorDeleteBlockedTime(int blockedTimeId) =>
      '$doctorScheduleBase/blocked-times/$blockedTimeId';
  // عام (مو تحت /doctor) - بيرجع الأوقات المتاحة الفعلية (Slots المولّدة)
  // لأي طبيب بأي مجال تواريخ وعيادة، مستخدم من جهة المريض للحجز، وهون
  // منستخدمه كمان من جهة الطبيب نفسه ليعرض له أوقاته المتاحة يوم بيوم.
  static String doctorAvailability(int doctorId) =>
      '/doctors/$doctorId/availability';

  // ✅ صار موجود فعلياً بالباك (Doctor / list + filter) - لائحة عامة
  // بكل الأطباء، بترجع كل طبيب مع أقسامه (departments، مستقلة عن
  // العيادة هلق) وعياداته (كل عيادة مع رسمها/سعرها الخاص consultation_fee).
  static const String doctorsPublicList = '/doctors';

  // --- Clinics / Departments (public) ---
  static const String clinics = '/clinics';
  static const String departments = '/departments';

  // --- Appointments (✅ حقيقية بالكامل - Postman collection: مجلد
  // "Appointment/Patient" و"Appointment/Doctor"). حالات الموعد يلي
  // بيرجعها الباك: scheduled / in_progress / completed / cancelled /
  // no_show.
  static const String patientAppointments = '/patient/appointments';
  static String patientAppointment(int id) => '$patientAppointments/$id';
  static String patientAppointmentCancel(int id) =>
      '$patientAppointments/$id/cancel';
  static String patientAppointmentReschedule(int id) =>
      '$patientAppointments/$id/reschedule';

  static const String doctorAppointments = '/doctor/appointments';
  static String doctorAppointment(int id) => '$doctorAppointments/$id';
  static String doctorAppointmentStart(int id) =>
      '$doctorAppointments/$id/start';
  static String doctorAppointmentComplete(int id) =>
      '$doctorAppointments/$id/complete';
  static String doctorAppointmentCancel(int id) =>
      '$doctorAppointments/$id/cancel';
  static String doctorAppointmentNoShow(int id) =>
      '$doctorAppointments/$id/no-show';
  // ✅ 19/8: صلاحية الطبيب برؤية السجل الطبي للمريض - مرتبطة حصراً
  // بموعد محدد (Postman: "Doctor/get medical profile for a patient")،
  // يعني الطبيب ما بيقدر يشوف سجل أي مريض إلا إذا عنده موعد فعلي معه -
  // والمريض نفسه فيه صلاحية يسحب هالوصول لاحقاً (Patient/access/...).
  static String doctorAppointmentMedicalRecord(int appointmentId) =>
      '$doctorAppointments/$appointmentId/medical-record';

  // --- Doctor Engagement (Favorites / Reviews / Reports) ---
  // ✅ مضافة: نقاط النهاية الحقيقية لموديول DoctorEngagement بالباك
  // (Controllers: PatientFavoriteController / PatientReviewController /
  // PublicDoctorReviewController / PatientReportController).
  static const String patientFavorites = '/patient/favorites';
  static String toggleDoctorFavorite(int doctorId) =>
      '/patient/doctors/$doctorId/favorite/toggle';

  static String patientDoctorReview(int doctorId) =>
      '/patient/doctors/$doctorId/review';

  static const String patientReports = '/patient/reports';
  static String submitDoctorReport(int doctorId) =>
      '/patient/doctors/$doctorId/report';
  static String reportFeedback(int reportId) =>
      '/patient/reports/$reportId/feedback';

  // عامة (بدون auth) - تُستخدم لعرض التقييمات على بروفايل الطبيب لكل
  // الزوار (Public: GET /doctors/{doctorId}/reviews[/summary]).
  static String doctorReviewsPublic(int doctorId) =>
      '/doctors/$doctorId/reviews';
  static String doctorReviewsSummaryPublic(int doctorId) =>
      '/doctors/$doctorId/reviews/summary';

  // --- Notifications (shared: doctor + patient, backend scopes by token) ---
  static const String notifications = '/notifications';
  static String notificationMarkRead(int id) => '$notifications/$id/read';
  static const String notificationsMarkAllRead = '$notifications/mark-all-read';

  // --- Wallet / Payments (Payments module - patient/doctor/shared) ---
  // Payment method values expected by the backend on booking and by the
  // payment-options response (App\Core\Enums\AppointmentPaymentMethod).
  static const String paymentMethodFullOnline = 'full_online';
  static const String paymentMethodCashDeposit = 'cash_deposit';

  static const String patientWallet = '/patient/wallet';
  static const String patientWalletTransactions = '$patientWallet/transactions';
  // خيارات الدفع (طرق مسموحة + نسبة العربون) - مستقلة عن أي موعد بعينه،
  // بتُستخدم بشاشة اختيار طريقة الدفع قبل تأكيد الحجز.
  static const String patientPaymentOptions = '$patientWallet/payment-options';
  static const String patientTopUpRequests = '$patientWallet/top-up-requests';

  static const String doctorWallet = '/doctor/wallet';
  static const String doctorWalletTransactions = '$doctorWallet/transactions';
  static const String doctorWithdrawalRequests = '$doctorWallet/withdrawal-requests';

  // --- Consultations (in-app chat) ---
  // Plain REST, no websocket/Firestore - inbox listing + per-appointment
  // message thread. Both doctor and patient sides use the same endpoints,
  // the backend scopes results to whoever the bearer token belongs to.
  static const String consultations = '/consultations';
  static String appointmentConsultation(int appointmentId) =>
      '/appointments/$appointmentId/consultation';
  static String appointmentConsultationMessages(int appointmentId) =>
      '${appointmentConsultation(appointmentId)}/messages';
  static String appointmentConsultationMessagesRead(int appointmentId) =>
      '${appointmentConsultationMessages(appointmentId)}/read';
}
