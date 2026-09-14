import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../view_models/register_cubit.dart';
import '../../view_models/register_state.dart';

class StepOneWidgets extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const StepOneWidgets({super.key, required this.formKey});

  @override
  State<StepOneWidgets> createState() => _StepOneWidgetsState();
}

class _StepOneWidgetsState extends State<StepOneWidgets> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _idCardNumberController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final model = context.read<DoctorRegisterCubit>().state.model;
    _firstNameController = TextEditingController(text: model.firstName);
    _lastNameController = TextEditingController(text: model.lastName);
    _emailController = TextEditingController(text: model.email);
    _idCardNumberController = TextEditingController(text: model.idCardNumber);
    _passwordController = TextEditingController(text: model.password);
    _confirmPasswordController = TextEditingController(text: model.confirmPassword);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idCardNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
    required bool isDarkMode,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.textLightGrey.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
          width: 2.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cubit = context.read<DoctorRegisterCubit>();

    return BlocListener<DoctorRegisterCubit, DoctorRegisterState>(
      listenWhen: (previous, current) => previous.currentStep != current.currentStep,
      listener: (context, state) {},
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),
              Text(
                AppStrings.tellUsAboutYourself(context),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              SizedBox(height: 5.h),
              Text(
                AppStrings.provideBasicInfo(context),
                style: TextStyle(fontSize: 13.sp, color: AppColors.textLightGrey),
              ),
              SizedBox(height: 25.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.firstName(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _firstNameController,
                          cursorColor: AppColors.primaryGreen,
                          validator: (val) => (val == null || val.isEmpty) ? AppStrings.requiredField(context) : null,
                          decoration: _inputDecoration(
                            hintText: AppStrings.firstNameHint(context),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            isDarkMode: isDarkMode,
                          ),
                          onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(firstName: value)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.lastName(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _lastNameController,
                          cursorColor: AppColors.primaryGreen,
                          validator: (val) => (val == null || val.isEmpty) ? AppStrings.requiredField(context) : null,
                          decoration: _inputDecoration(
                            hintText: AppStrings.lastNameHint(context),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            isDarkMode: isDarkMode,
                          ),
                          onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(lastName: value)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Text(AppStrings.emailAddress(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _emailController,
                cursorColor: AppColors.primaryGreen,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => (val == null || val.isEmpty || !val.contains('@')) ? AppStrings.invalidEmail(context) : null,
                decoration: _inputDecoration(
                  hintText: AppStrings.emailHint(context),
                  prefixIcon: const Icon(Icons.email_outlined),
                  isDarkMode: isDarkMode,
                ),
                onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(email: value)),
              ),
              SizedBox(height: 15.h),
              Text('ID Card Number', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _idCardNumberController,
                cursorColor: AppColors.primaryGreen,
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.isEmpty) ? AppStrings.requiredField(context) : null,
                decoration: _inputDecoration(
                  hintText: 'Enter your ID card number',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  isDarkMode: isDarkMode,
                ),
                onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(idCardNumber: value)),
              ),
              SizedBox(height: 15.h),
              Text(AppStrings.password(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _passwordController,
                cursorColor: AppColors.primaryGreen,
                obscureText: _obscurePassword,
                validator: (val) => (val == null || val.length < 8) ? AppStrings.passwordLengthWarning(context) : null,
                decoration: _inputDecoration(
                  hintText: AppStrings.passwordHint(context),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  isDarkMode: isDarkMode,
                ),
                onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(password: value)),
              ),
              SizedBox(height: 15.h),
              Text(AppStrings.confirmPassword(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _confirmPasswordController,
                cursorColor: AppColors.primaryGreen,
                obscureText: _obscureConfirmPassword,
                validator: (val) {
                  if (val == null || val.isEmpty) return AppStrings.requiredField(context);
                  if (val != _passwordController.text) return AppStrings.passwordsDoNotMatch(context);
                  return null;
                },
                decoration: _inputDecoration(
                  hintText: AppStrings.passwordHint(context),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  isDarkMode: isDarkMode,
                ),
                onChanged: (value) => cubit.updateRegisterModel(cubit.state.model.copyWith(confirmPassword: value)),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
