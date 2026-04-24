import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/planning/pricing/pricing_route_card.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  late final PlanningService _service;
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
    _load();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final routes = await _service.getRoutesWithPricingFlights();
      if (mounted) setState(() { _routes = routes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _routes;
    final q = _search.toLowerCase();
    return _routes.where((r) =>
        (r['flightNumber'] as String).toLowerCase().contains(q) ||
        (r['departsCode'] as String).toLowerCase().contains(q) ||
        (r['arrivesCode'] as String).toLowerCase().contains(q) ||
        (r['aircraftModel'] as String).toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String v) => setState(() => _search = v);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: _buildHeader(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    final isActive = _searchFocusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        CompositedTransformTarget(
          link: _searchLayerLink,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: colors.primaryContainer
                  .withValues(alpha: isActive ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(color: colors.onSurface),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                prefixIcon:
                    Icon(Icons.search, color: colors.primary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: colors.primary, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                labelText:
                    'Search by flight number, airport or aircraft',
                labelStyle:
                    TextStyle(color: colors.onSurfaceVariant),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Text('No routes available',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant)),
      );
    }

    final filtered = _filtered;

    if (filtered.isEmpty) {
      return Center(
        child: Text('No routes match "$_search"',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant)),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => PricingRouteCard(
        route: filtered[i],
        service: _service,
      ),
    );
  }
}