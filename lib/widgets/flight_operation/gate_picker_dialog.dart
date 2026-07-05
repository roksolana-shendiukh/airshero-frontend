import 'package:flutter/material.dart';
import '../../models/gate_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../flight_operation/gate_step.dart';

class GatePickerDialog extends StatefulWidget {
  final int operationId;
  final FlightOperationApiService api;

  const GatePickerDialog({
    super.key,
    required this.operationId,
    required this.api,
  });

  @override
  State<GatePickerDialog> createState() => _GatePickerDialogState();
}

class _GatePickerDialogState extends State<GatePickerDialog> {
  List<GateModel> _gates = [];
  GateModel? _selectedGate;
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
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Flight Gate'),
      content: SizedBox(
        width: 450,
        child: GateStep(
          gates: _gates,
          selected: _selectedGate,
          isLoading: _loading,
          onChanged: (gate) => setState(() => _selectedGate = gate),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_selectedGate == null || _saving)
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    final success = await widget.api.changeGate(
                      widget.operationId,
                      _selectedGate!.gateId,
                    );
                    if (success && mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}