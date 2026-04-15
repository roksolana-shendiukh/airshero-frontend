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

  static const double _seatSize    = 32.0;
  static const double _seatSpacing = 6.0;
  static const double _aisleGap    = 16.0;
  static const double _headerH     = 36.0;

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
      debugPrint('>>> passengerClassId: ${widget.passengerClassId}');
    debugPrint('>>> seat classIds: ${seats.map((s) => s['classId']).toSet()}');
    
      setState(() {
        _seats          = seats;
        _flightClassIds = Set<int>.from(seats.map((s) => s['classId'] as int));
        _isLoading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Failed to load seat map.';
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
      return _seats.firstWhere((s) => s['row'] == row && s['column'] == col);
    } catch (_) {
      return null;
    }
  }

  bool _isAisleBefore(String col) {
    final cols = _columns;
    final idx  = cols.indexOf(col);
    return idx > 0 && idx == cols.length ~/ 2;
  }

  bool _rowHasEmergencyExit(int row) =>
      _seats.any((s) => s['row'] == row && (s['isEmergencyExit'] as bool? ?? false));

  String _classNameById(int classId) {
    const names = {0: 'Economy', 1: 'Premium Economy', 2: 'Business', 3: 'First'};
    return names[classId] ?? 'Unknown';
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
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            _buildError()
          else ...[
            _buildLegend(),
            const SizedBox(height: 16),
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
          color:    _baseColor(widget.passengerClassId),
          label:    '${_classNameById(widget.passengerClassId)} (your class)',
          isActive: true,
        ),
        const _LegendItem(
          color:      Color(0xFF9E9E9E),
          label:      'Other class',
          isActive:   false,
        ),
        _LegendItem(
          color:    colors.primary,
          label:    'Selected',
          isActive: true,
          isSelected: true,
        ),
        const _LegendItem(
          color:      Color(0xFF9E9E9E),
          label:      'Occupied',
          isActive:   false,
          isOccupied: true,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.change_history, size: 14,
              color: Colors.orange.withValues(alpha: 0.85)),
            const SizedBox(width: 5),
            Text('Emergency exit',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatMap() {
    final colors = Theme.of(context).colorScheme;
    final rows   = _rows;
    final cols   = _columns;

    return Container(
      decoration: BoxDecoration(
        color:        colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: _headerH + 8),
              ...cols.map((col) => Column(
                children: [
                  if (_isAisleBefore(col)) SizedBox(height: _aisleGap),
                  Container(
                    width:  24,
                    height: _seatSize,
                    margin: const EdgeInsets.only(bottom: _seatSpacing),
                    alignment: Alignment.center,
                    child: Text(
                      col,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),

          const SizedBox(width: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: rows.asMap().entries.map((entry) {
                      final rowIndex    = entry.key;
                      final row         = entry.value;
                      final isEmergency = _rowHasEmergencyExit(row);
                      final prevIsEmergency = rowIndex > 0
                          ? _rowHasEmergencyExit(rows[rowIndex - 1])
                          : false;
                      final gapBefore = isEmergency && !prevIsEmergency;
                      final gapAfter  = !isEmergency && rowIndex > 0 && prevIsEmergency;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (gapBefore) SizedBox(width: _seatSpacing * 2),
                          Container(
                            width:  _seatSize,
                            height: _headerH,
                            margin: EdgeInsets.only(
                              right: _seatSpacing + (gapAfter ? _seatSpacing * 2 : 0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isEmergency)
                                  Icon(Icons.warning_amber_rounded,
                                      size: 12,
                                      color: Colors.orange.withValues(alpha: 0.85)),
                                const SizedBox(height: 2),
                                Text(
                                  '$row',
                                  style: TextStyle(
                                    fontSize:   10,
                                    fontWeight: isEmergency
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isEmergency
                                        ? Colors.orange.withValues(alpha: 0.85)
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  ...cols.map((col) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isAisleBefore(col)) SizedBox(height: _aisleGap),
                      Row(
                        children: rows.asMap().entries.map((entry) {
                          final rowIndex    = entry.key;
                          final row         = entry.value;
                          final seat        = _seatAt(row, col);
                          final isEmergency = _rowHasEmergencyExit(row);
                          final prevIsEmergency = rowIndex > 0
                              ? _rowHasEmergencyExit(rows[rowIndex - 1])
                              : false;
                          final gapBefore = isEmergency && !prevIsEmergency;
                          final gapAfter  = !isEmergency && rowIndex > 0 && prevIsEmergency;

                          return Row(
                            children: [
                              if (gapBefore) SizedBox(width: _seatSpacing * 2),
                              Container(
                                margin: EdgeInsets.only(
                                  right:  _seatSpacing + (gapAfter ? _seatSpacing * 2 : 0),
                                  bottom: _seatSpacing,
                                ),
                                child: seat == null
                                    ? SizedBox(width: _seatSize, height: _seatSize)
                                    : _buildSeat(seat),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(Map<String, dynamic> seat) {
    final colors           = Theme.of(context).colorScheme;
    final isOccupied       = seat['isOccupied']    as bool;
    final classId          = seat['classId']        as int;
    final seatPosition     = seat['seatPosition']   as String;
    final seatLayoutId     = seat['seatLayoutId']   as int;
    final isPassengerClass = classId == widget.passengerClassId;
    final isEmergency      = seat['isEmergencyExit'] as bool? ?? false;
    final isBlockedEmergency = isEmergency && !_passengerIsAdult;
    final isDisabled       = isOccupied || !isPassengerClass || isBlockedEmergency;
    final isSelected       = _selectedPosition == seatPosition;

    final base = _baseColor(classId);

    Color fill;
    Color border;

    if (isSelected) {
      fill   = colors.primary;
      border = colors.primary;
    } else if (isOccupied) {
      fill   = Colors.grey.withValues(alpha: 0.12);
      border = Colors.grey.withValues(alpha: 0.20);
    } else if (!isPassengerClass) {
      fill   = Colors.grey.withValues(alpha: 0.08);
      border = Colors.grey.withValues(alpha: 0.18);
    } else if (isBlockedEmergency) {
      fill   = Colors.orange.withValues(alpha: 0.08);
      border = Colors.orange.withValues(alpha: 0.25);
    } else {
      fill   = base.withValues(alpha: 0.20);
      border = base.withValues(alpha: 0.85);
    }

    String tooltip = '';
    if (isBlockedEmergency)      tooltip = 'Emergency exit — must be 18+';
    else if (!isPassengerClass)  tooltip = '${_classNameById(classId)}';

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
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
            width:  _seatSize,
            height: _seatSize,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(3),
                bottomLeft:  Radius.circular(3),
                topRight:    Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(
                color: border,
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: isOccupied
                ? Center(
                    child: Icon(Icons.close, size: 14,
                        color: Colors.grey.withValues(alpha: 0.4)),
                  )
                : isEmergency
                    ? Center(
                        child: RotatedBox(
                          quarterTurns: 0,
                          child: Icon(
                            Icons.change_history,
                            size: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.orange.withValues(alpha: 0.7),
                          ),
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
            ? () => widget.onSeatSelected(_selectedPosition!, _selectedLayoutId!)
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
            child: Text(_error!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error)),
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
  final bool   isOccupied;
  final bool   isSelected;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isActive,
    this.isOccupied = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgAlpha     = isSelected ? 1.0 : isOccupied ? 0.12 : isActive ? 0.20 : 0.08;
    final borderAlpha = isSelected ? 1.0 : isOccupied ? 0.20 : isActive ? 0.85 : 0.18;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: bgAlpha),
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(2),
              bottomLeft:  Radius.circular(2),
              topRight:    Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
            border: Border.all(
              color: color.withValues(alpha: borderAlpha),
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: isOccupied
              ? Center(
                  child: Icon(Icons.close, size: 9,
                      color: Colors.grey.withValues(alpha: 0.5)))
              : null,
        ),
        const SizedBox(width: 5),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 11)),
      ],
    );
  }
}