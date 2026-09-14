import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/constants/setting.dart';
import '../../../../models/attached_model.dart';

// =============================================
// Widget - صف الملف المرفق الواحد
// يعرض: أيقونة نوع الملف + اسم + حجم وحالة متوافقة مع ألوان ونصوص الثيم
// =============================================
class AttachedFileItem extends StatelessWidget {
  final AttachedFile file;
  final VoidCallback onDelete;

  const AttachedFileItem({
    super.key,
    required this.file,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            theme.cardColor, // دعم التغير التلقائي للون الكارد في الـ Dark Mode
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : Colors.black.withOpacity(
                    0.04,
                  ), // إخفاء أثر الظل في الوضع المعتم
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- أيقونة نوع الملف الديناميكية المحدثة بالأسفل ---
          _FileTypeIcon(fileType: file.fileType),

          const SizedBox(width: 12),

          // --- اسم الملف + حجمه وحالته التكبيرية الديناميكية ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 25 * scaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${file.size} • ${file.status}',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 25 * scaleFactor,
                  ),
                ),
              ],
            ),
          ),

          // --- أيقونة الحذف بلون تحذيري موحد وصريح للمشروع ---
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: Color(
                0xFFD32F2F,
              ), // الاعتماد على تدرج أحمر موحد بدلاً من رمادي مبهم
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Sub-widget - أيقونة نوع الملف المتكاملة مع الـ Dark Mode
// تم نقل الـ Getters خارج دالة الـ Build بشكل صحيح ومستقل
// =============================================
class _FileTypeIcon extends StatelessWidget {
  final AttachmentType fileType;

  const _FileTypeIcon({required this.fileType});

  // 1. لون خلفية الأيقونة بناءً على النوع (خارج الـ build)
  Color getBgColor(bool isDark) {
    switch (fileType) {
      case AttachmentType.pdf:
        return const Color(0xFFFFEBEE).withOpacity(isDark ? 0.15 : 1.0);
      case AttachmentType.image:
        return const Color(0xFFE8F5E9).withOpacity(isDark ? 0.15 : 1.0);
      case AttachmentType.other:
        return isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6);
    }
  }

  // 2. لون الأيقونة نفسها (خارج الـ build)
  Color getIconColor(bool isDark) {
    switch (fileType) {
      case AttachmentType.pdf:
        return const Color(0xFFE53935);
      case AttachmentType.image:
        return const Color(0xFF43A047);
      case AttachmentType.other:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  // 3. نوع الأيقونة (خارج الـ build)
  IconData get icon {
    switch (fileType) {
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: getBgColor(isDark),
        borderRadius: BorderRadius.circular(8), // مربع بزوايا مدورة
      ),
      child: Center(child: Icon(icon, color: getIconColor(isDark), size: 22)),
    );
  }
}
