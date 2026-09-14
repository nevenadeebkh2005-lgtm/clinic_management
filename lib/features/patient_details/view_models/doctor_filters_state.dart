import 'package:flutter/material.dart';
import '../models/doctor_dummy_data.dart';

enum AvailabilityFilter { none, today, tomorrow, thisWeek, custom }

enum FilterTimeSlot { morning, afternoon, evening }

enum SortOption { bestMatch, priceLowToHigh, priceHighToLow, topRated, mostExperienced }

class DoctorFiltersState {
  final List<DoctorListingModel> pool;

  final String searchQuery;
  final bool nearMeEnabled;
  final int? departmentId; // real Department.id from GET /departments, or null = any
  final String? departmentName; // display name matching departmentId, used for local preview
  final RangeValues experienceRange;
  final RangeValues priceRange;
  final AvailabilityFilter availability;
  final Set<FilterTimeSlot> timeSlots;
  final Set<String> genders; // 'male'/'female' values, matches DoctorListingModel.gender
  final SortOption sortBy;

  const DoctorFiltersState({
    required this.pool,
    this.searchQuery = '',
    this.nearMeEnabled = false,
    this.departmentId,
    this.departmentName,
    this.experienceRange = const RangeValues(0, 40),
    this.priceRange = const RangeValues(0, 500),
    this.availability = AvailabilityFilter.none,
    this.timeSlots = const {},
    this.genders = const {},
    this.sortBy = SortOption.bestMatch,
  });

  factory DoctorFiltersState.initial(List<DoctorListingModel> pool) =>
      DoctorFiltersState(pool: pool);

  /// Doctors from [pool] that satisfy every filter currently set. Only
  /// matches against fields that actually exist on [DoctorListingModel] —
  /// near-me has no backing field to preview locally (it needs a live GPS
  /// call), so it's intentionally not applied here rather than faked.
  List<DoctorListingModel> get matchingDoctors {
    return pool.where((doc) {
      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          doc.fullName.toLowerCase().contains(query) ||
          doc.departments.any((d) => d.toLowerCase().contains(query));

      final matchesDepartment = departmentName == null ||
          doc.departments.any((d) => d.toLowerCase() == departmentName!.toLowerCase());

      final years = int.tryParse(doc.experienceYears ?? '');
      final matchesExperience = years == null ||
          (years >= experienceRange.start && years <= experienceRange.end);

      final matchesPrice =
          doc.consultationFee >= priceRange.start && doc.consultationFee <= priceRange.end;

      final matchesGender = genders.isEmpty ||
          genders.length > 1 || // both selected = no restriction, same as sending no `gender` param
          doc.gender == null ||
          genders.contains(doc.gender);

      final matchesAvailability = switch (availability) {
        AvailabilityFilter.none => true,
        AvailabilityFilter.today => doc.availabilityStatus == 'today',
        AvailabilityFilter.tomorrow => doc.availabilityStatus == 'tomorrow',
        AvailabilityFilter.thisWeek => doc.availabilityStatus == 'today' ||
            doc.availabilityStatus == 'tomorrow' ||
            (doc.availabilityStatus == 'in_N_days' && (doc.availableInDays ?? 99) <= 7),
        AvailabilityFilter.custom => true,
      };

      return matchesQuery &&
          matchesDepartment &&
          matchesExperience &&
          matchesPrice &&
          matchesGender &&
          matchesAvailability;
    }).toList();
  }

  int get matchingCount => matchingDoctors.length;

  DoctorFiltersState copyWith({
    String? searchQuery,
    bool? nearMeEnabled,
    int? departmentId,
    String? departmentName,
    bool clearDepartment = false,
    RangeValues? experienceRange,
    RangeValues? priceRange,
    AvailabilityFilter? availability,
    Set<FilterTimeSlot>? timeSlots,
    Set<String>? genders,
    SortOption? sortBy,
  }) {
    return DoctorFiltersState(
      pool: pool,
      searchQuery: searchQuery ?? this.searchQuery,
      nearMeEnabled: nearMeEnabled ?? this.nearMeEnabled,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      departmentName: clearDepartment ? null : (departmentName ?? this.departmentName),
      experienceRange: experienceRange ?? this.experienceRange,
      priceRange: priceRange ?? this.priceRange,
      availability: availability ?? this.availability,
      timeSlots: timeSlots ?? this.timeSlots,
      genders: genders ?? this.genders,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
