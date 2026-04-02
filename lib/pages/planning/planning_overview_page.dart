import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../models/planning_overview_model.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/planning/planning_stats_cards.dart';
import '../../widgets/custom/custom_button.dart';

class PlanningOverviewPage extends StatefulWidget {
  const PlanningOverviewPage({super.key});

  @override
  State<PlanningOverviewPage> createState() => _PlanningOverviewPageState();
}

class _PlanningOverviewPageState extends State<PlanningOverviewPage> {
  late final PlanningService _service;

  PlanningOverviewStats? _stats;
  bool _statsLoading = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      final result = await _service.getOverviewStats();
      if (mounted) setState(() => _stats = result);
    } catch (e) {
      if (mounted) setState(() => _statsError = e.toString());
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(),
          ],
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Planning Overview',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        CustomButton(
          label: 'Add Flight',
          icon: Icons.add,
          isIconAfterLabel: false,
          verticalPadding: 12,
          horizontalPadding: 18,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_statsLoading) {
      return const SizedBox(
          height: 88, child: Center(child: CircularProgressIndicator()));
    }
    if (_statsError != null) {
      return _ErrorBanner(
          message: 'Could not load statistics', onRetry: _loadStats);
    }
    if (_stats == null) return const SizedBox.shrink();
    return PlanningStatsCards(stats: _stats!);
  }

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m];
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
          const SizedBox(width: 8),
          CustomButton(
              label: 'Retry',
              verticalPadding: 10,
              horizontalPadding: 14,
              onPressed: onRetry),
        ],
      ),
    );
  }
}