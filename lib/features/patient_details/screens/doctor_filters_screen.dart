import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/doctor_auth/models/department_model.dart';
import '../models/doctor_dummy_data.dart';
import '../view_models/doctor_filters_cubit.dart';
import '../view_models/doctor_filters_state.dart';
import '../view_models/doctor_listing_cubit.dart';

/// Push this to open the Filters screen. It owns its own short-lived
/// [DoctorFiltersCubit], seeded from the doctors already loaded in
/// [DoctorListingCubit], so "Apply Filters (n)" always reflects a real count.
class DoctorFiltersScreen extends StatelessWidget {
  const DoctorFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pool = context.read<DoctorListingCubit>().state.allDoctors;
    return BlocProvider(
      create: (_) => DoctorFiltersCubit(pool),
      child: const _DoctorFiltersView(),
    );
  }
}

class _DoctorFiltersView extends StatelessWidget {
  const _DoctorFiltersView();

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final currentScale = settingsState.fontScale;
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final filters = context.watch<DoctorFiltersCubit>().state;
    final cubit = context.read<DoctorFiltersCubit>();

    double titleSize = 20.sp;
    double sectionSize = 15.sp;
    double bodySize = 13.sp;
    if (currentScale == FontScale.medium) {
      titleSize = 23.sp;
      sectionSize = 17.sp;
      bodySize = 15.sp;
    } else if (currentScale == FontScale.large) {
      titleSize = 26.sp;
      sectionSize = 19.sp;
      bodySize = 17.sp;
    }

    final scaffoldBg = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundBeige;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark
        ? AppColors.darkPrimaryGreen
        : AppColors.primaryGreen;
    final borderColor = isDark ? Colors.white10 : AppColors.borderGrey;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16.w,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close_rounded,
                  color: primaryGreen,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  AppStrings.filtersTitle(context),
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                ),
              ),
              GestureDetector(
                onTap: cubit.reset,
                child: Text(
                  AppStrings.reset(context),
                  style: TextStyle(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SectionTitle(
                      AppStrings.search(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    _SearchField(
                      hint: AppStrings.searchDoctorHint(context),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      bodySize: bodySize,
                      onChanged: cubit.updateSearchQuery,
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          const ['Dr. Smith', 'Pediatrician', 'Mayo Clinic']
                              .map(
                                (tag) => _QuickTagChip(
                                  label: tag,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  bodySize: bodySize,
                                  onTap: () => cubit.applyQuickTag(tag),
                                ),
                              )
                              .toList(),
                    ),
                    SizedBox(height: 24.h),

                    _SectionTitle(
                      AppStrings.location(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    _NearMeButton(
                      label: AppStrings.nearMeGps(context),
                      isActive: filters.nearMeEnabled,
                      primaryGreen: primaryGreen,
                      textColor: textColor,
                      isDark: isDark,
                      bodySize: bodySize,
                      onTap: cubit.toggleNearMe,
                    ),
                    // ⚠️ إزالة عمدية: كان في هون Dropdown لاختيار مدينة/منطقة، بس
                    // العيادات بالباك ما عندها حقل city مهيكل (بس عنوان
                    // نصي حر address) - فالفلتر كان يحدّث الحالة محلياً بس
                    // وما كان يُرسل لأي endpoint فعلياً (لا يوجد query
                    // param اسمه city بالباك أصلاً). بدل ما نخلي عنصر واجهة
                    // "شغال" بالمظهر بس بلا أثر حقيقي، تمت إزالته وخلينا
                    // Near Me (GPS) هو خيار الموقع الوحيد لحد ما تنضاف
                    // بيانات مدينة مهيكلة بالباك.
                    SizedBox(height: 24.h),

                    _SectionTitle(
                      AppStrings.specialty(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    _DropdownRow(
                      label:
                          filters.departmentName ??
                          AppStrings.selectSpecialty(context),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: filters.departmentName == null
                          ? AppColors.textLightGrey
                          : textColor,
                      bodySize: bodySize,
                      onTap: () => _pickDepartment(
                        context: context,
                        title: AppStrings.specialty(context),
                        departments: cubit.departments,
                        onSelected: cubit.setDepartment,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    _SectionTitle(
                      AppStrings.experienceYears(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    _RangeCard(
                      cardBg: cardBg,
                      primaryGreen: primaryGreen,
                      textColor: textColor,
                      bodySize: bodySize,
                      values: filters.experienceRange,
                      min: 0,
                      max: 40,
                      minLabel: AppStrings.min(context),
                      maxLabel: AppStrings.max(context),
                      valueFormatter: (v) => v.round().toString(),
                      onChanged: cubit.setExperienceRange,
                    ),
                    SizedBox(height: 24.h),

                    _SectionTitle(
                      AppStrings.consultationPrice(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          _PriceHistogram(primaryGreen: primaryGreen),
                          SizedBox(height: 4.h),
                          RangeSlider(
                            values: filters.priceRange,
                            min: 0,
                            max: 500,
                            divisions: 20,
                            activeColor: primaryGreen,
                            inactiveColor: primaryGreen.withOpacity(0.15),
                            onChanged: cubit.setPriceRange,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$0',
                                style: TextStyle(
                                  fontSize: bodySize,
                                  color: AppColors.textLightGrey,
                                ),
                              ),
                              Text(
                                '\$500+',
                                style: TextStyle(
                                  fontSize: bodySize,
                                  color: AppColors.textLightGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    _SectionTitle(
                      AppStrings.availability(context),
                      sectionSize,
                      textColor,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleChip(
                            label: AppStrings.today(context),
                            selected:
                                filters.availability ==
                                AvailabilityFilter.today,
                            primaryGreen: primaryGreen,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            bodySize: bodySize,
                            onTap: () =>
                                cubit.setAvailability(AvailabilityFilter.today),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _ToggleChip(
                            label: AppStrings.tomorrow(context),
                            selected:
                                filters.availability ==
                                AvailabilityFilter.tomorrow,
                            primaryGreen: primaryGreen,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            bodySize: bodySize,
                            onTap: () => cubit.setAvailability(
                              AvailabilityFilter.tomorrow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleChip(
                            label: AppStrings.thisWeek(context),
                            selected:
                                filters.availability ==
                                AvailabilityFilter.thisWeek,
                            primaryGreen: primaryGreen,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            bodySize: bodySize,
                            onTap: () => cubit.setAvailability(
                              AvailabilityFilter.thisWeek,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _ToggleChip(
                            label: AppStrings.custom(context),
                            icon: Icons.calendar_today_rounded,
                            selected:
                                filters.availability ==
                                AvailabilityFilter.custom,
                            primaryGreen: primaryGreen,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            bodySize: bodySize,
                            onTap: () => cubit.setAvailability(
                              AvailabilityFilter.custom,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Text(
                      AppStrings.timeSlot(context),
                      style: TextStyle(
                        fontSize: bodySize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLightGrey,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _ToggleChip(
                          label: AppStrings.morning(context),
                          selected: filters.timeSlots.contains(
                            FilterTimeSlot.morning,
                          ),
                          primaryGreen: primaryGreen,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          bodySize: bodySize,
                          compact: true,
                          onTap: () =>
                              cubit.toggleTimeSlot(FilterTimeSlot.morning),
                        ),
                        _ToggleChip(
                          label: AppStrings.afternoon(context),
                          selected: filters.timeSlots.contains(
                            FilterTimeSlot.afternoon,
                          ),
                          primaryGreen: primaryGreen,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          bodySize: bodySize,
                          compact: true,
                          onTap: () =>
                              cubit.toggleTimeSlot(FilterTimeSlot.afternoon),
                        ),
                        _ToggleChip(
                          label: AppStrings.evening(context),
                          selected: filters.timeSlots.contains(
                            FilterTimeSlot.evening,
                          ),
                          primaryGreen: primaryGreen,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          bodySize: bodySize,
                          compact: true,
                          onTap: () =>
                              cubit.toggleTimeSlot(FilterTimeSlot.evening),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                AppStrings.gender(context),
                                sectionSize,
                                textColor,
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  _ToggleChip(
                                    label: AppStrings.male(context),
                                    selected: filters.genders.contains('male'),
                                    primaryGreen: primaryGreen,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    bodySize: bodySize,
                                    compact: true,
                                    onTap: () => cubit.toggleGender('male'),
                                  ),
                                  SizedBox(width: 8.w),
                                  _ToggleChip(
                                    label: AppStrings.female(context),
                                    selected: filters.genders.contains(
                                      'female',
                                    ),
                                    primaryGreen: primaryGreen,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    bodySize: bodySize,
                                    compact: true,
                                    onTap: () => cubit.toggleGender('female'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                AppStrings.sortBy(context),
                                sectionSize,
                                textColor,
                              ),
                              SizedBox(height: 10.h),
                              _DropdownRow(
                                label: _sortLabel(context, filters.sortBy),
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                bodySize: bodySize,
                                icon: Icons.swap_vert_rounded,
                                onTap: () => _pickSort(context, cubit),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- الأزرار السفلية الثابتة ---
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                decoration: BoxDecoration(
                  color: scaffoldBg,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1.w),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cubit.reset,
                        icon: Icon(
                          Icons.filter_alt_off_rounded,
                          color: primaryGreen,
                          size: 18.sp,
                        ),
                        label: Text(
                          AppStrings.clearAll(context),
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: bodySize,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: primaryGreen, width: 1.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _applyFilters(context, isEn),
                        icon: Icon(
                          Icons.check_circle_rounded,
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.white,
                          size: 18.sp,
                        ),
                        label: Text(
                          AppStrings.applyFilters(
                            context,
                            filters.matchingCount,
                          ),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: bodySize,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بتطلب من الباك الأطباء المطابقين للفلاتر المختارة (GET /doctors مع
  /// الفلاتر) وبتستبدل فيهم لائحة الأطباء بشاشة اللستنغ - أي طبيب ما
  /// طابق عالباك بيختفي فعلياً، مو بس محجوب محلياً. بتعرض مؤشر تحميل
  /// أثناء الطلب، وبترجع رسالة خطأ وتضل فاتحة الشاشة (بدون إغلاق) لو
  /// الطلب فشل حتى يقدر المستخدم يعدّل ويعيد المحاولة.
  Future<void> _applyFilters(BuildContext context, bool isEn) async {
    final filtersCubit = context.read<DoctorFiltersCubit>();
    final listingCubit = context.read<DoctorListingCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await filtersCubit.applyFilters();
      listingCubit.applyBackendFilters(results);
      if (!context.mounted) return;
      Navigator.pop(context); // يسكّر مؤشر التحميل
      Navigator.pop(context); // يسكّر شاشة الفلاتر
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(
        context,
      ); // يسكّر مؤشر التحميل بس، وبتضل شاشة الفلاتر مفتوحة
      final message = e is ApiException
          ? e.message
          : (isEn
                ? 'Could not reach the server, please try again.'
                : 'تعذّر الاتصال بالسيرفر، حاول مجدداً.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _sortLabel(BuildContext context, SortOption option) {
    switch (option) {
      case SortOption.bestMatch:
        return AppStrings.bestMatch(context);
      case SortOption.priceLowToHigh:
        return '${AppStrings.fee(context)} ↑';
      case SortOption.priceHighToLow:
        return '${AppStrings.fee(context)} ↓';
      case SortOption.topRated:
        return AppStrings.reviews(context);
      case SortOption.mostExperienced:
        return AppStrings.experienceYears(context);
    }
  }

  void _pickSort(BuildContext context, DoctorFiltersCubit cubit) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values
              .map(
                (option) => ListTile(
                  title: Text(_sortLabel(context, option)),
                  onTap: () {
                    cubit.setSortBy(option);
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _pickFromList({
    required BuildContext context,
    required String title,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
              ),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                onTap: () {
                  onSelected(option);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same bottom-sheet picker as [_pickFromList], but backed by the real
  /// departments loaded from GET /departments (id + name) instead of a
  /// hardcoded string list, so the selected value maps directly to a real
  /// department_id with no fuzzy name matching needed.
  void _pickDepartment({
    required BuildContext context,
    required String title,
    required List<DepartmentModel> departments,
    required ValueChanged<DepartmentModel?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
              ),
            ),
            if (departments.isEmpty)
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'لا توجد أقسام متاحة'
                      : 'No departments available',
                ),
              ),
            ...departments.map(
              (department) => ListTile(
                title: Text(department.name),
                onTap: () {
                  onSelected(department);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const _SectionTitle(this.text, this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final double bodySize;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.hint,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.bodySize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: TextStyle(color: textColor, fontSize: bodySize),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textLightGrey,
          fontSize: bodySize,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textLightGrey,
          size: 20.sp,
        ),
        filled: true,
        fillColor: cardBg,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _QuickTagChip extends StatelessWidget {
  final String label;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final double bodySize;
  final VoidCallback onTap;

  const _QuickTagChip({
    required this.label,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.bodySize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: bodySize,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NearMeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color primaryGreen;
  final Color textColor;
  final bool isDark;
  final double bodySize;
  final VoidCallback onTap;

  const _NearMeButton({
    required this.label,
    required this.isActive,
    required this.primaryGreen,
    required this.textColor,
    required this.isDark,
    required this.bodySize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isActive ? primaryGreen : primaryGreen.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14.r),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location_rounded,
              size: 18.sp,
              color: isActive
                  ? (isDark ? AppColors.darkBackground : AppColors.white)
                  : primaryGreen,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: bodySize,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? (isDark ? AppColors.darkBackground : AppColors.white)
                    : primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final double bodySize;
  final IconData icon;
  final VoidCallback onTap;

  const _DropdownRow({
    required this.label,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.bodySize,
    this.icon = Icons.keyboard_arrow_down_rounded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: bodySize,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, color: AppColors.textLightGrey, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final Color cardBg;
  final Color primaryGreen;
  final Color textColor;
  final double bodySize;
  final RangeValues values;
  final double min;
  final double max;
  final String minLabel;
  final String maxLabel;
  final String Function(double) valueFormatter;
  final ValueChanged<RangeValues> onChanged;

  const _RangeCard({
    required this.cardBg,
    required this.primaryGreen,
    required this.textColor,
    required this.bodySize,
    required this.values,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    required this.valueFormatter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: primaryGreen,
            inactiveColor: primaryGreen.withOpacity(0.15),
            onChanged: onChanged,
          ),
          Row(
            children: [
              Expanded(
                child: _ReadonlyValueBox(
                  label: minLabel,
                  value: valueFormatter(values.start),
                  textColor: textColor,
                  bodySize: bodySize,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ReadonlyValueBox(
                  label: maxLabel,
                  value: valueFormatter(values.end),
                  textColor: textColor,
                  bodySize: bodySize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadonlyValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final double bodySize;

  const _ReadonlyValueBox({
    required this.label,
    required this.value,
    required this.textColor,
    required this.bodySize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bodySize * 0.85,
            color: AppColors.textLightGrey,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGrey, width: 1.w),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: bodySize,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceHistogram extends StatelessWidget {
  final Color primaryGreen;
  const _PriceHistogram({required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    // تمثيل بصري بسيط (زخرفي) لتوزّع الأسعار، مطابق للتصميم في فيغما
    const heights = [0.25, 0.4, 0.75, 1.0, 0.6, 0.3];
    return SizedBox(
      height: 60.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights
            .map(
              (h) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 60.h * h,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.35 + (0.5 * h)),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color primaryGreen;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final double bodySize;
  final bool compact;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.primaryGreen,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.bodySize,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16.w : 8.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: selected ? primaryGreen.withOpacity(0.18) : cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: selected ? primaryGreen : borderColor,
          width: 1.w,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16.sp,
              color: selected ? primaryGreen : AppColors.textLightGrey,
            ),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: bodySize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primaryGreen : textColor,
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: compact ? child : SizedBox(width: double.infinity, child: child),
    );
  }
}

