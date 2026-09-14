import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../data/patient_profile_repository.dart';
import '../models/patient_profile_dummy_data.dart';
import '../../auth/Login.dart';
import '../../auth/patient_auth/views/forget_password.dart';
import '../views/widgets/settings_drawer_widget.dart';
import 'widgets/confirm_action_dialog.dart';
import '../../payments/screens/patient_wallet_screen.dart';

/// Displays the signed-in patient's profile. Pass [profile] explicitly when
/// wiring this up to a real data source — it defaults to the dummy record
/// so the screen can be dropped in and pushed on its own.
class PatientProfileScreen extends StatefulWidget {
  final PatientProfileModel profile;

  const PatientProfileScreen({super.key, this.profile = dummyPatientProfile});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final PatientProfileRepository _repository = PatientProfileRepository();
  final ImagePicker _picker = ImagePicker();
  late PatientProfileModel _profile = widget.profile;
  bool _isUploadingPhoto = false;

  /// ✅ تعديل بيانات المريض الأساسية - PUT /patient/profile (راجع
  /// ملاحظة الافتراض بـ api_constants.dart). بعد النجاح منحدّث
  /// الحالة المحلية فوراً (الشاشة Stateful هلق) بدل ما تضل عارضة
  /// القيم القديمة لحد ما يسكّر التطبيق ويرجع يفتحه.
  Future<void> _showEditProfileSheet(BuildContext context) async {
    final firstNameCtrl = TextEditingController(text: _profile.firstName);
    final lastNameCtrl = TextEditingController(text: _profile.lastName);
    final phoneCtrl = TextEditingController(text: _profile.phoneNumber);
    final addressCtrl = TextEditingController(text: _profile.homeAddress);

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
                  decoration: InputDecoration(labelText: AppStrings.homeAddress(sheetContext), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(AppStrings.save(sheetContext)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      try {
        final updated = await _repository.updateProfile({
          'first_name': firstNameCtrl.text.trim(),
          'last_name': lastNameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'address': addressCtrl.text.trim(),
        });
        if (mounted) setState(() => _profile = updated);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.somethingWentWrong(context)), backgroundColor: const Color(0xFFC0392B)),
          );
        }
      }
    }
  }

  /// ✅ رفع/تغيير صورة البروفايل - POST /patient/profile/photo (نفس
  /// نمط الطبيب: image_picker من المعرض ثم رفع كـ bytes، متوافقة مع
  /// الويب كمان).
  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      final photoUrl = await _repository.updatePhoto(bytes, file.name);
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          _profile = PatientProfileModel(
            id: _profile.id,
            firstName: _profile.firstName,
            lastName: _profile.lastName,
            avatarUrl: photoUrl,
            dateOfBirth: _profile.dateOfBirth,
            gender: _profile.gender,
            email: _profile.email,
            isEmailVerified: _profile.isEmailVerified,
            phoneNumber: _profile.phoneNumber,
            homeAddress: _profile.homeAddress,
          );
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFC0392B)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.somethingWentWrong(context)), backgroundColor: const Color(0xFFC0392B)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
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
            AppStrings.profile(context),
            style: TextStyle(fontSize: nameSize * 0.8, fontWeight: FontWeight.w800, color: primaryGreenColor),
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
                    backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                    child: profile.avatarUrl == null
                        ? Text(
                      profile.initials,
                      style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold, color: primaryGreenColor),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: isEn ? 0 : null,
                    left: isEn ? null : 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: primaryGreenColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: scaffoldBg, width: 2.w),
                        ),
                        child: _isUploadingPhoto
                            ? Padding(
                                padding: EdgeInsets.all(6.r),
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w800, color: primaryGreenColor),
            ),
            SizedBox(height: 10.h),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showEditProfileSheet(context),
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

            _SectionLabel(AppStrings.personalInformation(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: AppStrings.dateOfBirth(context),
                value: profile.dateOfBirth,
                iconBg: primaryGreenColor,
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
              ),
              _rowDivider(),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: AppStrings.gender(context),
                value: profile.gender == 'Male' ? AppStrings.male(context) : AppStrings.female(context),
                iconBg: primaryGreenColor,
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
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
                trailing: profile.isEmailVerified
                    ? Icon(Icons.verified_rounded, color: AppColors.textLightGrey, size: 18.sp)
                    : null,
              ),
              _rowDivider(),
              _InfoRow(
                icon: Icons.call_outlined,
                label: AppStrings.phoneNumber(context),
                value: profile.phoneNumber,
                iconBg: primaryGreenColor,
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
              ),
            ]),
            SizedBox(height: 24.h),

            _SectionLabel(AppStrings.address(context), sectionLabelSize),
            SizedBox(height: 10.h),
            _InfoCard(cardBg: cardBg, children: [
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: AppStrings.homeAddress(context),
                value: profile.homeAddress,
                iconBg: primaryGreenColor,
                textColor: textColor,
                labelSize: rowLabelSize,
                valueSize: rowValueSize,
              ),
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
                  MaterialPageRoute(builder: (_) => const PatientWalletScreen()),
                ),
              ),
              _rowDivider(),
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                label: AppStrings.changePassword(context),
                textColor: textColor,
                labelSize: rowValueSize,
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textLightGrey),
                // ✅ نفس تدفق "نسيت كلمة المرور" بالضبط (متل جهة الطبيب).
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
                  // بعد ما يأكد وتنمسح جلسته فعلياً (توكن + نداء /auth/logout)،
                  // منوديه لشاشة تسجيل الدخول ومنمسح كامل تاريخ التنقل خلفها
                  // حتى ما يقدر يرجع بزر الـ back لصفحات كانت تحتاج تسجيل دخول.
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
                Text(label, style: TextStyle(fontSize: labelSize, color: AppColors.textLightGrey)),
                SizedBox(height: 3.h),
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
