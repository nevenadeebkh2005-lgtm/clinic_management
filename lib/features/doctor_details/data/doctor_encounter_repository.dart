
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/encounter_models.dart';

/// نداءات حقيقية لتوثيق الزيارة السريرية (Doctor/Encounter) - نفس نمط
/// DoctorAppointmentsRepository. submit هي نقطة الحفظ الوحيدة المستخدمة
/// (راجع ملاحظة encounter_models.dart).
class DoctorEncounterRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// بيرجع null لو الموعد لسا ما توثّق فيه شي (data: null من الباك)
  /// أو لو الـ endpoint نفسه غير مفعّل بعد (404) - ما في داعي نعطّل
  /// الشاشة كاملة بسبب هيك، الطبيب ببساطة بيبلّش بمسودة فاضية.
  Future<Encounter?> show(int appointmentId) async {
    try {
      final response = await _dio.get(ApiConstants.doctorEncounter(appointmentId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        return Encounter.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapError(e);
    }
  }

  Future<Encounter> submit(
    int appointmentId, {
    required List<DraftNote> notes,
    required List<DraftDiagnosis> diagnoses,
    required List<DraftPrescriptionItem> prescriptionItems,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.doctorEncounterSubmit(appointmentId),
        data: {
          if (notes.isNotEmpty) 'notes': notes.map((n) => n.toJson()).toList(),
          if (diagnoses.isNotEmpty) 'diagnoses': diagnoses.map((d) => d.toJson()).toList(),
          if (prescriptionItems.isNotEmpty)
            'prescription_items': prescriptionItems.map((p) => p.toJson()).toList(),
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data is Map ? response.data['data'] : null;
      return Encounter.fromJson(Map<String, dynamic>.from(data as Map));
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
    Map<String, dynamic>? errors;
    if (data is Map) {
      message = data['message']?.toString() ?? message;
      if (data['errors'] is Map) {
        errors = Map<String, dynamic>.from(data['errors']);
        if (data['message'] == null && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          }
        }
      }
    }
    return ApiException(message, statusCode: response.statusCode, errors: errors);
  }
}
