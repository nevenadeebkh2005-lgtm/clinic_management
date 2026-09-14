/// Consultation models - built from the real, verified endpoints:
/// GET /consultations (inbox listing) and
/// GET /appointments/{appointmentId}/consultation (get-or-create thread).

class ConsultationOtherParty {
  final int id;
  final String name;

  const ConsultationOtherParty({required this.id, required this.name});

  factory ConsultationOtherParty.fromJson(Map<String, dynamic> json) => ConsultationOtherParty(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class ConsultationLastMessage {
  final String content;
  final String senderRole; // doctor / patient / system
  final DateTime createdAt;

  const ConsultationLastMessage({
    required this.content,
    required this.senderRole,
    required this.createdAt,
  });

  factory ConsultationLastMessage.fromJson(Map<String, dynamic> json) => ConsultationLastMessage(
        content: json['content']?.toString() ?? '',
        senderRole: json['sender_role']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class ConsultationModel {
  final int id;
  final int appointmentId;
  final String status; // waiting / active / completed / cancelled / missed
  final ConsultationOtherParty? otherParty;
  final ConsultationLastMessage? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const ConsultationModel({
    required this.id,
    required this.appointmentId,
    required this.status,
    this.otherParty,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.startedAt,
    this.endedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) => ConsultationModel(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        appointmentId: json['appointment_id'] is int
            ? json['appointment_id'] as int
            : int.tryParse('${json['appointment_id']}') ?? 0,
        status: json['status']?.toString() ?? 'waiting',
        otherParty: json['other_party'] is Map
            ? ConsultationOtherParty.fromJson(Map<String, dynamic>.from(json['other_party'] as Map))
            : null,
        lastMessage: json['last_message'] is Map
            ? ConsultationLastMessage.fromJson(Map<String, dynamic>.from(json['last_message'] as Map))
            : null,
        unreadCount:
            json['unread_count'] is int ? json['unread_count'] as int : int.tryParse('${json['unread_count']}') ?? 0,
        updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
        startedAt: json['started_at'] == null ? null : DateTime.tryParse(json['started_at'].toString()),
        endedAt: json['ended_at'] == null ? null : DateTime.tryParse(json['ended_at'].toString()),
      );
}
