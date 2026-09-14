import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/doctor_dummy_data.dart';

/// ✅ GET /doctors صار endpoint حقيقي وموجود بالباك (تأكدنا من الرد
/// الفعلي بالـ Postman collection) - رجعنا نرجع بيانات حقيقية بس، بلا
/// أي fallback لبيانات وهمية متل قبل (كان مؤقت لحد ما يجهز الـ endpoint،
/// وهلق جاهز).
class DoctorListingRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<DoctorListingModel>> getDoctors() async {
    try {
      final response = await _dio.get(ApiConstants.doctorsPublicList);
      final data = response.data is Map ? response.data['data'] : response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DoctorListingModel.fromApiJson)
            .toList();
      }
      return const [];
    } catch (_) {
      // خطأ اتصال أو رد غير متوقع - منرجع لائحة فاضية بهدوء بدل ما نكسر
      // الشاشة، مع الحفاظ على حالة "لا يوجد أطباء" الحقيقية (مو بيانات
      // وهمية بعد اليوم).
      return const [];
    }
  }

  /// نفس GET /doctors بس مع query params الحقيقية يلي بيفهمها
  /// DoctorSearchRequest بالباك (department_id, name, price_min/max,
  /// experience_min/max, availability, time_slot[], sort, lat/lng...).
  /// هاد هو الفرق الأساسي عن [getDoctors]: الفلترة صايرة عالباك نفسه،
  /// فيلي يرجع بالرد هو بالضبط الأطباء المطابقين - مو كل الأطباء
  /// وبعدين نصفّيهم محلياً. على عكس [getDoctors] ما منبلّع بهدوء عند
  /// الفشل: شاشة الفلاتر لازم تعرف إنو الطلب فشل حتى تقدر تعرض رسالة
  /// وما تسكّر نفسها وكأنو الفلتر انطبّق.
  Future<List<DoctorListingModel>> searchDoctors(
    Map<String, dynamic> filters,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.doctorsPublicList,
        queryParameters: filters,
      );
      final data = response.data is Map ? response.data['data'] : response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DoctorListingModel.fromApiJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
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
