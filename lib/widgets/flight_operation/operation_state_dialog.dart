import 'package:flutter/material.dart';
import '../../models/flight_operation_state_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_input_field.dart';

class OperationStateDialog extends StatefulWidget {
  final FlightOperationApiService apiService;
  final bool isCancel;
  final Future<void> Function(int? stateId, String? customReason) onConfirm;

  const OperationStateDialog({
    super.key,
    required this.apiService,
    required this.isCancel,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required FlightOperationApiService apiService,
    required bool isCancel,
    required Future<void> Function(int? stateId, String? customReason) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OperationStateDialog(
        apiService: apiService,
        isCancel:   isCancel,
        onConfirm:  onConfirm,
      ),
    );
  }

  @override
  State<OperationStateDialog> createState() => _OperationStateDialogState();
}

class _OperationStateDialogState extends State<OperationStateDialog> {
  List<FlightOperationStateModel> _states = [];
  bool   _isLoading    = true;
  bool   _isSubmitting = false;
  int?   _selectedStateId;
  String _customReason = '';
  bool   _useCustom    = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final states = await widget.apiService.getOperationStates();
    if (mounted) setState(() {
      _states    = states;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final stateId = _useCustom ? null : _selectedStateId;
    final reason  = _useCustom && _customReason.isNotEmpty
        ? _customReason
        : null;
    await widget.onConfirm(stateId, reason);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title  = widget.isCancel ? 'Cancel Operation' : 'Complete Operation';
    final icon   = widget.isCancel
        ? Icons.cancel_outlined
        : Icons.check_circle_outline;
    final color  = widget.isCancel ? colors.error : Colors.green;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(20),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a reason (optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Список причин
                          if (!_useCustom) ...[
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _states.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final s        = _states[i];
                                  final selected =
                                      _selectedStateId == s.stateId;
                                  return InkWell(
                                    onTap: () => setState(() =>
                                        _selectedStateId = selected
                                            ? null
                                            : s.stateId),
                                    borderRadius: BorderRadius.circular(8),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? color.withValues(alpha: 0.1)
                                            : colors.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selected
                                              ? color.withValues(alpha: 0.4)
                                              : colors.outlineVariant,
                                          width: selected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.description,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: selected
                                                    ? color
                                                    : colors.onSurface,
                                                fontWeight: selected
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (selected)
                                            Icon(Icons.check,
                                                size: 16, color: color),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _useCustom      = true;
                                _selectedStateId = null;
                              }),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 14,
                                      color: colors.primary),
                                  const SizedBox(width: 6),
                                  Text('Enter custom reason',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.primary,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ] else ...[
                            CustomInputField(
                              label: 'Custom reason',
                              value: _customReason,
                              icon: Icons.edit_outlined,
                              onChanged: (v) =>
                                  setState(() => _customReason = v),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _useCustom    = false;
                                _customReason = '';
                              }),
                              child: Row(
                                children: [
                                  Icon(Icons.list_outlined,
                                      size: 14,
                                      color: colors.primary),
                                  const SizedBox(width: 6),
                                  Text('Choose from list',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.primary,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(_isSubmitting
                            ? 'Processing...'
                            : widget.isCancel
                                ? 'Cancel Operation'
                                : 'Complete'),
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
}