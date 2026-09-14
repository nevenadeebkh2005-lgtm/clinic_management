import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../view_models/settings_drawer_cubit.dart';
import '../../view_models/settings_drawer_state.dart';
import '../../../auth/patient_auth/views/forget_password.dart';

void showSettingsDrawer(BuildContext context) {
  final isEn = context.read<SettingsCubit>().state.locale.languageCode == 'en';
  final settingsCubit = context.read<SettingsCubit>();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Settings',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsCubit),
          BlocProvider(create: (_) => SettingsDrawerUiCubit()),
        ],
        child: const SettingsDrawerContent(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: Offset(isEn ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(
        position: slideTween,
        child: child,
      );
    },
  );
}

/// Fully stateless & Cubit-driven: app settings (locale/theme/font scale)
/// come from [SettingsCubit], transient UI state (which section is
/// expanded, the notifications switch) comes from [SettingsDrawerUiCubit].
/// A single [BlocBuilder] rebuilds the whole panel on any change from
/// either source — there's no local setState left to fall out of sync
/// with the Cubit stream.
class SettingsDrawerContent extends StatelessWidget {
  const SettingsDrawerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final settingsCubit = context.read<SettingsCubit>();
    final currentScale = settingsState.fontScale;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;

    return BlocBuilder<SettingsDrawerUiCubit, SettingsDrawerUiState>(
      builder: (context, uiState) {
        final uiCubit = context.read<SettingsDrawerUiCubit>();

        // ضبط الخطوط حسب نمط الحجم المختار
        double titleSize = 18.sp;
        double itemTextSize = 13.sp;
        double versionTextSize = 11.sp;

        if (currentScale == FontScale.medium) {
          titleSize = 21.sp; itemTextSize = 15.sp; versionTextSize = 13.sp;
        } else if (currentScale == FontScale.large) {
          titleSize = 24.sp; itemTextSize = 17.sp; versionTextSize = 15.sp;
        }

        // تحديد الألوان التفاعلية للـ Drawer
        final drawerBgColor = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
        final containerBgColor = isDark ? AppColors.darkCard : AppColors.white;
        final textColor = isDark ? AppColors.darkText : AppColors.textDark;
        final primaryGreenColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
        final borderColor = isDark ? Colors.white10 : AppColors.borderGrey;
        final footerBgColor = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02);

        return Directionality(
          textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
          child: Material(
            type: MaterialType.transparency,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Align(
                alignment: isEn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: drawerBgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: isEn ? Radius.circular(16.r) : Radius.zero,
                      bottomLeft: isEn ? Radius.circular(16.r) : Radius.zero,
                      topRight: isEn ? Radius.zero : Radius.circular(16.r),
                      bottomRight: isEn ? Radius.zero : Radius.circular(16.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // --- الهيدر العلوي ---
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.settings(context),
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w700,
                                    color: primaryGreenColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Icon(Icons.close_rounded, color: textColor, size: 22.sp),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // --- قائمة العناصر ---
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // 1. الإشعارات
                              _buildContainerWrapper(
                                bgColor: containerBgColor,
                                borderColor: borderColor,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Row(
                                    children: [
                                      Icon(Icons.notifications_none_rounded, color: textColor, size: 20.sp),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          AppStrings.notificationSettings(context),
                                          style: TextStyle(fontSize: itemTextSize, fontWeight: FontWeight.w500, color: textColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 45.w,
                                        child: Transform.scale(
                                          scale: 0.8,
                                          child: Switch.adaptive(
                                            value: settingsState.notificationsEnabled,
                                            activeColor: isDark ? AppColors.darkBackground : AppColors.white,
                                            activeTrackColor: primaryGreenColor,
                                            onChanged: settingsCubit.toggleNotifications,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // 2. خيار المظهر (Theme)
                              _buildContainerWrapper(
                                bgColor: containerBgColor,
                                borderColor: borderColor,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: uiCubit.toggleThemeExpanded,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                        child: Row(
                                          children: [
                                            Icon(Icons.dark_mode_outlined, color: textColor, size: 20.sp),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                AppStrings.theme(context),
                                                style: TextStyle(fontSize: itemTextSize, fontWeight: FontWeight.w500, color: textColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              uiState.isThemeExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              color: AppColors.textLightGrey,
                                              size: 20.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (uiState.isThemeExpanded) ...[
                                      Divider(color: borderColor, height: 1),
                                      _buildSubMenuTile(AppStrings.lightMode(context), settingsState.themeMode == ThemeMode.light, itemTextSize, textColor, primaryGreenColor, () {
                                        if (settingsState.themeMode != ThemeMode.light) settingsCubit.toggleTheme();
                                      }),
                                      _buildSubMenuTile(AppStrings.darkMode(context), settingsState.themeMode == ThemeMode.dark, itemTextSize, textColor, primaryGreenColor, () {
                                        if (settingsState.themeMode != ThemeMode.dark) settingsCubit.toggleTheme();
                                      }),
                                    ]
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // 3. خيار اللغة (Language)
                              _buildContainerWrapper(
                                bgColor: containerBgColor,
                                borderColor: borderColor,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: uiCubit.toggleLangExpanded,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                        child: Row(
                                          children: [
                                            Icon(Icons.language_rounded, color: textColor, size: 20.sp),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                AppStrings.language(context),
                                                style: TextStyle(fontSize: itemTextSize, fontWeight: FontWeight.w500, color: textColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              uiState.isLangExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              color: AppColors.textLightGrey,
                                              size: 20.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (uiState.isLangExpanded) ...[
                                      Divider(color: borderColor, height: 1),
                                      // أسماء اللغات تُعرض دائماً بلغتها الأصلية (English / العربية)
                                      // بغض النظر عن لغة التطبيق الحالية — هذا سلوك متعمد وليس خطأ ترجمة.
                                      _buildSubMenuTile('English', isEn, itemTextSize, textColor, primaryGreenColor, () {
                                        if (!isEn) settingsCubit.toggleLanguage();
                                      }),
                                      _buildSubMenuTile('العربية', !isEn, itemTextSize, textColor, primaryGreenColor, () {
                                        if (isEn) settingsCubit.toggleLanguage();
                                      }),
                                    ]
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // 4. خيار حجم الخط (Font Scale)
                              GestureDetector(
                                onTap: settingsCubit.cycleFontScale,
                                child: _buildContainerWrapper(
                                  bgColor: containerBgColor,
                                  borderColor: borderColor,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    child: Row(
                                      children: [
                                        Icon(Icons.text_fields_rounded, color: textColor, size: 20.sp),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            '${AppStrings.fontScaleLabel(context)} (${_fontScaleLabel(context, currentScale)})',
                                            style: TextStyle(fontSize: itemTextSize, fontWeight: FontWeight.w500, color: textColor),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.style_rounded, color: AppColors.textLightGrey, size: 18.sp),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // ✅ إضافة: إعادة تعيين كلمة المرور - نفس شاشة
                              // "نسيت كلمة المرور" الحقيقية المستخدمة بتسجيل
                              // الدخول (ForgotPasswordScreen: بريد + كود
                              // تحقق + كلمة مرور جديدة عبر /auth/forgot-password
                              // و/auth/reset-password)، بس هلق قابلة
                              // للوصول من داخل الإعدادات لمستخدم مسجّل
                              // دخوله. مشتركة بين شاشة المريض والطبيب لأن
                              // showSettingsDrawer نفسه مستخدم بالاثنين.
                              _buildSimpleClickableRow(
                                Icons.lock_reset_rounded,
                                AppStrings.resetPassword(context),
                                itemTextSize,
                                containerBgColor,
                                borderColor,
                                textColor,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                              ),
                              SizedBox(height: 12.h),

                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Divider(color: borderColor),
                              ),

                              // 5. من نحن
                              _buildSimpleClickableRow(Icons.info_outline_rounded, AppStrings.aboutUs(context), itemTextSize, containerBgColor, borderColor, textColor),
                              SizedBox(height: 12.h),

                              // 6. مركز المساعدة
                              _buildSimpleClickableRow(Icons.help_outline_rounded, AppStrings.helpCenter(context), itemTextSize, containerBgColor, borderColor, textColor),
                            ],
                          ),
                        ),

                        // --- الفوتر السفلي لشعار والإصدار ---
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          color: footerBgColor,
                          child: Column(
                            children: [
                              Text(
                                AppStrings.appName,
                                style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700, color: primaryGreenColor),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                AppStrings.appVersionLabel(context),
                                style: TextStyle(fontSize: versionTextSize, fontWeight: FontWeight.w500, color: AppColors.textLightGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fontScaleLabel(BuildContext context, FontScale scale) {
    switch (scale) {
      case FontScale.normal:
        return AppStrings.fontScaleNormal(context);
      case FontScale.medium:
        return AppStrings.fontScaleMedium(context);
      case FontScale.large:
        return AppStrings.fontScaleLarge(context);
    }
  }

  static Widget _buildContainerWrapper({required Widget child, required Color bgColor, required Color borderColor}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.w),
        ),
        child: child
    );
  }

  static Widget _buildSimpleClickableRow(IconData icon, String title, double textSize, Color bgColor, Color borderColor, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: _buildContainerWrapper(
        bgColor: bgColor,
        borderColor: borderColor,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w500, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLightGrey, size: 14.sp),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSubMenuTile(String text, bool isSelected, double fontSize, Color textColor, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) Icon(Icons.check, color: activeColor, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
