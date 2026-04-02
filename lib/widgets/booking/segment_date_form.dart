import 'package:flutter/material.dart';
import '../custom/custom_input_field.dart';
import '../../services/booking_api_service.dart';
import '../../services/auth_service.dart';

class SegmentDateForm extends StatefulWidget {
  final int fromCityId;
  final String fromCity;
  final int toCityId;
  final String toCity;
  final bool isCalendarOpen;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onRemove;
  final void Function(
    GlobalKey fieldKey,
    List<String> availableDates,
    DateTime? current,
    void Function(DateTime?) onSelected,
  )? onOpenCalendar;

  const SegmentDateForm({
    super.key,
    required this.fromCityId,
    required this.fromCity,
    required this.toCityId,
    required this.toCity,
    required this.isCalendarOpen,
    required this.onDateChanged,
    required this.onRemove,
    this.onOpenCalendar,
  });

  @override
  State<SegmentDateForm> createState() => _SegmentDateFormState();
}

class _SegmentDateFormState extends State<SegmentDateForm> {
  DateTime? _selectedDate;
  List<String> _availableDates = [];
  bool _isLoading = true;

  final GlobalKey _dateFieldKey = GlobalKey();
  late final BookingApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = BookingApiService(AuthService());
    _loadAvailableDates();
  }

  Future<void> _loadAvailableDates() async {
    setState(() => _isLoading = true);
    try {
      final dates = await _apiService.getAvailableDates(
        widget.fromCityId,
        widget.toCityId,
      );
      if (mounted) {
        setState(() {
          _availableDates = dates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок сегменту
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  widget.fromCity,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.toCity,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.close,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withOpacity(0.4),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: _isLoading
                ? SizedBox(
                    height: 56,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  )
                : CustomInputField(
                    key: _dateFieldKey,
                    label: 'Departure date',
                    value: _formatDate(_selectedDate),
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    isSelected: widget.isCalendarOpen,
                    onTap: () {
                      widget.onOpenCalendar?.call(
                        _dateFieldKey,
                        _availableDates,
                        _selectedDate,
                        (date) {
                          setState(() => _selectedDate = date);
                          widget.onDateChanged(date);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}