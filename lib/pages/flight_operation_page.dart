import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_operation/flight_map.dart';

class FlightOperationPage extends StatelessWidget {
  const FlightOperationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      body: FlightMap(),
    );
  }
}