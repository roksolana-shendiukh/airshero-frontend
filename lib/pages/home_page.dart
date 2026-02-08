import 'package:flutter/material.dart';
import '../widgets/flight_search_form.dart';
import '../widgets/responsive_layout.dart';

class HomePage extends StatefulWidget {
  final bool isLightTheme;
  final VoidCallback onThemeChanged;

  const HomePage({
    super.key,
    required this.isLightTheme,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCalendarOpen = false;
  final GlobalKey _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      isLightTheme: widget.isLightTheme,
      onThemeChanged: widget.onThemeChanged,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!_isCalendarOpen) return;

          // Перевіряємо чи клік всередині форми
          final RenderBox? formBox = _formKey.currentContext?.findRenderObject() as RenderBox?;
          if (formBox != null && formBox.hasSize) {
            final formPosition = formBox.localToGlobal(Offset.zero);
            final formSize = formBox.size;
            
            final clickX = event.position.dx;
            final clickY = event.position.dy;
            
            // Область форми + календаря (приблизно 500px висота)
            final isInsideForm = clickX >= formPosition.dx &&
                clickX <= formPosition.dx + formSize.width &&
                clickY >= formPosition.dy &&
                clickY <= formPosition.dy + formSize.height + 500;
            
            if (!isInsideForm) {
              setState(() => _isCalendarOpen = false);
            }
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              FlightSearchForm(
                key: _formKey,
                isCalendarOpen: _isCalendarOpen,
                onCalendarToggle: (isOpen) {
                  setState(() => _isCalendarOpen = isOpen);
                },
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.flight,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to AirShero F',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your journey starts here',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}