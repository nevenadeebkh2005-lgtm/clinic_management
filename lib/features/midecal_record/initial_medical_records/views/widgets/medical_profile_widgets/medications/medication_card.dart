import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/constants/setting.dart';
import '../../../../models/medication_model.dart';

// =============================================
// Widget - كارد الدواء الواحد داخل القائمة المضافة
// يعرض: أيقونة حبة دواء + اسم + badge Active + 3 نقاط + Dosage + Frequency
// =============================================
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onMenuTap;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onMenuTap,
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
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- أيقونة حبة الدواء ---
            const _MedicationIcon(),

            const SizedBox(width: 12),

            // --- المحتوى: اسم + dosage + frequency ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          medication.name,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 25 * scaleFactor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Badge الحالة الديناميكي
                      _StatusBadge(status: medication.status),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // صف Dosage
                  _InfoRow(
                    icon: Icons.medication_outlined,
                    label: isEn ? 'Dosage:' : 'الجرعة:',
                    value: medication.dosage,
                  ),

                  const SizedBox(height: 4),

                  // صف Frequency
                  _InfoRow(
                    icon: Icons.access_time,
                    label: isEn ? 'Frequency:' : 'التكرار:',
                    value: medication.frequency,
                  ),
                ],
              ),
            ),

            // --- أيقونة الـ 3 نقاط (القائمة) ---
            GestureDetector(
              onTap: onMenuTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.more_vert,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================
// Sub-widget - دائرة أيقونة الحبة الدواء
// =============================================
class _MedicationIcon extends StatelessWidget {
  const _MedicationIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.medication, size: 22, color: theme.primaryColor),
      ),
    );
  }
}

// =============================================
// Sub-widget - Badge الحالة (Active / Inactive)
// =============================================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    // دعم فحص الحالة بالإنجليزية أو العربية حسب القيمة الممررة من الـ Model
    final bool isActive = status.toLowerCase() == 'active' || status == 'نشط';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE8F5E9).withOpacity(isDark ? 0.15 : 1.0)
            : Colors.grey[300]!.withOpacity(isDark ? 0.2 : 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive
              ? const Color(0xFF388E3C)
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
          fontSize: 25 * scaleFactor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// =============================================
// Sub-widget - صف المعلومات (Dosage / Frequency)
// =============================================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleFactor = BlocProvider.of<SettingsCubit>(
      context,
    ).state.scaleFactor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 13,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55),
            fontSize: 25 * scaleFactor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.85),
              fontSize: 25 * scaleFactor,
            ),
          ),
        ),
      ],
    );
  }
}
