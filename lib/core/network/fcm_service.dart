import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';
import 'api_constants.dart';

/// Registers this device's FCM token with the backend so
/// NotificationService (Laravel) can push chat/appointment notifications
/// to it. Call this right after login/register saves the auth token —
/// POST /device-tokens requires auth, so it can't run before that.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<void> registerToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _dio.post(ApiConstants.deviceTokens, data: {
        'token': token,
        'platform': 'android',
      });
    } catch (_) {
      // Push registration failing should never block login/register — the
      // app still works fine over plain REST either way.
    }
  }
}
