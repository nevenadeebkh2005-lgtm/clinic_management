/// نماذج نظام المحفظة (Wallet/Payments module) - نفس الحقول يلي بيرجعها
/// WalletResource / WalletTransactionResource / TopUpRequestResource /
/// WithdrawalRequestResource بالباك (راجع app/Modules/Payments/Resources).

class WalletModel {
  final int id;
  final double balance;
  final String currency;
  final bool isPlatform;

  const WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
    required this.isPlatform,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int? ?? 0,
      balance: double.tryParse('${json['balance']}') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      isPlatform: json['is_platform'] == true,
    );
  }
}

class WalletTransactionModel {
  final int id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int? ?? 0,
      type: json['type']?.toString() ?? '',
      amount: double.tryParse('${json['amount']}') ?? 0,
      balanceAfter: double.tryParse('${json['balance_after']}') ?? 0,
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// مشتركة بين TopUpRequest (مريض) وWithdrawalRequest (طبيب) - نفس الشكل
/// بالضبط بردود الباك (id/user_id/user_name/amount/status/admin_note/
/// processed_at/created_at).
class WalletRequestModel {
  final int id;
  final double amount;
  final String status; // pending | approved | rejected
  final String? adminNote;
  final DateTime? createdAt;

  const WalletRequestModel({
    required this.id,
    required this.amount,
    required this.status,
    this.adminNote,
    this.createdAt,
  });

  factory WalletRequestModel.fromJson(Map<String, dynamic> json) {
    return WalletRequestModel(
      id: json['id'] as int? ?? 0,
      amount: double.tryParse('${json['amount']}') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      adminNote: json['admin_note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// رد GET /patient/wallet/payment-options (PaymentService::paymentOptions()):
/// عدد مرات الغياب، الطرق المسموحة حالياً، ونسبة العربون المطبّقة.
class PaymentOptionsModel {
  final int noShowCount;
  final List<String> allowedMethods;
  final int depositPercent;

  const PaymentOptionsModel({
    required this.noShowCount,
    required this.allowedMethods,
    required this.depositPercent,
  });

  bool get cashDepositAllowed => allowedMethods.contains('cash_deposit');
  bool get fullOnlineAllowed => allowedMethods.contains('full_online');

  factory PaymentOptionsModel.fromJson(Map<String, dynamic> json) {
    final methods = json['allowed_methods'] as List? ?? const [];
    return PaymentOptionsModel(
      noShowCount: json['no_show_count'] as int? ?? 0,
      allowedMethods: methods.map((e) => e.toString()).toList(),
      depositPercent: json['deposit_percent'] as int? ?? 25,
    );
  }
}
