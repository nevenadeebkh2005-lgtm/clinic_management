import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/patient_profile_dummy_data.dart';

/// نداءات تعديل بروفايل المريض نفسه (اسم/تلفون/عنوان + صورة) - نفس نمط
/// DoctorRepository.updateProfile/updatePhoto حرفياً.
class PatientProfileRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PatientProfileModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final formData = FormData.fromMap(fields, ListFormat.multiCompatible);
      final response = await _dio.put(ApiConstants.patientProfile, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      // بعض الردود بترجع {user: {...}} وبعضها بيرجع الكائن مباشرة - منتعامل
      // مع الحالتين (نفس أسلوب AuthRepository.me()).
      final user = (data is Map && data['user'] is Map) ? data['user'] : data;
      if (user is Map<String, dynamic>) {
        return PatientProfileModel.fromUserJson(user);
      }
      throw ApiException('تعذّر قراءة بيانات الملف الشخصي');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<String?> updatePhoto(Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(ApiConstants.patientProfilePhoto, data: formData);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map) {
        return (data['avatar_url'] ?? data['photo_url'])?.toString();
      }
      return null;
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
