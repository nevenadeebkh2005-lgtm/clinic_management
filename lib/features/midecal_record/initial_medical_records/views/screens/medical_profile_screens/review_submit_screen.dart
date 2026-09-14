import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// --- Models ---
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/setting.dart';
import '../../../../../../core/cubits/medical_record_status_cubit.dart';
// --- Widgets ---
import '../../../models/review_models.dart';
import '../../../view_models/review_submit_cubit.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/step_progress_bar.dart';
import '../../widgets/medical_profile_widgets/review/review_section_card.dart';

// =============================================
// الشاشة الرئيسية - Medical Profile / Step 4
// Review & Submit
//
// ملاحظة معمارية: ما في نداء "إرسال نهائي" هون لأنه كل قسم (تاريخ
// مرضي/أدوية/ملفات) انحفظ فوراً بالباك وقت إضافته بالخطوات
// السابقة. هاي الشاشة بترجع نسخة طازجة (GET) للمراجعة بس، وزر
// "Confirm & Submit" هلق بيرجعك لنفس MainLayoutScreen يلي فتحت منه
// هالمعالج (popUntil لأقرب Route بالستاك) بدل ما يفتح شاشة
// MedicalOverviewScreen جديدة بمعزل عن الـ BottomNav.
//
// ⚠️ currentUserJson (بيانات كارد المريض العلوي) مو متوفرة بهاد
// الشاشة - مررها هون إذا صار عندك وصول إلها بهاد النقطة (مثلاً من
// AuthCubit عندكم)، وإلا الكارد بيعرض دعوة إكمال البروفايل مؤقتاً.
//
// ⚠️ Basic Info (الاسم، تاريخ الميلاد...) ضلت ثابتة (mock) لأنه
// ما في عندي أي endpoint لبروفايل المريض نفسه (غير سجله الطبي) -
// لازم تحدد لي وين هاي البيانات محفوظة بالباك حتى أربطها.
// =============================================
class ReviewSubmitScreen extends StatelessWidget {
  const ReviewSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewSubmitCubit()..loadRecord(),
      child: const _ReviewSubmitView(),
    );
  }
}

class _ReviewSubmitView extends StatelessWidget {
  const _ReviewSubmitView();

  // --- Basic Info: ثابتة مؤقتاً - بانتظار endpoint بروفايل المريض ---
  static const List<InfoField> _basicInfoFields = [
    InfoField(label: 'Full Legal Name', value: 'Jonathan Edward Doe'),
    InfoField(label: 'Date of Birth', value: 'August 14, 1982'),
    InfoField(label: 'Sex Assigned at Birth', value: 'Male'),
    InfoField(label: 'Phone Number', value: '(555) 019-2837'),
    InfoField(
      label: 'Primary Address',
      value: '1248 Evergreen Terrace, Suite 4B\nSpringfield, OR 97477',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: BlocConsumer<ReviewSubmitCubit, ReviewSubmitState>(
        listener: (context, state) {
          if (state.status == ReviewSubmitStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ReviewSubmitStatus.loading ||
              state.status == ReviewSubmitStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, theme, state);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        AppStrings.medicalProfileTitle(context),
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 25 * scaleFactor,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ReviewSubmitState state) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;

    final allergies = state.allergies.map((a) => AllergyChip(name: a.allergen)).toList();
    final chronicSummary = state.chronicConditions.isEmpty
        ? '—'
        : state.chronicConditions.map((c) => c.conditionName).join(', ');
    final surgeriesSummary = state.surgeries.isEmpty
        ? '—'
        : state.surgeries.map((s) => '${s.surgeryName} (${s.surgeryDate})').join('\n');

    final medications = state.medications
        .map((m) => ReviewMedication(name: m.drugName, details: '${m.strength} • ${m.frequency}'))
        .toList();

    final attachments = state.attachments
        .map((a) => ReviewAttachment(
      name: a.type,
      details: '${a.size} • ${a.uploadedAt?.toString().split(' ').first ?? ''}',
      isPdf: a.fileType.toString().contains('pdf'),
    ))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepProgressBar(currentStep: 4, totalSteps: 4),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppStrings.reviewSubmitTitle(context),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 25 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 25 * scaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.reviewSubmitDesc(context),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 25 * scaleFactor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // --- Basic Info (ثابتة - راجع الملاحظة فوق الملف) ---
          ReviewSectionCard(
            icon: Icons.person_outline,
            title: AppStrings.basicInfoSection(context),
            onEdit: () {},
            children: _basicInfoFields
                .map((f) => ReviewInfoField(label: f.label, value: f.value))
                .toList(),
          ),

          // --- History: بيانات حقيقية من الكيوبت ---
          ReviewSectionCard(
            icon: Icons.history,
            title: AppStrings.historySection(context),
            onEdit: () => Navigator.pop(context),
            children: [
              Text(
                AppStrings.knownAllergiesLabel(context),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 25 * scaleFactor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(children: allergies.map((a) => AllergyTag(name: a.name)).toList()),
              const SizedBox(height: 12),
              ReviewInfoField(
                label: AppStrings.chronicConditionsLabel(context),
                value: chronicSummary,
              ),
              ReviewInfoField(
                label: AppStrings.pastSurgeriesLabel(context),
                value: surgeriesSummary,
              ),
            ],
          ),

          // --- Meds: بيانات حقيقية ---
          ReviewSectionCard(
            icon: Icons.medication_outlined,
            title: AppStrings.medsSection(context),
            onEdit: () => Navigator.pop(context),
            children: medications
                .map((m) => ReviewMedCard(name: m.name, details: m.details))
                .toList(),
          ),

          // --- Attachments: بيانات حقيقية ---
          ReviewSectionCard(
            icon: Icons.attach_file,
            title: AppStrings.attachmentsSection(context),
            onEdit: () => Navigator.pop(context),
            children: attachments
                .map((a) => ReviewAttachmentCard(name: a.name, details: a.details, isPdf: a.isPdf))
                .toList(),
          ),

          const SizedBox(height: 8),

          // =============================================
          // زر Confirm & Submit - كل البيانات محفوظة أصلاً بالباك، هاد
          // الزر بيأكد الإنهاء ويرجعك لنفس MainLayoutScreen يلي فتحت
          // منه هاي الخطوات (مو شاشة MedicalOverviewScreen لحالها بمعزل
          // عن الـ BottomNav/التابات التانية) - popUntil بترجع لأقرب
          // Route موجود أصلاً بالستاك (MainLayoutScreen) وتشيل كل خطوات
          // هالمعالج من فوقه، بدل ما تفتح نسخة جديدة وتمسح كل الستاك.
          // =============================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // ✅ 18/8: قبل ما نرجع، منعلّم صراحة إنه المريض
                // صار عنده سجل طبي (عبر MedicalRecordStatusCubit
                // الموفّر فوق بـ MainLayoutScreen) - هيك شاشة
                // الـ Overview بتعرف فوراً إنه في سجل، بلا حاجة
                // لتسجيل خروج/دخول جديد لتحديث الحالة.
                context.read<MedicalRecordStatusCubit>().markHasRecord();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.confirmSubmitButton(context),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25 * scaleFactor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPrivacyText(context, theme, scaleFactor),
        ],
      ),
    );
  }

  Widget _buildPrivacyText(BuildContext context, ThemeData theme, double scaleFactor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 25 * scaleFactor,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: AppStrings.privacyStatementPrefix(context)),
                  TextSpan(
                    text: AppStrings.termsOfServiceLink(context),
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: AppStrings.privacyStatementMiddle(context)),
                  TextSpan(
                    text: AppStrings.privacyPolicyLink(context),
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: AppStrings.privacyStatementSuffix(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
