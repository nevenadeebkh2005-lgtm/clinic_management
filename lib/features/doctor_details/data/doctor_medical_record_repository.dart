import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/patient_medical_record_bundle.dart';

/// ✅ 19/8: قراءة السجل الطبي لمريض من جهة الطبيب - مسموحة بس عبر موعد
/// فعلي معه (GET /doctor/appointments/{id}/medical-record). لو المريض
/// سحب الصلاحية (Patient/access/revoke) الباك بيرجع 403 - لازم نعرض
/// رسالة واضحة مش خطأ عام.
class DoctorMedicalRecordRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PatientMedicalRecordBundle> getForAppointment(int appointmentId) async {
    try {
      final response = await _dio.get(ApiConstants.doctorAppointmentMedicalRecord(appointmentId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        // ✅ إصلاح احتمالي لمشكلة "السجل عم يطلع فاضي عند الطبيب رغم
        // إنو المريض معبّيه": بما إنو هاد الـ endpoint مربوط بموعد (مش
        // مباشرة بالمريض متل عند GET /patient/medical-record)، من
        // الممكن يكون الباك عم يرجع بيانات الموعد/المريض جنب السجل
        // الطبي بمستوى متداخل إضافي (مثلاً data.medical_record.* أو
        // data.record.*) بدل ما يكون medical_history/medications/
        // attachments مباشرة على data زي ما كان مفترض بالتعليق فوق.
        // هون منتحقق: إذا الشكل المباشر طلع فاضي بالكامل (ولا allergies
        // ولا chronic_conditions ولا medications ولا attachments) وفي
        // مفتاح متداخل معروف يحتوي هالحقول فعلياً، منستخدمه هوّي
        // بدل data مباشرة - فبتشتغل الشاشة صح بغض النظر عن أي الشكلين
        // اعتمده الباك فعلياً.
        final effective = _resolveRecordJson(data);
        return PatientMedicalRecordBundle.fromJson(effective);
      }
      throw ApiException('تعذّر قراءة السجل الطبي');
    } on DioException catch (e) {
      final response = e.response;
      if (response?.statusCode == 403) {
        throw ApiException('المريض سحب صلاحية الاطلاع على سجله الطبي لهالموعد', statusCode: 403);
      }
      if (response == null) {
        throw ApiException('تعذّر الاتصال بالسيرفر، تأكد من الإنترنت وحاول مجدداً');
      }
      final data = response.data;
      String message = 'حدث خطأ غير متوقع';
      if (data is Map) message = data['message']?.toString() ?? message;
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  /// يفحص إذا الشكل المباشر لـ [data] فاضي فعلياً (ولا سجل)، وإذا في
  /// مفتاح متداخل شائع (medical_record / record / patient_medical_record)
  /// فيه الحقول الحقيقية، بيرجعه بدلاً من data الأصلي. إذا الشكل المباشر
  /// فيه أي بيانات، منرجعه متل ما هو بدون أي تعديل (الأولوية دايماً
  /// للشكل الحقيقي المباشر).
  Map<String, dynamic> _resolveRecordJson(Map<String, dynamic> data) {
    bool looksEmpty(Map<String, dynamic> m) {
      final history = m['medical_history'];
      final historyEmpty = history is! Map ||
          ((history['allergies'] as List?)?.isEmpty ?? true) &&
              ((history['chronic_conditions'] as List?)?.isEmpty ?? true) &&
              ((history['surgeries'] as List?)?.isEmpty ?? true) &&
              ((history['family_history'] as List?)?.isEmpty ?? true);
      final medsEmpty = (m['medications'] as List?)?.isEmpty ?? true;
      final attachmentsEmpty = (m['attachments'] as List?)?.isEmpty ?? true;
      return historyEmpty && medsEmpty && attachmentsEmpty;
    }

    if (!looksEmpty(data)) return data;

    for (final key in const ['medical_record', 'record', 'patient_medical_record']) {
      final nested = data[key];
      if (nested is Map<String, dynamic> && !looksEmpty(nested)) {
        return nested;
      }
    }
    // ما لقينا شكل بديل فيه بيانات - منرجع الأصلي متل ما هو (يعني
    // فعلاً المريض ما عبّى سجله، أو الشكل مختلف كليًا عن كل الاحتمالات
    // المتوقعة وبده فحص يدوي لرد حقيقي من الباك).
    return data;
  }
}
