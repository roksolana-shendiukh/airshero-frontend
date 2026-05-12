import 'package:flutter/material.dart';
import '../../services/flight_operation_api_service.dart';
import 'airfleet_list_card.dart';

class AirfleetListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> airfleets;
  final Map<String, dynamic>? selected;
  final FlightOperationApiService flightApi;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const AirfleetListPanel({
    super.key,
    required this.airfleets,
    required this.selected,
    required this.flightApi,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Text('Aircraft Fleet',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: airfleets.isEmpty
              ? Center(
                  child: Text('No aircraft',
                      style:
                          TextStyle(color: colors.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: airfleets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final a = airfleets[i];
                    return AirfleetListCard(
                      airfleet: a,
                      isSelected:
                          selected?['airfleetId'] == a['airfleetId'],
                      flightApi: flightApi,
                      onConfigure: () => onSelect(a),
                      onEdit: () => onEdit(a),
                      onDelete: () => onDelete(a),
                    );
                  },
                ),
        ),
      ],
    );
  }
}