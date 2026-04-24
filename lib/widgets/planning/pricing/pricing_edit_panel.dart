import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/planning_service.dart';
import '../../custom/custom_button.dart';
import '../../custom/custom_input_field.dart';

class PricingEditPanel extends StatefulWidget {
  final Map<String, dynamic> flight;
  final PlanningService service;
  final void Function(int flightId, List<Map<String, dynamic>> newPrices)
      onPricesUpdated;
  final VoidCallback onClose;

  const PricingEditPanel({
    super.key,
    required this.flight,
    required this.service,
    required this.onPricesUpdated,
    required this.onClose,
  });

  @override
  State<PricingEditPanel> createState() => _PricingEditPanelState();
}

class _PricingEditPanelState extends State<PricingEditPanel> {
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;
  bool _saving = false;
  late Map<int, double> _editedPrices;
  late Map<int, double> _originalPrices;

  @override
  void initState() {
    super.initState();
    _initPrices();
    _loadHistory();
  }

  void _initPrices() {
    final prices = (widget.flight['prices'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    _editedPrices = {
      for (final p in prices)
        p['classId'] as int: (p['price'] as num).toDouble()
    };
    _originalPrices = Map.from(_editedPrices);
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _loadingHistory = true);
    try {
      final history = await widget.service
          .getFlightPriceHistory(widget.flight['flightId'] as int);
      if (mounted) {
        setState(() {
          _history = history;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final classPrices = _editedPrices.entries
          .map((e) => {'class_id': e.key, 'price': e.value})
          .toList();

      await widget.service.updateFlightPrices(
        flightId: widget.flight['flightId'] as int,
        classPrices: classPrices,
      );

      final prices = (widget.flight['prices'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final updatedPrices = prices.map((p) {
        final classId = p['classId'] as int;
        return {
          ...p,
          'price': _editedPrices[classId] ?? p['price'],
          'publishedDate':
              DateTime.now().toIso8601String().split('T')[0],
        };
      }).toList();

      widget.onPricesUpdated(widget.flight['flightId'] as int, updatedPrices);
      _originalPrices = Map.from(_editedPrices);
      await _loadHistory();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _hasChanges {
    for (final entry in _editedPrices.entries) {
      final original = _originalPrices[entry.key] ?? 0.0;
      if (entry.value != original) return true;
    }
    return false;
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtTime(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final prices = (widget.flight['prices'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return SizedBox(
      width: 900,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildEditSection(colors, prices)),
                  const SizedBox(width: 32),
                  Expanded(child: _buildHistorySection(colors)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payments_outlined,
                size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.flight['flightNumber']}  ·  '
                  '${widget.flight['departsCode']} → ${widget.flight['arrivesCode']}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_fmtDate(widget.flight['departsDatetime'] as String)}  ·  '
                  '${_fmtTime(widget.flight['departsDatetime'] as String)} → '
                  '${_fmtTime(widget.flight['arrivesDatetime'] as String)}',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(
      ColorScheme colors, List<Map<String, dynamic>> prices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDIT PRICES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        ...prices.map((p) {
          final classId = p['classId'] as int;
          final className = p['className'] as String;
          final currentPrice = _editedPrices[classId] ?? 0.0;
          final originalPrice = _originalPrices[classId] ?? 0.0;
          final isChanged = currentPrice != originalPrice;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: CustomInputField(
                    label: className,
                    value: currentPrice > 0
                        ? currentPrice.toStringAsFixed(0)
                        : '',
                    icon: Icons.attach_money_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      setState(() {
                        if (parsed != null && parsed > 0) {
                          _editedPrices[classId] = parsed;
                        }
                      });
                    },
                  ),
                ),
                if (isChanged) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${originalPrice.toStringAsFixed(0)} → \$${currentPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _editedPrices = Map.from(_originalPrices);
              }),
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Reset'),
            ),
            const SizedBox(width: 8),
            _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : CustomButton(
                    label: 'Save new prices',
                    icon: Icons.save_outlined,
                    isIconAfterLabel: false,
                    onPressed: _hasChanges ? _save : null,
                    verticalPadding: 10,
                    horizontalPadding: 20,
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRICE HISTORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        if (_loadingHistory)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
        else if (_history.isEmpty)
          Text('No history available',
              style: TextStyle(
                  fontSize: 13, color: colors.onSurfaceVariant))
        else
          _buildHistoryTable(colors),
      ],
    );
  }

  Widget _buildHistoryTable(ColorScheme colors) {
    final classNames = _getClassNames();

    // Для кожного рядку визначаємо які класи реально змінились
    // порівняно з попереднім записом
    final rows = _history;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: colors.outline.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2)},
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest
                  .withValues(alpha: 0.4),
            ),
            children: [
              _tableCell('Date', colors, isHeader: true),
              ...classNames.map(
                  (c) => _tableCell(c, colors, isHeader: true)),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final date = h['date'] as String;
            final prices = (h['prices'] as List<dynamic>)
                .cast<Map<String, dynamic>>();
            final priceMap = {
              for (final p in prices)
                p['className'] as String:
                    (p['price'] as num).toDouble()
            };

            // Попередній рядок для порівняння
            Map<String, double> prevPriceMap = {};
            if (i + 1 < rows.length) {
              final prevPrices =
                  (rows[i + 1]['prices'] as List<dynamic>)
                      .cast<Map<String, dynamic>>();
              prevPriceMap = {
                for (final p in prevPrices)
                  p['className'] as String:
                      (p['price'] as num).toDouble()
              };
            }

            final isLatest = i == 0;

            return TableRow(
              decoration: BoxDecoration(
                color: isLatest
                    ? colors.primaryContainer.withValues(alpha: 0.08)
                    : null,
                border: Border(
                    top: BorderSide(
                        color:
                            colors.outline.withValues(alpha: 0.1))),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        _fmtDate(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isLatest
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isLatest
                              ? colors.primary
                              : colors.onSurface,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'current',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...classNames.map((c) {
                  final price = priceMap[c];
                  final prevPrice = prevPriceMap[c];

                  // Якщо ціна та сама що і попередній запис — прочерк
                  final isUnchanged =
                      prevPrice != null && price == prevPrice;

                  if (isUnchanged) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Text('—',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant
                                  .withValues(alpha: 0.4))),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: price != null
                        ? Text(
                            '\$${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLatest
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isLatest
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          )
                        : Text('—',
                            style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant)),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<String> _getClassNames() {
    final classes = <String>{};
    for (final h in _history) {
      final prices = (h['prices'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final p in prices) {
        classes.add(p['className'] as String);
      }
    }
    return classes.toList()..sort();
  }

  Widget _tableCell(String label, ColorScheme colors,
      {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight:
              isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader
              ? colors.onSurfaceVariant
              : colors.onSurface,
        ),
      ),
    );
  }
}