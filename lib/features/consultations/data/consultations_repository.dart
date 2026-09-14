import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import 'consultation_message_model.dart';
import 'consultation_model.dart';

/// Real, verified endpoints against the Laravel backend (base
/// http://localhost:8000/api/v1). Plain REST - no websocket/Firestore,
/// callers are expected to poll on a timer while a chat screen is visible.
/// Shared by both the doctor and patient sides - the backend scopes every
/// response to whoever the bearer token belongs to.
class ConsultationsRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /consultations - inbox listing, standard paginated wrapper.
  Future<List<ConsultationModel>> getConsultations() async {
    try {
      final response = await _dio.get(ApiConstants.consultations);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data.whereType<Map>().map((e) => ConsultationModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /appointments/{appointmentId}/consultation - get-or-create the
  /// consultation thread for an appointment.
  Future<ConsultationModel> getConsultation(int appointmentId) async {
    try {
      final response = await _dio.get(ApiConstants.appointmentConsultation(appointmentId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        return ConsultationModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw ApiException('تعذّر تحميل المحادثة');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /appointments/{appointmentId}/consultation/messages - paginated,
  /// oldest first.
  Future<List<ConsultationMessageModel>> getMessages(int appointmentId) async {
    try {
      final response = await _dio.get(ApiConstants.appointmentConsultationMessages(appointmentId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ConsultationMessageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /appointments/{appointmentId}/consultation/messages - body
  /// {content}, returns the created message (201).
  Future<ConsultationMessageModel> sendMessage(int appointmentId, String content) async {
    try {
      final response = await _dio.post(
        ApiConstants.appointmentConsultationMessages(appointmentId),
        data: {'content': content},
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        return ConsultationMessageModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw ApiException('تعذّر إرسال الرسالة');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /appointments/{appointmentId}/consultation/messages/read - no
  /// body, marks every message not sent by the current user as read.
  Future<int> markRead(int appointmentId) async {
    try {
      final response = await _dio.post(ApiConstants.appointmentConsultationMessagesRead(appointmentId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map && data['updated'] != null) {
        return data['updated'] is int ? data['updated'] as int : int.tryParse('${data['updated']}') ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException('تعذّر الاتصال بالسيرفر، تأكد من الإنترنت وحاول مجدداً');
    }
    final data = response.data;
    String message = 'حدث خطأ غير متوقع';
    if (data is Map) {
      message = data['message']?.toString() ?? message;
      if (data['errors'] is Map) {
        final errors = Map<String, dynamic>.from(data['errors']);
        if (data['message'] == null && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          }
        }
      }
    }
    return ApiException(message, statusCode: response.statusCode);
  }
}
