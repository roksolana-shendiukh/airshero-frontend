import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';

class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      body: Center(
        child: Text('Check-In'),
      ),
    );
  }
}