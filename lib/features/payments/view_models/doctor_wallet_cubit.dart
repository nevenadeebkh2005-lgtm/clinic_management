import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../data/wallet_repository.dart';
import 'doctor_wallet_state.dart';

class DoctorWalletCubit extends Cubit<DoctorWalletState> {
  final WalletRepository _repository;

  DoctorWalletCubit({WalletRepository? repository})
      : _repository = repository ?? WalletRepository(),
        super(const DoctorWalletState());

  Future<void> load() async {
    emit(state.copyWith(status: DoctorWalletStatus.loading, clearError: true));
    try {
      final wallet = await _repository.getDoctorWallet();
      final transactions = await _repository.getDoctorTransactions();
      final withdrawalRequests = await _repository.getWithdrawalRequests();
      emit(state.copyWith(
        status: DoctorWalletStatus.loaded,
        wallet: wallet,
        transactions: transactions,
        withdrawalRequests: withdrawalRequests,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: DoctorWalletStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: DoctorWalletStatus.failure, errorMessage: 'تعذّر تحميل المحفظة'));
    }
  }

  Future<bool> requestWithdrawal(double amount) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true, clearSubmitSuccess: true));
    try {
      await _repository.requestWithdrawal(amount);
      emit(state.copyWith(isSubmitting: false, submitSuccess: 'submitted'));
      await load();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, submitError: 'تعذّر إرسال طلب السحب'));
      return false;
    }
  }
}
