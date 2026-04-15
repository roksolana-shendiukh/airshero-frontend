import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bag_detail.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_select_field.dart';

class BagRow extends StatelessWidget {
  final int        index;
  final double     weight;
  final BagDetail? calc;
  final bool       isExtra;
  final List<Map<String, dynamic>> baggageTypes;
  final int?       selectedTypeId;
  final ValueChanged<int?>    onTypeChanged;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onRemove;

  const BagRow({
    super.key,
    required this.index,
    required this.weight,
    required this.calc,
    required this.isExtra,
    required this.baggageTypes,
    required this.selectedTypeId,
    required this.onTypeChanged,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors       = Theme.of(context).colorScheme;
    final hasSurcharge = (calc?.surcharge ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color:        colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: colors.outline.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BAG ${index + 1}',
                      style: TextStyle(
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.2,
                        color:         colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExtra
                            ? colors.tertiaryContainer.withValues(alpha: 0.4)
                            : colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isExtra ? 'Extra' : 'Included',
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                          color: isExtra ? colors.tertiary : colors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isExtra)
                      InkWell(
                        onTap:        onRemove,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                if (isExtra) ...[
                  CustomSelectField(
                    label: 'Baggage type',
                    icon:  Icons.luggage_outlined,
                    value: selectedTypeId?.toString() ?? '',
                    items: baggageTypes
                        .map((t) => (t['baggageTypeId'] as int).toString())
                        .toList(),
                    itemLabels: baggageTypes
                        .map((t) => t['baggageTypeName'] as String)
                        .toList(),
                    onChanged: (v) =>
                        onTypeChanged(v != null ? int.tryParse(v) : null),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 190,
                      child: CustomInputField(
                        label: 'Weight (kg)',
                        value: weight > 0 ? weight.toStringAsFixed(1) : '',
                        icon:  Icons.scale_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (calc != null) ...[
                      Expanded(
                        child: !isExtra
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    calc!.typeName,
                                    style: TextStyle(
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                      color:      colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.straighten,
                                          size: 12,
                                          color: colors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        calc!.dimensions,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (hasSurcharge)
                        Text(
                          '+\$${calc!.surcharge.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFFE65100),
                          ),
                        ),
                    ],
                  ],
                ),

                if (calc != null && calc!.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size:  12,
                        color: hasSurcharge
                            ? const Color(0xFFE65100)
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          calc!.message,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasSurcharge
                                ? const Color(0xFFE65100)
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (hasSurcharge)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFE65100),
                  borderRadius: BorderRadius.only(
                    topLeft:    Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}