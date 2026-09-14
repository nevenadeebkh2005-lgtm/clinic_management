import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// --- Models ---
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/setting.dart';
import '../../../../../../core/cubits/medical_record_status_cubit.dart';

// --- Widgets ---
import '../../../models/medical_history_models.dart';
import '../../../view_models/medical_history_cubit.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/bottom_action_buttons.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/medical_section_card.dart';
import '../../widgets/medical_profile_widgets/medical_history_widgets/step_progress_bar.dart';
import 'medications_screen.dart';

// =============================================
// الشاشة الرئيسية - Medical Profile / Step 1
// تحويل من StatefulWidget لـ StatelessWidget: كل الحالة (تحميل، حذف،
// فتح/غلق الأقسام) صارت جوا MedicalHistoryCubit بدل State محلية.
// ملاحظة: الـ dialogs بالأسفل (لإضافة/تعديل عنصر) هي StatefulWidget
// صغيرة داخلية بس لإدارة TextEditingController مؤقتاً - هذا لا يخالف
// مبدأ "الشاشة stateless" لأنها مش جزء من شجرة الشاشة نفسها.
// =============================================
class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedicalHistoryCubit()..loadAll(),
      child: const _MedicalHistoryView(),
    );
  }
}

class _MedicalHistoryView extends StatelessWidget {
  const _MedicalHistoryView();

  static const List<MedicalSectionType> _sectionOrder = [
    MedicalSectionType.chronicCondition,
    MedicalSectionType.surgery,
    MedicalSectionType.allergy,
    MedicalSectionType.familyHistory,
  ];

  Widget _getSectionIcon(int index, ThemeData theme) {
    switch (index) {
      case 0:
        return const Icon(Icons.monitor_heart_outlined, size: 25, color: Color(0xFFD32F2F));
      case 1:
        return Icon(Icons.content_cut, size: 25, color: theme.textTheme.bodyMedium?.color);
      case 2:
        return const Icon(Icons.coronavirus_outlined, size: 25, color: Color(0xFFD32F2F));
      case 3:
        return Icon(Icons.people_outline, size: 25, color: theme.textTheme.bodyMedium?.color);
      default:
        return Icon(Icons.medical_services_outlined, size: 25, color: theme.primaryColor);
    }
  }

  Color _getSectionIconBg(int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (index) {
      case 0:
      case 2:
        return isDark ? const Color(0xFF421D1D) : const Color(0xFFFFEBEE);
      case 1:
      case 3:
        return theme.cardColor;
      default:
        return theme.primaryColor.withAlpha(26);
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
          // ⚠️ 19/8: تمرير MedicalRecordStatusCubit لنفس السبب المشروح
          // بـ medical_overview_screen.dart (كل قفزة Navigator.push جديدة
          // بتحتاج تمريره من جديد).
          final medicalRecordStatusCubit = context.read<MedicalRecordStatusCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: medicalRecordStatusCubit,
                child: const MedicationsScreen(),
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<MedicalHistoryCubit, MedicalHistoryState>(
        listener: (context, state) {
          if (state.status == MedicalHistoryStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == MedicalHistoryStatus.loading ||
              state.status == MedicalHistoryStatus.initial) {
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

  List<MedicalEntry> _entriesFor(MedicalSectionType type, MedicalHistoryState state) {
    switch (type) {
      case MedicalSectionType.chronicCondition:
        return state.chronicConditions.map((c) => c.toEntry()).toList();
      case MedicalSectionType.surgery:
        return state.surgeries.map((s) => s.toEntry()).toList();
      case MedicalSectionType.allergy:
        return state.allergies.map((a) => a.toEntry()).toList();
      case MedicalSectionType.familyHistory:
        return state.familyHistory.map((f) => f.toEntry()).toList();
    }
  }

  String _titleFor(MedicalSectionType type, BuildContext context) {
    switch (type) {
      case MedicalSectionType.chronicCondition:
        return AppStrings.chronicDiseasesSection(context);
      case MedicalSectionType.surgery:
        return AppStrings.surgeriesSection(context);
      case MedicalSectionType.allergy:
        return AppStrings.allergiesSection(context);
      case MedicalSectionType.familyHistory:
        return AppStrings.familyHistorySection(context);
    }
  }

  void _deleteEntry(BuildContext context, MedicalSectionType type, int id) {
    final cubit = context.read<MedicalHistoryCubit>();
    switch (type) {
      case MedicalSectionType.chronicCondition:
        cubit.deleteChronicCondition(id);
        break;
      case MedicalSectionType.surgery:
        cubit.deleteSurgery(id);
        break;
      case MedicalSectionType.allergy:
        cubit.deleteAllergy(id);
        break;
      case MedicalSectionType.familyHistory:
        cubit.deleteFamilyHistory(id);
        break;
    }
  }

  Widget _buildBody(BuildContext context, ThemeData theme, MedicalHistoryState state) {
    final scaleFactor = BlocProvider.of<SettingsCubit>(context).state.scaleFactor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepProgressBar(currentStep: 1, totalSteps: 4),
          const SizedBox(height: 24),
          Text(
            AppStrings.medicalHistoryTitle(context),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 25 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.medicalHistoryDesc(context),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 25 * scaleFactor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_sectionOrder.length, (index) {
            final type = _sectionOrder[index];
            final section = MedicalSection(
              type: type,
              title: _titleFor(type, context),
              iconAsset: '',
              isExpanded: state.expandedSections[index],
              entries: _entriesFor(type, state),
            );
            return MedicalSectionCard(
              section: section,
              iconWidget: _getSectionIcon(index, theme),
              iconBgColor: _getSectionIconBg(index, theme),
              onToggle: () => context.read<MedicalHistoryCubit>().toggleSection(index),
              onAddNew: () => _showEntryDialog(context, type),
              onEdit: (entry) => _showEntryDialog(context, type, editEntryId: entry.id),
              onDelete: (entry) => _deleteEntry(context, type, entry.id),
            );
          }),
        ],
      ),
    );
  }

  void _showEntryDialog(BuildContext context, MedicalSectionType type, {int? editEntryId}) {
    final cubit = context.read<MedicalHistoryCubit>();
    final state = cubit.state;

    switch (type) {
      case MedicalSectionType.chronicCondition:
        final existing = editEntryId == null
            ? null
            : state.chronicConditions.firstWhere((c) => c.id == editEntryId);
        showDialog(
          context: context,
          builder: (_) => _ChronicConditionDialog(cubit: cubit, existing: existing),
        );
        break;
      case MedicalSectionType.surgery:
        final existing =
        editEntryId == null ? null : state.surgeries.firstWhere((s) => s.id == editEntryId);
        showDialog(
          context: context,
          builder: (_) => _SurgeryDialog(cubit: cubit, existing: existing),
        );
        break;
      case MedicalSectionType.allergy:
        final existing =
        editEntryId == null ? null : state.allergies.firstWhere((a) => a.id == editEntryId);
        showDialog(
          context: context,
          builder: (_) => _AllergyDialog(cubit: cubit, existing: existing),
        );
        break;
      case MedicalSectionType.familyHistory:
        final existing = editEntryId == null
            ? null
            : state.familyHistory.firstWhere((f) => f.id == editEntryId);
        showDialog(
          context: context,
          builder: (_) => _FamilyHistoryDialog(cubit: cubit, existing: existing),
        );
        break;
    }
  }
}

// =============================================
// Dialogs - نماذج بسيطة لإضافة/تعديل عنصر واحد بكل قسم
// كل واحد StatefulWidget صغير محلي (بس لإدارة الـ controllers)
// =============================================
class _ChronicConditionDialog extends StatefulWidget {
  final MedicalHistoryCubit cubit;
  final ChronicCondition? existing;
  const _ChronicConditionDialog({required this.cubit, this.existing});

  @override
  State<_ChronicConditionDialog> createState() => _ChronicConditionDialogState();
}

class _ChronicConditionDialogState extends State<_ChronicConditionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  DateTime? _diagnosedAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.conditionName ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _diagnosedAt = widget.existing != null ? DateTime.tryParse(widget.existing!.diagnosedAt) : null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Condition' : 'Add Chronic Condition'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Condition name')),
          const SizedBox(height: 8),
          _DatePickerField(
            label: 'Diagnosed at',
            value: _diagnosedAt,
            onPick: (d) => setState(() => _diagnosedAt = d),
          ),
          const SizedBox(height: 8),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final diagnosedAtStr = _diagnosedAt == null
                ? null
                : '${_diagnosedAt!.year}-${_diagnosedAt!.month.toString().padLeft(2, '0')}-${_diagnosedAt!.day.toString().padLeft(2, '0')}';
            if (name.isEmpty || diagnosedAtStr == null) return;
            if (isEdit) {
              widget.cubit.updateChronicCondition(
                widget.existing!.id,
                conditionName: name,
                diagnosedAt: diagnosedAtStr,
                notes: _notesController.text.trim(),
              );
            } else {
              widget.cubit.addChronicCondition(
                conditionName: name,
                diagnosedAt: diagnosedAtStr,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SurgeryDialog extends StatefulWidget {
  final MedicalHistoryCubit cubit;
  final Surgery? existing;
  const _SurgeryDialog({required this.cubit, this.existing});

  @override
  State<_SurgeryDialog> createState() => _SurgeryDialogState();
}

class _SurgeryDialogState extends State<_SurgeryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  DateTime? _surgeryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.surgeryName ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _surgeryDate = widget.existing != null ? DateTime.tryParse(widget.existing!.surgeryDate) : null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Surgery' : 'Add Surgery'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Surgery name')),
          const SizedBox(height: 8),
          _DatePickerField(
            label: 'Surgery date',
            value: _surgeryDate,
            onPick: (d) => setState(() => _surgeryDate = d),
          ),
          const SizedBox(height: 8),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final dateStr = _surgeryDate == null
                ? null
                : '${_surgeryDate!.year}-${_surgeryDate!.month.toString().padLeft(2, '0')}-${_surgeryDate!.day.toString().padLeft(2, '0')}';
            if (name.isEmpty || dateStr == null) return;
            if (isEdit) {
              widget.cubit.updateSurgery(
                widget.existing!.id,
                surgeryName: name,
                surgeryDate: dateStr,
                notes: _notesController.text.trim(),
              );
            } else {
              widget.cubit.addSurgery(
                surgeryName: name,
                surgeryDate: dateStr,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AllergyDialog extends StatefulWidget {
  final MedicalHistoryCubit cubit;
  final Allergy? existing;
  const _AllergyDialog({required this.cubit, this.existing});

  @override
  State<_AllergyDialog> createState() => _AllergyDialogState();
}

class _AllergyDialogState extends State<_AllergyDialog> {
  late final TextEditingController _allergenController;
  late final TextEditingController _reactionController;
  late String _allergenType;
  late String _severity;

  static const _types = ['food', 'drug', 'environmental', 'other'];
  static const _severities = ['mild', 'moderate', 'severe'];

  @override
  void initState() {
    super.initState();
    _allergenController = TextEditingController(text: widget.existing?.allergen ?? '');
    _reactionController = TextEditingController(text: widget.existing?.reaction ?? '');
    _allergenType = widget.existing?.allergenType ?? _types.first;
    _severity = widget.existing?.severity ?? _severities.first;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Allergy' : 'Add Allergy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _allergenController, decoration: const InputDecoration(labelText: 'Allergen')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _allergenType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _allergenType = v ?? _allergenType),
          ),
          const SizedBox(height: 8),
          TextField(controller: _reactionController, decoration: const InputDecoration(labelText: 'Reaction')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _severity = v ?? _severity),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final allergen = _allergenController.text.trim();
            final reaction = _reactionController.text.trim();
            if (allergen.isEmpty || reaction.isEmpty) return;
            if (isEdit) {
              widget.cubit.updateAllergy(
                widget.existing!.id,
                allergenType: _allergenType,
                allergen: allergen,
                reaction: reaction,
                severity: _severity,
              );
            } else {
              widget.cubit.addAllergy(
                allergenType: _allergenType,
                allergen: allergen,
                reaction: reaction,
                severity: _severity,
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _FamilyHistoryDialog extends StatefulWidget {
  final MedicalHistoryCubit cubit;
  final FamilyHistoryEntry? existing;
  const _FamilyHistoryDialog({required this.cubit, this.existing});

  @override
  State<_FamilyHistoryDialog> createState() => _FamilyHistoryDialogState();
}

class _FamilyHistoryDialogState extends State<_FamilyHistoryDialog> {
  late final TextEditingController _conditionController;
  late final TextEditingController _relationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _conditionController = TextEditingController(text: widget.existing?.condition ?? '');
    _relationController = TextEditingController(text: widget.existing?.relation ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Family History' : 'Add Family History'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _conditionController, decoration: const InputDecoration(labelText: 'Condition')),
          const SizedBox(height: 8),
          TextField(controller: _relationController, decoration: const InputDecoration(labelText: 'Relation (e.g. father, mother)')),
          const SizedBox(height: 8),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final condition = _conditionController.text.trim();
            final relation = _relationController.text.trim();
            if (condition.isEmpty || relation.isEmpty) return;
            if (isEdit) {
              widget.cubit.updateFamilyHistory(
                widget.existing!.id,
                condition: condition,
                relation: relation,
                notes: _notesController.text.trim(),
              );
            } else {
              widget.cubit.addFamilyHistory(
                condition: condition,
                relation: relation,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// =============================================
// حقل اختيار تاريخ بسيط ومشترك بين الـ dialogs
// =============================================
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(text),
      ),
    );
  }
}
