import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/doctor_profile_models.dart';

/// نداءات الباك الحقيقية الخاصة بالطبيب - كل نقاط النهاية هون موجودة
/// فعلياً بالـ Postman collection (Doctor / ...) وشغالة 100%.
class DoctorRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<DoctorProfileInfo> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.doctorProfile);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return DoctorProfileInfo.fromApiJson(data);
      }
      throw ApiException('تعذّر قراءة بيانات الملف الشخصي للطبيب');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<DoctorProfileInfo> updateProfile(Map<String, dynamic> fields) async {
    try {
      final formData = FormData.fromMap(fields, ListFormat.multiCompatible);
      final response = await _dio.put(ApiConstants.doctorProfile, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return DoctorProfileInfo.fromApiJson(data);
      }
      // بعض نداءات update ما بترجع الكائن كامل - نعيد تحميله من جديد
      return getProfile();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<String?> updatePhoto(Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(ApiConstants.doctorProfilePhoto, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) return data['photo_url']?.toString();
      return null;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ✅ الانضمام لعيادة موجودة أصلاً - صار بس clinic_code + consultation_fee
  /// (التخصص/القسم ما عاد يُطلب هون؛ بينحدد مرة وحدة بالريجستر ومستقل
  /// عن أي عيادة معينة).
  /// ✅ 20/8: الحقل صار String clinicCode (مش int clinicId) - نفس تسمية
  /// وشكل حقل "Clinic Code" بخطوة الريجستر (register_model.dart)، لأنه
  /// مش بالضرورة رقم صرف، هو "كود" حسب تسمية الباك (clinic_code).
  Future<DoctorProfileInfo> joinClinic({required String clinicCode, required double consultationFee}) async {
    try {
      final formData = FormData.fromMap({
        'clinic_code': clinicCode,
        'consultation_fee': consultationFee.toString(),
      });
      final response = await _dio.post(ApiConstants.doctorJoinClinic, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorProfileInfo.fromApiJson(data);
      return getProfile();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ✅ إنشاء عيادة جديدة من حساب طبيب مسجّل أصلاً (مو بس وقت التسجيل
  /// الأول) - بتنحفظ بحالة "pending" لحد ما يوافق عليها الأدمن، تماماً
  /// متل إنشاء عيادة أثناء التسجيل.
  Future<DoctorProfileInfo> createClinic({
    required String name,
    required String address,
    required String phone,
    required double consultationFee,
    Uint8List? licenseBytes,
    String? licenseFileName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final formData = FormData.fromMap({
        'clinic_name': name,
        'clinic_address': address,
        'clinic_phone': phone,
        'consultation_fee': consultationFee.toString(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (licenseBytes != null)
          'clinic_license_file': MultipartFile.fromBytes(licenseBytes, filename: licenseFileName ?? 'clinic_license.jpg'),
      });
      final response = await _dio.post(ApiConstants.doctorCreateClinic, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorProfileInfo.fromApiJson(data);
      return getProfile();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ✅ تحديث رسم الكشف الخاص بعيادة معينة (بعد الانضمام إلها).
  Future<DoctorProfileInfo> updateClinicFee({required int clinicId, required double fee}) async {
    try {
      final response = await _dio.put(
        ApiConstants.doctorUpdateClinicFee(clinicId),
        data: {'consultation_fee': fee},
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorProfileInfo.fromApiJson(data);
      return getProfile();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> leaveDepartment({required int clinicId, required int departmentId}) async {
    try {
      final formData = FormData.fromMap({
        'clinic_id': clinicId.toString(),
        'department_id': departmentId.toString(),
      });
      await _dio.post(ApiConstants.doctorLeaveDepartment, data: formData);
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
