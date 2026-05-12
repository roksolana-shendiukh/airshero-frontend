import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/object_crud_service.dart';
import '../../custom/custom_input_field.dart';
import '../../custom/custom_select_field.dart';
import '../../custom/custom_button.dart';

class AirportTerminalDialog extends StatefulWidget {
  final int airportId;
  final Map<String, dynamic>? terminal;

  const AirportTerminalDialog({
    super.key,
    required this.airportId,
    this.terminal,
  });

  @override
  State<AirportTerminalDialog> createState() => _AirportTerminalDialogState();
}

class _AirportTerminalDialogState extends State<AirportTerminalDialog> {
  List<Map<String, dynamic>> _terminalTypes = [];
  bool _isLoadingTypes = true;

  String _code = '';
  String _size = '';
  int? _selectedTypeId;
  String? _selectedTypeName;

  bool _isSaving = false;
  String? _serverError;

  final Map<String, bool> _touched = {
    'type': false,
    'code': false,
    'size': false,
  };

  final _codeRegex = RegExp(r'^[a-zA-Z0-9]+$');
  final _sizeFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'));

  @override
  void initState() {
    super.initState();
    if (widget.terminal != null) {
      _prefill();
    }
    _loadTerminalTypes();
  }

  void _prefill() {
    final t = widget.terminal!;
    _code = (t['terminalCode'] ?? t['terminal_code'] ?? '').toString();
    _size = (t['terminalSize'] ?? t['terminal_size'] ?? '').toString();
    _selectedTypeId = t['terminalTypeId'] ?? t['terminal_type_id'];
    _selectedTypeName = (t['terminalTypeName'] ?? t['terminal_type_name'] ?? '').toString();
    _touched.updateAll((k, v) => true);
  }

  Future<void> _loadTerminalTypes() async {
    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final types = await api.getTerminalTypes();
      if (mounted) {
        setState(() {
          _terminalTypes = types;
          _isLoadingTypes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  String? _getCodeError(String v) {
    if (v.trim().isEmpty) return 'Required';
    if (v.length > 3) return 'Max 3 characters';
    if (!_codeRegex.hasMatch(v)) return 'Alphanumeric only';
    return null;
  }

  String? _getSizeError(String v) {
    if (v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Invalid number';
    if (n <= 0) return 'Must be positive';
    if (n >= 100000000) return 'Too large';
    return null;
  }

  bool get _isValid {
    return _selectedTypeId != null &&
        _getCodeError(_code) == null &&
        _getSizeError(_size) == null;
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() {
      _isSaving = true;
      _serverError = null;
    });

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final data = {
        'terminalTypeId': _selectedTypeId!,
        'terminalCode': _code.trim().toUpperCase(),
        'terminalSize': double.parse(_size),
      };

      if (widget.terminal != null) {
        final id = widget.terminal!['terminalId'] ?? widget.terminal!['terminal_id'];
        await api.updateTerminal(id, data);
      } else {
        await api.createTerminal(widget.airportId, data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _serverError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = widget.terminal != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit_outlined : Icons.apartment_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Edit Terminal' : 'Add Terminal',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CustomSelectField(
                      label: 'Terminal type',
                      icon: Icons.category_outlined,
                      value: _selectedTypeName ?? '',
                      items: _terminalTypes.map((t) => t['terminalTypeName'].toString()).toList(),
                      errorText: (_touched['type']! && _selectedTypeId == null) ? 'Required' : null,
                      onChanged: (val) {
                        final type = _terminalTypes.firstWhere((t) => t['terminalTypeName'] == val, orElse: () => {});
                        setState(() {
                          _selectedTypeId = type['terminalTypeId'];
                          _selectedTypeName = val;
                          _touched['type'] = true;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Terminal code',
                      icon: Icons.label_outline,
                      value: _code,
                      errorText: _serverError ?? (_touched['code']! ? _getCodeError(_code) : null),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      onChanged: (v) => setState(() {
                        _code = v.toUpperCase();
                        _touched['code'] = true;
                        _serverError = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Size (m²)',
                      icon: Icons.straighten_outlined,
                      value: _size,
                      errorText: _touched['size']! ? _getSizeError(_size) : null,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [_sizeFormatter],
                      onChanged: (v) => setState(() {
                        _size = v;
                        _touched['size'] = true;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : CustomButton(
                          label: isEdit ? 'Save Changes' : 'Add Terminal',
                          onPressed: _isValid ? _save : null,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}