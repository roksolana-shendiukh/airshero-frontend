import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'flight_route_section.dart';
import 'price_row.dart';
import 'baggage_option.dart'; // ← Додано import

class FlightRouteCard extends StatefulWidget {
  final String airlineName;
  final String airlineLogoUrl;
  final String flightClass;
  final String fromCity;
  final String toCity;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final bool hasBaggage;
  final bool isRoundTrip;
  
  final double pricePerAdult;
  final int adultsCount;
  final double? pricePerChild;
  final int? childrenCount;
  final double? pricePerInfant;
  final int? infantsCount;
  
  final VoidCallback onBook;

  const FlightRouteCard({
    super.key,
    required this.airlineName,
    required this.airlineLogoUrl,
    required this.flightClass,
    required this.fromCity,
    required this.toCity,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    this.hasBaggage = true,
    this.isRoundTrip = false,
    required this.pricePerAdult,
    this.adultsCount = 1,
    this.pricePerChild,
    this.childrenCount,
    this.pricePerInfant,
    this.infantsCount,
    required this.onBook,
  });

  @override
  State<FlightRouteCard> createState() => _FlightRouteCardState();
}

class _FlightRouteCardState extends State<FlightRouteCard> {
  late bool _selectedWithBaggage;

  @override
  void initState() {
    super.initState();
    _selectedWithBaggage = widget.hasBaggage;
  }

  double get totalPrice {
    double total = widget.pricePerAdult * widget.adultsCount;
    if (widget.pricePerChild != null && widget.childrenCount != null) {
      total += widget.pricePerChild! * widget.childrenCount!;
    }
    if (widget.pricePerInfant != null && widget.infantsCount != null) {
      total += widget.pricePerInfant! * widget.infantsCount!;
    }
    
    if (_selectedWithBaggage && !widget.hasBaggage) {
      total += 50.0;
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OUTBOUND ROUTE
          FlightRouteSection(
            airlineName: widget.airlineName,
            airlineLogoUrl: widget.airlineLogoUrl,
            flightClass: widget.flightClass,
            fromCity: widget.fromCity,
            toCity: widget.toCity,
            fromAirportCode: widget.fromAirportCode,
            toAirportCode: widget.toAirportCode,
            departureTime: widget.departureTime,
            arrivalTime: widget.arrivalTime,
            duration: widget.duration,
            isReturn: false,
          ),
          
          // RETURN ROUTE
          if (widget.isRoundTrip) ...[
            const Divider(height: 32),
            FlightRouteSection(
              airlineName: widget.airlineName,
              airlineLogoUrl: widget.airlineLogoUrl,
              flightClass: widget.flightClass,
              fromCity: widget.toCity,
              toCity: widget.fromCity,
              fromAirportCode: widget.toAirportCode,
              toAirportCode: widget.fromAirportCode,
              departureTime: '14:30',
              arrivalTime: '18:45',
              duration: '4h 15m',
              isReturn: true,
            ),
          ],
          
          const Divider(height: 32),
          
          // BAGGAGE SELECTOR
          Row(
            children: [
              Expanded(
                child: BaggageOption(
                  isWithBaggage: true,
                  isSelected: _selectedWithBaggage,
                  icon: Icons.luggage,
                  label: 'With Baggage',
                  showExtraCharge: !widget.hasBaggage,
                  onTap: () {
                    setState(() => _selectedWithBaggage = true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BaggageOption(
                  isWithBaggage: false,
                  isSelected: !_selectedWithBaggage,
                  icon: Icons.work_outline,
                  label: 'Hand Luggage',
                  showExtraCharge: false,
                  onTap: () {
                    setState(() => _selectedWithBaggage = false);
                  },
                ),
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // PRICES & BOOK BUTTON
          // PRICES & BOOK BUTTON
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // PRICES
    PriceRow(
      label: 'Adults (${widget.adultsCount})',
      price: widget.pricePerAdult * widget.adultsCount,
    ),
    if (widget.childrenCount != null && widget.childrenCount! > 0)
      PriceRow(
        label: 'Children (${widget.childrenCount})',
        price: widget.pricePerChild! * widget.childrenCount!,
      ),
    if (widget.infantsCount != null && widget.infantsCount! > 0)
      PriceRow(
        label: 'Infants (${widget.infantsCount})',
        price: widget.pricePerInfant! * widget.infantsCount!,
      ),
    if (_selectedWithBaggage && !widget.hasBaggage)
      const PriceRow(
        label: 'Baggage',
        price: 50.0,
      ),
    
    const SizedBox(height: 16),
    
    // TOTAL
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '\$${totalPrice.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
    
    const SizedBox(height: 16),
    
    // BOOK BUTTON (СПРАВА)
    Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220, // ← Більший розмір
        child: CustomButton(
          label: 'Book Now',
          onPressed: widget.onBook,
        ),
      ),
    ),
  ],
),
        
        ],
      ),
    );
  }
}