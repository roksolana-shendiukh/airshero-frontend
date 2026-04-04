import 'package:flutter/material.dart';

class PriceSummaryCard extends StatelessWidget {
  final List<PassengerPriceItem> passengerPrices;
  final double totalPrice;
  final bool showDetailedBaggage;

  const PriceSummaryCard({
    super.key,
    required this.passengerPrices,
    required this.totalPrice,
    this.showDetailedBaggage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Ціни за кожного пасажира
          ...passengerPrices.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            if (showDetailedBaggage) {
              // Детальний вигляд з окремою ціною рейсу та багажу
              return Column(
                children: [
                  // Назва пасажира та загальна ціна
                  _buildPriceRow(
                    context,
                    item.passengerType,
                    item.totalPrice,
                    isTotal: false,
                    isBold: true,
                  ),
                  // Якщо є багаж - показуємо деталі
                  if (item.baggageCount != null && item.baggageCount! > 0) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        children: [
                          _buildPriceRow(
                            context,
                            '  Flight',
                            item.flightPrice ?? 0,
                            isTotal: false,
                            isSubItem: true,
                          ),
                          const SizedBox(height: 4),
                          _buildPriceRow(
                            context,
                            '  Baggage (${item.baggageCount})',
                            item.baggagePrice ?? 0,
                            isTotal: false,
                            isSubItem: true,
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (index < passengerPrices.length - 1) 
                    const SizedBox(height: 12),
                ],
              );
            } else {
              // Простий вигляд - тільки тип пасажира (кількість) та ціна
              return Padding(
                padding: EdgeInsets.only(bottom: index < passengerPrices.length - 1 ? 8 : 0),
                child: _buildPriceRow(
                  context,
                  item.count > 1 
                      ? '${item.passengerType} (${item.count})'
                      : item.passengerType,
                  item.totalPrice,
                  isTotal: false,
                ),
              );
            }
          }),
          
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          
          _buildPriceRow(
            context,
            'Total',
            totalPrice,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double price, {
    bool isTotal = false,
    bool showPlus = false,
    bool isPrimary = false,
    bool isSubItem = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  color: isSubItem 
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                  fontSize: isSubItem ? 13 : null,
                ),
        ),
        Text(
          '${showPlus ? '+' : ''}\$${price.toStringAsFixed(2)}',
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.primary
                      : isSubItem
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                  fontSize: isSubItem ? 13 : null,
                ),
        ),
      ],
    );
  }
}

class PassengerPriceItem {
  final String passengerType; // "Adult 1", "Child 1", або "Adults", "Children" для групи
  final int count; // Кількість пасажирів цього типу (для групового відображення)
  final double totalPrice; // Загальна сума за пасажира (рейс + багаж)
  final double? flightPrice; // Ціна рейсу (опційно, для детального вигляду)
  final double? baggagePrice; // Ціна багажу (опційно, для детального вигляду)
  final int? baggageCount; // Кількість багажу (опційно, для детального вигляду)

  const PassengerPriceItem({
    required this.passengerType,
    this.count = 1,
    required this.totalPrice,
    this.flightPrice,
    this.baggagePrice,
    this.baggageCount,
  });
}

class PriceItem {
  final String label;
  final double price;
  final bool showPlus;

  const PriceItem({
    required this.label,
    required this.price,
    this.showPlus = false,
  });
}