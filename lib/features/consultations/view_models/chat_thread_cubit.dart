import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/consultations_repository.dart';
import 'chat_thread_state.dart';

/// Loads and polls the message thread for a single appointment
/// (GET /appointments/{appointmentId}/consultation/messages every ~8s
/// while the chat screen is visible), marks incoming messages as read on
/// load/poll, and exposes [send] for posting new text messages. Callers
/// must call [stopPolling] (or dispose the cubit) when navigating away.
class ChatThreadCubit extends Cubit<ChatThreadState> {
  final ConsultationsRepository _repository;
  final int appointmentId;
  Timer? _pollTimer;

  ChatThreadCubit({required this.appointmentId, ConsultationsRepository? repository})
      : _repository = repository ?? ConsultationsRepository(),
        super(const ChatThreadState());

  Future<void> load() async {
    if (state.messages.isEmpty) {
      emit(state.copyWith(status: ChatThreadStatus.loading));
    }
    try {
      final consultation = await _repository.getConsultation(appointmentId);
      final messages = await _repository.getMessages(appointmentId);
      if (isClosed) return;
      emit(state.copyWith(
        status: ChatThreadStatus.loaded,
        consultation: consultation,
        messages: messages,
        errorMessage: null,
      ));
      _markReadSilently();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: ChatThreadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> send(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;
    emit(state.copyWith(isSending: true, errorMessage: null));
    try {
      final message = await _repository.sendMessage(appointmentId, trimmed);
      if (isClosed) return;
      emit(state.copyWith(isSending: false, messages: [...state.messages, message]));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 8)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final messages = await _repository.getMessages(appointmentId);
      if (isClosed) return;
      emit(state.copyWith(messages: messages));
      _markReadSilently();
    } catch (_) {
      // Silent - polling failures shouldn't flash an error banner.
    }
  }

  void _markReadSilently() {
    _repository.markRead(appointmentId).catchError((_) => 0);
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
