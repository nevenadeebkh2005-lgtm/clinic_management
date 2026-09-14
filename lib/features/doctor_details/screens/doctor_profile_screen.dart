import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/theme/app_colors.dart';
import '../../patient_details/screens/widgets/confirm_action_dialog.dart';
import '../../patient_details/views/widgets/settings_drawer_widget.dart';
import '../../auth/Login.dart';
import '../../auth/patient_auth/views/forget_password.dart';
import '../models/doctor_profile_models.dart';
import '../data/doctor_repository.dart';
import '../../../core/network/api_exception.dart';
import '../view_models/doctor_home_cubit.dart';
import 'join_clinic_screen.dart';
import '../../payments/screens/doctor_wallet_screen.dart';

/// بروفايل الطبيب الكامل + الإعدادات - نفس بنية PatientProfileScreen
/// حرفياً (نفس الأقسام/الأحجام/الألوان) بس بحقول طبيب حقيقية (مسيرة
/// مهنية، أقسام، عيادات) بدل حقول مريض.
class DoctorProfileScreen extends StatelessWidget {
  final DoctorProfileInfo profile;

  const DoctorProfileScreen({super.key, required this.profile});

  /// يفتح شاشة "الانضمام لعيادة" الحقيقية (POST /doctor/profile
  /// /departments/join)، وإذا انضم فعلاً بنجاح، بيعمل reload لبروفايل
  /// الطبيب (عبر DoctorHomeCubit الموفّر أصلاً فوق بالشجرة من
  /// DoctorMainLayoutScreen) وبيرجع المستخدم للرئيسية ليشوف النتيجة
  /// المحدّثة فوراً.
  Future<void> _openJoinClinic(BuildContext context) async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JoinClinicScreen(alreadyJoinedClinicIds: profile.clinics.map((c) => c.id).toList()),
      ),
    );
    if (joined == true && context.mounted) {
      context.read<DoctorHomeCubit>().load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DoctorStrings.joinedClinicSuccess(context))),
      );
      Navigator.pop(context);
    }
  }

  /// ✅ تعديل رسم الكشف الخاص بعيادة معينة - PUT /doctor/profile
  /// /clinics/{id}/fee (حقيقي).
  Future<void> _showEditFeeSheet(BuildContext context, DoctorClinicRef clinic) async {
    final controller = TextEditingController(text: clinic.consultationFee?.toStringAsFixed(0) ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: 20.h + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 12.h),
              Text(DoctorStrings.consultationFeeLabel(sheetContext), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(height: 6.h),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(DoctorStrings.save(sheetContext)),
                ),
              ),
            ],
          ),
        );
      },
    );

    final fee = double.tryParse(controller.text.trim());
    if (saved == true && fee != null && context.mounted) {
      try {
        await DoctorRepository().updateClinicFee(clinicId: clinic.id, fee: fee);
        if (context.mounted) context.read<DoctorHomeCubit>().load();
      } on ApiException catch (e) {
        // ✅ إصلاح: كانت هون عم تعرض `'$e'` مباشرة (نص الاستثناء الخام
        // بلغة الكود، متل "ApiException: ...")، وهو اللي كان يبان
        // للمستخدم وكأنه "اكسبشن" غريب حتى لو الباك قبل الطلب فعلياً.
        // هلق منعرض e.message المقروء فقط.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.somethingWentWrong(context)), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      }
    }
  }

  /// ✅ إصلاح: زر "تعديل الملف الشخصي" كان `onPressed: () {}` فاضي
  /// تماماً - ما بيعمل أي شي إطلاقاً رغم إنو DoctorRepository.updateProfile()
  /// و PUT /doctor/profile جاهزين وشغالين فعلياً بالباك (راجع Postman:
  /// Doctor / update doctor profile). هلق عم نفتح شيت تعديل حقيقي
  /// للحقول الأساسية (first_name/last_name/phone/address/biography)
  /// وننادي الـ API فعلياً، وبعد النجاح نعمل reload لـ DoctorHomeCubit
  /// حتى ينعكس التعديل فوراً بكل الشاشة (بفضل التصحيح فوق).
  /// ✅ رفع/تغيير صورة الطبيب - POST /doctor/profile/photo (كانت
  /// DoctorRepository.updatePhoto() جاهزة وشغالة بالباك، بس ما في أي
  /// عنصر بالواجهة كان ينادي عليها - أيقونة الكاميرا كانت شكل بس بدون
  /// GestureDetector).
  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !context.mounted) return;
    try {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      await DoctorRepository().updatePhoto(bytes, file.name);
      if (context.mounted) context.read<DoctorHomeCubit>().load();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFC0392B)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.somethingWentWrong(context)), backgroundColor: const Color(0xFFC0392B)),
        );
      }
    }
  }

  Future<void> _showEditProfileSheet(BuildContext context, DoctorProfileInfo profile) async {
    final firstNameCtrl = TextEditingController(text: profile.firstName);
    final lastNameCtrl = TextEditingController(text: profile.lastName);
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    final addressCtrl = TextEditingController(text: profile.address ?? '');
    final bioCtrl = TextEditingController(text: profile.biography ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: 20.h + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.editProfile(sheetContext), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 14.h),
                TextField(
                  controller: firstNameCtrl,
                  decoration: InputDecoration(labelText: AppStrings.firstName(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: lastNameCtrl,
                  decoration: InputDecoration(labelText: AppStrings.lastName(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: AppStrings.phoneNumber(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(labelText: AppStrings.address(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: DoctorStrings.biography(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(DoctorStrings.save(sheetContext)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && context.mounted) {
      try {
        await DoctorRepository().updateProfile({
          'first_name': firstNameCtrl.text.trim(),
          'last_name': lastNameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'address': addressCtrl.text.trim(),
          'biography': bioCtrl.text.trim(),
        });
        if (context.mounted) context.read<DoctorHomeCubit>().load();
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.somethingWentWrong(context)), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إصلاح: هاي الشاشة كانت بتاخد profile مرّة وحدة بالـ constructor
    // (لحظة الدخول من doctor_home_screen)، وما كانت بتعيد بناء نفسها
    // أبداً بعدها. نتيجة هيك: تعديل رسم الكشف (أو أي تعديل تاني عالبروفايل)
    // كان بينجح فعلياً بالباك (PUT بيرجع 200) بس الواجهة تضل عارضة القيمة
    // القديمة، وأي محاولة استخدام لاحقة لـ clinic.id/consultationFee
    // القديمين (متل فتح شيت تعديل الرسم مرة تانية على بيانات غير محدّثة)
    // كانت تسبب استثناء أو سلوك غير متوقع. الحل: نسحب الـ profile الحيّة
    // من DoctorHomeCubit (نفس الكيوبت يلي `_showEditFeeSheet` بينادي
    // .load() عليه بعد الحفظ) عبر context.watch، فأي تحديث فيه بيعيد
    // بناء الشاشة تلقائياً بالقيم الجديدة. الاسم المحلي profile هون
    // بيغطي (shadow) الحقل widget.profile لبقية الدالة، فكل الأسطر
    // تحت يلي بتستخدم profile.* بتصير عم تقرأ من الحالة الحيّة تلقائياً
    // بدون ما نعدّل مئات الأسطر.
    final profile = context.watch<DoctorHomeCubit>().state.profile.doctorId != null
        ? context.watch<DoctorHomeCubit>().state.profile
        : this.profile;
    final settingsState = context.watch<SettingsCubit>().state;
    final settingsCubit = context.read<SettingsCubit>();
    final isEn = settingsState.locale.languageCode == 'en';
    final currentScale = settingsState.fontScale;
    final isDark = settingsState.themeMode == ThemeMode.dark;

    double nameSize = 22.sp;
    double sectionLabelSize = 12.sp;
    double rowLabelSize = 12.sp;
    double rowValueSize = 15.sp;
    if (currentScale == FontScale.medium) {
      nameSize = 25.sp; sectionLabelSize = 14.sp; rowLabelSize = 14.sp; rowValueSize = 17.sp;
    } else if (currentScale == FontScale.large) {
      nameSize = 28.sp; sectionLabelSize = 16.sp; rowLabelSize = 16.sp; rowValueSize = 19.sp;
    }

    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreenColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    const dangerColor = Color(0xFFC0392B);

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 4.w,
          leading: IconButton(
            icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: primaryGreenColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            DoctorStrings.doctorProfile(context),
            style: TextStyle(fontSize: nameSize * 0.7, fontWeight: FontWeight.w800, color: primaryGreenColor),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: textColor),
              onPressed: () => showSettingsDrawer(context),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56.r,
                    backgroundColor: primaryGreenColor.withOpacity(0.15),
                    backgroundImage:
                        (profile.photoUrl?.isNotEmpty ?? false) ? NetworkImage(profile.photoUrl!) : null,
                    child: (profile.photoUrl?.isNotEmpty ?? false)
                        ? null
                        : Text(profile.initials,
                            style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold, color: primaryGreenColor)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: isEn ? 0 : null,
                    left: isEn ? null : 0,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadPhoto(context),
                      child: Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: primaryGreenColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: scaffoldBg, width: 2.w),
                        ),
                        child: Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Dr. ${profile.fullName}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w800, color: primaryGreenColor),
            ),
            if (profile.mainSpecialty.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                profile.mainSpecialty,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textLightGrey, fontWeight: FontWeight.w600),
              ),
            ],
            SizedBox(height: 10.h),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showEditProfileSheet(context, profile),
                icon: Icon(Icons.edit_outlined, size: 16.sp, color: primaryGreenColor),
                label: Text(AppStrings.editProfile(context), style: TextStyle(color: primaryGreenColor, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryGreenColor.withOpacity(0.4), width: 1.w),
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                ),
              ),
            ),
            SizedBox(height: 28.h),

            _SectionLabel(DoctorStrings.careerInfo(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              _InfoRow(
                icon: Icons.verified_user_outlined,
                label: DoctorStrings.verificationStatus(context),
                value: profile.verificationStatus == 'verified'
                    ? DoctorStrings.verified(context)
                    : DoctorStrings.underReview(context),
                iconBg: profile.verificationStatus == 'verified' ? primaryGreenColor : const Color(0xFFD97706),
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
              ),
              if (profile.practiceStartDate != null) ...[
                _rowDivider(),
                _InfoRow(
                  icon: Icons.work_history_outlined,
                  label: DoctorStrings.practiceStartDate(context),
                  value: profile.practiceStartDate!.split('T').first,
                  iconBg: primaryGreenColor,
                  textColor: textColor,
                  labelSize: rowLabelSize,
                  valueSize: rowValueSize,
                ),
              ],
              if (profile.experienceYears != null) ...[
                _rowDivider(),
                _InfoRow(
                  icon: Icons.timeline_rounded,
                  label: DoctorStrings.yearsOfExperience(context),
                  value: '${profile.experienceYears}',
                  iconBg: primaryGreenColor,
                  textColor: textColor,
                  labelSize: rowLabelSize,
                  valueSize: rowValueSize,
                ),
              ],
              if (profile.consultationFee != null) ...[
                _rowDivider(),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: DoctorStrings.consultationFeeLabel(context),
                  value: profile.consultationFee!.toStringAsFixed(0),
                  iconBg: primaryGreenColor,
                  textColor: textColor,
                  labelSize: rowLabelSize,
                  valueSize: rowValueSize,
                ),
              ],
            ]),
            SizedBox(height: 24.h),

            if (profile.departments.isNotEmpty) ...[
              _SectionLabel(DoctorStrings.departmentsSpecialties(context), sectionLabelSize),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: profile.departments
                    .map((d) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: primaryGreenColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(d.name,
                              style: TextStyle(color: primaryGreenColor, fontWeight: FontWeight.w700, fontSize: 12.5.sp)),
                        ))
                    .toList(),
              ),
              SizedBox(height: 24.h),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(DoctorStrings.clinicsWorkplaces(context), sectionLabelSize),
                GestureDetector(
                  onTap: () => _openJoinClinic(context),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 16.sp, color: primaryGreenColor),
                      SizedBox(width: 4.w),
                      Text(DoctorStrings.joinClinic(context),
                          style: TextStyle(fontSize: 11.5.sp, color: primaryGreenColor, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (profile.clinics.isEmpty)
              _InfoCard(cardBg: cardBg, children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DoctorStrings.noClinicsYet(context),
                          style: TextStyle(fontSize: rowValueSize, color: AppColors.textLightGrey)),
                      SizedBox(height: 10.h),
                      OutlinedButton.icon(
                        onPressed: () => _openJoinClinic(context),
                        icon: Icon(Icons.add_rounded, size: 16.sp, color: primaryGreenColor),
                        label: Text(DoctorStrings.joinClinic(context), style: TextStyle(color: primaryGreenColor)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: primaryGreenColor.withOpacity(0.4))),
                      ),
                    ],
                  ),
                ),
              ])
            else
              _InfoCard(
                cardBg: cardBg,
                children: [
                  for (var i = 0; i < profile.clinics.length; i++) ...[
                    if (i > 0) _rowDivider(),
                    InkWell(
                      onTap: () => _showEditFeeSheet(context, profile.clinics[i]),
                      child: _InfoRow(
                        icon: Icons.local_hospital_outlined,
                        label: profile.clinics[i].address ?? '',
                        value: profile.clinics[i].name,
                        iconBg: primaryGreenColor,
                        textColor: textColor,
                        labelSize: rowLabelSize,
                        valueSize: rowValueSize,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.clinics[i].consultationFee != null
                                  ? profile.clinics[i].consultationFee!.toStringAsFixed(0)
                                  : '—',
                              style: TextStyle(fontSize: rowValueSize, fontWeight: FontWeight.w700, color: primaryGreenColor),
                            ),
                            Icon(Icons.edit_outlined, size: 13.sp, color: AppColors.textLightGrey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            SizedBox(height: 24.h),

            _SectionLabel(DoctorStrings.biography(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  (profile.biography?.isNotEmpty ?? false) ? profile.biography! : DoctorStrings.noBiographyYet(context),
                  style: TextStyle(
                    fontSize: rowValueSize,
                    color: (profile.biography?.isNotEmpty ?? false) ? textColor : AppColors.textLightGrey,
                    height: 1.5,
                  ),
                ),
              ),
            ]),
            SizedBox(height: 24.h),

            _SectionLabel(AppStrings.contactDetails(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: AppStrings.email(context),
                value: profile.email,
                iconBg: primaryGreenColor,
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
              ),
              if (profile.phone != null) ...[
                _rowDivider(),
                _InfoRow(
                  icon: Icons.call_outlined,
                  label: AppStrings.phoneNumber(context),
                  value: profile.phone!,
                  iconBg: primaryGreenColor,
                  textColor: textColor,
                  labelSize: rowLabelSize,
                  valueSize: rowValueSize,
                ),
              ],
              if (profile.address != null) ...[
                _rowDivider(),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: AppStrings.address(context),
                  value: profile.address!,
                  iconBg: primaryGreenColor,
                  textColor: textColor,
                  labelSize: rowLabelSize,
                  valueSize: rowValueSize,
                ),
              ],
            ]),
            SizedBox(height: 24.h),

            _SectionLabel(AppStrings.appSettings(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              _ActionRow(
                icon: Icons.account_balance_wallet_outlined,
                label: AppStrings.myWallet(context),
                textColor: textColor,
                labelSize: rowValueSize,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textLightGrey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorWalletScreen()),
                ),
              ),
              _rowDivider(),
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                label: AppStrings.changePassword(context),
                textColor: textColor,
                labelSize: rowValueSize,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textLightGrey),
                // ✅ إصلاح: كان onPressed فاضي تماماً. "تغيير كلمة المرور"
                // هون بالضبط نفس تدفق "نسيت كلمة المرور" (إيميل → كود
                // بالإيميل → كلمة مرور جديدة)، فبنعيد استخدام نفس الشاشة
                // والـ Cubit الموجودين أصلاً (ForgotPasswordScreen) بدل
                // ما نبني شاشة/منطق مختلف من الصفر.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
              ),
              _rowDivider(),
              _ActionRow(
                onTap: () {},
                icon: Icons.notifications_none_rounded,
                label: AppStrings.notificationSettings(context),
                textColor: textColor,
                labelSize: rowValueSize,
                trailing: Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: settingsState.notificationsEnabled,
                    activeColor: isDark ? AppColors.darkBackground : AppColors.white,
                    activeTrackColor: primaryGreenColor,
                    onChanged: settingsCubit.toggleNotifications,
                  ),
                ),
              ),
              _rowDivider(),
              _ActionRow(
                icon: Icons.logout_rounded,
                label: AppStrings.logOut(context),
                textColor: dangerColor,
                iconColor: dangerColor,
                labelSize: rowValueSize,
                onTap: () async {
                  final loggedOut = await showConfirmActionDialog(
                    context,
                    title: AppStrings.logOutConfirmTitle(context),
                    description: AppStrings.logOutConfirmDesc(context),
                    confirmLabel: AppStrings.logOut(context),
                    cancelLabel: AppStrings.cancel(context),
                    onConfirm: (cubit) => cubit.logOut(),
                  );
                  if (loggedOut == true && context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              _rowDivider(),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: AppStrings.deleteAccount(context),
                textColor: dangerColor,
                iconColor: dangerColor,
                labelSize: rowValueSize,
                showIconBg: false,
                onTap: () => showConfirmActionDialog(
                  context,
                  title: AppStrings.deleteAccountTitle(context),
                  description: AppStrings.deleteAccountDesc(context),
                  confirmLabel: AppStrings.delete(context),
                  cancelLabel: AppStrings.cancel(context),
                  onConfirm: (cubit) => cubit.deleteAccount(),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  static Widget _rowDivider() => Divider(color: AppColors.borderGrey.withOpacity(0.4), height: 1);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double size;
  const _SectionLabel(this.text, this.size);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: AppColors.textLightGrey, letterSpacing: 0.6),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color cardBg;
  final List<Widget> children;
  const _InfoCard({required this.cardBg, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16.r)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color textColor;
  final double labelSize;
  final double valueSize;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.textColor,
    required this.labelSize,
    required this.valueSize,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(color: iconBg.withOpacity(0.12), borderRadius: BorderRadius.circular(10.r)),
            alignment: Alignment.center,
            child: Icon(icon, size: 17.sp, color: iconBg),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) Text(label, style: TextStyle(fontSize: labelSize, color: AppColors.textLightGrey)),
                if (label.isNotEmpty) SizedBox(height: 3.h),
                Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w700, color: textColor)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color? iconColor;
  final double labelSize;
  final Widget? trailing;
  final bool showIconBg;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.textColor,
    this.iconColor,
    required this.labelSize,
    this.trailing,
    this.showIconBg = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: iconColor ?? textColor),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w600, color: textColor)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
