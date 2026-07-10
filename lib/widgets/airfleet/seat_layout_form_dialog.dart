import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/seat_layout_api_service.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_select_field.dart';

class SeatLayoutFormDialog extends StatefulWidget {
  final SeatLayoutApiService api;
  final int airfleetId;
  final Map<String, dynamic>? layout;
  final List<Map<String, dynamic>> seatTypes;

  const SeatLayoutFormDialog({
    super.key,
    required this.api,
    required this.airfleetId,
    this.layout,
    required this.seatTypes,
  });

  @override
  State<SeatLayoutFormDialog> createState() => _SeatLayoutFormDialogState();
}

class _SeatLayoutFormDialogState extends State<SeatLayoutFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String _rows = '';
  String _cols = 'ABC DEF';
  int? _classId;
  String? _className;
  int? _seatTypeId;
  String? _seatTypeName;

  bool _saving = false;

  static const _classes = [
    {'id': 0, 'name': 'Economy'},
    {'id': 1, 'name': 'Premium Economy'},
    {'id': 2, 'name': 'Business'},
    {'id': 3, 'name': 'First'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.layout != null) {
      final l = widget.layout!;
      _rows       = l['seat_layout_rows']?.toString() ?? '';
      _cols       = l['seat_layout_columns'] ?? '';
      _classId    = l['class_id'] as int?;
      _seatTypeId = l['seat_type_id'] as int?;

      final classMatch = _classes.firstWhere(
          (c) => c['id'] == _classId, orElse: () => {});
      _className = classMatch['name'] as String?;
      _seatTypeName = widget.seatTypes.firstWhere(
          (t) => t['seat_type_id'] == _seatTypeId,
          orElse: () => {})['seat_type_name'] as String?;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classId == null || _seatTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and seat type')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.layout == null) {
        await widget.api.createSeatLayout(
          airfleetId: widget.airfleetId,
          classId:    _classId!,
          seatTypeId: _seatTypeId!,
          rows:       int.parse(_rows),
          columns:    _cols.trim().toUpperCase(),
        );
      } else {
        await widget.api.updateSeatLayout(
          seatLayoutId: widget.layout!['seat_layout_id'] as int,
          classId:      _classId!,
          seatTypeId:   _seatTypeId!,
          rows:         int.parse(_rows),
          columns:      _cols.trim().toUpperCase(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = widget.layout != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Seat Class' : 'Add Seat Class',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              CustomSelectField(
                label: 'Service Class',
                icon:  Icons.stars_outlined,
                value: _className ?? '',
                items: _classes.map((c) => c['name'] as String).toList(),
                onChanged: (val) {
                  final c = _classes.firstWhere((e) => e['name'] == val);
                  setState(() {
                    _classId   = c['id'] as int;
                    _className = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              CustomSelectField(
                label: 'Seat Type',
                icon:  Icons.event_seat_outlined,
                value: _seatTypeName ?? '',
                items: widget.seatTypes
                    .map((t) => t['seat_type_name'] as String)
                    .toList(),
                onChanged: (val) {
                  final t = widget.seatTypes
                      .firstWhere((e) => e['seat_type_name'] == val);
                  setState(() {
                    _seatTypeId   = t['seat_type_id'] as int;
                    _seatTypeName = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomInputField(
                      label:            'Rows count',
                      icon:             Icons.format_list_numbered,
                      value:            _rows,
                      keyboardType:     TextInputType.number,
                      inputFormatters:  [FilteringTextInputFormatter.digitsOnly],
                      onChanged:        (v) => setState(() => _rows = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomInputField(
                      label:     'Pattern',
                      icon:      Icons.grid_on,
                      value:     _cols,
                      hint:      'e.g. ABC DEF',
                      onChanged: (v) =>
                          setState(() => _cols = v.toUpperCase()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text('Layout Preview:',
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      Colors.grey)),
              const SizedBox(height: 8),
              _buildColumnsPreview(colors),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    width:  120,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width:  20,
                              height: 20,
                              child:  CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnsPreview(ColorScheme colors) {
    final chars = _cols.split('');
    if (chars.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: chars.map((char) {
          if (char == ' ') {
            return const SizedBox(
                width: 20,
                child: Center(
                    child: Text('|',
                        style: TextStyle(color: Colors.grey))));
          }
          return Container(
            width:  28,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:        colors.primaryContainer,
              borderRadius: BorderRadius.circular(4),
              border:       Border.all(
                  color: colors.primary.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text(char,
                style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.bold,
                    color:      colors.onPrimaryContainer)),
          );
        }).toList(),
      ),
    );
  }
}