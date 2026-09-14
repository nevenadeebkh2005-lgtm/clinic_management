import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_strings.dart';
import '../view_models/register_cubit.dart';
import '../view_models/register_state.dart';
import 'widgets/step_one_widget.dart';
import 'widgets/step_verify_email_widget.dart';
import 'widgets/step_two_widget.dart';
import 'widgets/step_three_widget.dart';
import 'widgets/step_four_widget.dart';
import 'widgets/step_five_widget.dart';
// TODO: تأكد من المسار الصحيح لشاشة "الحساب قيد المراجعة" عندك بمشروعك.
// هون مفترض إنها نفس شاشة المريض (AccountUnderReviewScreen) وممكن تكون
// محتاجة نسخة خاصة بالدكتور أو مسار مختلف - عدّل الـ import حسب مشروعك.
import 'package:untitled3/features/auth/patient_auth/views/account_under_review_screen.dart';

class DoctorRegisterMainScreen extends StatefulWidget {
  const DoctorRegisterMainScreen({super.key});

  @override
  State<DoctorRegisterMainScreen> createState() => _DoctorRegisterMainScreenState();
}

class _DoctorRegisterMainScreenState extends State<DoctorRegisterMainScreen> {
  // فورم كي خاص بخطوة 1 بس، هي الخطوة الوحيدة اللي فيها validators حاليًا.
  // أي خطوة جديدة بالمستقبل تحتاج تحقق، بتاخد كي خاص فيها بنفس الأسلوب
  // بدل إرجاع فورم واحد يلف كل الخطوات الستة مع بعض.
  final GlobalKey<FormState> _stepOneFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DoctorRegisterCubit, DoctorRegisterState>(
      listener: (context, state) {
        if (state is DoctorRegisterSubmitSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AccountUnderReviewScreen()),
                (route) => false,
          );
        }
        if (state is DoctorRegisterSubmitFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<DoctorRegisterCubit>();
        final isSubmitting = state is DoctorRegisterStepSubmitting;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isSubmitting ? null : () => cubit.previousStep(context),
            ),
            title: LinearProgressIndicator(
              value: state.currentStep / cubit.totalSteps,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              minHeight: 6.h,
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Center(
                  child: Text(
                    '${state.currentStep}/${cubit.totalSteps}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child:

                PageView(
                  controller: cubit.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepOneWidgets(formKey: _stepOneFormKey),
                    const StepVerifyEmailWidgets(),
                    const StepTwoWidgets(),
                    StepThreeWidgets(),
                    StepFourWidgets(),
                    const DoctorStepFiveWidget(),
                  ],
                ),
              ),
              _buildBottomNavigation(context, state, cubit, isSubmitting),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(
      BuildContext context, DoctorRegisterState state, DoctorRegisterCubit
      cubit, bool isSubmitting) {
    final isLastStep = state.currentStep == cubit.totalSteps;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (state.currentStep > 1) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: isSubmitting ? null : () => cubit.previousStep(context),
                child: Text(AppStrings.back(context)),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: isSubmitting
                  ? null
                  : () => cubit.nextStep(state.currentStep == 1 ? _stepOneFormKey : null),
              child: isSubmitting
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
                  : Text(
                isLastStep ? AppStrings.confirmSubmit(context) : AppStrings.nextStep(context),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
