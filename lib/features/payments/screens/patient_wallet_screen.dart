import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../models/wallet_models.dart';
import '../view_models/patient_wallet_cubit.dart';
import '../view_models/patient_wallet_state.dart';

/// شاشة محفظة المريض - رصيد حالي، طلب شحن جديد (POST
/// /patient/wallet/top-up-requests)، وسجل طلبات الشحن + الحركات.
/// كيوبت مستقل خاص فيها (مو موفّر من شجرة فوق) لأنها بتنفتح دايماً عبر
/// Navigator.push من صفحة البروفايل - نفس نمط DoctorProfileScreen.
class PatientWalletScreen extends StatelessWidget {
  const PatientWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientWalletCubit()..load(),
      child: const _PatientWalletView(),
    );
  }
}

class _PatientWalletView extends StatefulWidget {
  const _PatientWalletView();

  @override
  State<_PatientWalletView> createState() => _PatientWalletViewState();
}

class _PatientWalletViewState extends State<_PatientWalletView> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.enterValidAmount(context))),
      );
      return;
    }
    final ok = await context.read<PatientWalletCubit>().requestTopUp(value);
    if (ok && context.mounted) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.topUpRequestSubmitted(context))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: primaryGreen),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            AppStrings.walletTitle(context),
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen),
          ),
        ),
        body: BlocBuilder<PatientWalletCubit, PatientWalletState>(
          builder: (context, state) {
            if (state.status == PatientWalletStatus.loading || state.status == PatientWalletStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == PatientWalletStatus.failure && state.wallet == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Text(
                    state.errorMessage ?? AppStrings.unexpectedError(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 14.sp),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<PatientWalletCubit>().load(),
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _BalanceCard(
                    balance: state.wallet?.balance ?? 0,
                    cardBg: cardBg,
                    textColor: textColor,
                    primaryGreen: primaryGreen,
                    isDark: isDark,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    AppStrings.requestTopUp(context),
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor, fontSize: 14.sp),
                          decoration: InputDecoration(
                            labelText: AppStrings.amountLabel(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          height: 44.h,
                          child: ElevatedButton(
                            onPressed: state.isSubmitting ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                            child: state.isSubmitting
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    AppStrings.submitRequest(context),
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.sp),
                                  ),
                          ),
                        ),
                        if (state.submitError != null) ...[
                          SizedBox(height: 8.h),
                          Text(state.submitError!, style: const TextStyle(color: Color(0xFFC0392B))),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    AppStrings.topUpHistory(context),
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  SizedBox(height: 10.h),
                  if (state.topUpRequests.isEmpty)
                    _EmptyHint(text: AppStrings.noRequestsYet(context), textColor: textColor)
                  else
                    ...state.topUpRequests.map(
                      (r) => _RequestTile(request: r, cardBg: cardBg, textColor: textColor),
                    ),
                  SizedBox(height: 20.h),
                  Text(
                    AppStrings.transactionsLabel(context),
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  SizedBox(height: 10.h),
                  if (state.transactions.isEmpty)
                    _EmptyHint(text: AppStrings.noTransactionsYet(context), textColor: textColor)
                  else
                    ...state.transactions.map(
                      (t) => _TransactionTile(transaction: t, cardBg: cardBg, textColor: textColor),
                    ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final Color cardBg;
  final Color textColor;
  final Color primaryGreen;
  final bool isDark;

  const _BalanceCard({
    required this.balance,
    required this.cardBg,
    required this.textColor,
    required this.primaryGreen,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.currentBalance(context),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  final Color textColor;

  const _EmptyHint({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Text(text, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13.sp)),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final WalletRequestModel request;
  final Color cardBg;
  final Color textColor;

  const _RequestTile({required this.request, required this.cardBg, required this.textColor});

  Color _statusColor() {
    switch (request.status) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC0392B);
      default:
        return const Color(0xFFB8860B);
    }
  }

  String _statusLabel(BuildContext context) {
    switch (request.status) {
      case 'approved':
        return AppStrings.statusApproved(context);
      case 'rejected':
        return AppStrings.statusRejected(context);
      default:
        return AppStrings.statusPending(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\$${request.amount.toStringAsFixed(2)}',
              style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
            child: Text(
              _statusLabel(context),
              style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;
  final Color cardBg;
  final Color textColor;

  const _TransactionTile({required this.transaction, required this.cardBg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    final color = isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC0392B);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type,
                  style: TextStyle(color: textColor, fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                if (transaction.createdAt != null)
                  Text(
                    '${transaction.createdAt!.toLocal()}'.split('.').first,
                    style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 10.5.sp),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
