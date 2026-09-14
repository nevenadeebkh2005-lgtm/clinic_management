import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/features/auth/patient_auth/views/widgets/login_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import 'patient_auth/view_models/login_cubit.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final isEn = context.read<SettingsCubit>().state.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: BlocProvider(
        create: (context) => LoginCubit(),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 7.h),
                      _buildSettingsBar(context, themeColor),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 90.w,
                        height: 120.h,
                        errorBuilder: (c, e, s) => Icon(Icons.local_hospital, size: 70.sp, color: themeColor),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        AppStrings.welcomeMessage(context),
                        style: TextStyle(fontSize: 17.sp, color: AppColors.textLightGrey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5.h),

                      LoginCardWidgets(themeColor: themeColor, isEn: isEn),

                      SizedBox(height: 10.h),
                      _buildFooterText(context, themeColor),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsBar(BuildContext context, Color themeColor) {
    final settingsCubit = context.read<SettingsCubit>();
    final currentScale = settingsCubit.state.fontScale;

    IconData fontIcon = currentScale == FontScale.normal
        ? Icons.text_fields
        : currentScale == FontScale.medium ? Icons.text_increase : Icons.format_size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(fontIcon, color: themeColor),
          tooltip: 'حجم الخط / Font Size',
          onPressed: () => settingsCubit.cycleFontScale(),
        ),
        IconButton(
          icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode, color: themeColor),
          onPressed: () => settingsCubit.toggleTheme(),
        ),
        TextButton.icon(
          icon: Icon(Icons.language, color: themeColor),
          label: Text(settingsCubit.state.locale.languageCode == 'en' ? 'العربية' : 'English', style: TextStyle(fontSize: 14.sp, color: themeColor)),
          onPressed: () => settingsCubit.toggleLanguage(),
        ),
      ],
    );
  }

  Widget _buildFooterText(BuildContext context, Color activeColor) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 10.sp, color: AppColors.textLightGrey, fontFamily: 'Roboto'),
        children: [
          TextSpan(text: AppStrings.loginFooterPre(context)),
          TextSpan(text: AppStrings.termsOfService(context), style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
          TextSpan(text: AppStrings.loginFooterAnd(context)),
          TextSpan(text: AppStrings.privacyPolicy(context), style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
