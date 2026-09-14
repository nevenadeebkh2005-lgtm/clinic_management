import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../core/constants/setting.dart';
// =============================================
// Widget - زرا Back و Next Step في الأسفل
// ثابتان في أسفل الشاشة دائماً وممتدان ديناميكياً حسب لغة وثيم النظام
// =============================================
class BottomActionButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNextStep;

  const BottomActionButtons({
    super.key,
    required this.onBack,
    required this.onNextStep,
  });

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:
            theme.scaffoldBackgroundColor, // متوافق تماماً مع وضع الـ Dark Mode
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.grey[800]!
                : const Color(0xEFEFEFEF), // استبدال الـ borderGrey الثابت
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // --- زر Back: border فقط بدون fill متوافق مع اللغات والثيم ---
          Expanded(
            flex: 2, // أصغر من زر Next Step
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? Colors.grey[600]!
                      : const Color(
                          0xFFD1D5DB,
                        ), // استبدال backButtonBorder الثابت
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
              child: Text(
                AppStrings.back(context), // جلب النص المترجم والموحد
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 25 * scaleFactor, // دعم معامل تكبير الخط
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // --- زر Next Step: لون الثيم الرئيسي مع سهم مرن الاتجاه ---
          Expanded(
            flex: 3, // أكبر من زر Back
            child: ElevatedButton(
              onPressed: onNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme
                    .primaryColor, // استبدال primaryGreen بألوان الثيم المركزي
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.nextStep(context), // جلب النص المترجم والموحد
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25 * scaleFactor, // دعم معامل تكبير الخط
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // السهم يتجه لليمين في الإنجليزية ولليسار في العربية لضمان تجربة مستخدم مثالية
                  Icon(
                    isEn ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
