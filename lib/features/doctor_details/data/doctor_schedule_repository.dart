import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/work_schedule_models.dart';

/// ✅ ريبو حقيقي بالكامل - كل الدوال هون بتنادي endpoints فعلية موجودة
/// بالباك (راجع Postman collection المحدّث - مجلد "Schedule"). ما عاد في
/// أي تخزين محلي وهمي لجدول العمل.
class DoctorScheduleRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ClinicScheduleModel>> getAllSchedules() async {
    try {
      final response = await _dio.get(ApiConstants.doctorAllSchedules());
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map((e) => ClinicScheduleModel.fromJson(e)).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ClinicScheduleModel> getSchedule(int clinicId, {String clinicName = ''}) async {
    try {
      final response = await _dio.get(ApiConstants.doctorSchedule(clinicId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return ClinicScheduleModel.fromJson(data, clinicName: clinicName);
      }
      return ClinicScheduleModel.empty(clinicId, clinicName);
    } on DioException catch (e) {
      // إذا العيادة ما إلها جدول بعد (أول مرة)، الباك ممكن يرجع 404 -
      // منعتبرها ببساطة جدول فاضي (حالة "أول دخول" الطبيعية).
      if (e.response?.statusCode == 404) {
        return ClinicScheduleModel.empty(clinicId, clinicName);
      }
      throw _mapError(e);
    }
  }

  Future<ClinicScheduleModel> saveWeeklySchedule(
    int clinicId, {
    required int consultationDuration,
    required int breakDuration,
    required bool bufferEnabled,
    required List<ScheduleDay> days,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.doctorSchedule(clinicId),
        data: {
          'consultation_duration': consultationDuration,
          'break_duration': breakDuration,
          'buffer_enabled': bufferEnabled,
          'days': days.map((d) => d.toJson()).toList(),
        },
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) return ClinicScheduleModel.fromJson(data);
      return getSchedule(clinicId);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// بيولّد المواعيد الفعلية (Slots) القابلة للحجز اعتماداً على الجدول
  /// الأسبوعي المحفوظ - لازم يتنادى بعد أي حفظ لجدول جديد حتى تطلع
  /// الأوقات فعلياً بشاشة "الأوقات المتاحة" (availability).
  /// ⚠️ 19/8: تصحيح جوهري - الباك بيطلب date_from/date_to إلزامياً
  /// بجسم الـ request (حسب Postman: POST .../generate-slots بـ
  /// form-data فيها date_from/date_to)، وكانت هون عم تنبعت فاضية
  /// فبيرجع 422 "date_from/date_to field is required" - وبما إنه
  /// التوليد كان عم يفشل بصمت (ما في try/catch حواليه بمكان
  /// النداء)، ولا Slot كان عم يتولّد فعلياً بالباك، وهيك المريض ما
  /// كان شايف أي أوقات متاحة إطلاقاً.
  Future<void> generateSlots(int clinicId, {required DateTime dateFrom, required DateTime dateTo}) async {
    try {
      await _dio.post(
        ApiConstants.doctorGenerateSlots(clinicId),
        data: FormData.fromMap({
          'date_from': _formatDate(dateFrom),
          'date_to': _formatDate(dateTo),
        }),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<AvailabilitySlot>> getAvailability({
    required int doctorId,
    required int clinicId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.doctorAvailability(doctorId),
        queryParameters: {
          'clinic_id': clinicId.toString(),
          'date_from': _formatDate(dateFrom),
          'date_to': _formatDate(dateTo),
        },
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(AvailabilitySlot.fromJson).toList();
      }
      return const [];
    } on DioException catch (e) {
      // ⚠️ 18/8 تصحيح مهم: كان هون بلاش قبل بيبتلع 422 كمان (متل 404)
      // ويرجع لائحة فاضية بهدوء - هيك كان عم يخبي خطأ حقيقي (زي
      // "date_from required") ويظهر للمستخدم إنه بس "ما في أوقات"
      // بدل ما يبيّن المشكلة الفعلية. هلق 404 بس (لسا ما استدعى
      // generate-slots) بيرجع فاضي، أي خطأ تاني (422 وغيره) بيطلع
      // كخطأ حقيقي.
      if (e.response?.statusCode == 404) return const [];
      throw _mapError(e);
    }
  }

  Future<void> setVacation(int clinicId, {required DateTime startDate, required DateTime endDate}) async {
    try {
      await _dio.post(
        ApiConstants.doctorVacation(clinicId),
        data: FormData.fromMap({
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        }),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deactivateVacation(int clinicId) async {
    try {
      await _dio.delete(ApiConstants.doctorVacation(clinicId));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<BlockedTime>> getBlockedTimes(int clinicId) async {
    try {
      final response = await _dio.get(ApiConstants.doctorBlockedTimes(clinicId));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(BlockedTime.fromJson).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// حجب وقت بتاريخ محدد (مرة وحدة) - block_date + start_time + end_time.
  Future<void> blockTimeByDate(
    int clinicId, {
    required DateTime date,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      await _dio.post(
        ApiConstants.doctorBlockedTimes(clinicId),
        data: FormData.fromMap({
          'block_date': _formatDate(date),
          'start_time': startTime,
          'end_time': endTime,
          if (reason != null) 'reason': reason,
        }),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// حجب متكرر كل أسبوع بنفس اليوم (day_of_week) - مثلاً كل يوم أحد.
  Future<void> blockTimeByDayOfWeek(
    int clinicId, {
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      await _dio.post(
        ApiConstants.doctorBlockedTimes(clinicId),
        data: FormData.fromMap({
          'day_of_week': dayOfWeek.toString(),
          'start_time': startTime,
          'end_time': endTime,
          if (reason != null) 'reason': reason,
        }),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteBlockedTime(int blockedTimeId) async {
    try {
      await _dio.delete(ApiConstants.doctorDeleteBlockedTime(blockedTimeId));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ApiException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException('تعذّر الاتصال بالسيرفر، تأكد من الإنترنت وحاول مجدداً');
    }
    final data = response.data;
    String message = 'حدث خطأ غير متوقع';
    if (data is Map) {
      message = data['message']?.toString() ?? message;
      // بحالة أخطاء تحقق (422) زي {"errors": {"date_from": ["..."]}}،
      // منضيف أول رسالة تفصيلية حتى تبين وين المشكلة بالضبط بدل رسالة
      // عامة بس.
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final firstKey = errors.keys.isNotEmpty ? errors.keys.first : null;
        final firstVal = firstKey != null ? errors[firstKey] : null;
        if (firstVal is List && firstVal.isNotEmpty) {
          message = firstVal.first.toString();
        }
      }
    }
    return ApiException(message, statusCode: response.statusCode);
  }
}
