/// Real notification model - matches NotificationResource (GET
/// /notifications, shared by doctor and patient; the backend scopes
/// everything to whoever the bearer token belongs to).
///
/// [type] is kept as a raw string (not a Dart enum) on purpose: the backend
/// has ~19 NotificationType values today and may add more later without an
/// app update, so callers should switch on the well-known constants below
/// and fall back to a generic look for anything unrecognized instead of
/// crashing on an unknown value.
library;

class NotificationTypes {
  NotificationTypes._();

  static const String appointmentConfirmed = 'appointment_confirmed';
  static const String appointmentCancelled = 'appointment_cancelled';
  static const String appointmentReminder = 'appointment_reminder';
  static const String appointmentRescheduled = 'appointment_rescheduled';
  static const String appointmentCompleted = 'appointment_completed';
  static const String consultationStarted = 'consultation_started';
  static const String consultationMessageReceived = 'consultation_message_received';
  static const String consultationEnded = 'consultation_ended';
  static const String paymentConfirmed = 'payment_confirmed';
  static const String paymentFailed = 'payment_failed';
  static const String invoiceIssued = 'invoice_issued';
  static const String accessGranted = 'access_granted';
  static const String accessRevoked = 'access_revoked';
  static const String doctorVerified = 'doctor_verified';
  static const String doctorRejected = 'doctor_rejected';
  static const String reportReceived = 'report_received';
  static const String systemAlert = 'system_alert';
  static const String refundRequested = 'refund_requested';
  static const String refundCompleted = 'refund_completed';

  /// أي نوع بيبدأ بـ "appointment_" بيستفيد من نفس الأيقونة/التنقّل
  /// (لائحة المواعيد) بدون ما نعدد كل قيمة يدوياً.
  static bool isAppointment(String type) => type.startsWith('appointment_');
  static bool isConsultation(String type) => type.startsWith('consultation_');
}

class NotificationModel {
  final int id;
  final String type;
  final String status;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  /// appointment_id مبعوت ضمن data لأي إشعار مرتبط بموعد (تأكيد/إلغاء/
  /// تذكير/محادثة...) - راجع الباك (AppointmentBookingService،
  /// AppointmentStatusService، ConsultationService::notifyOtherParticipant).
  int? get appointmentId {
    final raw = data['appointment_id'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) => NotificationModel(
        id: id,
        type: type,
        status: status,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'].toString()),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
