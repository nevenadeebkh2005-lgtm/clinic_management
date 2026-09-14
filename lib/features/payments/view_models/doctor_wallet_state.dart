import '../models/wallet_models.dart';

enum DoctorWalletStatus { initial, loading, loaded, failure }

class DoctorWalletState {
  final DoctorWalletStatus status;
  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final List<WalletRequestModel> withdrawalRequests;
  final String? errorMessage;
  final bool isSubmitting;
  final String? submitError;
  final String? submitSuccess;

  const DoctorWalletState({
    this.status = DoctorWalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.withdrawalRequests = const [],
    this.errorMessage,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess,
  });

  DoctorWalletState copyWith({
    DoctorWalletStatus? status,
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    List<WalletRequestModel>? withdrawalRequests,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    String? submitSuccess,
    bool clearSubmitSuccess = false,
  }) {
    return DoctorWalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      withdrawalRequests: withdrawalRequests ?? this.withdrawalRequests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSuccess: clearSubmitSuccess ? null : (submitSuccess ?? this.submitSuccess),
    );
  }
}
