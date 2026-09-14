import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/constants/setting.dart';
// =============================================
// Widget - شريط التقدم العلوي
// يعرض: "STEP X OF Y" يسار، النسبة % يمين، وشريط ممتلئ بنسبة معينة متوافق مع الثيم
// =============================================
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  // حساب النسبة المئوية تلقائياً
  double get _progressValue => currentStep / totalSteps;
  int get _percentage => (_progressValue * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;
    final isEn =
        BlocProvider.of<SettingsCubit>(context).state.locale.languageCode ==
        'en';

    // صياغة النص ديناميكياً حسب اللغة الحالية للمشروع
    final progressText = isEn
        ? 'STEP $currentStep OF $totalSteps'
        : 'الخطوة $currentStep من $totalSteps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- صف النص: STEP X OF Y  و  XX% ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progressText,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(
                  0.6,
                ), // توافق رمادي مع الـ Dark Mode
                fontSize: 25 * scaleFactor,
                fontWeight: FontWeight.w600,
                letterSpacing: isEn
                    ? 0.8
                    : 0.0, // تباعد الحروف مفعل للإنجليزية فقط لمظهر احترافي
              ),
            ),
            Text(
              '$_percentage%',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 25 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // --- شريط التقدم متناسق الألوان والوضعية ---
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.grey[800]
                : const Color(0xFFE5E7EB), // بديل ديناميكي لـ progressBg
            valueColor: AlwaysStoppedAnimation<Color>(
              theme
                  .primaryColor, // تعبئة الشريط بلون الثيم الأساسي (بديل لـ progressFill)
            ),
          ),
        ),
      ],
    );
  }
}
