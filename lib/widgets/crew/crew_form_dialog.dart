import 'package:flutter/material.dart';
import '../../models/flight_crew_model.dart';
import '../../services/crew_api_service.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_select_field.dart';
import '../custom/custom_button.dart';

class CrewFormDialog extends StatefulWidget {
  final CrewApiService api;
  final FlightCrewModel? crew;
  final List<Map<String, dynamic>> positions;
  final List<Map<String, dynamic>> licenseTypes;

  const CrewFormDialog({
    super.key,
    required this.api,
    required this.crew,
    required this.positions,
    required this.licenseTypes,
  });

  @override
  State<CrewFormDialog> createState() => _CrewFormDialogState();
}

class _CrewFormDialogState extends State<CrewFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _firstName;
  late String _lastName;
  late String _experience;
  int? _positionId;
  int? _licenseTypeId;
  bool _saving = false;

  final _nameRegex = RegExp(r'^[a-zA-Z]+$');

  @override
  void initState() {
    super.initState();
    final c = widget.crew;
    _firstName     = c?.firstName       ?? '';
    _lastName      = c?.lastName        ?? '';
    _experience    = c?.experienceYears?.toString() ?? '';
    _positionId    = c?.positionId;
    _licenseTypeId = c?.licenseTypeId;
  }

  List<Map<String, dynamic>> get _availableLicenses {
    if (_positionId == null) return widget.licenseTypes;

    final posName = widget.positions
        .firstWhere((p) => p['id'] == _positionId)['name'] as String;

    if (posName == 'Pilot' || posName == 'Co-Pilot') {
      return widget.licenseTypes.where((l) {
        final name = l['name'] as String;
        return name.contains('Pilot License');
      }).toList();
    }

    if (posName == 'Engineer') {
      return widget.licenseTypes.where((l) {
        return (l['name'] as String) == 'Flight Engineer License';
      }).toList();
    }

    return widget.licenseTypes;
  }

  String? _validateName(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (value.length > 20) return 'Max 20 characters';
    if (!_nameRegex.hasMatch(value)) return 'English letters only';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.crew == null) {
        await widget.api.create(
          firstName:       _firstName.trim(),
          lastName:        _lastName.trim(),
          positionId:      _positionId!,
          licenseTypeId:   _licenseTypeId!,
          experienceYears: int.parse(_experience.trim()),
        );
      } else {
        await widget.api.update(
          crewId:          widget.crew!.flightCrewId,
          firstName:       _firstName.trim(),
          lastName:        _lastName.trim(),
          positionId:      _positionId!,
          licenseTypeId:   _licenseTypeId!,
          experienceYears: int.parse(_experience.trim()),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.crew != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Crew Member' : 'Add Crew Member'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildManagedInput(
                        label:        'First Name',
                        initialValue: _firstName,
                        icon:         Icons.person_outline,
                        onChanged:    (v) => _firstName = v,
                        validator:    (v) => _validateName(v, 'First Name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildManagedInput(
                        label:        'Last Name',
                        initialValue: _lastName,
                        icon:         Icons.person_outline,
                        onChanged:    (v) => _lastName = v,
                        validator:    (v) => _validateName(v, 'Last Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPositionSelect(),
                const SizedBox(height: 16),
                _buildLicenseSelect(),
                const SizedBox(height: 16),
                _buildManagedInput(
                  label:        'Experience (years)',
                  initialValue: _experience,
                  icon:         Icons.work_history_outlined,
                  keyboardType: TextInputType.number,
                  onChanged:    (v) => _experience = v,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter valid years';
                    if (n > 50) return 'Max 50 years';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          label:           isEdit ? 'Save' : 'Create',
          verticalPadding: 12,
          onPressed:       _saving ? null : _save,
        ),
      ],
    );
  }

  Widget _buildPositionSelect() {
    return FormField<int>(
      initialValue: _positionId,
      validator:    (v) => v == null ? 'Required' : null,
      builder: (state) {
        return CustomSelectField(
          label:      'Position',
          icon:       Icons.badge_outlined,
          value:      _positionId?.toString() ?? '',
          items:      widget.positions.map((e) => e['id'].toString()).toList(),
          itemLabels: widget.positions.map((e) => e['name'] as String).toList(),
          errorText:  state.errorText,
          onChanged:  (val) {
            setState(() {
              _positionId    = val != null ? int.tryParse(val) : null;
              _licenseTypeId = null;
              state.didChange(_positionId);
            });
          },
        );
      },
    );
  }

  Widget _buildLicenseSelect() {
    final available = _availableLicenses;
    return FormField<int>(
      key:          ValueKey('pos_$_positionId'),
      initialValue: _licenseTypeId,
      validator:    (v) => v == null ? 'Please select a valid license' : null,
      builder: (state) {
        return CustomSelectField(
          label:      'License Type',
          icon:       Icons.card_membership_outlined,
          value:      _licenseTypeId?.toString() ?? '',
          items:      available.map((e) => e['id'].toString()).toList(),
          itemLabels: available.map((e) => e['name'] as String).toList(),
          errorText:  state.errorText,
          onChanged:  (val) {
            setState(() {
              _licenseTypeId = val != null ? int.tryParse(val) : null;
              state.didChange(_licenseTypeId);
            });
          },
        );
      },
    );
  }

  Widget _buildManagedInput({
    required String label,
    required String initialValue,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: initialValue,
      validator:    validator,
      builder: (state) {
        return CustomInputField(
          label:        label,
          value:        initialValue,
          icon:         icon,
          keyboardType: keyboardType,
          errorText:    state.errorText,
          onChanged: (v) {
            onChanged(v);
            state.didChange(v);
          },
        );
      },
    );
  }
}