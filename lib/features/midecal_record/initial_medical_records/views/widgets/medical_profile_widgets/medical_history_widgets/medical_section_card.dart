import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../core/constants/setting.dart';
import '../../../../models/medical_history_models.dart';
import 'medical_entry_item.dart';

// =============================================
// Widget - كارد القسم القابل للطي والفتح
// يعرض: أيقونة + عنوان + زر Add New + سهم، ومتوافق تماماً مع الثيم واللغة وتكبير النصوص
// =============================================
class MedicalSectionCard extends StatelessWidget {
  final MedicalSection section;
  final Widget iconWidget; // أيقونة القسم (مختلفة لكل قسم)
  final Color iconBgColor; // لون خلفية دائرة الأيقونة
  final VoidCallback onToggle; // فتح/غلق القسم
  final VoidCallback onAddNew; // زر + Add New
  final Function(MedicalEntry) onEdit;
  final Function(MedicalEntry) onDelete;

  const MedicalSectionCard({
    super.key,
    required this.section,
    required this.iconWidget,
    required this.iconBgColor,
    required this.onToggle,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme
            .cardColor, // استبدال كود الألوان الثابت ليدعم الـ Dark Mode تلقائياً
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : Colors.black.withOpacity(
                    0.04,
                  ), // إخفاء الظلال الحادة في الـ Dark Mode
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =============================================
          // Header: أيقونة + عنوان + زر Add New + سهم
          // =============================================
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- صف العنوان والسهم ---
                Row(
                  children: [
                    // دائرة الأيقونة
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: iconWidget),
                    ),
                    const SizedBox(width: 12),

                    // عنوان القسم المتجاوب
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 25 * scaleFactor, // دعم معامل تكبير الخط
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // سهم الفتح/الغلق
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                        section.isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: theme.hintColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // --- زر + Add New المترجم والمتجاوب ---
                _AddNewButton(onTap: onAddNew),
              ],
            ),
          ),

          // =============================================
          // القائمة المنسدلة - تظهر فقط إذا isExpanded
          // =============================================
          if (section.isExpanded && section.entries.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark
                  ? Colors.grey[800]
                  : const Color(0xFFE5E7EB), // خط فاصل متوافق مع الثيم
            ),
            // عرض كل عنصر بالقائمة
            ...section.entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              // الخط الفاصل لا يظهر تحت آخر عنصر
              final isLast = index == section.entries.length - 1;
              return MedicalEntryItem(
                entry: entry,
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry),
                showDivider: !isLast,
              );
            }),
          ],
        ],
      ),
    );
  }
}

// =============================================
// Sub-widget - زر + Add New المترجم والمتوافق مع الثيم
// =============================================
class _AddNewButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNewButton({required this.onTap});

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          // تعديل اللون في وضع الـ Dark Mode ليكون مريحاً ومقروءاً للعين
          color: isDark
              ? theme.primaryColor.withOpacity(0.15)
              : theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20), // شكل pill
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // على قدر النص فقط
          children: [
            Icon(Icons.add, size: 14, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              AppStrings.addNew(
                context,
              ), // سحب نص الزر المترجم من ملف الترجمة الموحد للمشروع
              style: TextStyle(
                color: theme.primaryColor,
                fontSize:
                    25 *
                    scaleFactor, // دعم معامل تكبير الخط للزر الفرعي لقراءة أوضح
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
