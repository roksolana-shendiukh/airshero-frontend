import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/flight_operation_state_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_button.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_select_field.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.45),
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
  String _selectedStateId = '';
  String _ownReason    = '';
  bool   _writeOwn     = false;

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

  bool get _canSubmit {
    if (!widget.isCancel) return true;
    if (_writeOwn) return _ownReason.trim().isNotEmpty;
    return _selectedStateId.isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    final stateId = _writeOwn || _selectedStateId.isEmpty
        ? null
        : int.tryParse(_selectedStateId);
    final reason = _writeOwn && _ownReason.trim().isNotEmpty
        ? _ownReason.trim()
        : null;
    await widget.onConfirm(stateId, reason);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors       = Theme.of(context).colorScheme;
    final isCancel     = widget.isCancel;
    final accentColor  = isCancel ? colors.error : colors.primary;
    final title        = isCancel ? 'Cancel operation' : 'Complete operation';
    final icon         = isCancel ? Icons.cancel_outlined : Icons.check_circle_outline;
    final confirmLabel = isCancel ? 'Cancel operation' : 'Complete';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color:        colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colors, icon, accentColor, title),
              const Divider(height: 1),
              _buildBody(colors, accentColor),
              _buildFooter(colors, accentColor, confirmLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, IconData icon,
      Color accentColor, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colors, Color accentColor) {
    final stateIds = _states
      .map((s) => s.stateId.toString())
      .toList()
      .cast<String>(); 
    final stateLabels  = _states.map((s) => s.description).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isCancel ? 'Reason' : 'Note',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color:      colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (widget.isCancel)
                      Text('*',
                          style: TextStyle(
                              color: colors.error, fontSize: 12))
                    else
                      Text('(optional)',
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 10),

                if (!_writeOwn) ...[
                  CustomSelectField(
                    label:      widget.isCancel
                        ? 'Select a reason'
                        : 'Select a note',
                    value:      _selectedStateId,
                    icon:       Icons.list_outlined,
                    items:      stateIds,
                    itemLabels: stateLabels,
                    onChanged:  (v) => setState(
                        () => _selectedStateId = v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      _writeOwn        = true;
                      _selectedStateId = '';
                    }),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 13, color: colors.primary),
                        const SizedBox(width: 5),
                        Text('Write your own',
                            style: TextStyle(
                                fontSize:   12,
                                color:      colors.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ] else ...[
                  CustomInputField(
                    label:           widget.isCancel
                        ? 'Describe the reason'
                        : 'Add a note',
                    value:           _ownReason,
                    icon:            Icons.edit_outlined,
                    inputFormatters: [LengthLimitingTextInputFormatter(70)],
                    onChanged: (v) => setState(() => _ownReason = v),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_ownReason.length} / 70',
                      style: TextStyle(
                          fontSize: 11,
                          color:    colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _writeOwn    = false;
                      _ownReason   = '';
                    }),
                    child: Row(
                      children: [
                        Icon(Icons.list_outlined,
                            size: 13, color: colors.primary),
                        const SizedBox(width: 5),
                        Text('Choose from list',
                            style: TextStyle(
                                fontSize:   12,
                                color:      colors.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],

                if (widget.isCancel && !_canSubmit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: colors.error),
                      const SizedBox(width: 4),
                      Text('Reason is required to cancel',
                          style: TextStyle(
                              fontSize: 11, color: colors.error)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ),
    );
  }

  Widget _buildFooter(ColorScheme colors, Color accentColor,
      String confirmLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: const Text('Back',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              label:             confirmLabel,
              verticalPadding:   11,
              horizontalPadding: 16,
              onPressed: _isSubmitting || !_canSubmit ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}