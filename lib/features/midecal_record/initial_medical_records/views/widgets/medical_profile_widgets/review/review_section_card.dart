import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/constants/setting.dart';
// =============================================
// Widget - كارد القسم القابل للتكرار في صفحة المراجعة
// يعرض: أيقونة + عنوان يسار + زر Edit يمين + محتوى مرن (children)
// =============================================
class ReviewSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  const ReviewSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.children,
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: أيقونة + عنوان + زر Edit ---
            Row(
              children: [
                Icon(icon, size: 20, color: theme.textTheme.bodyLarge?.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 25 * scaleFactor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // زر Edit المتجاوب مع اللغة والوضع الداكن
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEn ? 'Edit' : 'تعديل',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 25 * scaleFactor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 14),

            // --- المحتوى الداخلي ---
            ...children,
          ],
        ),
      ),
    );
  }
}

// =============================================
// Sub-widget - حقل معلومة واحدة
// =============================================
class ReviewInfoField extends StatelessWidget {
  final String label;
  final String value;

  const ReviewInfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55),
              fontSize: 25 * scaleFactor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Sub-widget - chip الحساسية (AllergyTag)
// =============================================
class AllergyTag extends StatelessWidget {
  final String name;

  const AllergyTag({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE).withOpacity(isDark ? 0.15 : 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 13,
            color: Color(0xFFD32F2F),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: const Color(0xFFD32F2F),
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Sub-widget - كارد الدواء الداخلي بقسم Meds
// =============================================
class ReviewMedCard extends StatelessWidget {
  final String name;
  final String details;

  const ReviewMedCard({super.key, required this.name, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800]! : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.medication_outlined,
                size: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 25 * scaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 25 * scaleFactor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Sub-widget - كارد الملف الداخلي بقسم Attachments
// =============================================
class ReviewAttachmentCard extends StatelessWidget {
  final String name;
  final String details;
  final bool isPdf;

  const ReviewAttachmentCard({
    super.key,
    required this.name,
    required this.details,
    required this.isPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    // تلوين الأيقونات والخلفيات بشكل طبيعي لملفات صفحة المراجعة
    final Color bgColor = isPdf
        ? const Color(0xFFFFEBEE).withOpacity(isDark ? 0.15 : 1.0)
        : const Color(0xFFE8F5E9).withOpacity(isDark ? 0.15 : 1.0);

    final Color iconColor = isPdf
        ? const Color(0xFFD32F2F)
        : const Color(0xFF388E3C);
    final IconData iconData = isPdf
        ? Icons.picture_as_pdf
        : Icons.image_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(iconData, size: 18, color: iconColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 25 * scaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 25 * scaleFactor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
