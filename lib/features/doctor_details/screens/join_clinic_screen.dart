import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings_doctor.dart';
import '../../../core/widgets/location_pick_field.dart';
import '../data/doctor_repository.dart';

/// شاشة "إضافة عيادة" (طبيب مسجّل أصلاً وبدو ينضم أو ينشئ عيادة ثانية).
///
/// ✅ 20/8: وحّدنا الشكل بالكامل مع خطوة "Clinic Setup" بالريجستر
/// (step_four_widget.dart) - نفس التسميات/الأيقونات/الـ upload box.
/// كمان شلنا خطوة "البحث عن العيادة بالـ ID + تأكيد" القديمة: صار وضع
/// Join حقل واحد "Clinic Code" + رسم الكشف وبس، بلا أي lookup مسبق،
/// بالضبط متل الريجستر (الباك بياخد clinic_code مباشرة بدون حاجة
/// للتحقق منها قبل الإرسال). وضع "Create Clinic" حقيقي 100% هلق
/// (POST /doctor/profile/clinics/create).
class JoinClinicScreen extends StatefulWidget {
  final List<int> alreadyJoinedClinicIds;

  const JoinClinicScreen({super.key, this.alreadyJoinedClinicIds = const []});

  @override
  State<JoinClinicScreen> createState() => _JoinClinicScreenState();
}

class _JoinClinicScreenState extends State<JoinClinicScreen> {
  final DoctorRepository _doctorRepository = DoctorRepository();
  final ImagePicker _picker = ImagePicker();

  String _mode = 'join_clinic';
  bool _isSubmitting = false;

  // --- Join mode ---
  final TextEditingController _clinicCodeController = TextEditingController();
  final TextEditingController _joinFeeController = TextEditingController();

  // --- Create mode ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _createFeeController = TextEditingController();
  double? _latitude;
  double? _longitude;
  Uint8List? _licenseBytes;
  String? _licenseFileName;

  @override
  void dispose() {
    _clinicCodeController.dispose();
    _joinFeeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _createFeeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _clinicCodeController.text.trim();
    final fee = double.tryParse(_joinFeeController.text.trim());
    if (code.isEmpty || fee == null) {
      _showMessage('عبّي كود العيادة ورسم الكشف');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _doctorRepository.joinClinic(clinicCode: code, consultationFee: fee);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickLicense() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _licenseBytes = bytes;
      _licenseFileName = file.name;
    });
  }

  Future<void> _createClinic() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final fee = double.tryParse(_createFeeController.text.trim());
    if (name.isEmpty || address.isEmpty || phone.isEmpty || fee == null) {
      _showMessage('عبّي كل الحقول المطلوبة (بما فيها رسم الكشف)');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _doctorRepository.createClinic(
        name: name,
        address: address,
        phone: phone,
        consultationFee: fee,
        licenseBytes: _licenseBytes,
        licenseFileName: _licenseFileName,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(Object e) => _showMessage('$e');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFFC0392B)));
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final themeColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: themeColor),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(DoctorStrings.joinClinic(context),
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: themeColor)),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),

                  // --- اختيار الوضع (نفس ستايل step_four_widget.dart) ---
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        _buildModeButton(context, themeColor, value: 'join_clinic', label: DoctorStrings.joinExistingClinicMode(context)),
                        _buildModeButton(context, themeColor, value: 'create_clinic', label: DoctorStrings.createNewClinicMode(context)),
                      ],
                    ),
                  ),
                  SizedBox(height: 25.h),

                  if (_mode == 'join_clinic') ...[
                    Text('Clinic Code', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _clinicCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter the clinic code',
                        prefixIcon: const Icon(Icons.local_hospital_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Temporary: ask your clinic admin for its code. This will be replaced with a search field once available.',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textLightGrey),
                    ),
                    SizedBox(height: 15.h),
                    Text('Your Consultation Fee at this Clinic', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _joinFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '20',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                    SizedBox(height: 25.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _join,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                        child: Text(DoctorStrings.confirmJoin(context), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ] else ...[
                    // --- create_clinic (نفس حقول step_four_widget.dart حرفياً) ---
                    Text('Clinic Name', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: 'Clinic name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                    ),
                    SizedBox(height: 15.h),
                    Text('Clinic Address', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(hintText: 'Clinic address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                    ),
                    LocationPickField(
                      latitude: _latitude,
                      longitude: _longitude,
                      label: 'تحديد موقع العيادة من الخريطة',
                      onPicked: (lat, lng) => setState(() {
                        _latitude = lat;
                        _longitude = lng;
                      }),
                    ),
                    SizedBox(height: 15.h),
                    Text('Clinic Phone', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(hintText: 'Clinic phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
                    ),
                    SizedBox(height: 15.h),
                    Text('Consultation Fee at this Clinic', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _createFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '20',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text('Clinic License', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8.h),
                    _buildUploadBox(context, themeColor, _licenseBytes, _pickLicense),
                    SizedBox(height: 25.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _createClinic,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
                        child: const Text('Create Clinic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'رح تنحفظ العيادة بحالة "قيد المراجعة" لحد ما يوافق عليها الأدمن.',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textLightGrey),
                    ),
                  ],
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            if (_isSubmitting)
              Container(color: Colors.black.withOpacity(0.15), child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  // --- نفس _buildModeButton بالضبط من step_four_widget.dart ---
  Widget _buildModeButton(BuildContext context, Color themeColor, {required String value, required String label}) {
    final isSelected = _mode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = value),
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

  // --- نفس _buildUploadBox بالضبط من step_four_widget.dart / step_three_widget.dart ---
  Widget _buildUploadBox(BuildContext context, Color themeColor, Uint8List? bytes, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: bytes == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: themeColor, size: 30.sp),
            SizedBox(height: 8.h),
            Text('Upload Image', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: themeColor)),
          ],
        )
            : Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.memory(bytes, width: double.infinity, height: 120.h, fit: BoxFit.cover),
            ),
            const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40)),
          ],
        ),
      ),
    );
  }
}
