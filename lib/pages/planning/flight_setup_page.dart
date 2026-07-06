import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/planning/setup/setup_route_card.dart';

class FlightSetupPage extends StatefulWidget {
  const FlightSetupPage({super.key});

  @override
  State<FlightSetupPage> createState() => _FlightSetupPageState();
}

class _FlightSetupPageState extends State<FlightSetupPage> {
  late final PlanningService _service;
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final routes = await _service.getRoutesWithPlannedFlights();
      if (mounted) setState(() { _routes = routes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _routes;
    final q = _search.toLowerCase();
    return _routes.where((r) =>
        (r['flight_number'] as String).toLowerCase().contains(q) ||
        (r['departs_code'] as String).toLowerCase().contains(q) ||
        (r['arrives_code'] as String).toLowerCase().contains(q) ||
        (r['aircraft_model'] as String).toLowerCase().contains(q)).toList();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Flight setup',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(color: colors.onSurface),
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: colors.primary),
                    hintText:
                        'Search by flight number, airport or aircraft...',
                    hintStyle:
                        TextStyle(color: colors.onSurfaceVariant),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                color: colors.primary),
                            onPressed: () =>
                                setState(() => _search = ''),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (!_loading && _routes.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_filtered.length} routes',
                  style: TextStyle(
                      fontSize: 13, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('All flights are configured',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'No routes match "$_search"',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => SetupRouteCard(
        route: _filtered[i],
        service: _service,
      ),
    );
  }
}