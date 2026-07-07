import 'package:flutter/material.dart';
import '../../services/seat_layout_api_service.dart';

class SeatClassFormDialog extends StatefulWidget {
  final SeatLayoutApiService api;
  final int airfleetId;
  final Map<String, dynamic>? layout;
  final List<Map<String, dynamic>> seatTypes;

  const SeatClassFormDialog({
    super.key,
    required this.api,
    required this.airfleetId,
    this.layout,
    required this.seatTypes,
  });

  @override
  State<SeatClassFormDialog> createState() => _SeatClassFormDialogState();
}

class _SeatClassFormDialogState extends State<SeatClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rows;
  late final TextEditingController _cols;

  int? _classId;
  int? _seatTypeId;
  bool _saving = false;

  bool get _isEdit => widget.layout != null;

  static const _cabinClasses = [
    {'id': 1, 'name': 'First'},
    {'id': 2, 'name': 'Business'},
    {'id': 3, 'name': 'Economy'},
    {'id': 4, 'name': 'Premium Economy'},
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.layout;
    _rows       = TextEditingController(text: l?['seat_layout_rows']?.toString() ?? '');
    _cols       = TextEditingController(text: l?['seat_layout_columns']?.toString() ?? '');
    _classId    = l?['class_id'] as int?;
    _seatTypeId = l?['seat_type_id'] as int?;
  }

  @override
  void dispose() {
    _rows.dispose();
    _cols.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cabin class')),
      );
      return;
    }
    if (_seatTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a seat type')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await widget.api.updateSeatLayout(
          seatLayoutId: widget.layout!['seat_layout_id'] as int,
          classId:      _classId!,
          seatTypeId:   _seatTypeId!,
          rows:         int.parse(_rows.text),
          columns:      _cols.text.trim(),
        );
      } else {
        await widget.api.createSeatLayout(
          airfleetId: widget.airfleetId,
          classId:    _classId!,
          seatTypeId: _seatTypeId!,
          rows:       int.parse(_rows.text),
          columns:    _cols.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit Class' : 'Add Cabin Class',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:        const Icon(Icons.close),
                      onPressed:   () => Navigator.pop(context),
                      padding:     EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Define rows, columns and seat type for this class',
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<int>(
                  value:     _classId,
                  decoration: _dec('Cabin class *'),
                  items: _cabinClasses
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name'] as String),
                          ))
                      .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _classId = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value:     _seatTypeId,
                  decoration: _dec('Seat type *'),
                  items: widget.seatTypes
                      .map((t) => DropdownMenuItem<int>(
                            value: t['seat_type_id'] as int,
                            child: Text(t['seat_type_name'] as String? ?? '—'),
                          ))
                      .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _seatTypeId = v),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller:   _rows,
                  decoration:   _dec('Number of rows *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) < 1) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cols,
                  decoration: _dec('Columns layout *').copyWith(
                    helperText:  'e.g. "3 3" for 3+3, "2 4 2" for 2+4+2',
                    helperStyle: TextStyle(
                        fontSize: 10, color: colors.onSurfaceVariant),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                if (_cols.text.trim().isNotEmpty && _rows.text.isNotEmpty)
                  _buildPreview(colors),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width:  16,
                              height: 16,
                              child:  CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Save' : 'Add class'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme colors) {
    final parts = _cols.text
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? 0)
        .where((n) => n > 0)
        .toList();
    final rowCount = (int.tryParse(_rows.text) ?? 0).clamp(0, 4);
    if (parts.isEmpty || rowCount == 0) return const SizedBox.shrink();

    final classColor = _classId == 1
        ? const Color(0xFFD85A30)
        : _classId == 2
            ? const Color(0xFF7F77DD)
            : _classId == 4
                ? const Color(0xFF378ADD)
                : const Color(0xFF1D9E75);

    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview',
              style: TextStyle(
                  fontSize:   10,
                  color:      colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          ...List.generate(
            rowCount,
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    child: Text('${r + 1}',
                        style: TextStyle(
                            fontSize: 9, color: colors.onSurfaceVariant)),
                  ),
                  ...parts.asMap().entries.expand((e) => [
                    if (e.key > 0) const SizedBox(width: 5),
                    ...List.generate(
                      e.value,
                      (_) => Container(
                        width:  16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color:        classColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          if ((int.tryParse(_rows.text) ?? 0) > 4)
            Text('+ ${(int.tryParse(_rows.text) ?? 0) - 4} more rows',
                style: TextStyle(
                    fontSize: 9, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText:      label,
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense:        true,
      );
}