import 'dart:async';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/fcm_service.dart';
import '../../../core/network/secure_storage_service.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> register(Map<String, dynamic> fields) async {
    try {
      final formData = FormData.fromMap(fields);
      final response = await _dio.post(ApiConstants.register, data: formData);
      await _saveTokenIfPresent(response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> verifyEmailCode(String code) async {
    try {
      final formData = FormData.fromMap({'code': code});
      final response = await _dio.post(
        ApiConstants.verifyEmailCode,
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // إعادة إرسال كود التفعيل
  Future<Map<String, dynamic>> resendCode() async {
    try {
      final response = await _dio.post(ApiConstants.resendCode);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // خطوة 3: إكمال الملف الشخصي
  Future<Map<String, dynamic>> completeProfile(
    Map<String, dynamic> fields,
  ) async {
    try {
      // ListFormat.multiCompatible: أي قيمة List جوا fields (متل
      // certificates أو department_ids) بتتبعت كمفاتيح متكررة
      // "key[]" بدل "key" وبس. بدونها، dio كان عم يبعت نفس المفتاح
      // بدون [] لكل عنصر، والباك (Laravel) كان عم ياخد آخر قيمة بس
      // ويرفض الباقي كـ "must be an array" - هيك ظهر الخطأ بالـ
      // Postman response لما جربنا complete-profile للدكتور.
      final formData = FormData.fromMap(fields, ListFormat.multiCompatible);
      final response = await _dio.post(
        ApiConstants.completeProfile,
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // تسجيل الدخول
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final formData = FormData.fromMap({'email': email, 'password': password});
      final response = await _dio.post(ApiConstants.login, data: formData);
      await _saveTokenIfPresent(response.data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // نسيت كلمة المرور - بيرسل كود لإيميل المستخدم (لو موجود؛ الباك ما بيفصح
  // إذا الإيميل مسجل أو لأ لأسباب أمنية، فبيرجع نفس رسالة النجاح دايماً)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final formData = FormData.fromMap({'email': email});
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // إعادة تعيين كلمة المرور بالكود يلي وصل عالإيميل
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        'code': code,
        'password': password,
        ApiConstants.passwordConfirmationKey: passwordConfirmation,
      });
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on DioException catch (_) {
      // حتى لو فشل نداء اللوغ اوت بالسيرفر، منمسح التوكن محلياً
    } finally {
      await SecureStorageService.instance.clearToken();
    }
  }

  // GET /auth/me - يرجّع {data: {user, dashboard}} لصاحب الـ token الحالي.
  // مفيدة لأي شاشة ما وصلها currentUserJson عبر شجرة الـ widgets (متل
  // doctor_profile_screen المفتوحة من أكتر من مكان) وبتحتاج id المستخدم
  // الحالي لحاجة عابرة بسيطة.
  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get(ApiConstants.authMe);
      final data = response.data is Map ? response.data['data'] : null;
      final user = data is Map ? data['user'] : null;
      if (user is Map) {
        return Map<String, dynamic>.from(user);
      }
      throw ApiException('تعذّر جلب بيانات المستخدم الحالي');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> _saveTokenIfPresent(dynamic responseData) async {
    final data = responseData is Map ? responseData['data'] : null;
    final token = data is Map ? data['token'] : null;
    if (token is String && token.isNotEmpty) {
      await SecureStorageService.instance.saveToken(token);
      // Fire-and-forget: register this device for push notifications now
      // that we have an auth token. Never blocks/fails login on its account.
      unawaited(FcmService.instance.registerToken());
    }
  }

  ApiException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        'تعذّر الاتصال بالسيرفر، تأكد من الإنترنت وحاول مجدداً',
      );
    }

    final data = response.data;
    String message = 'حدث خطأ غير متوقع';
    Map<String, dynamic>? errors;

    if (data is Map) {
      message = data['message']?.toString() ?? message;
      // هون عدلنا هاد الجزء لحتى يظهر تفاصيل الخطأ
      if (data['errors'] is Map) {
        errors = Map<String, dynamic>.from(data['errors']);

        if (errors.isNotEmpty) {
          final messages = <String>[];

          errors.forEach((field, value) {
            if (value is List) {
              for (final error in value) {
                messages.add('$field: $error');
              }
            } else {
              messages.add('$field: $value');
            }
          });

          message = messages.join('\n');
        }
      }
      // هاد الجزء القديم اللي ما كان يعرض تفاصيل الخطأ
      // if (data['errors'] is Map) {
      //   errors = Map<String, dynamic>.from(data['errors']);
      //   // أول رسالة validation نعرضها كملخص إذا ما كان في message واضح
      //   if (data['message'] == null && errors.isNotEmpty) {
      //     final firstKey = errors.keys.first;
      //     final firstVal = errors[firstKey];
      //     if (firstVal is List && firstVal.isNotEmpty) {
      //       message = firstVal.first.toString();
      //     }
      //   }
      // }
    }

    return ApiException(
      message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
