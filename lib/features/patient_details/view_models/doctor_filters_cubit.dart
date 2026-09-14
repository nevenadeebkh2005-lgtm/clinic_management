import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/doctor_auth/data/departments_repository.dart';
import '../../auth/doctor_auth/models/department_model.dart';
import '../data/doctor_listing_repository.dart';
import '../models/doctor_dummy_data.dart';
import 'doctor_filters_state.dart';

class DoctorFiltersCubit extends Cubit<DoctorFiltersState> {
  final DoctorListingRepository _listingRepository;
  final DepartmentsRepository _departmentsRepository;

  /// أقسام حقيقية من GET /departments (id + name) - هاد المصدر الوحيد
  /// للأقسام بشاشة الفلاتر (ما في قائمة تخصصات وهمية/hardcoded متل قبل).
  /// بتتحمّل مرة وحدة وقت فتح شاشة الفلاتر بدل ما ننتظرها وقت الضغط
  /// عالـ Apply.
  List<DepartmentModel> _departments = const [];
  List<DepartmentModel> get departments => _departments;

  DoctorFiltersCubit(
    List<DoctorListingModel> pool, {
    DoctorListingRepository? listingRepository,
    DepartmentsRepository? departmentsRepository,
  }) : _listingRepository = listingRepository ?? DoctorListingRepository(),
       _departmentsRepository =
           departmentsRepository ?? DepartmentsRepository(),
       super(DoctorFiltersState.initial(pool)) {
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    _departments = await _departmentsRepository.getDepartments();
  }

  void updateSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void applyQuickTag(String tag) => emit(state.copyWith(searchQuery: tag));

  void toggleNearMe() =>
      emit(state.copyWith(nearMeEnabled: !state.nearMeEnabled));

  void setDepartment(DepartmentModel? department) => emit(
    department == null
        ? state.copyWith(clearDepartment: true)
        : state.copyWith(
            departmentId: department.id,
            departmentName: department.name,
          ),
  );

  void setExperienceRange(RangeValues range) =>
      emit(state.copyWith(experienceRange: range));

  void setPriceRange(RangeValues range) =>
      emit(state.copyWith(priceRange: range));

  void setAvailability(AvailabilityFilter value) {
    // Tapping the same availability chip again clears it back to "none".
    final next = state.availability == value ? AvailabilityFilter.none : value;
    emit(state.copyWith(availability: next));
  }

  void toggleTimeSlot(FilterTimeSlot slot) {
    final next = Set<FilterTimeSlot>.from(state.timeSlots);
    next.contains(slot) ? next.remove(slot) : next.add(slot);
    emit(state.copyWith(timeSlots: next));
  }

  void toggleGender(String gender) {
    final next = Set<String>.from(state.genders);
    next.contains(gender) ? next.remove(gender) : next.add(gender);
    emit(state.copyWith(genders: next));
  }

  void setSortBy(SortOption option) => emit(state.copyWith(sortBy: option));

  void reset() => emit(DoctorFiltersState.initial(state.pool));

  /// بتبني query params من الفلاتر المختارة حالياً وبتطلب من الباك
  /// الأطباء المطابقين فعلياً (GET /doctors مع الفلاتر) بدل ما نصفّي
  /// محلياً على [state.pool] المحدود. لأي فلتر بقيمته الافتراضية (يعني
  /// المستخدم ما لمسه) ما منرسل الـ param إطلاقاً، حتى ما نقيّد الطلب
  /// بشي المستخدم ما طلبه فعلياً.
  Future<List<DoctorListingModel>> applyFilters() async {
    final query = <String, dynamic>{};

    final name = state.searchQuery.trim();
    if (name.isNotEmpty) query['name'] = name;

    if (state.departmentId != null) {
      query['department_id'] = state.departmentId.toString();
    }

    if (state.experienceRange.start > 0) {
      query['experience_min'] = state.experienceRange.start.round().toString();
    }
    if (state.experienceRange.end < 40) {
      query['experience_max'] = state.experienceRange.end.round().toString();
    }

    if (state.priceRange.start > 0)
      query['price_min'] = state.priceRange.start.toString();
    if (state.priceRange.end < 500)
      query['price_max'] = state.priceRange.end.toString();

    final availabilityValue = switch (state.availability) {
      AvailabilityFilter.today => 'today',
      AvailabilityFilter.tomorrow => 'tomorrow',
      AvailabilityFilter.thisWeek => 'this_week',
      // ما في date picker موصول لـ "Custom" لسا (custom_date إلزامي
      // بالباك لما availability=custom) - منتجاهله بدل ما نبعت طلب
      // ناقص الباك بيرفضه. AvailabilityFilter.none بردو بلا قيمة.
      AvailabilityFilter.custom => null,
      AvailabilityFilter.none => null,
    };
    if (availabilityValue != null) query['availability'] = availabilityValue;

    if (state.timeSlots.isNotEmpty) {
      // مفتاح الـ query لازم يكون بصيغة array PHP الصريحة time_slot[]،
      // لأنو Dio بشكل افتراضي بيكرر نفس المفتاح لكل عنصر بلائحة
      // (time_slot=morning&time_slot=afternoon) وهيك PHP/Laravel
      // بياخد آخر قيمة بس وبيعتبرها string مو array. بإضافة [] يدوياً
      // للمفتاح، الناتج بيصير time_slot[]=morning&time_slot[]=afternoon
      // يلي Laravel فعلياً بيفهمه كـ array.
      query['time_slot[]'] = state.timeSlots.map((s) => s.name).toList();
    }

    // الباك بيقبل قيمة gender وحدة بس (male أو female عبر whereHas
    // user.gender) - لو المستخدم اختار الجنسين معاً بنفس الوقت فهاد
    // عملياً معناه "بلا فلترة جنس" فما منرسل الـ param إطلاقاً، تماماً
    // متل أي فلتر تاني بقيمته الافتراضية.
    if (state.genders.length == 1) {
      query['gender'] = state.genders.first;
    }

    query['sort'] = switch (state.sortBy) {
      SortOption.bestMatch => 'best_match',
      SortOption.priceLowToHigh => 'fee_asc',
      SortOption.priceHighToLow => 'fee_desc',
      SortOption.mostExperienced => 'experience',
      // الباك لسا ما عندو ترتيب حسب التقييمات (ما في جدول reviews) -
      // منرجع لـ best_match بدل ما نبعت قيمة الباك رح يرفضها.
      SortOption.topRated => 'best_match',
    };

    if (state.nearMeEnabled) {
      final position = await _tryGetCurrentPosition();
      if (position != null) {
        query['latitude'] = position.latitude.toString();
        query['longitude'] = position.longitude.toString();
      }
    }

    return _listingRepository.searchDoctors(query);
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      // "قربي مني" هيك بتنطبّق بهدوء بلا إحداثيات بدل ما توقف كل
      // الفلاتر التانية عن الشغل لمجرد ما قدرنا ناخد الموقع.
      return null;
    }
  }
}
