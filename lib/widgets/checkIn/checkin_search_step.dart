import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_button.dart';

class CheckInSearchStep extends StatefulWidget {
  final void Function({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
  }) onSearch;

  const CheckInSearchStep({super.key, required this.onSearch});

  @override
  State<CheckInSearchStep> createState() => _CheckInSearchStepState();
}

class _CheckInSearchStepState extends State<CheckInSearchStep> {
  final _documentNumberController = TextEditingController();
  final _flightNumberController    = TextEditingController();
  DateTime? _departDate;

  bool _documentNumberTouched = false;
  bool _flightNumberTouched   = false;
  bool _departDateTouched     = false;
  bool _isLoading             = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _departDate = picked;
        _departDateTouched = true;
      });
    }
  }

  bool get _isFormValid =>
      _documentNumberController.text.trim().isNotEmpty &&
      _flightNumberController.text.trim().isNotEmpty &&
      _departDate != null;

  void _handleSearch() {
    setState(() {
      _documentNumberTouched = true;
      _flightNumberTouched   = true;
      _departDateTouched     = true;
    });

    if (!_isFormValid) return;

    widget.onSearch(
      documentNumber: _documentNumberController.text.trim().toUpperCase(),
      flightNumber:   _flightNumberController.text.trim().toUpperCase(),
      departDate:     _departDate!,
    );
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _flightNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Document Number ──────────────────────────────────────────────
          CustomInputField(
            label: 'Document Number',
            value: _documentNumberController.text,
            icon:  Icons.contact_page_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (v) {
              _documentNumberController.text = v.toUpperCase();
              setState(() {});
            },
          ),
          if (_documentNumberTouched &&
              _documentNumberController.text.trim().isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Required field',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Flight Number + Date ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomInputField(
                      label: 'Flight Number',
                      value: _flightNumberController.text,
                      icon:  Icons.flight_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (v) {
                        _flightNumberController.text = v.toUpperCase();
                        setState(() {});
                      },
                    ),
                    if (_flightNumberTouched &&
                        _flightNumberController.text.trim().isEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Required field',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomInputField(
                      label:    'Departure Date',
                      value:    _formatDate(_departDate),
                      icon:     Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap:    _pickDate,
                    ),
                    if (_departDateTouched && _departDate == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Required field',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Search Button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label:     'Find Booking',
                    onPressed: _handleSearch,
                  ),
          ),
        ],
      ),
    );
  }
}