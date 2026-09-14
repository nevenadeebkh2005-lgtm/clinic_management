import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/consultations_repository.dart';
import 'consultations_inbox_state.dart';

/// Loads the consultations inbox (GET /consultations) and polls it every
/// ~8s while the inbox screen is visible, for a "live" feel without a
/// websocket. Callers must call [stopPolling] (or just dispose the cubit)
/// when navigating away.
class ConsultationsInboxCubit extends Cubit<ConsultationsInboxState> {
  final ConsultationsRepository _repository;
  Timer? _pollTimer;

  ConsultationsInboxCubit({ConsultationsRepository? repository})
      : _repository = repository ?? ConsultationsRepository(),
        super(const ConsultationsInboxState());

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(status: ConsultationsInboxStatus.loading));
    }
    try {
      final items = await _repository.getConsultations();
      items.sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
      if (isClosed) return;
      emit(state.copyWith(status: ConsultationsInboxStatus.loaded, items: items, errorMessage: null));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: ConsultationsInboxStatus.failure, errorMessage: e.toString()));
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 8)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
