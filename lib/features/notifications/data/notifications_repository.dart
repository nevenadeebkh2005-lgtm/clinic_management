import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/notification_model.dart';

/// نداءات إشعارات حقيقية (GET /notifications + mark-read/mark-all-read) -
/// مشتركة بين الطبيب والمريض، الباك بيحدد صاحب كل إشعار حسب التوكن.
class NotificationsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false, int perPage = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {
          if (unreadOnly) 'unread_only': 'true',
          'per_page': perPage.toString(),
        },
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data.whereType<Map>().map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.post(ApiConstants.notificationMarkRead(id));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.post(ApiConstants.notificationsMarkAllRead);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map && data['updated_count'] != null) {
        return data['updated_count'] is int ? data['updated_count'] as int : int.tryParse('${data['updated_count']}') ?? 0;
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
    }
    return ApiException(message, statusCode: response.statusCode);
  }
}
