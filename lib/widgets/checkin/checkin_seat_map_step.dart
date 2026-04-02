import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../custom/custom_button.dart';

class CheckInSeatMapStep extends StatefulWidget {
  final AuthService authService;
  final int         flightOperationId;
  final int         passengerClassId;
  final String?     passengerDateOfBirth;
  final void Function(String seatPosition, int seatLayoutId) onSeatSelected;

  const CheckInSeatMapStep({
    super.key,
    required this.authService,
    required this.flightOperationId,
    required this.passengerClassId,
    required this.onSeatSelected,
    this.passengerDateOfBirth,
  });

  @override
  State<CheckInSeatMapStep> createState() => _CheckInSeatMapStepState();
}

class _CheckInSeatMapStepState extends State<CheckInSeatMapStep> {
  List<Map<String, dynamic>> _seats          = [];
  Set<int>                   _flightClassIds = {};
  bool                       _isLoading      = true;
  String?                    _error;

  String? _selectedPosition;
  int?    _selectedLayoutId;

  static const _classColors = {
    0: Color(0xFF00BCD4),
    1: Color(0xFF2196F3), 
    2: Color(0xFFFF6B9D), 
    3: Color(0xFFFFD700), 
  };

  Color _baseColor(int classId) =>
      _classColors[classId] ?? const Color(0xFF9E9E9E);

  bool get _passengerIsAdult {
    if (widget.passengerDateOfBirth == null) return true;
    try {
      final dob = DateTime.parse(widget.passengerDateOfBirth!);
      final now = DateTime.now();
      final age = now.year - dob.year -
          ((now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day))
              ? 1
              : 0);
      return age >= 18;
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    try {
      final api    = CheckInApiService(widget.authService);
      final result = await api.getSeatMap(widget.flightOperationId);
      if (!mounted) return;
      final seats = List<Map<String, dynamic>>.from(result['seats'] ?? []);
      setState(() {
        _seats          = seats;
        _flightClassIds = Set<int>.from(seats.map((s) => s['classId'] as int));
        _isLoading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Failed to load seat map. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<String> get _columns {
    final cols = _seats.map((s) => s['column'] as String).toSet().toList();
    cols.sort();
    return cols;
  }

  List<int> get _rows {
    final rows = _seats.map((s) => s['row'] as int).toSet().toList();
    rows.sort();
    return rows;
  }

  Map<String, dynamic>? _seatAt(int row, String col) {
    try {
      return _seats.firstWhere(
        (s) => s['row'] == row && s['column'] == col,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isAisleBefore(String col) {
    final cols = _columns;
    return cols.indexOf(col) == cols.length ~/ 2;
  }

  int _rowClassId(int row) {
    try {
      return _seats.firstWhere((s) => s['row'] == row)['classId'] as int;
    } catch (_) {
      return 0;
    }
  }

  bool _isClassBoundary(int rowIndex) {
    final rows = _rows;
    if (rowIndex == 0) return false;
    return _rowClassId(rows[rowIndex]) != _rowClassId(rows[rowIndex - 1]);
  }

  bool _rowHasEmergencyExit(int row) =>
      _seats.any((s) =>
          s['row'] == row && (s['isEmergencyExit'] as bool? ?? false));

  bool _isEmergencyExit(Map<String, dynamic> seat) =>
      seat['isEmergencyExit'] as bool? ?? false;

  String _classNameById(int classId) {
    const names = {
      0: 'Economy',
      1: 'Premium Economy',
      2: 'Business',
      3: 'First',
    };
    return names[classId] ?? 'Unknown';
  }

  double _columnHeight(List<String> cols) {
    return cols.length * 40.0 + (cols.length ~/ 2) * 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.airline_seat_recline_normal_outlined,
                  color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Select seat',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildError()
          else ...[
            _buildLegend(),
            const SizedBox(height: 20),
            _buildSeatMap(),
            const SizedBox(height: 20),
            _buildConfirmButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [

        _LegendItem(
          color:      _baseColor(widget.passengerClassId),
          label:      '${_classNameById(widget.passengerClassId)} (your class)',
          isActive:   true,
          isOnFlight: true,
        ),

        if (_flightClassIds.any((id) => id != widget.passengerClassId))
          const _LegendItem(
            color:      Color(0xFF9E9E9E),
            label:      'Other class',
            isActive:   false,
            isOnFlight: true,
          ),

        if (_classColors.keys.any((id) => !_flightClassIds.contains(id)))
          const _LegendItem(
            color:      Color(0xFF9E9E9E),
            label:      'Not on this flight',
            isActive:   false,
            isOnFlight: false,
          ),

        _LegendItem(
          color:      colors.primary,
          label:      'Selected',
          isActive:   true,
          isOnFlight: true,
          isSelected: true,
        ),

        const _LegendItem(
          color:      Color(0xFF9E9E9E),
          label:      'Occupied',
          isActive:   false,
          isOnFlight: true,
          isOccupied: true,
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.change_history,
              size:  14,
              color: Colors.orange.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 5),
            Text(
              'Emergency exit row',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  
  Widget _buildSeatMap() {
    final cols = _columns;
    final rows = _rows;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: cols.map((col) => Column(
                children: [
                  if (_isAisleBefore(col)) const SizedBox(height: 16),
                  SizedBox(
                    width:  20,
                    height: 36,
                    child: Center(
                      child: Text(
                        col,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              )).toList(),
            ),
          ),

          const SizedBox(width: 4),

          ...rows.asMap().entries.map((entry) {
            final rowIndex    = entry.key;
            final row         = entry.value;
            final isEmergency = _rowHasEmergencyExit(row);
            final prevIsEmergency = rowIndex > 0
                ? _rowHasEmergencyExit(rows[rowIndex - 1])
                : false;
            final nextIsEmergency = rowIndex < rows.length - 1
                ? _rowHasEmergencyExit(rows[rowIndex + 1])
                : false;

            final gapBefore = isEmergency && !prevIsEmergency;
            final gapAfter  = isEmergency && !nextIsEmergency;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (_isClassBoundary(rowIndex))
                  Container(
                    width:  1,
                    margin: const EdgeInsets.only(right: 6, top: 20),
                    height: _columnHeight(cols),
                    color:  Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),

                Column(
                  children: [

                    if (gapBefore)
                      SizedBox(
                        width:  36,
                        height: 14,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size:  10,
                                color: Colors.orange.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width:  36,
                      height: 20,
                      child: Center(
                        child: Row(
                          mainAxisSize:      MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isEmergency)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size:  10,
                                  color: Colors.orange
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            Text(
                              '$row',
                              style: TextStyle(
                                fontSize:   10,
                                fontWeight: isEmergency
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isEmergency
                                    ? Colors.orange.withValues(alpha: 0.85)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    ...cols.map((col) {
                      final seat = _seatAt(row, col);
                      return Column(
                        children: [
                          if (_isAisleBefore(col))
                            const SizedBox(height: 16),
                          _buildSeat(seat),
                          const SizedBox(height: 4),
                        ],
                      );
                    }),

                    if (gapAfter)
                      Container(
                        width:  36,
                        height: 10,
                        margin: const EdgeInsets.only(top: 2),
                        child: Center(
                          child: Container(
                            height: 1.5,
                            color: Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 4),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeat(Map<String, dynamic>? seat) {
    if (seat == null) return const SizedBox(width: 36, height: 36);

    final colors             = Theme.of(context).colorScheme;
    final isOccupied         = seat['isOccupied']      as bool;
    final classId            = seat['classId']          as int;
    final seatPosition       = seat['seatPosition']     as String;
    final seatLayoutId       = seat['seatLayoutId']     as int;
    final isPassengerClass   = classId == widget.passengerClassId;
    final isOnFlight         = _flightClassIds.contains(classId);
    final isSelected         = _selectedPosition == seatPosition;
    final isEmergency        = _isEmergencyExit(seat);
    final isBlockedEmergency = isEmergency && !_passengerIsAdult;
    final isDisabled         = isOccupied || !isPassengerClass || isBlockedEmergency;

    final base = _baseColor(classId);

    Color bgColor;
    Color borderColor;

    if (isSelected) {
      bgColor     = colors.primary;
      borderColor = colors.primary;
    } else if (isOccupied) {
      bgColor     = Colors.grey.withValues(alpha: 0.12);
      borderColor = Colors.grey.withValues(alpha: 0.20);
    } else if (!isOnFlight) {
      bgColor     = base.withValues(alpha: 0.04);
      borderColor = base.withValues(alpha: 0.08);
    } else if (!isPassengerClass) {
      bgColor     = Colors.grey.withValues(alpha: 0.08);
      borderColor = Colors.grey.withValues(alpha: 0.18);
    } else if (isBlockedEmergency) {
      bgColor     = Colors.orange.withValues(alpha: 0.08);
      borderColor = Colors.orange.withValues(alpha: 0.25);
    } else {
      bgColor     = base.withValues(alpha: 0.22);
      borderColor = base.withValues(alpha: 0.85);
    }

    String tooltipMsg = '';
    if (isBlockedEmergency) {
      tooltipMsg = 'Emergency exit — passenger must be 18+';
    } else if (!isPassengerClass && isOnFlight) {
      tooltipMsg = '${_classNameById(classId)} — not available for this passenger';
    } else if (!isOnFlight) {
      tooltipMsg = '${_classNameById(classId)} — not available on this flight';
    }

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Tooltip(
        message: tooltipMsg,
        child: GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              if (_selectedPosition == seatPosition) {
                _selectedPosition = null;
                _selectedLayoutId = null;
              } else {
                _selectedPosition = seatPosition;
                _selectedLayoutId = seatLayoutId;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(6),
                topRight:    Radius.circular(6),
                bottomLeft:  Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: isOccupied
                ? Center(
                    child: Icon(
                      Icons.close,
                      size:  14,
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                  )
                : isEmergency
                    ? Center(
                        child: Icon(
                          Icons.change_history,
                          size:  12,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.orange.withValues(alpha: 0.7),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: _selectedPosition != null
            ? 'Confirm seat $_selectedPosition'
            : 'Select a seat',
        onPressed: _selectedPosition != null
            ? () => widget.onSeatSelected(
                _selectedPosition!,
                _selectedLayoutId!,
              )
            : null,
      ),
    );
  }

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        colors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  final bool   isActive;
  final bool   isOnFlight;
  final bool   isOccupied;
  final bool   isSelected;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isActive,
    required this.isOnFlight,
    this.isOccupied = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed      = !isOnFlight;
    final bgAlpha     = isSelected ? 1.0
        : isOccupied  ? 0.12
        : isActive    ? 0.22
        : dimmed      ? 0.04
        : 0.08;
    final borderAlpha = isSelected ? 1.0
        : isOccupied  ? 0.20
        : isActive    ? 0.85
        : dimmed      ? 0.08
        : 0.18;

    return Opacity(
      opacity: dimmed ? 0.4 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  14,
            height: 14,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: bgAlpha),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: color.withValues(alpha: borderAlpha),
                width: isActive ? 1.5 : 0.5,
              ),
            ),
            child: isOccupied
                ? Center(
                    child: Icon(
                      Icons.close,
                      size:  9,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}