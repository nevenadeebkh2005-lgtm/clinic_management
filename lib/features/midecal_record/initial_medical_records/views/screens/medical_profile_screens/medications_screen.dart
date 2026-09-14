import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// --- Models ---
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/setting.dart';
import '../../../../../../core/cubits/medical_record_status_cubit.dart';
// --- Widgets ---
import '../../../models/medication_model.dart';
import '../../../view_models/medication_cubit.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/bottom_action_buttons.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/step_progress_bar.dart';
import '../../widgets/medical_profile_widgets/medications/medication_card.dart';
import 'attachment_screen.dart';

// =============================================
// الشاشة الرئيسية - Medical Profile / Step 2
// تحويل من StatefulWidget لـ StatelessWidget: البيانات صارت جوا
// MedicationsCubit، والـ FAB/dialog صارو ينادوا عليه مباشرة.
// =============================================
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedicationsCubit()..loadMedications(),
      child: const _MedicationsView(),
    );
  }
}

class _MedicationsView extends StatelessWidget {
  const _MedicationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _AddMedicationDialog(cubit: context.read<MedicationsCubit>()),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomActionButtons(
        onBack: () => Navigator.pop(context),
        onNextStep: () {
          // ⚠️ 19/8: تمرير MedicalRecordStatusCubit - نفس السبب المشروح
          // بباقي خطوات المعالج.
          final medicalRecordStatusCubit = context.read<MedicalRecordStatusCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: medicalRecordStatusCubit,
                child: const AttachmentScreen(),
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<MedicationsCubit, MedicationsState>(
        listener: (context, state) {
          if (state.status == MedicationsStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == MedicationsStatus.loading ||
              state.status == MedicationsStatus.initial) {
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

  void _showMenuOptions(BuildContext context, Medication medication, ThemeData theme) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;
    final isDark = theme.brightness == Brightness.dark;
    final isEn = BlocProvider.of<SettingsCubit>(context).state.locale.languageCode == 'en';
    final cubit = context.read<MedicationsCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!medication.isStopped)
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined, color: Color(0xFFD32F2F)),
                title: Text(
                  isEn ? 'Mark as stopped' : 'إيقاف الدواء',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 25 * scaleFactor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => _StopMedicationDialog(cubit: cubit, medicationId: medication.id),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
              title: Text(
                isEn ? 'Delete' : 'حذف',
                style: TextStyle(color: const Color(0xFFD32F2F), fontSize: 25 * scaleFactor),
              ),
              onTap: () {
                Navigator.pop(context);
                cubit.deleteMedication(medication.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, MedicationsState state) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepProgressBar(currentStep: 2, totalSteps: 4),
          const SizedBox(height: 24),
          Text(
            AppStrings.medicationsTitle(context),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.medicationsDesc(context),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 25 * scaleFactor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...state.medications.map(
                (medication) => MedicationCard(
              medication: medication,
              onMenuTap: () => _showMenuOptions(context, medication, theme),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// Dialog - إضافة دواء جديد
// =============================================
class _AddMedicationDialog extends StatefulWidget {
  final MedicationsCubit cubit;
  const _AddMedicationDialog({required this.cubit});

  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final _drugNameController = TextEditingController();
  final _formController = TextEditingController(text: 'tablet');
  final _strengthController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _routeController = TextEditingController(text: 'oral');
  final _notesController = TextEditingController();
  DateTime? _startDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _drugNameController, decoration: const InputDecoration(labelText: 'Drug name')),
            TextField(controller: _formController, decoration: const InputDecoration(labelText: 'Form (tablet, syrup...)')),
            TextField(controller: _strengthController, decoration: const InputDecoration(labelText: 'Strength (e.g. 500mg)')),
            TextField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 tablet)')),
            TextField(controller: _frequencyController, decoration: const InputDecoration(labelText: 'Frequency (e.g. once daily)')),
            TextField(controller: _routeController, decoration: const InputDecoration(labelText: 'Route (oral, topical...)')),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Start date'),
                child: Text(_startDate == null
                    ? 'Select date'
                    : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'),
              ),
            ),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_drugNameController.text.trim().isEmpty || _startDate == null) return;
            widget.cubit.addMedication(
              drugName: _drugNameController.text.trim(),
              form: _formController.text.trim(),
              strength: _strengthController.text.trim(),
              dosage: _dosageController.text.trim(),
              frequency: _frequencyController.text.trim(),
              route: _routeController.text.trim(),
              startDate:
              '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// =============================================
// Dialog - إيقاف دواء (stop) مع سبب اختياري
// =============================================
class _StopMedicationDialog extends StatefulWidget {
  final MedicationsCubit cubit;
  final int medicationId;
  const _StopMedicationDialog({required this.cubit, required this.medicationId});

  @override
  State<_StopMedicationDialog> createState() => _StopMedicationDialogState();
}

class _StopMedicationDialogState extends State<_StopMedicationDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark medication as stopped'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.cubit.stopMedication(
              widget.medicationId,
              reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
