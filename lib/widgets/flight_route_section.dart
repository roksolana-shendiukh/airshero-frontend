import 'package:flutter/material.dart';

class FlightRouteSection extends StatelessWidget {
  final String airlineName;
  final String airlineLogoUrl;
  final String flightClass;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final bool isReturn;

  const FlightRouteSection({
    super.key,
    required this.airlineName,
    required this.airlineLogoUrl,
    required this.flightClass,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    this.isReturn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  airlineLogoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.flight,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    airlineName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isReturn ? 'Return' : 'Outbound'} • $flightClass',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              const SizedBox(width: 8),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TIMES ROW
                    Padding(
                      padding: const EdgeInsets.only(left: 52, right: 52),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            departureTime,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            duration,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            arrivalTime,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // LINE WITH ICONS
                    SizedBox(
                      height: 20,
                      child: Stack(
                        children: [
                          // ЛІНІЯ
                          Positioned(
                            left: 60,
                            right: 60,
                            top: 9,
                            child: Container(
                              height: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          
                          // ЛІВА ІКОНКА
                          Positioned(
                            left: 52,
                            top: -2,
                            child: Icon(
                              Icons.location_on,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          
                          // ПРАВА ІКОНКА
                          Positioned(
                            right: 52,
                            top: -2,
                            child: Icon(
                              Icons.location_on,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          
                          // ЛІТАК
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Transform.rotate(
                                  angle: isReturn ? -1.5708 : 1.5708,
                                  child: Icon(
                                    Icons.flight,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),
                    
                    // AIRPORT CODES
                    Padding(
                      padding: const EdgeInsets.only(left: 52, right: 52),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fromAirportCode,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            toAirportCode,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                            
            ],
          ),
        ),
      ],
    );
  }
}