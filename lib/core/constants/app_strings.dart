import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled3/core/constants/setting.dart';

class AppStrings {
  static bool _isEn(BuildContext context) {
    return BlocProvider.of<SettingsCubit>(context).state.locale.languageCode ==
        'en';
  }

  // --- General & Login ---
  static String welcomeMessage(BuildContext context) =>
      _isEn(context) ? 'Welcome to MediZone' : 'مرحباً بك في MediZone';
  static const String appName = 'MediZone';
  static String login(BuildContext context) =>
      _isEn(context) ? 'Login' : 'تسجيل الدخول';
  static String signIn(BuildContext context) =>
      _isEn(context) ? 'Sign In' : 'دخول';
  static String signUpAs(BuildContext context) =>
      _isEn(context) ? 'Sign up as' : 'التسجيل كـ';
  static String doctor(BuildContext context) =>
      _isEn(context) ? 'Doctor' : 'طبيب';
  static String patient(BuildContext context) =>
      _isEn(context) ? 'Patient' : 'مريض';
  static String createAccount(BuildContext context) =>
      _isEn(context) ? ' Register' : 'إنشاء حساب';
  static String forgotPassword(BuildContext context) =>
      _isEn(context) ? 'Forgot Password?' : 'نسيت كلمة المرور؟';
  static String rememberDevice(BuildContext context) =>
      _isEn(context) ? 'Remember this device' : 'تذكر هذا الجهاز';
  static String orContinue(BuildContext context) =>
      _isEn(context) ? 'OR CONTINUE WITH' : 'أو المتابعة بواسطة';
  static String google(BuildContext context) =>
      _isEn(context) ? 'Google' : 'غوغل';
  static String apple(BuildContext context) => _isEn(context) ? 'Apple' : 'آبل';

  // --- Footer & Legal -
  static String loginFooterPre(BuildContext context) => _isEn(context)
      ? 'By logging in, you agree to our '
      : 'بتسجيل الدخول، فإنك توافق على ';
  static String termsOfService(BuildContext context) =>
      _isEn(context) ? 'Terms of Service' : 'شروط الخدمة';
  static String loginFooterAnd(BuildContext context) =>
      _isEn(context) ? ' and ' : ' و ';
  static String privacyPolicy(BuildContext context) =>
      _isEn(context) ? 'Privacy Policy.' : 'سياسة الخصوصية.';
  static String termsReviewNote(BuildContext context) => _isEn(context)
      ? 'By submitting this form, you agree to our Terms of Service and acknowledge our Privacy Policy regarding the handling of your medical and personal data.'
      : 'بتقديم هذا النموذج، فإنك توافق على شروط الخدمة الخاصة بنا وتقر بسياسة الخصوصية المتعلقة بالتعامل مع بياناتك الطبية والشخصية.';

  // --- Basic Information ---
  static String firstName(BuildContext context) =>
      _isEn(context) ? 'First Name' : 'الاسم الأول';
  static String firstNameHint(BuildContext context) =>
      _isEn(context) ? 'John' : 'أحمد';
  static String lastName(BuildContext context) =>
      _isEn(context) ? 'Last Name' : 'الاسم الأخير';
  static String lastNameHint(BuildContext context) =>
      _isEn(context) ? 'Doe' : 'العلوان';
  static String fullName(BuildContext context) =>
      _isEn(context) ? 'Full Name' : 'الاسم الكامل';
  static String emailAddress(BuildContext context) =>
      _isEn(context) ? 'Email Address' : 'البريد الإلكتروني';
  static String emailHint(BuildContext context) =>
      _isEn(context) ? 'example@mail.com' : 'example@mail.com';
  static String professionalEmail(BuildContext context) =>
      _isEn(context) ? 'Professional Email' : 'البريد الإلكتروني المهني';
  static String phoneNumber(BuildContext context) =>
      _isEn(context) ? 'Phone Number' : 'رقم الهاتف';
  static String phoneHint(BuildContext context) =>
      _isEn(context) ? '+963 9xx xxx xxx' : '+963 9xx xxx xxx';
  static String password(BuildContext context) =>
      _isEn(context) ? 'Password' : 'كلمة المرور';
  static String passwordHint(BuildContext context) =>
      _isEn(context) ? '••••••••' : '••••••••';
  static String confirmPassword(BuildContext context) =>
      _isEn(context) ? 'Confirm Password' : 'تأكيد كلمة المرور';

  // --- Step Titles & Subtitles ---
  static String tellUsAboutYourself(BuildContext context) =>
      _isEn(context) ? 'Tell us about yourself' : 'أخبرنا عن نفسك';
  static String provideBasicInfo(BuildContext context) => _isEn(context)
      ? 'Please provide your basic information'
      : 'يرجى إدخال معلوماتك الأساسية لبدء التسجيل';
  static String personalDetails(BuildContext context) =>
      _isEn(context) ? 'Personal Details' : 'التفاصيل الشخصية';
  static String personalDetailsHint(BuildContext context) =>
      _isEn(context) ? 'Personal Details' : 'تفاصيل شخصية';
  static String providePersonalInfo(BuildContext context) => _isEn(context)
      ? 'Please enter your personal details accurately'
      : 'يرجى إدخال معلوماتك الشخصية بدقة';
  static String professionalDocuments(BuildContext context) =>
      _isEn(context) ? 'Professional Documents' : 'الوثائق المهنية';
  static String uploadCertificatesHint(BuildContext context) => _isEn(context)
      ? 'Please upload your certificates for verification'
      : 'يرجى تحميل شهاداتك للتحقق من هويتك المهنية';
  static String professionalInfo(BuildContext context) =>
      _isEn(context) ? 'Professional Information' : 'المعلومات المهنية';
  static String workplaceExperienceHint(BuildContext context) => _isEn(context)
      ? 'Current workplaces and experience'
      : 'أماكن العمل الحالية والخبرة';
  static String reviewSubmit(BuildContext context) =>
      _isEn(context) ? 'Review & Submit' : 'المراجعة والإرسال';
  static String reviewInstructions(BuildContext context) => _isEn(context)
      ? 'Please review your information below before submitting.'
      : 'يرجى مراجعة معلوماتك أدناه قبل الإرسال النهائي.';

  // --- Detailed Personal Info ---
  static String dateOfBirth(BuildContext context) =>
      _isEn(context) ? 'Date of Birth' : 'تاريخ الميلاد';
  static String dateOfBirthHint(BuildContext context) =>
      _isEn(context) ? 'YYYY-MM-DD' : 'YYYY-MM-DD';
  static String gender(BuildContext context) =>
      _isEn(context) ? 'Gender' : 'الجنس';
  static String selectGender(BuildContext context) =>
      _isEn(context) ? 'Select Gender' : 'اختر الجنس';
  static String male(BuildContext context) => _isEn(context) ? 'Male' : 'ذكر';
  static String female(BuildContext context) =>
      _isEn(context) ? 'Female' : 'أنثى';
  static String nationality(BuildContext context) =>
      _isEn(context) ? 'Nationality' : 'الجنسية';
  static String enterFullAddress(BuildContext context) =>
      _isEn(context) ? 'Enter Full Address' : 'ادخل عنوانك الكامل';
  static String nationalIdNumber(BuildContext context) =>
      _isEn(context) ? 'National ID Number' : 'رقم الهوية الوطنية';
  static String nationalityHint(BuildContext context) =>
      _isEn(context) ? 'e.g. Syrian' : 'مثال: سوري';
  static String residentialAddress(BuildContext context) =>
      _isEn(context) ? 'Residential Address' : 'مكان الإقامة / العنوان';
  static String homeAddress(BuildContext context) =>
      _isEn(context) ? 'Home Address' : 'عنوان السكن';
  static String streetAddress(BuildContext context) =>
      _isEn(context) ? 'Street Address' : 'عنوان الشارع';
  static String cityStateZip(BuildContext context) =>
      _isEn(context) ? 'City, State, Zip' : 'المدينة، الولاية، الرمز البريدي';
  static String addressHint(BuildContext context) =>
      _isEn(context) ? 'Street, City, Country' : 'الشارع، المدينة، الدولة';

  // --- Professional/Doctor Specific ---
  static String mainSpecialty(BuildContext context) =>
      _isEn(context) ? 'Main Specialty' : 'التخصص الرئيسي';
  static String subSpecialty(BuildContext context) =>
      _isEn(context) ? 'Sub Specialty' : 'التخصص الفرعي';
  static String selectSpecialty(BuildContext context) =>
      _isEn(context) ? 'Select Specialty' : 'اختر التخصص';
  static String universityDegree(BuildContext context) =>
      _isEn(context) ? 'University Degree' : 'الشهادة الجامعية';
  static String educationDegree(BuildContext context) =>
      _isEn(context) ? 'Education Degree' : 'الدرجة العلمية';
  static String practiceLicense(BuildContext context) =>
      _isEn(context) ? 'Practice License' : 'مزاولة المهنة';
  static String licenseNumber(BuildContext context) =>
      _isEn(context) ? 'License Number' : 'رقم الترخيص';
  static String uploadImage(BuildContext context) =>
      _isEn(context) ? 'Upload Image' : 'رفع صورة';
  static String workplaces(BuildContext context) =>
      _isEn(context) ? 'Workplaces' : 'أماكن العمل';
  static String addWorkplace(BuildContext context) =>
      _isEn(context) ? 'Add Workplace' : 'إضافة مكان عمل';
  static String workplaceType(BuildContext context) =>
      _isEn(context) ? 'Workplace Type' : 'نوع مكان العمل';
  static String workplaceName(BuildContext context) =>
      _isEn(context) ? 'Workplace Name' : 'اسم مكان العمل';
  static String hospital(BuildContext context) =>
      _isEn(context) ? 'Hospital' : 'مستشفى';
  static String center(BuildContext context) =>
      _isEn(context) ? 'Medical Center' : 'مركز طبي';
  static String clinic(BuildContext context) =>
      _isEn(context) ? 'Clinic' : 'عيادة';
  static String experienceYearsLabel(BuildContext context) =>
      _isEn(context) ? 'Experience Years' : 'سنوات الخبرة';
  static String briefBio(BuildContext context) =>
      _isEn(context) ? 'Brief Bio' : 'نبذة عنك';
  static String optional(BuildContext context) =>
      _isEn(context) ? '(Optional)' : '(اختياري)';
  static String bioHintText(BuildContext context) => _isEn(context)
      ? 'Write a small bio...'
      : 'اكتب نبذة مختصرة عن مسيرتك المهنية...';
  static String onlineConsultation(BuildContext context) =>
      _isEn(context) ? 'Online Consultation' : 'استشارات الكترونية';
  static String onlineConsultationDesc(BuildContext context) => _isEn(context)
      ? 'Enable temporary chat consultations'
      : 'تفعيل خاصية الاستشارات عبر الشات المؤقت';
  static String duration(BuildContext context) =>
      _isEn(context) ? 'Duration' : 'المدة';
  static String fee(BuildContext context) => _isEn(context) ? 'Fee' : 'السعر';
  static String availability(BuildContext context) =>
      _isEn(context) ? 'Availability on App' : 'ساعات التواجد على التطبيق';
  static String workingHours(BuildContext context) =>
      _isEn(context) ? 'Working Hours' : 'ساعات العمل';

  // --- Identity Verification (Patient) ---
  static String verifyYourIdentity(BuildContext context) =>
      _isEn(context) ? 'Verify your identity' : 'تحقق من هويتك';
  static String uploadClearImage(BuildContext context) => _isEn(context)
      ? 'Upload a clear image of your national ID or passport to continue.'
      : 'قم بتحميل صورة واضحة لبطاقة الهوية الوطنية أو جواز السفر للمتابعة.';
  static String tapToCapture(BuildContext context) =>
      _isEn(context) ? 'Tap to capture' : 'انقر للالتقاط';
  static String orBrowseFiles(BuildContext context) =>
      _isEn(context) ? 'or browse files' : 'أو تصفح الملفات';
  static String identityDataEncrypted(BuildContext context) => _isEn(context)
      ? 'Your identity data is encrypted and stored securely following medical compliance standards.'
      : 'بيانات هويتك مشفرة ومخزنة بشكل آمن باتباع معايير الامتثال الطبي.';
  static String identityVerificationTitle(BuildContext context) =>
      _isEn(context) ? 'Identity Verification' : 'التحقق من الهوية';
  static String documentScannedSuccessfully(BuildContext context) =>
      _isEn(context)
      ? 'Your document has been successfully scanned and verified.'
      : 'تم مسح مستندك والتحقق منه بنجاح.';

  // --- Review Sections ---
  static String basicInfo(BuildContext context) =>
      _isEn(context) ? 'Basic Info' : 'المعلومات الأساسية';
  static String accountInfo(BuildContext context) =>
      _isEn(context) ? 'Account Information' : 'معلومات الحساب';
  static String specialtyAndDetails(BuildContext context) =>
      _isEn(context) ? 'Specialty & Details' : 'التخصص والتفاصيل';
  static String documents(BuildContext context) =>
      _isEn(context) ? 'Documents' : 'الوثائق';
  static String workAndExperience(BuildContext context) =>
      _isEn(context) ? 'Work & Experience' : 'العمل والخبرة';

  // --- Buttons & Navigation ---
  static String nextStep(BuildContext context) =>
      _isEn(context) ? 'Next Step' : 'الخطوة التالية';
  static String back(BuildContext context) =>
      _isEn(context) ? 'Back' : 'السابق';
  static String submit(BuildContext context) =>
      _isEn(context) ? 'Submit' : 'إرسال البيانات';
  static String confirmSubmit(BuildContext context) =>
      _isEn(context) ? 'Confirm & Submit' : 'تأكيد وإرسال';
  static String retake(BuildContext context) =>
      _isEn(context) ? 'Retake' : 'إعادة التقاط';
  static String cancel(BuildContext context) =>
      _isEn(context) ? 'Cancel' : 'إلغاء';
  static String add(BuildContext context) => _isEn(context) ? 'Add' : 'إضافة';
  static String saveDraft(BuildContext context) =>
      _isEn(context) ? 'Save Draft' : 'حفظ كمسودة';
  static String continueText(BuildContext context) =>
      _isEn(context) ? 'Continue' : 'متابعة';

  // --- Validations & Warnings ---
  static String requiredField(BuildContext context) =>
      _isEn(context) ? 'This field is required' : 'هذا الحقل مطلوب';
  static String invalidEmail(BuildContext context) => _isEn(context)
      ? 'Please enter a valid email address'
      : 'يرجى إدخال بريد إلكتروني صحيح';
  static String passwordLengthWarning(BuildContext context) => _isEn(context)
      ? 'Must be at least 8 characters'
      : 'يجب ألا تقل عن 8 خانات أو رموز';
  static String passwordsDoNotMatch(BuildContext context) =>
      _isEn(context) ? 'Passwords do not match' : 'كلمات المرور غير متطابقة';
  static String viewProfile(BuildContext context) =>
      _isEn(context) ? 'View Profile' : 'الملف الشخصي';
  static String findDoctorTitle(BuildContext context) =>
      _isEn(context) ? 'Find a Doctor' : 'البحث عن دكتور';

  // --- Specialties Lists ---
  static List<String> mainSpecialties(BuildContext context) => _isEn(context)
      ? ['Medicine', 'Dentistry', 'Pharmacy']
      : ['الطب البشري', 'طب الأسنان', 'الصيدلة'];

  static List<String> subSpecialties(BuildContext context, String main) {
    final isEn = _isEn(context);
    if (main == 'Medicine' || main == 'الطب البشري') {
      return isEn
          ? [
              'Cardiology',
              'Dermatology',
              'Neurology',
              'Pediatrics',
              'Surgery',
              'Orthopedics',
              'Ophthalmology',
              'ENT',
            ]
          : [
              'قلبية',
              'جلدية',
              'عصبية',
              'أطفال',
              'جراحة عامة',
              'عظمية',
              'عينية',
              'أذن أنف حنجرة',
            ];
    }
    if (main == 'Dentistry' || main == 'طب الأسنان') {
      return isEn
          ? [
              'Orthodontics',
              'Endodontics',
              'Oral Surgery',
              'Periodontics',
              'Pedodontics',
            ]
          : ['تقويم', 'معالجة لبية', 'جراحة فم', 'لثة', 'أسنان أطفال'];
    }
    if (main == 'Pharmacy' || main == 'الصيدلة') {
      return isEn
          ? ['Clinical Pharmacy', 'Pharmacology']
          : ['صيدلة سريرية', 'علم أدوية'];
    }
    return isEn ? ['General'] : ['عام'];
  }

  // --- Canonical (locale-independent) values ---
  // NOTE: doctor records store specialty names in English only (see
  // DoctorListingModel). Filter chips must therefore be matched against
  // this canonical English list, never against the translated display
  // label — otherwise selecting a specialty filter while in Arabic mode
  // silently returns zero doctors, since 'قلبية' never equals 'Cardiology'.
  static const String allSpecialtiesValue = '__all__';

  static List<String> subSpecialtiesCanonical(String main) {
    if (main == 'Medicine' || main == 'الطب البشري') {
      return const [
        'Cardiology',
        'Dermatology',
        'Neurology',
        'Pediatrics',
        'Surgery',
        'Orthopedics',
        'Ophthalmology',
        'ENT',
      ];
    }
    if (main == 'Dentistry' || main == 'طب الأسنان') {
      return const [
        'Orthodontics',
        'Endodontics',
        'Oral Surgery',
        'Periodontics',
        'Pedodontics',
      ];
    }
    if (main == 'Pharmacy' || main == 'الصيدلة') {
      return const ['Clinical Pharmacy', 'Pharmacology'];
    }
    return const ['General'];
  }

  static String reviewSubmitTitle(BuildContext context) =>
      _isEn(context) ? 'Review & Submit' : 'المراجعة والإرسال';
  static String reviewSubmitDesc(BuildContext context) => _isEn(context)
      ? 'Please verify that all the information provided is correct before finalizing your profile creation. A complete and accurate profile ensures better care.'
      : 'يرجى التحقق من أن جميع المعلومات المقدمة صحيحة قبل إنهاء إنشاء ملفك الشخصي. الملف الشخصي الكامل والدقيق يضمن رعاية أفضل.';

  static String basicInfoSection(BuildContext context) =>
      _isEn(context) ? 'Basic Info' : 'المعلومات الأساسية';
  static String historySection(BuildContext context) =>
      _isEn(context) ? 'History' : 'السجل الطبي';
  static String medsSection(BuildContext context) =>
      _isEn(context) ? 'Meds' : 'الأدوية';

  static String knownAllergiesLabel(BuildContext context) =>
      _isEn(context) ? 'Known Allergies' : 'الحساسية المعروفة';
  static String chronicConditionsLabel(BuildContext context) =>
      _isEn(context) ? 'Chronic Conditions' : 'الأمراض المزمنة';
  static String pastSurgeriesLabel(BuildContext context) => _isEn(context)
      ? 'Past Surgeries / Procedures'
      : 'العمليات الجراحية / الإجراءات السابقة';

  static String confirmSubmitButton(BuildContext context) =>
      _isEn(context) ? 'Confirm & Submit Profile' : 'تأكيد وإرسال الملف الشخصي';

  static String privacyStatementPrefix(BuildContext context) => _isEn(context)
      ? 'Your data is securely encrypted. By submitting, you agree to the '
      : 'بياناتك مشفرة بشكل آمن. من خلال الإرسال، فإنك توافق على ';
  static String termsOfServiceLink(BuildContext context) =>
      _isEn(context) ? 'Terms of Service' : 'شروط الخدمة';
  static String privacyStatementMiddle(BuildContext context) =>
      _isEn(context) ? ' and acknowledge the ' : ' وتقر بـ ';
  static String privacyPolicyLink(BuildContext context) =>
      _isEn(context) ? 'Privacy Policy' : 'سياسة الخصوصية';
  static String privacyStatementSuffix(BuildContext context) => _isEn(context)
      ? ' regarding your Protected Health Information (PHI).'
      : ' فيما يتعلق بمعلوماتك الصحية المحمية (PHI).';
  static String medicalProfileTitle(BuildContext context) =>
      _isEn(context) ? 'Medical Profile' : 'الملف الطبي';
  static String attachmentsSection(BuildContext context) =>
      _isEn(context) ? 'Attachments Section' : 'قسم المرفقات';
  static String uploadFilesTitle(BuildContext context) =>
      _isEn(context) ? 'Upload Files' : 'تحميل الملفات';
  static String uploadFilesDesc(BuildContext context) => _isEn(context)
      ? 'Please provide any relevant documents to complete your profile. This helps us tailor your care.'
      : 'يرجى تقديم أي وثائق طبية ذات صلة لإكمال ملفك التعريفي ومساعدتنا في تخصيص الرعاية الخاصة بك.';
  static String attachedFilesSection(BuildContext context) =>
      _isEn(context) ? 'Attached Files Section' : 'قسم الملفات المرفقة';

  // --- نصوص إضافية مستخدمة في الشاشات السابقة لضمان الاكتمال التام ---
  static String medicalHistoryTitle(BuildContext context) =>
      _isEn(context) ? 'Medical History' : 'التاريخ الطبي';
  static String medicalHistoryDesc(BuildContext context) => _isEn(context)
      ? 'Please provide details about your past and current medical conditions to help us tailor your care.'
      : 'يرجى تقديم تفاصيل حول حالتك الطبية السابقة والحالية لمساعدتنا في تخصيص رعاية صحية لك.';
  static String chronicDiseasesSection(BuildContext context) =>
      _isEn(context) ? 'Chronic Diseases' : 'الأمراض المزمنة';
  static String surgeriesSection(BuildContext context) =>
      _isEn(context) ? 'Surgeries' : 'العمليات الجراحية';
  static String allergiesSection(BuildContext context) =>
      _isEn(context) ? 'Allergies' : 'الحساسية';
  static String familyHistorySection(BuildContext context) =>
      _isEn(context) ? 'Family History' : 'التاريخ الطبي للعائلة';
  static String medicationsTitle(BuildContext context) =>
      _isEn(context) ? 'Medications' : 'الأدوية';
  static String medicationsDesc(BuildContext context) => _isEn(context)
      ? 'Please review or add your current prescribed medications and dosages.'
      : 'يرجى مراجعة أو إضافة أدوية وجرعات موصوفة لك حالياً.';
  static String attachedFilesTitle(BuildContext context) =>
      _isEn(context) ? 'Attached Files' : 'الملفات المرفقة';
  static String addNew(BuildContext context) =>
      _isEn(context) ? 'Add New ' : 'اضافة جديدة ';
  static String tapToUpload(BuildContext context) =>
      _isEn(context) ? 'Tap to upload file' : 'اضغط لرفع الملف';
  static String orDragDrop(BuildContext context) =>
      _isEn(context) ? 'or drag and drop here' : 'أو قم بسحب وإفلاته هنا';
  static String medicalRecords(BuildContext context) =>
      _isEn(context) ? 'Medical Records' : 'السجل الطبي';
  static String encountersHistory(BuildContext context) =>
      _isEn(context) ? 'Encounters History' : 'تواريخ المقابلات';
  static String comprehensiveHistory(BuildContext context) =>
      _isEn(context) ? 'Comprehensive History' : 'التاريخ المرضي الشامل';
  static String endOfRecentHistory(BuildContext context) =>
      _isEn(context) ? 'End of recent history' : 'نهاية السجل الأخير';
  static String otherConditions(BuildContext context) =>
      _isEn(context) ? 'Other Conditions' : 'حالات اخرى';
  static String familyHistory(BuildContext context) =>
      _isEn(context) ? 'Family History' : 'التاريخ العائلي (وراثة)';
  static String allergies(BuildContext context) =>
      _isEn(context) ? 'allergies' : 'الحساسية';
  static String surgeries(BuildContext context) =>
      _isEn(context) ? 'surgeries' : 'العمليات الجراحية';
  static String chronicDiseases(BuildContext context) =>
      _isEn(context) ? 'Chronic Diseases' : 'الامراض المزمنة';
  static String viewAll(BuildContext context) =>
      _isEn(context) ? 'View All' : 'عرض الكل';
  static String view(BuildContext context) => _isEn(context) ? 'view' : 'عرض';
  static String download(BuildContext context) =>
      _isEn(context) ? 'download' : 'تحميل';
  static String prescriptions(BuildContext context) =>
      _isEn(context) ? 'prescriptions' : 'وصفة طبية';
  static String labResults(BuildContext context) =>
      _isEn(context) ? 'Lab Results' : 'نتائج مخبرية';
  static String medicalImages(BuildContext context) =>
      _isEn(context) ? 'Medical Images' : 'صور طبية';
  static String attachments(BuildContext context) =>
      _isEn(context) ? 'attachments' : 'المرفقات';
  static String activeMedications(BuildContext context) =>
      _isEn(context) ? 'Active Medications' : 'الادوية الحالية';
  static String currentPrescriptions(BuildContext context) =>
      _isEn(context) ? 'Current Prescriptions' : 'الوصفات الطبية الحالية';
  static String manage(BuildContext context) =>
      _isEn(context) ? 'Manage' : 'ادارة';
  static String latestVitals(BuildContext context) =>
      _isEn(context) ? 'Latest Vitals' : 'اخر المستجدات';
  static String viewTrends(BuildContext context) =>
      _isEn(context) ? 'View Trends' : 'عرض الاتجاهات';
  static String medications(BuildContext context) =>
      _isEn(context) ? 'medications' : 'الادوية';
  static String history(BuildContext context) =>
      _isEn(context) ? 'history' : 'التاريخ';
  static String overview(BuildContext context) =>
      _isEn(context) ? 'Overview' : 'معلومات عامة';
  static String recentActivity(BuildContext context) =>
      _isEn(context) ? 'Recent Activity' : 'النشاطات الاخيرة';
  static String diagnosisSummary(BuildContext context) =>
      _isEn(context) ? 'Diagnosis Summary' : 'ملخص التشخيص';
  static String viewFullDetails(BuildContext context) =>
      _isEn(context) ? 'View Full Details' : 'عرض التفاصيل الكاملة';
  static String surgeryDateLabel(BuildContext context) =>
      _isEn(context) ? 'Surgery date' : 'تاريخ العملية';
  static String reactionLabel(BuildContext context) =>
      _isEn(context) ? 'Reaction' : 'رد الفعل';
  static String relationLabel(BuildContext context) =>
      _isEn(context) ? 'Relation' : 'صلة القرابة';
  static String severityLabel(BuildContext context) =>
      _isEn(context) ? 'Severity' : 'الشدة';
  static String diagnosed(BuildContext context) =>
      _isEn(context) ? 'Diagnosed' : 'تم التشخيص';
  static String availableDoctors(BuildContext context) =>
      _isEn(context) ? 'Available Doctors' : 'الأطباء المتاحون';
  static String savedDoctors(BuildContext context) =>
      _isEn(context) ? 'Saved Doctors' : 'الأطباء المحفوظون';
  static String visit(BuildContext context) =>
      _isEn(context) ? 'visit' : 'زيارة';
  static String home(BuildContext context) =>
      _isEn(context) ? 'Home' : 'الرئيسية';
  static String appointments(BuildContext context) =>
      _isEn(context) ? 'My Appointments' : 'حجوزاتي';
  static String doctors(BuildContext context) =>
      _isEn(context) ? 'Doctors' : 'الأطباء';
  static String chats(BuildContext context) =>
      _isEn(context) ? 'Chats' : 'المحادثات';
  static String searchHint(BuildContext context) => _isEn(context)
      ? 'Search by name, specialty...'
      : 'ابحث باسم الطبيب، التخصص...';
  static String about(BuildContext context) =>
      _isEn(context) ? 'About' : 'نبذة عن';
  static String availableSchedule(BuildContext context) =>
      _isEn(context) ? 'Available Schedule' : 'المواعيد المتاحة';
  static String morning(BuildContext context) =>
      _isEn(context) ? 'Morning' : 'الفترة الصباحية';
  static String afternoon(BuildContext context) =>
      _isEn(context) ? 'Afternoon' : 'فترة بعد الظهر';
  static String noSlotsForPeriod(BuildContext context) =>
      _isEn(context) ? 'No slots available' : 'لا يوجد مواعيد متاحة';
  static String consultationFeeLabel(BuildContext context) =>
      _isEn(context) ? 'Consultation Fee' : 'قيمة الاستشارة';
  static String bookAppointment(BuildContext context) =>
      _isEn(context) ? 'Book appointment' : 'حجز موعد';
  static String messageDoctor(BuildContext context) =>
      _isEn(context) ? 'Message' : 'مراسلة';
  static String messageDoctorRequiresAppointmentTitle(BuildContext context) =>
      _isEn(context)
      ? 'Book an appointment to chat'
      : 'احجز موعداً حتى تتمكن من المراسلة';
  static String messageDoctorRequiresAppointmentBody(BuildContext context) =>
      _isEn(context)
      ? 'You can message a doctor once you have an appointment with them.'
      : 'يمكنك مراسلة الطبيب بعد حجز موعد معه.';
  static String ok(BuildContext context) => _isEn(context) ? 'OK' : 'حسناً';
  static String reviews(BuildContext context) =>
      _isEn(context) ? 'reviews' : 'تقييم';
  static String settings(BuildContext context) =>
      _isEn(context) ? 'Settings' : 'الإعدادات';
  static String notificationSettings(BuildContext context) =>
      _isEn(context) ? 'Notification Settings' : 'إعدادات الإشعارات';
  static String theme(BuildContext context) =>
      _isEn(context) ? 'Theme' : 'المظهر / الثيم';
  static String language(BuildContext context) =>
      _isEn(context) ? 'Language' : 'اللغة';
  static String aboutUs(BuildContext context) =>
      _isEn(context) ? 'About Us' : 'من نحن';
  static String helpCenter(BuildContext context) =>
      _isEn(context) ? 'Help Center' : 'مركز المساعدة';

  // --- Settings Drawer (theme / font scale) ---
  static String lightMode(BuildContext context) =>
      _isEn(context) ? 'Light Mode' : 'الوضع الفاتح';
  static String darkMode(BuildContext context) =>
      _isEn(context) ? 'Dark Mode' : 'الوضع الداكن';
  static String fontScaleLabel(BuildContext context) =>
      _isEn(context) ? 'Font Size' : 'حجم الخط';
  static String fontScaleNormal(BuildContext context) =>
      _isEn(context) ? 'Normal' : 'عادي';
  static String fontScaleMedium(BuildContext context) =>
      _isEn(context) ? 'Medium' : 'متوسط';
  static String fontScaleLarge(BuildContext context) =>
      _isEn(context) ? 'Large' : 'كبير';
  static String appVersionLabel(BuildContext context) => _isEn(context)
      ? 'Version 2.4.0 (Clinical Stable)'
      : 'الإصدار 2.4.0 (الإصدار السريري المستقر)';

  // --- Search bar / Filters entry point ---
  static String searchDoctorHint(BuildContext context) =>
      _isEn(context) ? 'Search doctor' : 'ابحث عن طبيب';
  static String filtersTooltip(BuildContext context) =>
      _isEn(context) ? 'Filters' : 'الفلاتر';

  // --- Filters Screen ---
  static String filtersTitle(BuildContext context) =>
      _isEn(context) ? 'Filters' : 'الفلاتر';
  static String reset(BuildContext context) =>
      _isEn(context) ? 'Reset' : 'إعادة تعيين';
  static String search(BuildContext context) =>
      _isEn(context) ? 'Search' : 'البحث';
  static String location(BuildContext context) =>
      _isEn(context) ? 'Location' : 'الموقع';
  static String nearMeGps(BuildContext context) =>
      _isEn(context) ? 'Near me (GPS)' : 'بالقرب مني (GPS)';
  static String selectCityArea(BuildContext context) =>
      _isEn(context) ? 'Select City / Area' : 'اختر المدينة / المنطقة';
  static String specialty(BuildContext context) =>
      _isEn(context) ? 'Specialty' : 'التخصص';
  static String experienceYears(BuildContext context) =>
      _isEn(context) ? 'Experience (Years)' : 'سنوات الخبرة';
  static String min(BuildContext context) =>
      _isEn(context) ? 'Min' : 'الحد الأدنى';
  static String max(BuildContext context) =>
      _isEn(context) ? 'Max' : 'الحد الأقصى';
  static String consultationPrice(BuildContext context) =>
      _isEn(context) ? 'Consultation Price' : 'سعر الاستشارة';
  static String today(BuildContext context) =>
      _isEn(context) ? 'Today' : 'اليوم';
  static String tomorrow(BuildContext context) =>
      _isEn(context) ? 'Tomorrow' : 'غداً';
  static String thisWeek(BuildContext context) =>
      _isEn(context) ? 'This week' : 'هذا الأسبوع';
  static String custom(BuildContext context) =>
      _isEn(context) ? 'Custom' : 'مخصص';
  static String timeSlot(BuildContext context) =>
      _isEn(context) ? 'Time Slot' : 'الفترة الزمنية';
  static String evening(BuildContext context) =>
      _isEn(context) ? 'Evening' : 'المساء';
  static String consultationType(BuildContext context) =>
      _isEn(context) ? 'Consultation Type' : 'نوع الاستشارة';
  static String inPerson(BuildContext context) =>
      _isEn(context) ? 'In-person' : 'حضوري';
  static String online(BuildContext context) =>
      _isEn(context) ? 'Online' : 'عن بُعد';
  static String both(BuildContext context) =>
      _isEn(context) ? 'Both' : 'كلاهما';
  static String sortBy(BuildContext context) =>
      _isEn(context) ? 'Sort By' : 'الترتيب حسب';
  static String bestMatch(BuildContext context) =>
      _isEn(context) ? 'Best Match' : 'الأنسب';
  static String clearAll(BuildContext context) =>
      _isEn(context) ? 'Clear All' : 'مسح الكل';
  static String applyFilters(BuildContext context, int count) =>
      _isEn(context) ? 'Apply Filters ($count)' : 'تطبيق الفلاتر ($count)';

  // --- Home Screen (Patient) ---
  static String goodMorning(BuildContext context) =>
      _isEn(context) ? 'Good morning,' : 'صباح الخير،';
  static String goodAfternoon(BuildContext context) =>
      _isEn(context) ? 'Good afternoon,' : 'مساء الخير،';
  static String goodEvening(BuildContext context) =>
      _isEn(context) ? 'Good evening,' : 'مساء الخير،';
  static String findDoctorEasilyTitle(BuildContext context) =>
      _isEn(context) ? 'Find your doctor easily' : 'اعثر على طبيبك بسهولة';
  static String searchNow(BuildContext context) =>
      _isEn(context) ? 'Search now' : 'ابحث الآن';
  static String doctorSpecialties(BuildContext context) =>
      _isEn(context) ? 'Doctor Specialties' : 'تخصصات الأطباء';
  static String seeAll(BuildContext context) =>
      _isEn(context) ? 'See all' : 'عرض الكل';
  static String doctorsNearYou(BuildContext context) =>
      _isEn(context) ? 'Doctors Near You' : 'أطباء بالقرب منك';
  static String book(BuildContext context) => _isEn(context) ? 'Book' : 'حجز';
  static String noDoctorsFound(BuildContext context) =>
      _isEn(context) ? 'No doctors found' : 'لا يوجد أطباء';
  static String noSavedDoctorsYet(BuildContext context) =>
      _isEn(context) ? 'No saved doctors yet.' : 'لا يوجد أطباء محفوظون بعد.';
  static String favourites(BuildContext context) =>
      _isEn(context) ? 'Favourites' : 'المفضلة';
  static String doctorsFoundCount(BuildContext context, int count) =>
      _isEn(context) ? '$count found' : '$count نتيجة';
  static String doctorsSavedCount(BuildContext context, int count) =>
      _isEn(context) ? '$count saved' : '$count محفوظ';

  // --- Patient Profile Screen ---
  static String profile(BuildContext context) =>
      _isEn(context) ? 'Profile' : 'الملف الشخصي';
  static String editProfile(BuildContext context) =>
      _isEn(context) ? 'Edit Profile' : 'تعديل الملف الشخصي';
  static String personalInformation(BuildContext context) =>
      _isEn(context) ? 'Personal Information' : 'المعلومات الشخصية';
  static String contactDetails(BuildContext context) =>
      _isEn(context) ? 'Contact Details' : 'معلومات التواصل';
  static String email(BuildContext context) =>
      _isEn(context) ? 'Email' : 'البريد الإلكتروني';
  static String address(BuildContext context) =>
      _isEn(context) ? 'Address' : 'العنوان';
  static String appSettings(BuildContext context) =>
      _isEn(context) ? 'App Settings' : 'إعدادات التطبيق';
  static String changePassword(BuildContext context) =>
      _isEn(context) ? 'Change Password' : 'تغيير كلمة المرور';
  // ✅ إضافة: "إعادة تعيين كلمة المرور" بنفس آلية "نسيت كلمة المرور"
  // المستخدمة بشاشة تسجيل الدخول (بريد + كود تحقق + كلمة مرور جديدة)،
  // بس متاحة من قائمة الإعدادات لمستخدم مسجّل دخوله فعلاً.
  static String resetPassword(BuildContext context) =>
      _isEn(context) ? 'Reset Password' : 'إعادة تعيين كلمة المرور';
  static String logOut(BuildContext context) =>
      _isEn(context) ? 'Log Out' : 'تسجيل الخروج';
  static String deleteAccount(BuildContext context) =>
      _isEn(context) ? 'Delete account' : 'حذف الحساب';

  // --- Delete Account Confirmation Dialog ---
  static String deleteAccountTitle(BuildContext context) =>
      _isEn(context) ? 'Delete Account?' : 'حذف الحساب؟';
  static String deleteAccountDesc(BuildContext context) => _isEn(context)
      ? 'Are you sure you want to delete your account? This action is permanent and all your medical history and data will be lost.'
      : 'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء نهائي وسيتم فقدان جميع بياناتك وتاريخك الطبي.';
  static String delete(BuildContext context) =>
      _isEn(context) ? 'Delete' : 'حذف';
  static String logOutConfirmTitle(BuildContext context) =>
      _isEn(context) ? 'Log Out?' : 'تسجيل الخروج؟';
  static String logOutConfirmDesc(BuildContext context) => _isEn(context)
      ? 'Are you sure you want to log out of your account?'
      : 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟';

  // --- Patient Medical Record (view) - shared across tabs ---
  static String refresh(BuildContext context) =>
      _isEn(context) ? 'Refresh' : 'تحديث';
  // ✅ إضافة: كان ما في أي طريقة لتعديل السجل الطبي بعد أول تعبئة -
  // زر يفتح نفس معالج الإدخال (History/Medications/Attachments) على
  // البيانات الموجودة أصلاً حتى يقدر المريض يعدّلها.
  static String editMedicalRecord(BuildContext context) =>
      _isEn(context) ? 'Edit Medical Record' : 'تعديل السجل الطبي';
  static String retry(BuildContext context) =>
      _isEn(context) ? 'Retry' : 'إعادة المحاولة';
  static String somethingWentWrong(BuildContext context) =>
      _isEn(context) ? 'Something went wrong.' : 'حدث خطأ ما.';
  static String confirm(BuildContext context) =>
      _isEn(context) ? 'Confirm' : 'تأكيد';
  static String noMedicalRecordYetTitle(BuildContext context) =>
      _isEn(context) ? 'No medical record yet' : 'لا يوجد سجل طبي بعد';
  static String noMedicalRecordYetDesc(BuildContext context) => _isEn(context)
      ? 'Complete your medical record so we can tailor your care and keep everything in one place.'
      : 'أكمل سجلك الطبي حتى نقدر نخصص رعايتك ونجمع كل شي بمكان واحد.';
  static String startMedicalRecord(BuildContext context) =>
      _isEn(context) ? 'Start Medical Record' : 'ابدأ السجل الطبي';
  static String recordSummary(BuildContext context) =>
      _isEn(context) ? 'Record Summary' : 'ملخص السجل';
  static String completeProfilePrompt(BuildContext context) => _isEn(context)
      ? 'Complete your profile to see it here.'
      : 'أكمل ملفك الشخصي ليظهر هنا.';

  // --- Medications tab ---
  static String active(BuildContext context) =>
      _isEn(context) ? 'Active' : 'نشط';
  static String past(BuildContext context) => _isEn(context) ? 'Past' : 'سابق';
  static String stopped(BuildContext context) =>
      _isEn(context) ? 'Stopped' : 'موقوف';
  static String stopMedication(BuildContext context) =>
      _isEn(context) ? 'Stop Medication' : 'إيقاف الدواء';
  static String stopMedicationConfirmTitle(BuildContext context) =>
      _isEn(context) ? 'Stop this medication?' : 'إيقاف هذا الدواء؟';
  static String stopMedicationConfirmDesc(BuildContext context) =>
      _isEn(context)
      ? 'It will be marked as stopped and moved under Past.'
      : 'سيتم وضع علامة "موقوف" عليه ونقله إلى قسم السابقة.';
  static String stopReasonHint(BuildContext context) =>
      _isEn(context) ? 'Reason (optional)' : 'السبب (اختياري)';
  static String noMedicationsYet(BuildContext context) =>
      _isEn(context) ? 'No medications added yet.' : 'لا توجد أدوية مضافة بعد.';
  static String dosageLabel(BuildContext context) =>
      _isEn(context) ? 'Dosage' : 'الجرعة';
  static String frequencyLabel(BuildContext context) =>
      _isEn(context) ? 'Frequency' : 'التكرار';
  static String strengthLabel(BuildContext context) =>
      _isEn(context) ? 'Strength' : 'التركيز';
  static String routeLabel(BuildContext context) =>
      _isEn(context) ? 'Route' : 'طريقة الاستخدام';
  static String startedOn(BuildContext context) =>
      _isEn(context) ? 'Started' : 'بدأ في';
  static String stoppedOn(BuildContext context) =>
      _isEn(context) ? 'Stopped on' : 'أُوقف في';
  static String notesLabel(BuildContext context) =>
      _isEn(context) ? 'Notes' : 'ملاحظات';

  // --- History tab ---
  static String noHistoryRecordsYet(BuildContext context) => _isEn(context)
      ? 'No records in this section yet.'
      : 'لا توجد سجلات ضمن هذا القسم بعد.';

  // --- Attachments tab ---
  static String noAttachmentsYet(BuildContext context) => _isEn(context)
      ? 'No attachments uploaded yet.'
      : 'لا توجد مرفقات مرفوعة بعد.';
  static String encrypted(BuildContext context) =>
      _isEn(context) ? 'Encrypted' : 'مشفّر';
  static String uploadedOn(BuildContext context) =>
      _isEn(context) ? 'Uploaded' : 'تم الرفع';
  static String downloading(BuildContext context) =>
      _isEn(context) ? 'Downloading...' : 'جارِ التحميل...';
  static String downloadFailed(BuildContext context) =>
      _isEn(context) ? 'Download failed' : 'فشل التحميل';
  static String deleteConfirmTitle(BuildContext context) =>
      _isEn(context) ? 'Delete this item?' : 'حذف هذا العنصر؟';
  static String deleteConfirmDesc(BuildContext context) => _isEn(context)
      ? 'This action cannot be undone.'
      : 'لا يمكن التراجع عن هذا الإجراء.';
  static String deleteAttachmentConfirmTitle(BuildContext context) =>
      _isEn(context) ? 'Delete this file?' : 'حذف هذا الملف؟';
  static String deleteAttachmentConfirmDesc(BuildContext context) =>
      _isEn(context)
      ? 'This action cannot be undone.'
      : 'لا يمكن التراجع عن هذا الإجراء.';
  // ✅ إضافة: تاب Encounter الجديد بصفحة السجل الطبي عند المريض
  static String encounterTab(BuildContext context) =>
      _isEn(context) ? 'Encounters' : 'الزيارات';
  static String encounterDetails(BuildContext context) =>
      _isEn(context) ? 'Encounter Details' : 'تفاصيل الزيارة';
  static String clinicalNotes(BuildContext context) =>
      _isEn(context) ? 'Clinical Notes' : 'الملاحظات السريرية';
  static String diagnosis(BuildContext context) =>
      _isEn(context) ? 'Diagnosis' : 'التشخيص';
  static String noEncountersYet(BuildContext context) =>
      _isEn(context) ? 'No encounters yet' : 'لا يوجد زيارات مسجّلة بعد';
  static String noEncountersDesc(BuildContext context) => _isEn(context)
      ? 'Completed visits with your doctor\'s diagnosis and notes will appear here.'
      : 'الزيارات المكتملة مع تشخيص وملاحظات طبيبك رح تظهر هون.';
  // --- Patient Appointments / Bookings (⚠️ 19/8: أضيفت مع ربط الحجز
  // الحقيقي بـ POST /patient/appointments وGET/cancel/reschedule). ---
  static String bookings(BuildContext context) =>
      _isEn(context) ? 'Bookings' : 'الحجوزات';
  static String upcomingAppointments(BuildContext context) =>
      _isEn(context) ? 'Upcoming' : 'الحالية';
  static String appointmentsHistory(BuildContext context) =>
      _isEn(context) ? 'History' : 'السابقة';
  static String cancelledAppointments(BuildContext context) =>
      _isEn(context) ? 'Cancelled' : 'الملغاة';
  static String confirmBookingTitle(BuildContext context) =>
      _isEn(context) ? 'Confirm booking' : 'تأكيد الحجز';
  static String confirmBookingDesc(BuildContext context) => _isEn(context)
      ? 'Do you want to confirm this booking?'
      : 'هل تريد تأكيد هذا الحجز؟';
  static String confirmYes(BuildContext context) =>
      _isEn(context) ? 'Yes, confirm' : 'نعم، تأكيد';
  static String confirmNo(BuildContext context) =>
      _isEn(context) ? 'Not now' : 'لا الآن';
  static String bookingSuccessTitle(BuildContext context) =>
      _isEn(context) ? 'Booking confirmed' : 'تم تأكيد الحجز';
  static String bookingSuccessDesc(BuildContext context) => _isEn(context)
      ? 'Your appointment has been booked and paid successfully.'
      : 'تم حجز موعدك ودفعه بنجاح.';
  static String slotNoLongerAvailable(BuildContext context) => _isEn(context)
      ? 'This time slot is no longer available. Please pick another one.'
      : 'هالموعد لم يعد متاحاً، اختر وقت تاني من فضلك.';
  static String noAppointmentsHere(BuildContext context) =>
      _isEn(context) ? 'No appointments here' : 'لا يوجد حجوزات هون';
  static String cancelBookingTitle(BuildContext context) =>
      _isEn(context) ? 'Cancel appointment?' : 'إلغاء الموعد؟';
  static String cancelAppointmentAction(BuildContext context) =>
      _isEn(context) ? 'Cancel appointment' : 'إلغاء الموعد';
  static String cancelBookingDesc(BuildContext context) => _isEn(context)
      ? 'Are you sure you want to cancel this appointment?'
      : 'متأكد إنك بدك تلغي هالموعد؟';
  static String keepBooking(BuildContext context) =>
      _isEn(context) ? 'Keep it' : 'رجوع';
  static String rescheduleAppointment(BuildContext context) =>
      _isEn(context) ? 'Reschedule' : 'تعديل الموعد';
  static String selectNewSlot(BuildContext context) =>
      _isEn(context) ? 'Choose a new time' : 'اختر وقت جديد';
  static String rescheduleSuccessTitle(BuildContext context) =>
      _isEn(context) ? 'Appointment updated' : 'تم تعديل الموعد';

  // --- Doctor Engagement: Favorites / Report / Review (DoctorEngagement module) ---
  static String favoriteAdded(BuildContext context) =>
      _isEn(context) ? 'Doctor added to favorites' : 'تمت إضافة الطبيب للمفضلة';
  static String favoriteRemoved(BuildContext context) => _isEn(context)
      ? 'Doctor removed from favorites'
      : 'تمت إزالة الطبيب من المفضلة';

  static String reportDoctorAction(BuildContext context) =>
      _isEn(context) ? 'Report doctor' : 'الإبلاغ عن الطبيب';
  static String reportDoctorTitle(BuildContext context) =>
      _isEn(context) ? 'Report this doctor' : 'الإبلاغ عن هذا الطبيب';
  static String reportCategoryLabel(BuildContext context) =>
      _isEn(context) ? 'Reason' : 'سبب الإبلاغ';
  static String reportDescriptionLabel(BuildContext context) =>
      _isEn(context) ? 'Details' : 'تفاصيل';
  static String reportDescriptionHint(BuildContext context) => _isEn(context)
      ? 'Describe what happened...'
      : 'اشرح اللي صار بالتفصيل...';
  static String reportDescriptionRequired(BuildContext context) =>
      _isEn(context)
      ? 'Please describe what happened.'
      : 'لازم تكتب تفاصيل البلاغ.';
  static String reportSubmitAction(BuildContext context) =>
      _isEn(context) ? 'Submit report' : 'إرسال البلاغ';
  static String reportSubmittedSuccess(BuildContext context) => _isEn(context)
      ? 'Your report has been submitted. Our team will review it.'
      : 'تم إرسال بلاغك، فريقنا رح يراجعه قريباً.';
  static String reportRequiresCompletedVisit(BuildContext context) => _isEn(context)
      ? 'You can only report a doctor after a completed visit with them.'
      : 'ما بتقدر تبلّغ عن طبيب إلا بعد ما يكون عندك موعد مكتمل معه.';

  static String rateDoctorAction(BuildContext context) =>
      _isEn(context) ? 'Rate doctor' : 'قيّم الطبيب';
  static String rateDoctorTitle(BuildContext context) =>
      _isEn(context) ? 'How was your visit?' : 'كيف كانت زيارتك؟';
  static String ratingRequired(BuildContext context) => _isEn(context)
      ? 'Please select a star rating.'
      : 'لازم تختار عدد النجوم أولاً.';
  static String reviewCommentHint(BuildContext context) =>
      _isEn(context) ? 'Write a comment (optional)' : 'اكتب تعليقك (اختياري)';
  static String reviewSubmittedSuccess(BuildContext context) => _isEn(context)
      ? 'Thanks! Your rating has been submitted.'
      : 'شكراً! تم إرسال تقييمك بنجاح.';
  static String reviewsCountLabel(BuildContext context) =>
      _isEn(context) ? 'reviews' : 'تقييم';

  static String unexpectedError(BuildContext context) => _isEn(context)
      ? 'Something went wrong. Please try again.'
      : 'صار في خطأ غير متوقع، حاول مرة تانية.';

  static String save(BuildContext context) =>
      _isEn(context) ? 'Save' : 'حفظ';

  // --- Wallet / Payments (Payments module - shared patient/doctor UI) ---
  static String myWallet(BuildContext context) =>
      _isEn(context) ? 'My Wallet' : 'محفظتي';
  static String walletTitle(BuildContext context) =>
      _isEn(context) ? 'Wallet' : 'المحفظة';
  static String currentBalance(BuildContext context) =>
      _isEn(context) ? 'Current balance' : 'الرصيد الحالي';
  static String loadingWallet(BuildContext context) =>
      _isEn(context) ? 'Loading wallet...' : 'جارِ تحميل المحفظة...';
  static String transactionsLabel(BuildContext context) =>
      _isEn(context) ? 'Transactions' : 'الحركات';
  static String noTransactionsYet(BuildContext context) =>
      _isEn(context) ? 'No transactions yet.' : 'لا يوجد أي حركات بعد.';
  static String requestTopUp(BuildContext context) =>
      _isEn(context) ? 'Request top-up' : 'طلب شحن رصيد';
  static String requestWithdrawal(BuildContext context) =>
      _isEn(context) ? 'Request withdrawal' : 'طلب سحب رصيد';
  static String amountLabel(BuildContext context) =>
      _isEn(context) ? 'Amount' : 'المبلغ';
  static String enterValidAmount(BuildContext context) => _isEn(context)
      ? 'Please enter a valid amount.'
      : 'أدخل مبلغاً صحيحاً من فضلك.';
  static String amountExceedsBalance(BuildContext context) => _isEn(context)
      ? 'This amount exceeds your available balance.'
      : 'هالمبلغ أكبر من رصيدك المتاح.';
  static String submitRequest(BuildContext context) =>
      _isEn(context) ? 'Submit request' : 'إرسال الطلب';
  static String submittingRequest(BuildContext context) =>
      _isEn(context) ? 'Submitting...' : 'جارِ الإرسال...';
  static String topUpRequestSubmitted(BuildContext context) => _isEn(context)
      ? 'Top-up request submitted. An administrator will review it shortly.'
      : 'تم إرسال طلب الشحن. رح يراجعه الأدمن قريباً.';
  static String withdrawalRequestSubmitted(BuildContext context) => _isEn(context)
      ? 'Withdrawal request submitted. An administrator will review it shortly.'
      : 'تم إرسال طلب السحب. رح يراجعه الأدمن قريباً.';
  static String topUpHistory(BuildContext context) =>
      _isEn(context) ? 'Top-up requests' : 'طلبات الشحن';
  static String withdrawalHistory(BuildContext context) =>
      _isEn(context) ? 'Withdrawal requests' : 'طلبات السحب';
  static String noRequestsYet(BuildContext context) =>
      _isEn(context) ? 'No requests yet.' : 'لا يوجد أي طلبات بعد.';
  static String statusPending(BuildContext context) =>
      _isEn(context) ? 'Pending' : 'قيد المراجعة';
  static String statusApproved(BuildContext context) =>
      _isEn(context) ? 'Approved' : 'تمت الموافقة';
  static String statusRejected(BuildContext context) =>
      _isEn(context) ? 'Rejected' : 'مرفوض';

  // --- Booking payment step (choose payment method before confirming) ---
  static String choosePaymentMethod(BuildContext context) => _isEn(context)
      ? 'Choose how to pay'
      : 'اختر طريقة الدفع';
  static String loadingPaymentOptions(BuildContext context) => _isEn(context)
      ? 'Loading payment options...'
      : 'جارِ تحميل خيارات الدفع...';
  static String payFullOnline(BuildContext context) =>
      _isEn(context) ? 'Pay in full online' : 'دفع كامل أونلاين';
  static String payFullOnlineDesc(BuildContext context) => _isEn(context)
      ? 'The full consultation fee is paid now from your wallet.'
      : 'يتم دفع كامل رسم الاستشارة الآن من محفظتك.';
  static String payCashDeposit(BuildContext context) =>
      _isEn(context) ? 'Cash at the clinic + online deposit' : 'كاش بالعيادة + عربون أونلاين';
  static String payCashDepositDesc(BuildContext context, int depositPercent) => _isEn(context)
      ? 'Pay a $depositPercent% deposit now, and the rest in cash at the clinic.'
      : 'ادفع عربون $depositPercent% الآن، والباقي كاش بالعيادة.';
  static String onlineOnlyNotice(BuildContext context) => _isEn(context)
      ? 'Cash payment is unavailable on your account right now - only full online payment is offered.'
      : 'الدفع كاش غير متاح على حسابك حالياً - متاح فقط الدفع الكامل أونلاين.';
  static String totalPriceLabel(BuildContext context) =>
      _isEn(context) ? 'Total price' : 'السعر الكامل';
  static String amountDueNowLabel(BuildContext context) =>
      _isEn(context) ? 'Due now' : 'المطلوب الآن';
  static String walletBalanceLabel(BuildContext context) =>
      _isEn(context) ? 'Wallet balance' : 'رصيد المحفظة';
  static String confirmAndPay(BuildContext context) =>
      _isEn(context) ? 'Confirm & pay' : 'تأكيد والدفع';
  static String insufficientWalletBalance(BuildContext context) => _isEn(context)
      ? 'Your wallet balance is not enough for this payment method.'
      : 'رصيد محفظتك غير كافٍ لهذه الطريقة.';
  static String topUpNow(BuildContext context) =>
      _isEn(context) ? 'Top up wallet' : 'شحن المحفظة';
}
