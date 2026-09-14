import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/theme/app_colors.dart';
import 'package:untitled3/core/constants/app_strings.dart';

import '../../../../patient_details/screens/main_layout_screen.dart';
import '../../../../doctor_details/screens/doctor_main_layout_screen.dart';
import '../../../doctor_auth/view_models/register_cubit.dart';
import '../../../doctor_auth/views/doctor_register_screen.dart';
import '../../view_models/login_cubit.dart';
import '../../view_models/login_state.dart';
import '../forget_password.dart';
import '../register_basic_info_screen.dart';

class LoginCardWidgets extends StatefulWidget {
  final Color themeColor;
  final bool isEn;

  const LoginCardWidgets({
    super.key,
    required this.themeColor,
    required this.isEn,
  });

  @override
  State<LoginCardWidgets> createState() => _LoginCardWidgetsState();
}

class _LoginCardWidgetsState extends State<LoginCardWidgets> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    context.read<LoginCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeColor = widget.themeColor;
    final isEn = widget.isEn;

    return BlocListener<LoginCubit, LoginState>(
    listener: (context, state) {
      // 1. حساب معلّق (Pending)
      if (state.status == LoginStatus.pending && state.pendingMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.pendingMessage!),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }

      if (state.status == LoginStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }

      // بعد نجاح الدخول: نوجّه حسب دور الحساب (data.user.role) القادم
      // فعلياً من رد /auth/login - طبيب بيروح لواجهاته (DoctorMainLayoutScreen)،
      // أي دور تاني (مريض ...) بيروح للواجهة الحالية تبع المريض.
      if (state.status == LoginStatus.success) {
        final userData = state.userData;
        final isDoctor = state.userRole == 'doctor';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isDoctor && userData != null
                ? DoctorMainLayoutScreen(currentUserJson: userData)
                : MainLayoutScreen(currentUserJson: userData),
          ),
        );
      }
    },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            color: theme.cardColor,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTabButton(
                        title: AppStrings.login(context),
                        isActive: state.activeTab == LoginTab.login,
                        activeColor: themeColor,
                        textColor: isDarkMode ? Colors.white : AppColors.textLightGrey,
                        onTap: () => context.read<LoginCubit>().switchTab(LoginTab.login),
                      ),
                      _buildTabButton(
                        title: AppStrings.createAccount(context),
                        isActive: state.activeTab == LoginTab.register,
                        activeColor: themeColor,
                        textColor: isDarkMode ? Colors.white : AppColors.textLightGrey,
                        onTap: () => context.read<LoginCubit>().switchTab(LoginTab.register),
                      ),
                    ],
                  ),
                  Divider(height: 1.h, thickness: 1, color: theme.dividerColor),
                  SizedBox(height: 20.h),

                  if (state.activeTab == LoginTab.login) ...[
                    Text(
                      AppStrings.emailAddress(context),
                      style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: AppStrings.emailHint(context),
                        prefixIcon: Icon(Icons.email_outlined, color: theme.iconTheme.color),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.password(context),
                          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            AppStrings.forgotPassword(context),
                            style: TextStyle(fontSize: 13.sp, color: themeColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: state.obscurePassword,
                      style: TextStyle(fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: AppStrings.passwordHint(context),
                        prefixIcon: Icon(Icons.lock_outline, color: theme.iconTheme.color),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: theme.iconTheme.color,
                          ),
                          onPressed: () => context.read<LoginCubit>().togglePasswordVisibility(),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        onPressed: (state.isLoading || state.status == LoginStatus.loading)
                            ? null
                            : () => _handleLogin(context),
                        child: (state.isLoading || state.status == LoginStatus.loading)
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppStrings.signIn(context), style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8.w),
                            Icon(isEn ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(
                          AppStrings.signUpAs(context),
                          style: TextStyle(fontSize: 16.sp, color: isDarkMode ? Colors.grey[400] : AppColors.textLightGrey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    _buildRegisterOptionButton(
                      label: AppStrings.doctor(context),
                      activeColor: themeColor.withOpacity(0.75),
                      isEn: isEn,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => DoctorRegisterCubit(),
                              child: const DoctorRegisterMainScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20.h),
                    _buildRegisterOptionButton(
                      label: AppStrings.patient(context),
                      activeColor: themeColor,
                      isEn: isEn,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterMainLayout()),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required Color activeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2.h)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterOptionButton({
    required String label,
    required Color activeColor,
    required bool isEn,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8.w),
            Icon(isEn ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
