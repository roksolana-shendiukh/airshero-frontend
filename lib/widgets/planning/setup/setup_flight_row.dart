import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/planning_service.dart';

class SetupFlightRow extends StatelessWidget {
  final Map<String, dynamic> flight;
  final PlanningService service;
  final VoidCallback onConfigured;

  const SetupFlightRow({
    super.key,
    required this.flight,
    required this.service,
    required this.onConfigured,
  });

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _fmtTime(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final depDt = flight['departsDatetime'] as String;
    final arrDt = flight['arrivesDatetime'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: colors.outline.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(depDt),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              _fmtTime(depDt),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              _fmtTime(arrDt),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              flight['flightDuration'] as String? ?? '—',
              style: TextStyle(
                  fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 100,
            child: FilledButton(
              onPressed: () {
                context.go(
                  '/planning/setup/flight/${flight['flightId']}',
                  extra: {
                    'flight': flight,
                    'onConfigured': onConfigured,
                  },
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Configure'),
            ),
          ),
        ],
      ),
    );
  }
}