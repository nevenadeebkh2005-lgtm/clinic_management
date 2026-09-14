import '../data/consultation_model.dart';

enum ConsultationsInboxStatus { initial, loading, loaded, failure }

class ConsultationsInboxState {
  final ConsultationsInboxStatus status;
  final List<ConsultationModel> items;
  final String? errorMessage;

  const ConsultationsInboxState({
    this.status = ConsultationsInboxStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  int get totalUnread => items.fold(0, (sum, c) => sum + c.unreadCount);

  ConsultationsInboxState copyWith({
    ConsultationsInboxStatus? status,
    List<ConsultationModel>? items,
    String? errorMessage,
  }) {
    return ConsultationsInboxState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}
