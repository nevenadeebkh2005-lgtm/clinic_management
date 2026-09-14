import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/constants/setting.dart';
import '../../../../models/medical_history_models.dart';

// =============================================
// Widget - صف العنصر الواحد داخل القسم
// يعرض: العنوان والتفاصيل، وأيقونات التحكم المتوافقة مع الثيم وأبعاد الخطوط
// =============================================
class MedicalEntryItem extends StatelessWidget {
  final MedicalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider; // هل يظهر الخط الفاصل تحت العنصر

  const MedicalEntryItem({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- النص: العنوان + التفاصيل المتجاوبة مع حجم الخط والثيم ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize:
                            25 * scaleFactor, // تكبير ديناميكي ذكي للعنوان
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize:
                            25 * scaleFactor, // تكبير ديناميكي ذكي للتفاصيل
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // --- أيقونتا التعديل والحذف المتوافقتين مع ألوان السحب والوضع الليلي ---
              Row(
                children: [
                  // أيقونة التعديل المتجاوبة مع ثيم التطبيق المركزي
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme
                          .hintColor, // الاعتماد على ألوان الـ theme لمنع اختفاء الأيقونات بالوضع المظلم
                    ),
                  ),
                  const SizedBox(width: 12),
                  // أيقونة الحذف بلون أحمر صريح ومريح للعين في كلا الوضعين
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(
                        0xFFD32F2F,
                      ), // استبدال اللون الثابت بلون النظام التحذيري للملفات المرفوضة
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // خط فاصل ديناميكي يتغير لونه حسب وضع الـ Dark Mode تلقائياً
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
