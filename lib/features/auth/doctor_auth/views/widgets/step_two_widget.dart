import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/location_pick_field.dart';
import '../../view_models/register_cubit.dart';
import '../../view_models/register_state.dart';

class StepTwoWidgets extends StatelessWidget {
  const StepTwoWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final cubit = context.read<DoctorRegisterCubit>();

    return BlocBuilder<DoctorRegisterCubit, DoctorRegisterState>(
      builder: (context, state) {
        final currentGender = state.model.gender ?? 'male';

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),
              Text(
                AppStrings.personalDetails(context),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: themeColor),
              ),
              SizedBox(height: 5.h),
              Text(
                AppStrings.providePersonalInfo(context),
                style: TextStyle(fontSize: 13.sp, color: AppColors.textLightGrey),
              ),
              SizedBox(height: 25.h),

              Text(AppStrings.dateOfBirth(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                controller: TextEditingController(text: state.model.dateOfBirth),
                key: ValueKey(state.model.dateOfBirth),
                readOnly: true,
                decoration: InputDecoration(
                  hintText: AppStrings.dateOfBirthHint(context),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaleFactor: 1.0,
                        ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppColors.primaryGreen,
                              ),
                            ),
                        child: child!,
                      ));
                    },
                  );
                  if (pickedDate != null) {
                    final formattedDate =
                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    cubit.updateRegisterModel(state.model.copyWith(dateOfBirth: formattedDate));
                  }
                },
              ),
              SizedBox(height: 20.h),

              Text(AppStrings.gender(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    _buildGenderButton(context, cubit, state, currentGender, value: 'male', label: AppStrings.male(context)),
                    _buildGenderButton(context, cubit, state, currentGender, value: 'female', label: AppStrings.female(context)),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              Text(AppStrings.homeAddress(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                initialValue: state.model.homeAddress,
                cursorColor: AppColors.primaryGreen,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppStrings.homeAddress(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(12.w),
                ),
                onChanged: (value) => cubit.updateRegisterModel(state.model.copyWith(homeAddress: value)),
              ),
              LocationPickField(
                latitude: state.model.latitude,
                longitude: state.model.longitude,
                onPicked: (lat, lng) => cubit.updateRegisterModel(
                  state.model.copyWith(latitude: lat, longitude: lng),
                ),
              ),
              SizedBox(height: 20.h),

              Text(AppStrings.phoneNumber(context), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 6.h),
              TextFormField(
                initialValue: state.model.phone,
                cursorColor: AppColors.primaryGreen,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: AppStrings.phoneHint(context),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                onChanged: (value) => cubit.updateRegisterModel(state.model.copyWith(phone: value)),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderButton(BuildContext context, DoctorRegisterCubit cubit, DoctorRegisterState state, String currentGender,
      {required String value, required String label}) {
    final isSelected = currentGender == value;
    final themeColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => cubit.updateRegisterModel(state.model.copyWith(gender: value)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? themeColor : AppColors.textLightGrey,
            ),
          ),
        ),
      ),
    );
  }
}
