import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_bloc/flutter_bloc.dart';
// --- Models ---
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/setting.dart';
import '../../../../../../core/cubits/medical_record_status_cubit.dart';

// --- Widgets ---
import '../../../view_models/attachment_cubit.dart';
import '../../../view_models/attachment_state.dart';
import '../../widgets/medical_profile_widgets/attachments/attached_file_item.dart';
import '../../widgets/medical_profile_widgets/attachments/upload_drop_zone.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/bottom_action_buttons.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/step_progress_bar.dart';
import 'review_submit_screen.dart';

// =============================================
// الشاشة الرئيسية - Medical Profile / Step 3
// تحويل من StatefulWidget لـ StatelessWidget: قائمة الملفات صارت جوا
// AttachmentCubit، والرفع الفعلي (bytes) بيصير عبر MedicalRecordRepository.
// ملاحظة: الباك ما بيخزن اسم الملف الأصلي - بس فئة (type) بيحددها
// المستخدم، فلهيك بعد اختيار الملف(ات) بنسأله عن الفئة قبل الرفع.
// =============================================
class AttachmentScreen extends StatelessWidget {
  const AttachmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttachmentCubit()..loadAttachments(),
      child: const _AttachmentView(),
    );
  }
}

class _AttachmentView extends StatelessWidget {
  const _AttachmentView();

  Future<void> _pickAndUpload(BuildContext context) async {
    final result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fp.FileType.any,
      withData: true, // لازم حتى نقدر نرفع bytes الملف فعلياً للباك
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final type = await showDialog<String>(
      context: context,
      builder: (_) => const _AttachmentTypeDialog(),
    );
    if (type == null || type.trim().isEmpty) return;
    if (!context.mounted) return;

    final cubit = context.read<AttachmentCubit>();
    for (final file in result.files) {
      if (file.bytes == null) continue;
      await cubit.uploadAttachment(bytes: file.bytes!, filename: file.name, type: type.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      bottomNavigationBar: BottomActionButtons(
        onBack: () => Navigator.pop(context),
        onNextStep: () {
          // ⚠️ 19/8: تمرير MedicalRecordStatusCubit - نفس السبب المشروح
          // بباقي خطوات المعالج (medical_overview_screen.dart وغيرها).
          // هاي آخر قفزة بالسلسلة، وReviewSubmitScreen هي يلي فعلياً
          // بتستخدم الكيوبت (زر Confirm & Submit)، فلازم توصلها سليمة.
          final medicalRecordStatusCubit = context.read<MedicalRecordStatusCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: medicalRecordStatusCubit,
                child: const ReviewSubmitScreen(),
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<AttachmentCubit, AttachmentState>(
        listener: (context, state) {
          if (state.status == AttachmentStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AttachmentStatus.loading ||
              state.status == AttachmentStatus.initial) {
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color, size: 22),
        onPressed: () => Navigator.pop(context),
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

  Widget _buildBody(BuildContext context, ThemeData theme, AttachmentState state) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;
    final cubit = context.read<AttachmentCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.attachmentsSection(context),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const StepProgressBar(currentStep: 3, totalSteps: 4),
          const SizedBox(height: 24),
          Text(
            AppStrings.uploadFilesTitle(context),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.uploadFilesDesc(context),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 25 * scaleFactor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (state.status == AttachmentStatus.uploading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          UploadDropZone(onTap: () => _pickAndUpload(context)),
          const SizedBox(height: 24),
          if (state.attachments.isNotEmpty) ...[
            Text(
              AppStrings.attachedFilesSection(context),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 25 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...state.attachments.map(
                  (file) => AttachedFileItem(
                file: file,
                onDelete: () => cubit.deleteAttachment(file.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================
// Dialog - اختيار فئة الملف (type) قبل الرفع
// نفس التصنيفات المعروضة أصلاً بـ upload_drop_zone.dart كـ chips،
// بالإضافة لحقل نص حر لأي فئة تانية.
// =============================================
class _AttachmentTypeDialog extends StatefulWidget {
  const _AttachmentTypeDialog();

  @override
  State<_AttachmentTypeDialog> createState() => _AttachmentTypeDialogState();
}

class _AttachmentTypeDialogState extends State<_AttachmentTypeDialog> {
  final _customController = TextEditingController();
  static const _quickOptions = ['Lab Results', 'Prescriptions', 'Medical Images', 'X-ray photo'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What kind of file is this?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickOptions
                .map((label) => ActionChip(
              label: Text(label),
              onPressed: () => Navigator.pop(context, label),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            decoration: const InputDecoration(labelText: 'Or type your own'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _customController.text),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
