import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/wallet_models.dart';

/// نداءات محفظة المريض والطبيب - نفس الـ endpoints تحت /patient/wallet
/// و/doctor/wallet (Payments module بالباك). مشتركة عمداً بريبوزيتوري
/// واحد (زي WalletService بالباك) لأنه المنطق نفسه بس الـ base path
/// مختلف - ما في داعي لصفين منفصلين لنفس الشكل.
class WalletRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<WalletModel> getPatientWallet() => _getWallet(ApiConstants.patientWallet);
  Future<WalletModel> getDoctorWallet() => _getWallet(ApiConstants.doctorWallet);

  Future<List<WalletTransactionModel>> getPatientTransactions({String? type}) =>
      _getTransactions(ApiConstants.patientWalletTransactions, type: type);
  Future<List<WalletTransactionModel>> getDoctorTransactions({String? type}) =>
      _getTransactions(ApiConstants.doctorWalletTransactions, type: type);

  Future<PaymentOptionsModel> getPaymentOptions() async {
    try {
      final response = await _dio.get(ApiConstants.patientPaymentOptions);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return PaymentOptionsModel.fromJson(data);
      }
      throw ApiException('تعذّر قراءة خيارات الدفع');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<WalletRequestModel> requestTopUp(double amount) async {
    try {
      final response = await _dio.post(
        ApiConstants.patientTopUpRequests,
        data: FormData.fromMap({'amount': amount.toString()}),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return WalletRequestModel.fromJson(data);
      }
      throw ApiException('تعذّر قراءة طلب الشحن');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<WalletRequestModel>> getTopUpRequests() async {
    try {
      final response = await _dio.get(ApiConstants.patientTopUpRequests);
      return _parseRequestList(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<WalletRequestModel> requestWithdrawal(double amount) async {
    try {
      final response = await _dio.post(
        ApiConstants.doctorWithdrawalRequests,
        data: FormData.fromMap({'amount': amount.toString()}),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return WalletRequestModel.fromJson(data);
      }
      throw ApiException('تعذّر قراءة طلب السحب');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<WalletRequestModel>> getWithdrawalRequests() async {
    try {
      final response = await _dio.get(ApiConstants.doctorWithdrawalRequests);
      return _parseRequestList(response.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<WalletModel> _getWallet(String path) async {
    try {
      final response = await _dio.get(path);
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map<String, dynamic>) {
        return WalletModel.fromJson(data);
      }
      throw ApiException('تعذّر قراءة رصيد المحفظة');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<WalletTransactionModel>> _getTransactions(String path, {String? type}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {if (type != null && type.isNotEmpty) 'type': type},
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => WalletTransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  List<WalletRequestModel> _parseRequestList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => WalletRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
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
