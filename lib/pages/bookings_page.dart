import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/flight_search_form.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/animation/animated_flight_progress.dart';
import '../config/routes.dart';
import '../services/recent_searches_service.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _isSearching = false;
  bool _isRestoringSearch = true;
  final _recentSearchesService = RecentSearchesService();
  void Function(Offset position)? _closeFormOverlays;

  @override
  void initState() {
    super.initState();
    _tryRestoreLastSearch();
  }

  Future<void> _tryRestoreLastSearch() async {
    try {
      final last = await _recentSearchesService.loadLastSearch();
      if (last != null && mounted) {
        final fromCityId = last['fromCityId'] as int? ?? 0;
        final fromCity = last['fromCity'] as String? ?? '';
        final toCityId = last['toCityId'] as int? ?? 0;
        final toCity = last['toCity'] as String? ?? '';
        final departDateStr = last['departDate'] as String? ?? '';
        final returnDateStr = last['returnDate'] as String?;
        final adults = last['adults'] as int? ?? 1;
        final children = last['children'] as int? ?? 0;
        final infants = last['infants'] as int? ?? 0;

        final departDate = DateTime.tryParse(departDateStr);

        if (fromCity.isNotEmpty && toCity.isNotEmpty && departDate != null) {
          final url = buildSearchResultsUrl(
            fromCityId: fromCityId,
            fromCity: fromCity,
            toCityId: toCityId,
            toCity: toCity,
            departDate: departDate,
            returnDate: returnDateStr != null
                ? DateTime.tryParse(returnDateStr)
                : null,
            passengers: {
              'adults': adults,
              'children': children,
              'infants': infants,
            },
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.push(url);
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isRestoringSearch = false);
    }
  }

  void _handleSearch({
    required int fromCityId,
    required String fromLocation,
    required int toCityId,
    required String toLocation,
    required DateTime departDate,
    DateTime? returnDate,
    required Map<String, int> passengers,
  }) async {
    setState(() => _isSearching = true);

    await _recentSearchesService.saveLastSearch(
      fromCityId: fromCityId,
      fromCity: fromLocation,
      toCityId: toCityId,
      toCity: toLocation,
      departDate: departDate,
      returnDate: returnDate,
      passengers: passengers,
    );

    try {
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() => _isSearching = false);

        context.push(
          buildSearchResultsUrl(
            fromCityId: fromCityId,
            fromCity: fromLocation,
            toCityId: toCityId,
            toCity: toLocation,
            departDate: departDate,
            returnDate: returnDate,
            passengers: passengers,
          ),
          extra: SearchResultsArguments(
            fromCityId: fromCityId,
            fromCity: fromLocation,
            toCityId: toCityId,
            toCity: toLocation,
            departDate: departDate,
            returnDate: returnDate,
            passengers: passengers,
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
    if (_isRestoringSearch) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveLayout(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _closeFormOverlays?.call(event.position);
        },
        child: SingleChildScrollView(
          child: Column(
          children: [
            FlightSearchForm(
              onOverlayControllerReady: (closeOverlaysIfOutside) {
                _closeFormOverlays = closeOverlaysIfOutside;
              },
              onSearch: ({
                required int fromCityId,
                required String fromLocation,
                required int toCityId,
                required String toLocation,
                required DateTime departDate,
                DateTime? returnDate,
                required Map<String, int> passengers,
              }) {
                _handleSearch(
                  fromCityId: fromCityId,
                  fromLocation: fromLocation,
                  toCityId: toCityId,
                  toLocation: toLocation,
                  departDate: departDate,
                  returnDate: returnDate,
                  passengers: passengers,
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
                      'Welcome to AirShero',
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding the best deals for you',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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