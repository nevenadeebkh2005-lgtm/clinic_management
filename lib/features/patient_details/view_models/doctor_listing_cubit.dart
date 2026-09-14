import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../data/doctor_listing_repository.dart';
import '../data/doctor_engagement_repository.dart';
import '../models/doctor_dummy_data.dart';
import 'doctor_listing_state.dart';

class DoctorListingCubit extends Cubit<DoctorListingState> {
  final DoctorListingRepository _repository;
  final DoctorEngagementRepository _engagementRepository;

  DoctorListingCubit(
    List<DoctorListingModel> initialDoctors, {
    DoctorListingRepository? repository,
    DoctorEngagementRepository? engagementRepository,
  }) : _repository = repository ?? DoctorListingRepository(),
       _engagementRepository = engagementRepository ?? DoctorEngagementRepository(),
       super(DoctorListingState.initial(initialDoctors)) {
    // The search field's controller lives here, in the Cubit, instead of
    // being rebuilt on every state emission inside the screen's build().
    // Recreating a TextEditingController on every keystroke (as the old
    // screen did) drops the cursor position and breaks IME composition —
    // especially noticeable typing Arabic. A single controller with a
    // proper lifecycle fixes that.
    searchController.addListener(() {
      if (searchController.text != state.searchQuery) {
        updateSearchQuery(searchController.text);
      }
    });
  }

  final TextEditingController searchController = TextEditingController();

  /// يجيب الأطباء الحقيقيين المسجّلين فعلياً بالتطبيق (راجع ملاحظة
  /// DoctorListingRepository). بتستبدل أي بيانات أولية كانت موجودة
  /// (حتى لو كانت dummy لأغراض العرض المؤقت) بمجرد ما يوصل الرد.
  Future<void> loadDoctors() async {
    final doctors = await _repository.getDoctors();
    emit(
      state.copyWith(
        allDoctors: doctors,
        favCount: doctors.where((d) => d.isFavourite).length,
      ),
    );
    _filterAndSearch();
    // ⚠️ GET /doctors (لائحة عامة) ما بيرجع rating/reviewCount إطلاقاً
    // (موديول DoctorEngagement انضاف لاحقاً) - فمنجيب ملخص كل طبيب
    // (GET /doctors/{id}/reviews/summary - عام) بالتوازي ومنحدّث
    // اللائحة فيهن بعد ما توصل، بدل ما تضل صفر بالكرت/الهوم.
    unawaited(_loadRatingSummaries(doctors));
  }

  Future<void> _loadRatingSummaries(List<DoctorListingModel> doctors) async {
    final results = await Future.wait(
      doctors.map((doctor) async {
        final doctorId = int.tryParse(doctor.id);
        if (doctorId == null) return doctor;
        try {
          final summary = await _engagementRepository.getRatingSummary(doctorId);
          return doctor.copyWith(
            rating: summary.averageRating ?? 0,
            reviewCount: summary.totalReviews,
          );
        } catch (_) {
          return doctor;
        }
      }),
    );

    if (isClosed) return;
    emit(state.copyWith(allDoctors: results));
    _filterAndSearch();
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }

  void changeTab(int index) {
    emit(state.copyWith(currentIndex: index));
  }

  void updateFilter(String filter) {
    emit(state.copyWith(selectedFilter: filter));
    _filterAndSearch();
  }

  void updateSearchQuery(String query) {
    if (searchController.text != query) {
      searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    emit(state.copyWith(searchQuery: query));
    _filterAndSearch();
  }

  /// Applied by the Filters screen when the user taps "Apply Filters":
  /// switches to the full (non-favourites) list, jumps to the Doctors tab,
  /// and carries over the specialty + search query that were chosen there.
  void applyExternalFilters({
    String? subSpecialty,
    required String searchQuery,
  }) {
    emit(
      state.copyWith(
        showingAll: true,
        currentIndex: 1,
        selectedFilter: subSpecialty ?? AppStrings.allSpecialtiesValue,
        searchQuery: searchQuery,
      ),
    );
    if (searchController.text != searchQuery) {
      searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }
    _filterAndSearch();
  }

  /// بتستبدل لائحة الأطباء المعروضة بالنتيجة الحقيقية يلي رجعها الباك
  /// لطلب البحث المفلتر (GET /doctors مع query params الفلاتر) - أي
  /// طبيب ما رجعه الباك بيختفي فعلياً من الشاشة، مو بس محجوب بفلترة
  /// محلية إضافية فوق لائحة قديمة. مختلفة عن [applyExternalFilters] يلي
  /// كانت بس بتمرر subSpecialty/searchQuery وتصفّي محلياً على
  /// [DoctorListingState.allDoctors] الأصلية.
  void applyBackendFilters(List<DoctorListingModel> doctors) {
    emit(
      state.copyWith(
        allDoctors: doctors,
        visibleDoctors: doctors,
        favCount: doctors.where((d) => d.isFavourite).length,
        showingAll: true,
        currentIndex: 1,
        selectedFilter: AppStrings.allSpecialtiesValue,
        searchQuery: '',
      ),
    );
    if (searchController.text.isNotEmpty) {
      searchController.clear();
    }
  }

  void toggleShowingAll() {
    emit(state.copyWith(showingAll: !state.showingAll));
    _filterAndSearch();
  }

  /// ⚠️ منعمل تحديث متفائل (Optimistic) فوري بالواجهة، وبعدها ننادي
  /// الباك فعلياً (POST /favorite/toggle) - ولو فشل منرجع الحالة
  /// القديمة (Rollback). قبل هيك كانت هاي الدالة محلية بس وما كانت
  /// تنادي الباك إطلاقاً، فالتفضيل كان يضيع أول ما يعمل refresh.
  Future<void> toggleFavourite(String id) async {
    final doctorId = int.tryParse(id);
    if (doctorId == null) return;

    final previousDoctors = state.allDoctors;
    final optimisticDoctors = previousDoctors
        .map((doc) => doc.id == id ? doc.copyWith(isFavourite: !doc.isFavourite) : doc)
        .toList();

    emit(state.copyWith(
      allDoctors: optimisticDoctors,
      favCount: optimisticDoctors.where((d) => d.isFavourite).length,
    ));
    _filterAndSearch();

    try {
      final isFavorite = await _engagementRepository.toggleFavorite(doctorId);
      if (isClosed) return;
      final confirmedDoctors = state.allDoctors
          .map((doc) => doc.id == id ? doc.copyWith(isFavourite: isFavorite) : doc)
          .toList();
      emit(state.copyWith(
        allDoctors: confirmedDoctors,
        favCount: confirmedDoctors.where((d) => d.isFavourite).length,
      ));
      _filterAndSearch();
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        allDoctors: previousDoctors,
        favCount: previousDoctors.where((d) => d.isFavourite).length,
      ));
      _filterAndSearch();
    }
  }

  void _filterAndSearch() {
    final pool = state.showingAll
        ? state.allDoctors
        : state.allDoctors.where((d) => d.isFavourite).toList();

    final query = state.searchQuery.trim().toLowerCase();

    final filtered = pool.where((doc) {
      final matchQuery =
          query.isEmpty ||
          doc.fullName.toLowerCase().contains(query) ||
          doc.departments.any((d) => d.toLowerCase().contains(query));

      final matchFilter =
          !state.showingAll ||
          state.selectedFilter == AppStrings.allSpecialtiesValue ||
          doc.departments.any(
            (d) => d.toLowerCase() == state.selectedFilter.toLowerCase(),
          );

      return matchQuery && matchFilter;
    }).toList();

    emit(state.copyWith(visibleDoctors: filtered));
  }
}
