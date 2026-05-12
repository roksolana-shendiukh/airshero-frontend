import 'package:flutter/material.dart';
import '../../models/gate_model.dart';
import '../../models/flight_operation_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_select_field.dart';
import '../custom/custom_button.dart';
import 'gate_step.dart';

class GatePickerDialog extends StatefulWidget {
  final int operationId;
  final FlightOperationApiService api;
  final FlightOperationModel operation;

  const GatePickerDialog({
    super.key,
    required this.operationId,
    required this.api,
    required this.operation,
  });

  @override
  State<GatePickerDialog> createState() => _GatePickerDialogState();
}

class _GatePickerDialogState extends State<GatePickerDialog> {
  List<GateModel> _gates = [];
  GateModel? _selectedGate;
  String? _openTerminal;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGates();
  }

  Future<void> _loadGates() async {
    try {
      final data = await widget.api.getAvailableGates(widget.operationId);
      if (mounted) {
        setState(() {
          _gates = data;
          _loading = false;

          if (_gates.isNotEmpty) {
            final currentGateCode = widget.operation.gateCode;
            
            GateModel? currentMatch;
            if (currentGateCode != null) {
              try {
                currentMatch = _gates.firstWhere((g) => g.gateCode == currentGateCode);
              } catch (_) {}
            }

            if (currentMatch != null) {
              _openTerminal = currentMatch.terminalCode;
              _selectedGate = currentMatch;
            } else {
              _openTerminal = _gates.first.terminalCode;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<GateModel>> get _groupedGates {
    final map = <String, List<GateModel>>{};
    for (final g in _gates) {
      final key = g.terminalCode ?? '?';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final grouped = _groupedGates;

    return AlertDialog(
      title: const Text('Change Flight Gate'),
      content: SizedBox(
        width: 450,
        height: 450,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomSelectField(
                    label: 'Select Terminal',
                    value: _openTerminal ?? '',
                    icon: Icons.business_outlined,
                    items: ['', ...grouped.keys],
                    itemLabels: [
                      'Select terminal',
                      ...grouped.keys.map((t) => 
                        'Terminal $t (${grouped[t]!.first.terminalType ?? "Standard"})'),
                    ],
                    onChanged: (v) => setState(() {
                      _openTerminal = (v == null || v.isEmpty) ? null : v;
                      _selectedGate = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_openTerminal != null && grouped.containsKey(_openTerminal)) ...[
                    _buildTerminalInfo(grouped[_openTerminal]!.first, colors),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: grouped[_openTerminal]!.map((gate) {
                            final isSelected = _selectedGate?.gateId == gate.gateId;
                            return _buildGateTile(gate, isSelected, colors);
                          }).toList(),
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Center(
                        child: Text(
                          'No gates available in this terminal',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        CustomButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
          borderRadius: 6,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        CustomButton(
          label: _saving ? '' : 'Confirm',
          onPressed: (_selectedGate == null || _saving) ? null : _submit,
          borderRadius: 6,
          icon: _saving ? null : null,
        ),
      ],
    );
  }

  Widget _buildTerminalInfo(GateModel gate, ColorScheme colors) {
    final String termType = gate.terminalType ?? "Standard";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terminal Type: $termType',
              style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateTile(GateModel gate, bool isSelected, ColorScheme colors) {
    final isAvailable = gate.isAvailable;
    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedGate = isSelected ? null : gate) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72, height: 56,
        decoration: BoxDecoration(
          color: !isAvailable 
            ? colors.surfaceContainerHighest.withOpacity(0.5) 
            : isSelected ? colors.primaryContainer.withOpacity(0.35) : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !isAvailable ? colors.outlineVariant.withOpacity(0.4) : isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(gate.gateCode, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: !isAvailable ? colors.onSurfaceVariant.withOpacity(0.4) : isSelected ? colors.primary : colors.onSurface,
            )),
            Text(isAvailable ? 'Gate' : 'Busy', style: TextStyle(
              fontSize: 10, color: isSelected ? colors.primary.withOpacity(0.7) : colors.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final ok = await widget.api.changeGate(widget.operationId, _selectedGate!.gateId);
      if (ok && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }
}