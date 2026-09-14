import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../data/wallet_repository.dart';
import 'patient_wallet_state.dart';

class PatientWalletCubit extends Cubit<PatientWalletState> {
  final WalletRepository _repository;

  PatientWalletCubit({WalletRepository? repository})
      : _repository = repository ?? WalletRepository(),
        super(const PatientWalletState());

  Future<void> load() async {
    emit(state.copyWith(status: PatientWalletStatus.loading, clearError: true));
    try {
      final wallet = await _repository.getPatientWallet();
      final transactions = await _repository.getPatientTransactions();
      final topUpRequests = await _repository.getTopUpRequests();
      emit(state.copyWith(
        status: PatientWalletStatus.loaded,
        wallet: wallet,
        transactions: transactions,
        topUpRequests: topUpRequests,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PatientWalletStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: PatientWalletStatus.failure, errorMessage: 'تعذّر تحميل المحفظة'));
    }
  }

  Future<bool> requestTopUp(double amount) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true, clearSubmitSuccess: true));
    try {
      await _repository.requestTopUp(amount);
      emit(state.copyWith(isSubmitting: false, submitSuccess: 'submitted'));
      await load();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, submitError: 'تعذّر إرسال طلب الشحن'));
      return false;
    }
  }
}
