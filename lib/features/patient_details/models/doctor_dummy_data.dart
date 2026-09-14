
/// عيادة واحدة من عيادات الطبيب (بمعرّفها الحقيقي id) - لازم الـ id
/// تحديداً لاستدعاء GET /doctors/{id}/availability بشكل صحيح لكل عيادة
/// (مو بس الاسم للعرض متل workplaceNames).
class DoctorListingClinicRef {
  final int id;
  final String name;
  final double? consultationFee;

  const DoctorListingClinicRef({required this.id, required this.name, this.consultationFee});
}

class DoctorListingModel {
  final String id;
  final String firstName;
  final String lastName;
  // ✅ توحيد mainSpecialty/subSpecialty السابقين بحقل واحد departments -
  // القسم/الأقسام الحقيقية يلي الطبيب منتسب إلها فعلياً بالباك
  // (doctor_departments pivot، راجع DoctorPublicResource::toArray)، بلا
  // أي تمييز "رئيسي/فرعي" مصطنع كان مبني بس على ترتيب المصفوفة.
  final List<String> departments;
  final String? profileImageUrl;
  final double rating;
  final int reviewCount;
  final List<String> workplaceNames;
  final List<DoctorListingClinicRef> clinicRefs;
  final String primaryWorkplaceType;
  final String? availabilityStatus;
  final int? availableInDays;
  final double consultationFee;
  final bool offersOnlineConsultation;
  final String? educationDegree;
  final String? experienceYears;
  final bool isFavourite;
  // ✅ إضافة: النبذة عن الطبيب (biography) - موجودة فعلياً برد GET
  // /doctors الحقيقي (راجع Postman) بس ما كانت موجودة إطلاقاً بهاد
  // الموديل، فكانت شاشة بروفايل الطبيب عند المريض دايماً عم تعرض نص
  // عام ثابت بدل النبذة الحقيقية يلي الطبيب كتبها بملفه.
  final String? biography;
  // ✅ إضافة: قيمة الجنس الخام من الباك ('male'/'female') - GET /doctors
  // هلق بيرجعها (راجع DoctorPublicResource::toArray) بعد ما صار فلتر
  // الجنس شغال فعلياً بالباك؛ تُستخدم هون بس للمعاينة المحلية
  // (matchingDoctors) بحيث تطابق تماماً شو رح يرجع الباك فعلياً.
  final String? gender;

  DoctorListingModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.departments = const [],
    this.profileImageUrl,
    required this.rating,
    required this.reviewCount,
    required this.workplaceNames,
    this.clinicRefs = const [],
    required this.primaryWorkplaceType,
    this.availabilityStatus,
    this.availableInDays,
    required this.consultationFee,
    required this.offersOnlineConsultation,
    this.educationDegree,
    this.experienceYears,
    this.isFavourite = false,
    this.biography,
    this.gender,
  });

  String get fullName => 'Dr. $firstName $lastName';

  /// اسم أول قسم منتسب له الطبيب، للعرض المختصر ببطاقات اللائحة (كان
  /// قبل subSpecialty) - فاضي إذا الطبيب بلا أقسام مسجّلة.
  String get department => departments.isNotEmpty ? departments.first : '';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  DoctorListingModel copyWith({bool? isFavourite, double? rating, int? reviewCount}) => DoctorListingModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    departments: departments,
    profileImageUrl: profileImageUrl,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    workplaceNames: workplaceNames,
    clinicRefs: clinicRefs,
    primaryWorkplaceType: primaryWorkplaceType,
    availabilityStatus: availabilityStatus,
    availableInDays: availableInDays,
    consultationFee: consultationFee,
    offersOnlineConsultation: offersOnlineConsultation,
    educationDegree: educationDegree,
    experienceYears: experienceYears,
    isFavourite: isFavourite ?? this.isFavourite,
    biography: biography,
    gender: gender,
  );

  factory DoctorListingModel.fromJson(Map<String, dynamic> json) =>
      DoctorListingModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        departments: json['departments'] == null
            ? const []
            : List<String>.from(json['departments'] as List),
        profileImageUrl: json['profileImageUrl'] as String?,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        workplaceNames: List<String>.from(json['workplaceNames'] as List),
        primaryWorkplaceType: json['primaryWorkplaceType'] as String,
        availabilityStatus: json['availabilityStatus'] as String?,
        availableInDays: json['availableInDays'] as int?,
        consultationFee: (json['consultationFee'] as num).toDouble(),
        offersOnlineConsultation:
        json['offersOnlineConsultation'] as bool? ?? false,
        educationDegree: json['educationDegree'] as String?,
        experienceYears: json['experienceYears'] as String?,
        isFavourite: json['isFavourite'] as bool? ?? false,
      );

  /// يبني الموديل من شكل الاستجابة الحقيقي لباقي الـ API (snake_case،
  /// نفس بنية account/career/departments/clinics المستخدمة برد
  /// GET /doctor/profile) - يُستخدم من DoctorListingRepository لما ينضاف
  /// endpoint لائحة الأطباء العامة بالباك (راجع ApiConstants.doctorsPublicList).
  /// ✅ يبني الموديل من الشكل الحقيقي المؤكد لرد GET /doctors (لائحة
  /// عامة) - مختلف عن شكل GET /doctor/profile (self): هون "name" اسم
  /// كامل مدمج (مو first/last منفصلين)، والأقسام (departments) عامة
  /// مستقلة عن العيادة، وكل عيادة معها consultation_fee خاص فيها.
  factory DoctorListingModel.fromApiJson(Map<String, dynamic> json) {
    final fullName = json['name']?.toString().trim() ?? '';
    final spaceIndex = fullName.indexOf(' ');
    final firstName = spaceIndex == -1 ? fullName : fullName.substring(0, spaceIndex);
    final lastName = spaceIndex == -1 ? '' : fullName.substring(spaceIndex + 1);

    final departmentsJson = json['departments'] as List? ?? const [];
    final clinics = json['clinics'] as List? ?? const [];
    final qualifications = json['qualifications'] as List? ?? const [];
    // career قد ما يكون موجود إطلاقاً برد GET /doctors العام (شوهد فقط
    // برد GET /doctor/profile الخاص) - منتعامل معه كاختياري بس نحاول
    // نقرأه لو انضاف لاحقاً بالباك.
    final career = json['career'] as Map<String, dynamic>?;

    // نفضّل رسم أول عيادة فعّالة (active) كسعر افتراضي للعرض، وإلا
    // نرجع لـ online_consultation_fee (رسم الاستشارة عن بعد العام).
    double fee = 0;
    final activeClinic = clinics.cast<Map>().where((c) => c['status'] == 'active').toList();
    final feeSource = activeClinic.isNotEmpty ? activeClinic.first : (clinics.isNotEmpty ? clinics.first as Map : null);
    if (feeSource != null && feeSource['consultation_fee'] != null) {
      fee = double.tryParse('${feeSource['consultation_fee']}') ?? 0;
    } else if (json['online_consultation_fee'] != null) {
      fee = double.tryParse('${json['online_consultation_fee']}') ?? 0;
    }

    return DoctorListingModel(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      // كل الأقسام الحقيقية يلي الطبيب منتسب إلها (doctor_departments)،
      // بلا أي تمييز "رئيسي/فرعي" - الترتيب متل ما رجعه الباك تماماً.
      departments: departmentsJson
          .map((d) => (d as Map)['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      profileImageUrl: json['photo_url']?.toString(),
      rating: 0,
      reviewCount: 0,
      workplaceNames: clinics.map((c) => c['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
      clinicRefs: clinics.cast<Map>().map((c) => DoctorListingClinicRef(
            id: c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}') ?? 0,
            name: c['name']?.toString() ?? '',
            consultationFee: c['consultation_fee'] == null ? null : double.tryParse('${c['consultation_fee']}'),
          )).toList(),
      primaryWorkplaceType: 'clinic',
      consultationFee: fee,
      offersOnlineConsultation: json['online_consultation_fee'] != null,
      educationDegree: qualifications.isNotEmpty ? qualifications.first['degree']?.toString() : null,
      // ✅ إضافة: biography موجودة على المستوى الأعلى مباشرة برد GET
      // /doctors (راجع Postman). experience_years هلق مرجّعة مباشرة
      // برد GET /doctors (راجع DoctorPublicResource::experience_years)
      // فمنقراها من هونيك أولاً، وإلا نرجع لـ career لو موجودة (رد
      // GET /doctor/profile الخاص).
      biography: json['biography']?.toString(),
      experienceYears: json['experience_years'] != null
          ? '${json['experience_years']}'
          : (career?['experience_years'] != null ? '${career!['experience_years']}' : null),
      gender: json['gender']?.toString(),
    );
  }
}


final List<DoctorListingModel> dummyDoctors = [
  DoctorListingModel(id:'1',firstName:'Sarah',lastName:'Jenkins',departments:['Cardiology'],rating:4.9,reviewCount:128,workplaceNames:['City Heart Hospital'],primaryWorkplaceType:'hospital',availabilityStatus:'today',consultationFee:150,offersOnlineConsultation:true,experienceYears:'12',isFavourite:true),
  DoctorListingModel(id:'2',firstName:'Marcus',lastName:'Chen',departments:['General Practice'],rating:4.8,reviewCount:95,workplaceNames:['BlueCare Medical Center'],primaryWorkplaceType:'center',availabilityStatus:'tomorrow',consultationFee:90,offersOnlineConsultation:false,experienceYears:'8'),
  DoctorListingModel(id:'3',firstName:'Emily',lastName:'Thorne',departments:['Dermatology'],rating:4.9,reviewCount:210,workplaceNames:['Skin & Beauty Clinic'],primaryWorkplaceType:'clinic',availabilityStatus:'today',consultationFee:120,offersOnlineConsultation:true,experienceYears:'15'),
  DoctorListingModel(id:'4',firstName:'Ali',lastName:'Khalid',departments:['Orthodontics'],rating:4.7,reviewCount:67,workplaceNames:['Smile Pro Dental Center'],primaryWorkplaceType:'center',availabilityStatus:'in_N_days',availableInDays:3,consultationFee:80,offersOnlineConsultation:false,experienceYears:'6'),
];
