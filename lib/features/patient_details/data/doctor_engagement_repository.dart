import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/doctor_engagement_models.dart';

/// نداءات موديول DoctorEngagement الحقيقية (Favorites / Reviews / Reports)
/// - نفس نمط باقي الـ repositories بالمشروع (Dio مباشر + ApiException).
class DoctorEngagementRepository {
  final Dio _dio = ApiClient.instance.dio;

  // --- Favorites ---

  /// بيبدّل حالة المفضلة للطبيب المحدد، وبيرجع الحالة الجديدة (true =
  /// صار مفضّل، false = انشال من المفضلة).
  Future<bool> toggleFavorite(int doctorId) async {
    try {
      final response = await _dio.post(ApiConstants.toggleDoctorFavorite(doctorId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map && data['is_favorite'] != null) {
        return data['is_favorite'] == true;
      }
      return false;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // --- Reviews ---

  /// تقييم المريض الحالي لهاد الطبيب (null لو لسا ما قيّمه).
  Future<DoctorReview?> getMyReview(int doctorId) async {
    try {
      final response = await _dio.get(ApiConstants.patientDoctorReview(doctorId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorReview.fromJson(data);
      return null;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// إرسال/تحديث تقييم (نجمة 1-5 + تعليق اختياري) - مسموح بس بعد موعد
  /// completed واحد على الأقل مع هاد الطبيب (شرط الباك).
  Future<DoctorReview> submitReview({
    required int doctorId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.patientDoctorReview(doctorId),
        data: FormData.fromMap({
          'rating': rating.toString(),
          if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        }),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorReview.fromJson(data);
      throw ApiException('تعذّر قراءة بيانات التقييم');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteReview(int doctorId) async {
    try {
      await _dio.delete(ApiConstants.patientDoctorReview(doctorId));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// ملخص التقييمات العام لطبيب (متوسط + عدد) - عام، ما بيحتاج تسجيل
  /// دخول، يُستخدم لعرضه على بروفايل الطبيب لكل الزوار.
  Future<DoctorRatingSummary> getRatingSummary(int doctorId) async {
    try {
      final response = await _dio.get(ApiConstants.doctorReviewsSummaryPublic(doctorId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorRatingSummary.fromJson(data);
      return const DoctorRatingSummary(totalReviews: 0, averageRating: null);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // --- Reports ---

  Future<DoctorReport> submitReport({
    required int doctorId,
    required String category,
    required String description,
    int? encounterId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.submitDoctorReport(doctorId),
        data: FormData.fromMap({
          'category': category,
          'description': description,
          if (encounterId != null) 'encounter_id': encounterId.toString(),
        }),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return DoctorReport.fromJson(data);
      throw ApiException('تعذّر قراءة بيانات البلاغ');
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
