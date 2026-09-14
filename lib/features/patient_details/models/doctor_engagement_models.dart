/// موديلات موديول DoctorEngagement الحقيقي بالباك (favorites / reviews /
/// reports) - راجع Resources: DoctorReviewResource / DoctorReportResource
/// / DoctorFavoriteResource.

/// تقييم واحد لطبيب (نجمة 1-5 + تعليق اختياري).
class DoctorReview {
  final int id;
  final int rating;
  final String? comment;
  final String? patientName;
  final DateTime? createdAt;

  const DoctorReview({
    required this.id,
    required this.rating,
    this.comment,
    this.patientName,
    this.createdAt,
  });

  factory DoctorReview.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] is Map ? Map<String, dynamic>.from(json['patient']) : null;
    return DoctorReview(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 0,
      comment: json['comment']?.toString(),
      patientName: patient?['name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// ملخص تقييمات الطبيب (متوسط النجوم + عددها) - يُعرض على بروفايل
/// الطبيب لكل الزوار (Public: GET /doctors/{id}/reviews/summary).
class DoctorRatingSummary {
  final int totalReviews;
  final double? averageRating;

  const DoctorRatingSummary({required this.totalReviews, this.averageRating});

  factory DoctorRatingSummary.fromJson(Map<String, dynamic> json) {
    final avg = json['average_rating'];
    return DoctorRatingSummary(
      totalReviews: json['total_reviews'] is int ? json['total_reviews'] as int : int.tryParse('${json['total_reviews']}') ?? 0,
      averageRating: avg == null ? null : double.tryParse('$avg'),
    );
  }
}

/// بلاغ عن طبيب (SubmitReportRequest: category + description + encounter_id
/// اختياري).
class DoctorReport {
  final int id;
  final String category;
  final String description;
  final String status;

  const DoctorReport({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
  });

  factory DoctorReport.fromJson(Map<String, dynamic> json) {
    return DoctorReport(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

/// فئات البلاغ (category) - مطابقة حرفياً لـ enum الباك الحقيقي
/// (App\Core\Enums\ReportCategory).
class ReportCategories {
  ReportCategories._();

  static const String misconduct = 'misconduct';
  static const String negligence = 'negligence';
  static const String fraud = 'fraud';
  static const String verbalAbuse = 'verbal_abuse';
  static const String privacyViolation = 'privacy_violation';
  static const String other = 'other';

  static const List<String> values = [
    misconduct,
    negligence,
    fraud,
    verbalAbuse,
    privacyViolation,
    other,
  ];
}
