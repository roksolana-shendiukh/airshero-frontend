import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/flight_operation_model.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';

const _statusColors = {
  'Waiting':         Color(0xFF9E9E9E),
  'Boarding':        Color(0xFF2196F3),
  'Baggage Loading': Color(0xFF9C27B0),
  'Departed':        Color(0xFFFF9800),
  'Arrived':         Color(0xFF00BCD4),
  'Completed':       Color(0xFF4CAF50),
  'Cancelled':       Color(0xFFF44336),
};

class OperatorStatusBar extends StatefulWidget {
  const OperatorStatusBar({super.key});

  @override
  State<OperatorStatusBar> createState() => _OperatorStatusBarState();
}

class _OperatorStatusBarState extends State<OperatorStatusBar> {
  FlightOperationModel? _operation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authService = context.read<AuthService>();
    final operationId = authService.currentUser?.operationId;
    if (operationId == null) return;

    setState(() => _isLoading = true);
    final apiService = FlightOperationApiService(authService);
    final op = await apiService.getFlightOperation(operationId);
    if (mounted) setState(() { _operation = op; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final operationId = authService.currentUser?.operationId;
        if (operationId == null) return const SizedBox.shrink();
        if (_isLoading) return const SizedBox.shrink();
        if (_operation == null) return const SizedBox.shrink();

        final op     = _operation!;
        final colors = Theme.of(context).colorScheme;
        final color  = _statusColors[op.statusName] ?? colors.onSurfaceVariant;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
              left:   BorderSide(color: color, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.flight_takeoff_rounded, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                op.flightNumber ?? '—',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      colors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${op.departsCode ?? '—'} → ${op.arrivesCode ?? '—'}',
                style: TextStyle(
                  fontSize: 13,
                  color:    colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  op.statusName ?? '—',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      color,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/flight-operations/active'),
                icon:  const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Go to operation', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}