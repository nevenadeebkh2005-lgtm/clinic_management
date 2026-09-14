import '../data/consultation_message_model.dart';
import '../data/consultation_model.dart';

enum ChatThreadStatus { initial, loading, loaded, failure }

class ChatThreadState {
  final ChatThreadStatus status;
  final ConsultationModel? consultation;
  final List<ConsultationMessageModel> messages;
  final bool isSending;
  final String? errorMessage;

  const ChatThreadState({
    this.status = ChatThreadStatus.initial,
    this.consultation,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  ChatThreadState copyWith({
    ChatThreadStatus? status,
    ConsultationModel? consultation,
    List<ConsultationMessageModel>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatThreadState(
      status: status ?? this.status,
      consultation: consultation ?? this.consultation,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}
