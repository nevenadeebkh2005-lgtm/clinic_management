import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/doctor_appointment_models.dart';

/// ✅ 19/8: نداءات حقيقية بالكامل (Postman: Appointment/Doctor) - ما
/// عاد تخزين محلي وهمي.
class DoctorAppointmentsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<DoctorAppointment>> getAppointments() async {
    try {
      final response = await _dio.get(ApiConstants.doctorAppointments);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => DoctorAppointment.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// تسجيل دخول المريض للكشف - الموعد بيصير in_progress.
  Future<void> start(int appointmentId) async {
    try {
      await _dio.post(ApiConstants.doctorAppointmentStart(appointmentId));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// انتهاء الكشف فعلياً - المريض حضر - الموعد بيصير completed.
  Future<void> complete(int appointmentId) async {
    try {
      await _dio.post(ApiConstants.doctorAppointmentComplete(appointmentId));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ⚠️ 19/8: نفس تصحيح جهة المريض - reason إلزامي هلق بالباك.
  Future<void> cancel(int appointmentId, {required String reason}) async {
    try {
      await _dio.post(
        ApiConstants.doctorAppointmentCancel(appointmentId),
        data: FormData.fromMap({'reason': reason}),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// المريض ما حضر أصلاً - الموعد بيصير no_show.
  Future<void> markNoShow(int appointmentId) async {
    try {
      await _dio.post(ApiConstants.doctorAppointmentNoShow(appointmentId));
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
