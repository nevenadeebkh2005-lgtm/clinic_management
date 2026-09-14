import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../core/constants/setting.dart';
// =============================================
// Widget - منطقة رفع الملفات
// تعرض: border متوافق مع الثيم، أيقونة خضراء، نصوص مترجمة، و3 chips تصنيف
// =============================================
class UploadDropZone extends StatelessWidget {
  final VoidCallback onTap;

  const UploadDropZone({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          // لون خلفية متناسق ديناميكياً بدلاً من البيج الثابت
          color: isDark ? theme.cardColor : const Color(0xFFF9F9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- دائرة الأيقونة الخضراء ---
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.upload_file,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- نصوص منطقة الرفع المسحوبة والموحدة من الـ AppStrings ---
            Text(
              AppStrings.tapToUpload(context),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 25 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              AppStrings.orDragDrop(context),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 12 * scaleFactor,
              ),
            ),

            const SizedBox(height: 16),

            // --- الـ chips: Lab Results, Prescriptions, Medical Images ---
            const _FileTypeChips(),
          ],
        ),
      ),
    );
  }
}

// =============================================
// Sub-widget - chips تصنيف أنواع الملفات المترجمة
// =============================================
class _FileTypeChips extends StatelessWidget {
  const _FileTypeChips();

  @override
  Widget build(BuildContext context) {
    final isEn =
        BlocProvider.of<SettingsCubit>(context).state.locale.languageCode ==
        'en';

    // دعم ترجمة التصنيفات بشكل مباشر وثابت بناءً على لغة النظام الحالية لـ Cubit
    final List<String> types = isEn
        ? ['Lab Results', 'Prescriptions', 'Medical Images']
        : ['نتائج المختبر', 'الوصفات الطبية', 'الصور الطبية'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: types.map((type) => _Chip(label: type)).toList(),
    );
  }
}

// =============================================
// Sub-widget - chip تصنيف واحد متوافق مع وضع الـ Dark Mode
// =============================================
class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          fontSize: 25 * scaleFactor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
