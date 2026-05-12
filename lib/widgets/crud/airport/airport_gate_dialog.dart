import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/object_crud_service.dart';
import '../../custom/custom_input_field.dart';
import '../../custom/custom_button.dart';

class AirportGateDialog extends StatefulWidget {
  final int terminalId;
  final String terminalCode;
  final Map<String, dynamic>? gate;

  const AirportGateDialog({
    super.key,
    required this.terminalId,
    required this.terminalCode,
    this.gate,
  });

  @override
  State<AirportGateDialog> createState() => _AirportGateDialogState();
}

class _AirportGateDialogState extends State<AirportGateDialog> {
  String _gateCode = '';
  String? _serverError; 
  bool _isLoading = false;
  bool _touched = false;

  final _codeRegex = RegExp(r'^[a-zA-Z0-9]+$');

  @override
  void initState() {
    super.initState();
    if (widget.gate != null) {
      _gateCode = (widget.gate!['gateCode'] ?? widget.gate!['gate_code'] ?? '').toString();
      _touched = true;
    }
  }

  String? _getCodeError(String v) {
    if (v.trim().isEmpty) return 'Required';
    if (v.length > 3) return 'Max 3 characters';
    if (!_codeRegex.hasMatch(v)) return 'Alphanumeric only';
    return null;
  }

  bool get _isValid => _getCodeError(_gateCode) == null;

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _isLoading = true;
      _serverError = null; 
    });

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final String cleanCode = _gateCode.trim().toUpperCase();
      final data = {'gateCode': cleanCode};

      if (widget.gate == null) {
        await api.createGate(widget.terminalId, data);
      } else {
        final gateId = widget.gate!['gateId'] ?? widget.gate!['gate_id'] ?? widget.gate!['id'];
        await api.updateGate(gateId as int, data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _serverError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.gate != null;
    final colors = Theme.of(context).colorScheme;

    final String? activeError = _serverError ?? (_touched ? _getCodeError(_gateCode) : null);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit : Icons.add_business, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Gate' : 'Add Gate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Terminal ${widget.terminalCode}',
                          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: CustomInputField(
                  label: 'Gate Code',
                  icon: Icons.door_front_door_outlined,
                  value: _gateCode,
                  errorText: activeError, 
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(3),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (val) => setState(() {
                    _gateCode = val.toUpperCase();
                    _touched = true;
                    _serverError = null; 
                  }),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : CustomButton(
                          label: isEdit ? 'Save changes' : 'Add gate',
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