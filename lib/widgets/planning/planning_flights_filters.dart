import 'package:flutter/material.dart';
import '../custom/custom_select_field.dart';
import 'flight_number_search.dart';

class PlanningFlightsFilters extends StatelessWidget {
  final List<String> statusOptions;
  final List<String> aircraftOptions;
  final List<String> allFlightNumbers;
  final String? selectedStatus;
  final String? selectedAircraft;
  final String sortBy;
  final String searchQuery;
  final void Function(String?) onStatusChanged;
  final void Function(String?) onAircraftChanged;
  final void Function(String?) onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const PlanningFlightsFilters({
    super.key,
    required this.statusOptions,
    required this.aircraftOptions,
    required this.allFlightNumbers,
    required this.selectedStatus,
    required this.selectedAircraft,
    required this.sortBy,
    required this.searchQuery,
    required this.onStatusChanged,
    required this.onAircraftChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: FlightNumberSearch(
              allFlightNumbers: allFlightNumbers,
              value: searchQuery,
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: CustomSelectField(
              label: 'Status',
              icon: Icons.circle_outlined,
              value: selectedStatus ?? 'All',
              items: statusOptions,
              onChanged: (v) => onStatusChanged(v == 'All' ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: CustomSelectField(
              label: 'Aircraft',
              icon: Icons.airplanemode_active_outlined,
              value: selectedAircraft ?? 'All',
              items: aircraftOptions,
              onChanged: (v) => onAircraftChanged(v == 'All' ? null : v),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: CustomSelectField(
              label: 'Sort by Load',
              icon: Icons.sort_rounded,
              value: sortBy == 'load_desc'
                  ? 'Highest first'
                  : sortBy == 'load_asc'
                      ? 'Lowest first'
                      : 'Default',
              items: const ['Default', 'Highest first', 'Lowest first'],
              onChanged: (v) => onSortChanged(v),
            ),
          ),
        ],
      ),
    );
  }
}



