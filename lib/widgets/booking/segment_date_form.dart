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
  final int? finalDestinationCityId;
  final void Function(
    GlobalKey fieldKey,
    List<String> availableDates,
    DateTime? current,
    void Function(DateTime?) onSelected,
  )? onOpenCalendar;

  final DateTime? leg1Date;

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
    this.leg1Date,
    this.finalDestinationCityId,
  });

  @override
  State<SegmentDateForm> createState() => _SegmentDateFormState();
}

class _SegmentDateFormState extends State<SegmentDateForm> {
  DateTime? _selectedDate;
  List<String> _availableDates = [];
  bool _isLoading = false;
  bool _isLocked = false; 


  
  final GlobalKey _dateFieldKey = GlobalKey();
  late final BookingApiService _apiService;

  bool get _isLeg2 => widget.leg1Date != null ||
      (widget.leg1Date == null && _isLocked);

  @override
  void initState() {
    super.initState();
    _apiService = BookingApiService(AuthService());

    if (widget.finalDestinationCityId != null) {
      _loadLeg1ConnectingDates();
    } else {
      _loadAvailableDates();
    } 
  }

  Future<void> _loadLeg1ConnectingDates() async {
    setState(() => _isLoading = true);
    try {
      final dates = await _apiService.getLeg1ConnectingDates(
        fromCityId: widget.fromCityId,
        hubCityId: widget.toCityId,
        toCityId: widget.finalDestinationCityId!,
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

  bool get _isLeg2Mode => false; 

  @override
  void didUpdateWidget(SegmentDateForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.leg1Date != oldWidget.leg1Date) {
      if (widget.leg1Date != null) {
        setState(() {
          _isLocked = false;
          _selectedDate = null;
        });
        widget.onDateChanged(null);
        _loadLeg2Dates(widget.leg1Date!);
      } else {
        setState(() {
          _isLocked = true;
          _availableDates = [];
          _selectedDate = null;
        });
        widget.onDateChanged(null);
      }
    }
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

  Future<void> _loadLeg2Dates(DateTime leg1Date) async {
    setState(() {
      _isLoading = true;
      _availableDates = [];
    });

    try {
      final leg1DateStr =
          '${leg1Date.year}-${leg1Date.month.toString().padLeft(2, '0')}-${leg1Date.day.toString().padLeft(2, '0')}';

      final dates = await _apiService.getLeg2AvailableDates(
        hubCityId: widget.fromCityId,
        toCityId: widget.toCityId,
        leg1Date: leg1DateStr,
      );

      if (!mounted) return;

      setState(() {
        _availableDates = dates;
        _isLoading = false;
      });

      if (dates.length == 1) {
        final onlyDate = DateTime.parse(dates.first);
        _showSingleDateConfirmation(onlyDate);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSingleDateConfirmation(DateTime date) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Only one date available'),
          content: Text(
            'The only available date for ${widget.fromCity} → ${widget.toCity} '
            'within 24 hours is $formatted.\n\nConfirm this date?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _selectedDate = date);
                widget.onDateChanged(date);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDisabled = _isLocked && widget.leg1Date == null;

    return Container(
      decoration: BoxDecoration(
        color: isDisabled
            ? colors.surfaceContainerLow.withValues(alpha: .5)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDisabled ? 0.3 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  widget.fromCity,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDisabled ? colors.onSurfaceVariant : null,
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
                    color: isDisabled ? colors.onSurfaceVariant : null,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withValues(alpha: .4),
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
                : isDisabled
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Select first leg date first',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : _availableDates.isEmpty && !_isLoading
                        ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: colors.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No available dates within 24 hours of first leg',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.error,
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