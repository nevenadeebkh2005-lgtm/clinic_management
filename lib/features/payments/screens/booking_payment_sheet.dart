import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/wallet_repository.dart';
import '../models/wallet_models.dart';
import 'patient_wallet_screen.dart';

/// بيفتح شيت اختيار طريقة الدفع قبل تأكيد الحجز - بيجيب خيارات الدفع
/// الفعلية للمريض الحالي (GET /patient/wallet/payment-options) ورصيد
/// محفظته، وبيفلتر الخيارات المعروضة حسب allowed_methods (لو عنده 3
/// غيابات مثلاً، ما بيعرض إلا "دفع كامل أونلاين"). بيرجع قيمة
/// payment_method المختارة (ApiConstants.paymentMethodFullOnline/
/// CashDeposit) أو null لو المستخدم رجع بدون ما يختار.
Future<String?> showBookingPaymentSheet(
  BuildContext context, {
  required double price,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingPaymentSheet(price: price),
  );
}

class _BookingPaymentSheet extends StatefulWidget {
  final double price;

  const _BookingPaymentSheet({required this.price});

  @override
  State<_BookingPaymentSheet> createState() => _BookingPaymentSheetState();
}

class _BookingPaymentSheetState extends State<_BookingPaymentSheet> {
  final WalletRepository _repository = WalletRepository();

  bool _isLoading = true;
  String? _errorMessage;
  PaymentOptionsModel? _options;
  double _walletBalance = 0;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final options = await _repository.getPaymentOptions();
      final wallet = await _repository.getPatientWallet();
      if (!mounted) return;
      setState(() {
        _options = options;
        _walletBalance = wallet.balance;
        _isLoading = false;
        // فُل أونلاين مختار افتراضياً دايماً لأنه متاح دايماً (allowedMethods
        // بترجع فيه أكيد - راجع PaymentService::allowedMethodsFor()).
        _selectedMethod = ApiConstants.paymentMethodFullOnline;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحميل خيارات الدفع';
      });
    }
  }

  double get _dueNow {
    final options = _options;
    if (options == null) return widget.price;
    if (_selectedMethod == ApiConstants.paymentMethodCashDeposit) {
      return widget.price * options.depositPercent / 100;
    }
    return widget.price;
  }

  bool get _hasEnoughBalance => _walletBalance >= _dueNow;

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final sheetBg = isDark ? AppColors.darkCard : AppColors.white;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(22.r), topRight: Radius.circular(22.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
            child: _isLoading
                ? SizedBox(
                    height: 180.h,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 12.h),
                          Text(
                            AppStrings.loadingPaymentOptions(context),
                            style: TextStyle(color: textColor, fontSize: 12.5.sp),
                          ),
                        ],
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? SizedBox(
                        height: 160.h,
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor, fontSize: 13.sp),
                          ),
                        ),
                      )
                    : _buildContent(context, textColor, primaryGreen, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor, Color primaryGreen, bool isDark) {
    final options = _options!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(4.r)),
          ),
        ),
        Text(
          AppStrings.choosePaymentMethod(context),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: textColor),
        ),
        SizedBox(height: 14.h),

        // ── خيار: دفع كامل أونلاين (متاح دايماً) ──
        _PaymentMethodOption(
          selected: _selectedMethod == ApiConstants.paymentMethodFullOnline,
          enabled: true,
          title: AppStrings.payFullOnline(context),
          subtitle: AppStrings.payFullOnlineDesc(context),
          amountLabel: '\$${widget.price.toStringAsFixed(2)}',
          textColor: textColor,
          primaryGreen: primaryGreen,
          isDark: isDark,
          onTap: () => setState(() => _selectedMethod = ApiConstants.paymentMethodFullOnline),
        ),
        SizedBox(height: 10.h),

        // ── خيار: كاش + عربون (مفلتر حسب allowed_methods - إذا وصل
        // المريض لعتبة 3 غيابات ما بيظهر متاح أبداً). ──
        _PaymentMethodOption(
          selected: _selectedMethod == ApiConstants.paymentMethodCashDeposit,
          enabled: options.cashDepositAllowed,
          title: AppStrings.payCashDeposit(context),
          subtitle: AppStrings.payCashDepositDesc(context, options.depositPercent),
          amountLabel: '\$${(widget.price * options.depositPercent / 100).toStringAsFixed(2)}',
          textColor: textColor,
          primaryGreen: primaryGreen,
          isDark: isDark,
          onTap: options.cashDepositAllowed
              ? () => setState(() => _selectedMethod = ApiConstants.paymentMethodCashDeposit)
              : null,
        ),

        if (!options.cashDepositAllowed) ...[
          SizedBox(height: 8.h),
          Text(
            AppStrings.onlineOnlyNotice(context),
            style: TextStyle(color: const Color(0xFFB8860B), fontSize: 11.5.sp),
          ),
        ],

        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.backgroundBeige,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: AppStrings.totalPriceLabel(context),
                value: '\$${widget.price.toStringAsFixed(2)}',
                textColor: textColor,
              ),
              SizedBox(height: 6.h),
              _SummaryRow(
                label: AppStrings.amountDueNowLabel(context),
                value: '\$${_dueNow.toStringAsFixed(2)}',
                textColor: textColor,
                bold: true,
              ),
              SizedBox(height: 6.h),
              _SummaryRow(
                label: AppStrings.walletBalanceLabel(context),
                value: '\$${_walletBalance.toStringAsFixed(2)}',
                textColor: _hasEnoughBalance ? textColor : const Color(0xFFC0392B),
              ),
            ],
          ),
        ),

        if (!_hasEnoughBalance) ...[
          SizedBox(height: 10.h),
          Text(
            AppStrings.insufficientWalletBalance(context),
            style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // سكّر الشيت أول
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientWalletScreen()));
            },
            child: Text(
              AppStrings.topUpNow(context),
              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
            ),
          ),
        ],

        SizedBox(height: 14.h),
        SizedBox(
          height: 48.h,
          child: ElevatedButton(
            onPressed: (_selectedMethod != null && _hasEnoughBalance)
                ? () => Navigator.pop(context, _selectedMethod)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              disabledBackgroundColor: primaryGreen.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            ),
            child: Text(
              AppStrings.confirmAndPay(context),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final String amountLabel;
  final Color textColor;
  final Color primaryGreen;
  final bool isDark;
  final VoidCallback? onTap;

  const _PaymentMethodOption({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.textColor,
    required this.primaryGreen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? primaryGreen : Colors.grey.withOpacity(0.3);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
            borderRadius: BorderRadius.circular(14.r),
            color: selected ? primaryGreen.withOpacity(0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? primaryGreen : Colors.grey,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.65), fontSize: 11.sp)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(amountLabel, style: TextStyle(color: primaryGreen, fontSize: 13.sp, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final bool bold;

  const _SummaryRow({required this.label, required this.value, required this.textColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12.5.sp)),
        Text(
          value,
          style: TextStyle(color: textColor, fontSize: 13.sp, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
        ),
      ],
    );
  }
}
