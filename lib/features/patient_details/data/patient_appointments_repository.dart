import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/patient_appointment_model.dart';

/// نداءات الحجز الحقيقية للمريض (Postman: Appointment/Patient).
class PatientAppointmentsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PatientAppointment>> getAppointments() async {
    try {
      final response = await _dio.get(ApiConstants.patientAppointments);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => PatientAppointment.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// بيحجز الموعد ويدفعه بنفس الطلب (atomic) - الباك ما بينشئ الموعد
  /// كـ Scheduled إلا لو الدفع نجح فعلياً (راجع
  /// AppointmentBookingService::book()), فـ payment_method إلزامي هون.
  /// بيرجع 409 تحديداً إذا صار حدا تاني حجز نفس الـ slot أول - لازم
  /// نميّزها لنعرض رسالة "الموعد لم يعد متاحاً" بدل رسالة عامة.
  Future<PatientAppointment> book({
    required int slotId,
    required String paymentMethod,
    String encounterType = 'in_person',
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.patientAppointments,
        data: FormData.fromMap({
          'slot_id': slotId.toString(),
          'encounter_type': encounterType,
          'payment_method': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return PatientAppointment.fromJson(data);
      }
      throw ApiException('تعذّر قراءة بيانات الحجز');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ⚠️ 19/8: الباك بيرجع 422 "The reason field is required" لو انبعت
  /// فاضي - صار reason إلزامي فعلياً هون.
  Future<void> cancel(int appointmentId, {required String reason}) async {
    try {
      await _dio.post(
        ApiConstants.patientAppointmentCancel(appointmentId),
        data: FormData.fromMap({'reason': reason}),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PatientAppointment> reschedule({required int appointmentId, required int newSlotId}) async {
    try {
      final response = await _dio.post(
        ApiConstants.patientAppointmentReschedule(appointmentId),
        data: FormData.fromMap({'new_slot_id': newSlotId.toString()}),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return PatientAppointment.fromJson(data);
      }
      throw ApiException('تعذّر قراءة بيانات الموعد المعدّل');
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
