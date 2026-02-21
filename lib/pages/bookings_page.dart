import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/flight_search_form.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/animation/animated_flight_progress.dart';
import '../models/class.dart';
import '../config/routes.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _isCalendarOpen = false;
  bool _isSearching = false;
  final GlobalKey _formKey = GlobalKey();

  void _handleSearch({
    required String fromLocation,
    required String toLocation,
    required DateTime departDate,
    DateTime? returnDate,
    required Map<String, int> passengers,
    required Map<int, Class> passengerClasses,
  }) async {
    if (_isCalendarOpen) {
      setState(() => _isCalendarOpen = false);
    }

    setState(() => _isSearching = true);

    try {
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() => _isSearching = false);

        context.push(
          '/search-results',
          extra: SearchResultsArguments(
            fromCity: fromLocation,
            toCity: toLocation,
            departDate: departDate,
            returnDate: returnDate,
            passengers: passengers,
            passengerClasses: passengerClasses,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!_isCalendarOpen) return;

          final RenderBox? formBox =
              _formKey.currentContext?.findRenderObject() as RenderBox?;
          if (formBox != null && formBox.hasSize) {
            final formPosition = formBox.localToGlobal(Offset.zero);
            final formSize = formBox.size;

            final isInsideForm = event.position.dx >= formPosition.dx &&
                event.position.dx <= formPosition.dx + formSize.width &&
                event.position.dy >= formPosition.dy &&
                event.position.dy <= formPosition.dy + formSize.height + 500;

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
                onSearch: ({
                  required String fromLocation,
                  required String toLocation,
                  required DateTime departDate,
                  DateTime? returnDate,
                  required Map<String, int> passengers,
                  required Map<int, Class> passengerClasses,
                }) {
                  _handleSearch(
                    fromLocation: fromLocation,
                    toLocation: toLocation,
                    departDate: departDate,
                    returnDate: returnDate,
                    passengers: passengers,
                    passengerClasses: passengerClasses,
                  );
                },
              ),

              const SizedBox(height: 24),

              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedFlightProgress(
                    isSearching: _isSearching,
                    onComplete: () {},
                  ),
                ),

              const SizedBox(height: 48),

              if (!_isSearching)
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

              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'Searching for flights...',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Finding the best deals for you',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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