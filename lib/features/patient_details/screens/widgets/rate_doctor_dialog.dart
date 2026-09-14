import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/doctor_engagement_repository.dart';

/// نافذة تقييم بسيطة (5 نجوم يضغط عليهن المريض فبتتلوّن + زر موافق) -
/// تُستخدم بعد ما يصير الموعد completed. بترجع true لو انبعت التقييم
/// فعلاً (حتى تحدّث الشاشة الأصلية إذا لازم).
Future<bool?> showRateDoctorDialog(
  BuildContext context, {
  required int doctorId,
  String? doctorName,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _RateDoctorDialog(doctorId: doctorId, doctorName: doctorName),
  );
}

class _RateDoctorDialog extends StatefulWidget {
  final int doctorId;
  final String? doctorName;
  const _RateDoctorDialog({required this.doctorId, this.doctorName});

  @override
  State<_RateDoctorDialog> createState() => _RateDoctorDialogState();
}

class _RateDoctorDialogState extends State<_RateDoctorDialog> {
  final DoctorEngagementRepository _repository = DoctorEngagementRepository();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _errorMessage = AppStrings.ratingRequired(context));
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _repository.submitReview(
        doctorId: widget.doctorId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppStrings.unexpectedError(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isDark = settingsState.themeMode == ThemeMode.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    const starColor = Color(0xFFFBBF24);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.star_rounded, color: primaryGreen, size: 28.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              AppStrings.rateDoctorTitle(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: textColor),
            ),
            if (widget.doctorName != null) ...[
              SizedBox(height: 4.h),
              Text(
                widget.doctorName!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5.sp, color: primaryGreen, fontWeight: FontWeight.w600),
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFilled = starIndex <= _rating;
                return GestureDetector(
                  onTap: () => setState(() {
                    _rating = starIndex;
                    _errorMessage = null;
                  }),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFilled ? starColor : AppColors.textLightGrey.withOpacity(0.5),
                      size: 38.sp,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 18.h),
            TextField(
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              style: TextStyle(fontSize: 13.sp, color: textColor),
              decoration: InputDecoration(
                hintText: AppStrings.reviewCommentHint(context),
                hintStyle: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 8.h),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12)),
            ],
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: _isSubmitting
                    ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(AppStrings.confirmYes(context), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.sp)),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                child: Text(AppStrings.confirmNo(context), style: TextStyle(color: AppColors.textLightGrey, fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
