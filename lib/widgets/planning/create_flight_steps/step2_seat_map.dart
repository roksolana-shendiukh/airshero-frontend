import 'package:flutter/material.dart';
import '../../../services/planning_service.dart';

class Step2SeatMap extends StatefulWidget {
  final PlanningService service;
  final int airfleetId;
  
  final void Function(List<int> activeClassIds) onClassesConfirmed;

  final void Function(
    Map<int, int> classSeats, 
    Map<int, String> classNames, 
    List<int> blockedSeatLayoutIds, 
  ) onChanged;

  const Step2SeatMap({
    super.key,
    required this.service,
    required this.airfleetId,
    required this.onChanged,
    required this.onClassesConfirmed,
  });

  @override
  State<Step2SeatMap> createState() => _Step2SeatMapState();
}

class _Seat {
  final int seatLayoutId;
  final int row;
  final String column;
  final int classId;
  final String className;
  final String seatTypeName;
  final bool isEmergencyExit;

  _Seat({
    required this.seatLayoutId,
    required this.row,
    required this.column,
    required this.classId,
    required this.className,
    required this.seatTypeName,
    this.isEmergencyExit = false,
  });
}

const _palette =[
  Color(0xFF2196F3), 
  Color(0xFFFF6B9D), 
  Color(0xFF00BCD4), 
  Color(0xFFFFD700), 
  Color(0xFF4CAF50), 
  Color(0xFFFF9800), 
];

class _Step2SeatMapState extends State<Step2SeatMap> {
  List<_Seat> _seats =[];
  bool _loading = true;
  String? _error;

  final Set<int> _activeClassIds = {};

  Set<int> get _allClassIds => _seats.map((s) => s.classId).toSet();
  List<int> get _rows => _seats.map((s) => s.row).toSet().toList()..sort();
  List<String> get _columns => _seats.map((s) => s.column).toSet().toList()..sort();

  Map<int, String> get _classNames => {
        for (final s in _seats) s.classId: s.className,
      };

  Color _classColor(int classId) {
    final ids = _allClassIds.toList()..sort();
    return _palette[ids.indexOf(classId) % _palette.length];
  }

  bool _isAisleBefore(String col) {
    final cols = _columns;
    final idx = cols.indexOf(col);
    return idx > 0 && idx == cols.length ~/ 2;
  }

  bool _rowHasEmergencyExit(int row) =>
      _seats.any((s) => s.row == row && s.isEmergencyExit);

  _Seat? _seatAt(int row, String col) {
    try {
      return _seats.firstWhere((s) => s.row == row && s.column == col);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await widget.service.getSeatLayout(widget.airfleetId);
      if (!mounted) return;

      final seats = raw.map((r) {
        final typeName = (r['seat_type_name'] ?? r['seatType'] ?? '').toString();
        bool isEmerg = false;
        if (r['is_emergency_exit'] == true || r['is_emergency_exit'] == 1) isEmerg = true;
        if (r['isEmergencyExit'] == true || r['isEmergencyExit'] == 1) isEmerg = true;
        if (typeName.toLowerCase().contains('emergency') || typeName.toLowerCase().contains('exit')) isEmerg = true;

        return _Seat(
          seatLayoutId: r['seat_layout_id'] ?? r['seatLayoutId'] as int,
          row: r['seat_layout_rows'] ?? r['row'] as int,
          column: r['seat_layout_columns'] ?? r['column'] as String,
          classId: r['class_id'] ?? r['classId'] as int,
          className: r['class_name'] ?? r['className'] as String,
          seatTypeName: typeName,
          isEmergencyExit: isEmerg,
        );
      }).toList();

      final classIds = seats.map((s) => s.classId).toSet();
      _activeClassIds.addAll(classIds);

      setState(() {
        _seats = seats;
        _loading = false;
      });
      
      _notifyParent();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _notifyParent() {
    final classSeats = <int, int>{};

    for (final s in _seats) {
      if (_activeClassIds.contains(s.classId)) {
        classSeats[s.classId] = (classSeats[s.classId] ?? 0) + 1;
      }
    }

    widget.onChanged(classSeats, _classNames,[]);
  }

  void _toggleClass(int classId) {
    setState(() {
      if (_activeClassIds.contains(classId)) {
        _activeClassIds.remove(classId);
      } else {
        _activeClassIds.add(classId);
      }
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        _buildSectionLabel('Step 2: Enable Classes for Flight'),
        const SizedBox(height: 8),
        Text(
          'Select which classes will be sold on this flight. Disabled classes will be unavailable for booking.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _buildClassToggles(),
        const SizedBox(height: 32),
        
        _buildSeatMap(),
        
        const SizedBox(height: 32),
        _buildSummary(),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children:[
        Icon(Icons.flight_class_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildClassToggles() {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allClassIds.map((classId) {
        final enabled = _activeClassIds.contains(classId);
        final color = _classColor(classId);
        final name = _classNames[classId] ?? 'Class $classId';
        
        return GestureDetector(
          onTap: () => _toggleClass(classId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: enabled ? color.withValues(alpha: 0.12) : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? color : colors.outline.withValues(alpha: 0.25),
                width: enabled ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                Icon(
                  enabled ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: enabled ? color : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                    color: enabled ? color : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatMap() {
    final rows = _rows;
    final cols = _columns;
    final colors = Theme.of(context).colorScheme;

    const double seatSize = 32.0;
    const double seatSpacing = 6.0;
    const double aisleSpacing = 16.0;
    const double headerHeight = 36.0; 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Column(
            children:[
              const SizedBox(height: headerHeight + 8), 
              ...cols.map((col) {
                return Column(
                  children:[
                    if (_isAisleBefore(col)) const SizedBox(height: aisleSpacing),
                    Container(
                      width: 24, 
                      height: seatSize,
                      margin: const EdgeInsets.only(bottom: seatSpacing),
                      alignment: Alignment.center,
                      child: Text(
                        col,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          
          const SizedBox(width: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    children: rows.map((row) {
                      final isEmergencyRow = _rowHasEmergencyExit(row);
                      return Container(
                        width: seatSize,
                        height: headerHeight,
                        margin: const EdgeInsets.only(right: seatSpacing),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children:[
                            if (isEmergencyRow)
                              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.withValues(alpha: 0.85)),
                            const SizedBox(height: 2),
                            Text(
                              '$row',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isEmergencyRow ? FontWeight.bold : FontWeight.normal,
                                color: isEmergencyRow ? Colors.orange : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 8),

                  // МАТРИЦЯ КРІСЕЛ
                  ...cols.map((col) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        if (_isAisleBefore(col)) const SizedBox(height: aisleSpacing),
                        Row(
                          children: rows.map((row) {
                            final seat = _seatAt(row, col);
                            return Container(
                              margin: const EdgeInsets.only(right: seatSpacing, bottom: seatSpacing),
                              child: seat == null
                                  ? const SizedBox(width: seatSize, height: seatSize)
                                  : _buildSeat(seat, colors),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(_Seat seat, ColorScheme colors) {
    final isActive = _activeClassIds.contains(seat.classId);
    
    final Color fill;
    final Color border;

    if (isActive) {
      final c = _classColor(seat.classId);
      fill = c.withValues(alpha: 0.2);
      border = c.withValues(alpha: 0.7);
    } else {
      fill = colors.surfaceContainerHighest.withValues(alpha: 0.5);
      border = colors.outline.withValues(alpha: 0.2);
    }

    return Tooltip(
      message: isActive 
        ? '${seat.className} · Row ${seat.row}${seat.column} · ${seat.seatTypeName}'
        : '${seat.className} (Disabled)',
      waitDuration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(color: border, width: isActive ? 1.0 : 0.5),
        ),
        child: seat.isEmergencyExit
            ? Center(
                child: RotatedBox(
                  quarterTurns: 3, 
                  child: Icon(
                    Icons.change_history,
                    size: 14,
                    color: isActive ? Colors.orange.withValues(alpha: 0.9) : Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSummary() {
    final colors = Theme.of(context).colorScheme;
    final classCount = <int, int>{};

    for (final s in _seats) {
      if (_activeClassIds.contains(s.classId)) {
        classCount[s.classId] = (classCount[s.classId] ?? 0) + 1;
      }
    }

    if (classCount.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            'Seat availability summary',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...classCount.entries.map((e) {
            final color = _classColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children:[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text(_classNames[e.key] ?? 'Class ${e.key}',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('${e.value} seats',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              const Text('Total available capacity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                '${classCount.values.fold(0, (sum, count) => sum + count)} seats',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          )
        ],
      ),
    );
  }
}