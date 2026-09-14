import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../theme/app_colors.dart';
import 'location_picker_screen.dart';

/// ✅ 20/8: رجّعناها تعتمد على خريطة حقيقية (LocationPickerScreen) بدل
/// GPS-only. السبب: المستخدم وقت التسجيل مش لازم يكون واقف بمكان
/// الموقع يلي بدو يسجّله (مثلاً طبيب بدو يحدد موقع عيادة وهو مش فيها
/// هلق) - فأخذ "موقعي الحالي" تلقائياً كان غلط منطقياً.
/// LocationPickerScreen أصلاً موجودة وجاهزة (flutter_map + latlong2 +
/// geolocator، وكلهم مضافين بالـ pubspec.yaml) - وفيها زر GPS اختياري
/// جوا الخريطة نفسها لمين حاب يستخدمو كنقطة بداية بس.
class LocationPickField extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onPicked;
  final String? label;

  const LocationPickField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onPicked,
    this.label,
  });

  bool get _hasValue => latitude != null && longitude != null;

  Future<void> _openPicker(BuildContext context) async {
    debugPrint('🔴 NEW LOCATION FIELD TAPPED');
    final initial = _hasValue ? LatLng(latitude!, longitude!) : null;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialPosition: initial)),
    );
    if (result != null) {
      onPicked(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;

    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _hasValue ? primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _hasValue ? primaryGreen.withOpacity(0.35) : AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Icon(_hasValue ? Icons.location_on_rounded : Icons.map_outlined, size: 18, color: primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _hasValue
                    ? (isEn
                    ? 'Location set (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})'
                    : 'تم تحديد الموقع (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})')
                    : (label ?? (isEn ? 'Pick location on map' : 'تحديد الموقع من الخريطة')),
                style: TextStyle(
                  fontSize: 12.5,
                  color: _hasValue ? textColor : AppColors.textLightGrey,
                  fontWeight: _hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textLightGrey),
          ],
        ),
      ),
    );
  }
}
