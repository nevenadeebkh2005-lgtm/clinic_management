/// A single consultation message - GET/POST
/// /appointments/{appointmentId}/consultation/messages.
/// Only `message_type: "text"` is supported by the backend right now,
/// `content` is always a non-null string.
class ConsultationMessageModel {
  final int id;
  final int consultationId;
  final int senderId;
  final String senderRole; // doctor / patient / system
  final String senderName;
  final String messageType;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const ConsultationMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.messageType,
    required this.content,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  /// Bubble alignment: compare against the currently logged-in user's id.
  bool isMine(int currentUserId) => senderId == currentUserId;

  factory ConsultationMessageModel.fromJson(Map<String, dynamic> json) => ConsultationMessageModel(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        consultationId: json['consultation_id'] is int
            ? json['consultation_id'] as int
            : int.tryParse('${json['consultation_id']}') ?? 0,
        senderId: json['sender_id'] is int ? json['sender_id'] as int : int.tryParse('${json['sender_id']}') ?? 0,
        senderRole: json['sender_role']?.toString() ?? '',
        senderName: json['sender_name']?.toString() ?? '',
        messageType: json['message_type']?.toString() ?? 'text',
        content: json['content']?.toString() ?? '',
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'].toString()),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
