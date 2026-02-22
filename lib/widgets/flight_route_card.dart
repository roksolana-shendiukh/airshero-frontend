import 'package:flutter/material.dart';
import 'custom/custom_button.dart';
import 'flight_route_section.dart';
import 'baggage_option.dart';
import 'price_summary_card.dart';

class FlightRouteCard extends StatefulWidget {
  final String airlineName;
  final String airlineLogoUrl;
  final String flightClass;
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

  List<PassengerPriceItem> get _passengerPrices {
    List<PassengerPriceItem> items = [];
    
    // Дорослі
    if (widget.adultsCount > 0) {
      items.add(PassengerPriceItem(
        passengerType: 'Adults',
        count: widget.adultsCount,
        totalPrice: widget.pricePerAdult * widget.adultsCount,
      ));
    }
    
    // Діти
    if (widget.childrenCount != null && widget.childrenCount! > 0) {
      items.add(PassengerPriceItem(
        passengerType: 'Children',
        count: widget.childrenCount!,
        totalPrice: widget.pricePerChild! * widget.childrenCount!,
      ));
    }
    
    // Немовлята
    if (widget.infantsCount != null && widget.infantsCount! > 0) {
      items.add(PassengerPriceItem(
        passengerType: 'Infants',
        count: widget.infantsCount!,
        totalPrice: widget.pricePerInfant! * widget.infantsCount!,
      ));
    }
    
    return items;
  }

  double get baseFlightPrice {
    return _passengerPrices.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  double get baggagePrice {
    if (_selectedWithBaggage && !widget.hasBaggage) {
      return 50.0;
    }
    return 0.0;
  }

  double get totalPrice => baseFlightPrice + baggagePrice;

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
          FlightRouteSection(
            airlineName: widget.airlineName,
            airlineLogoUrl: widget.airlineLogoUrl,
            flightClass: widget.flightClass,
            fromAirportCode: widget.fromAirportCode,
            toAirportCode: widget.toAirportCode,
            departureTime: widget.departureTime,
            arrivalTime: widget.arrivalTime,
            duration: widget.duration,
            isReturn: false,
          ),
          
          if (widget.isRoundTrip) ...[
            const Divider(height: 32),
            FlightRouteSection(
              airlineName: widget.airlineName,
              airlineLogoUrl: widget.airlineLogoUrl,
              flightClass: widget.flightClass,
              fromAirportCode: widget.toAirportCode,
              toAirportCode: widget.fromAirportCode,
              departureTime: '14:30',
              arrivalTime: '18:45',
              duration: '4h 15m',
              isReturn: true,
            ),
          ],
          
          const Divider(height: 32),
          
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
          
          PriceSummaryCard(
            passengerPrices: _passengerPrices, // Групується: Adults (2), Children (1)
            totalPrice: totalPrice,
            showDetailedBaggage: false, // Простий вигляд
          ),
                    
          const SizedBox(height: 16),
          
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: CustomButton(
                label: 'Book Now',
                onPressed: widget.onBook,
              ),
            ),
          ),
        ],
      ),
    );
  }
}