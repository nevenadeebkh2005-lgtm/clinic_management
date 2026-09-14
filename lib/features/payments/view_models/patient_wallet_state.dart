import '../models/wallet_models.dart';

enum PatientWalletStatus { initial, loading, loaded, failure }

class PatientWalletState {
  final PatientWalletStatus status;
  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final List<WalletRequestModel> topUpRequests;
  final String? errorMessage;
  final bool isSubmitting;
  final String? submitError;
  final String? submitSuccess;

  const PatientWalletState({
    this.status = PatientWalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.topUpRequests = const [],
    this.errorMessage,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess,
  });

  PatientWalletState copyWith({
    PatientWalletStatus? status,
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    List<WalletRequestModel>? topUpRequests,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    String? submitSuccess,
    bool clearSubmitSuccess = false,
  }) {
    return PatientWalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      topUpRequests: topUpRequests ?? this.topUpRequests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSuccess: clearSubmitSuccess ? null : (submitSuccess ?? this.submitSuccess),
    );
  }
}
