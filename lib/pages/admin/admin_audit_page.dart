import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/admin_api_service.dart';
import '../../services/auth_service.dart';

class AdminSystemPage extends StatefulWidget {
  const AdminSystemPage({super.key});

  @override
  State<AdminSystemPage> createState() => _AdminSystemPageState();
}

class _AdminSystemPageState extends State<AdminSystemPage>
    with SingleTickerProviderStateMixin {
  late final AdminApiService _adminApi;
  late final TabController _tabController;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adminApi = AdminApiService(context.read<AuthService>());
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _adminApi.getSystemAnalytics(),
        _adminApi.getSystemHistory(),
      ]);
      setState(() {
        _data = results[0] as Map<String, dynamic>;
        _history = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ResponsiveLayout(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Analytics',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Live snapshot · History up to 4h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                IconButton.outlined(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _load,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            tabs: const [
              Tab(icon: Icon(Icons.dns_outlined), text: 'Server'),
              Tab(icon: Icon(Icons.storage_outlined), text: 'Database'),
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _data == null
                  ? const SizedBox()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ServerTab(
                          data: _data!['server'] as Map<String, dynamic>,
                          history: _history,
                        ),
                        _DatabaseTab(
                          data: _data!['database'] as Map<String, dynamic>,
                        ),
                        _UsersTab(
                          data: _data!['users'] as Map<String, dynamic>,
                        ),
                      ],
                    ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// SERVER TAB
// ═══════════════════════════════════════════════════════════

class _ServerTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> history;

  const _ServerTab({required this.data, required this.history});

  @override
  Widget build(BuildContext context) {
    final cpu = (data['cpu_percent'] as num).toDouble();
    final ram = (data['ram_percent'] as num).toDouble();
    final disk = (data['disk_percent'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Current Load'),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cols == 3 ? 2.4 : 3.5,
              children: [
                _GaugeCard(
                  label: 'CPU',
                  subtitle: 'Processor load',
                  percent: cpu,
                  icon: Icons.memory_outlined,
                ),
                _GaugeCard(
                  label: 'RAM  ${data['ram_used_gb']} / ${data['ram_total_gb']} GB',
                  subtitle: 'Memory usage',
                  percent: ram,
                  icon: Icons.developer_board_outlined,
                ),
                _GaugeCard(
                  label: 'Disk  ${data['disk_used_gb']} / ${data['disk_total_gb']} GB',
                  subtitle: 'Storage usage',
                  percent: disk,
                  icon: Icons.disc_full_outlined,
                ),
              ],
            );
          }),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionLabel(context, 'Trend — Last ${history.length} snapshots (5 min interval)'),
            const SizedBox(height: 12),
            _ServerTrendChart(history: history),
          ] else ...[
            const SizedBox(height: 28),
            _EmptyHistory(),
          ],
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final double percent;
  final IconData icon;

  const _GaugeCard({
    required this.label,
    required this.subtitle,
    required this.percent,
    required this.icon,
  });

  Color _color(BuildContext context) {
    if (percent >= 85) return Colors.red.shade600;
    if (percent >= 60) return Colors.orange.shade600;
    return Theme.of(context).colorScheme.primary;
  }

  String _insight() {
    if (percent >= 85) return '⚠ Critical — performance may be degraded';
    if (percent >= 60) return 'Elevated — monitor closely';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${percent.toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 6),
          Text(_insight(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: percent >= 60
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _ServerTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _ServerTrendChart({required this.history});

  List<FlSpot> _spots(String key) {
    return history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value[key] as num).toDouble());
    }).toList();
  }

  int? _peakIndex(String key) {
    if (history.isEmpty) return null;
    double max = -1;
    int idx = 0;
    for (int i = 0; i < history.length; i++) {
      final v = (history[i][key] as num).toDouble();
      if (v > max) {
        max = v;
        idx = i;
      }
    }
    return (history[idx][key] as num).toDouble() >= 85 ? idx : null;
  }

  String _timeLabel(int index) {
    final raw = history[index]['captured_at'] as String?;
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cpuSpots = _spots('cpu_percent');
    final ramSpots = _spots('ram_percent');
    final cpuPeak = _peakIndex('cpu_percent');
    final ramPeak = _peakIndex('ram_percent');

    final annotations = <int>{};
    if (cpuPeak != null) annotations.add(cpuPeak);
    if (ramPeak != null) annotations.add(ramPeak);

    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _legendDot(primary, 'CPU %', context),
              const SizedBox(width: 16),
              _legendDot(Colors.orange.shade400, 'RAM %', context),
              const Spacer(),
              if (annotations.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text('Peak anomaly detected',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.red.shade600)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: onSurface)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (history.length / 5).ceilToDouble(),
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_timeLabel(idx),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: onSurface)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                // 85% threshold line
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 85,
                    color: Colors.red.shade300.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                          fontSize: 10, color: Colors.red.shade400),
                      labelResolver: (_) => 'Critical 85%',
                    ),
                  ),
                ]),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final label = s.barIndex == 0 ? 'CPU' : 'RAM';
                      final time = s.x.toInt() < history.length
                          ? _timeLabel(s.x.toInt())
                          : '';
                      return LineTooltipItem(
                        '$label ${s.y.toStringAsFixed(1)}%\n$time',
                        TextStyle(
                          fontSize: 11,
                          color: s.bar.color,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _line(cpuSpots, primary, cpuPeak),
                  _line(ramSpots, Colors.orange.shade400, ramPeak),
                ],
              ),
            ),
          ),
          if (annotations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...annotations.map((idx) {
              final cpu = (history[idx]['cpu_percent'] as num).toDouble();
              final ram = (history[idx]['ram_percent'] as num).toDouble();
              final time = _timeLabel(idx);
              final msgs = <String>[];
              if (cpu >= 85) msgs.add('CPU at ${cpu.toStringAsFixed(1)}%');
              if (ram >= 85) msgs.add('RAM at ${ram.toStringAsFixed(1)}%');
              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.red.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${msgs.join(' · ')} at $time — '
                        'possible spike due to high load or background job.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, int? peakIdx) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: peakIdx != null,
        checkToShowDot: (spot, _) => spot.x.toInt() == peakIdx,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 5,
          color: Colors.red.shade600,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  Widget _legendDot(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(context),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            'History will appear after the first 5-minute interval.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATABASE TAB
// ═══════════════════════════════════════════════════════════

class _DatabaseTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DatabaseTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final tables = (data['tables'] as List).cast<Map<String, dynamic>>();
    final dbSize = (data['db_size_mb'] as num).toDouble();
    final connections = data['active_connections'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Overview'),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 500 ? 2 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3.2,
              children: [
                _StatCard(
                  label: 'Database Size',
                  value: '${dbSize.toStringAsFixed(1)} MB',
                  icon: Icons.storage_outlined,
                  insight: dbSize > 1000
                      ? '⚠ Over 1 GB — consider archiving old data'
                      : 'Within normal range',
                  isWarning: dbSize > 1000,
                ),
                _StatCard(
                  label: 'Active Connections',
                  value: '$connections',
                  icon: Icons.cable_outlined,
                  insight: connections > 50
                      ? '⚠ High — check for connection leaks'
                      : 'Normal',
                  isWarning: connections > 50,
                ),
              ],
            );
          }),
          if (tables.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionLabel(context, 'Table Sizes'),
            const SizedBox(height: 12),
            _TableSizeChart(tables: tables),
            const SizedBox(height: 20),
            _sectionLabel(context, 'Table Details'),
            const SizedBox(height: 12),
            _TableDetailsCard(tables: tables),
          ],
        ],
      ),
    );
  }
}

class _TableSizeChart extends StatelessWidget {
  final List<Map<String, dynamic>> tables;

  const _TableSizeChart({required this.tables});

  @override
  Widget build(BuildContext context) {
    final top = tables.take(8).toList();
    final maxSize = top
        .map((t) => (t['size_mb'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    final onSurface = Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 16),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Size by table (MB)',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxSize * 1.2,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final t = top[group.x];
                      return BarTooltipItem(
                        '${t['table']}\n${rod.toY.toStringAsFixed(2)} MB\n${t['rows']} rows',
                        TextStyle(fontSize: 11, color: primary),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length) {
                          return const SizedBox();
                        }
                        final name = top[idx]['table'] as String;
                        final short = name.length > 8
                            ? '${name.substring(0, 7)}…'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(short,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: onSurface)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: onSurface)),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: top.asMap().entries.map((e) {
                  final size = (e.value['size_mb'] as num).toDouble();
                  final isLargest = size == maxSize;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: size,
                        color: isLargest
                            ? Colors.orange.shade400
                            : primary.withValues(alpha: 0.7),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          if (maxSize > 100) ...[
            const SizedBox(height: 10),
            _insightBanner(
              context,
              '${(top.first['table'])} is the largest table '
              '(${top.first['size_mb']} MB). '
              'Consider indexing or archiving if queries are slow.',
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _TableDetailsCard extends StatelessWidget {
  final List<Map<String, dynamic>> tables;

  const _TableDetailsCard({required this.tables});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2)),
                    ),
                  ),
                  children: [
                    _th(context, 'Table'),
                    _th(context, 'Rows'),
                    _th(context, 'Size MB'),
                  ],
                ),
                ...tables.map((r) => TableRow(children: [
                      _td(context, r['table'] as String),
                      _td(context, '${r['rows']}'),
                      _td(context, '${r['size_mb']}'),
                    ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// USERS TAB
// ═══════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _UsersTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final byRole = (data['by_role'] as List).cast<Map<String, dynamic>>();
    final byStatus = (data['by_status'] as List).cast<Map<String, dynamic>>();
    final total = data['total_users'] as int;
    final disabled = data['disabled_users'] as int;
    final neverLogged = data['never_logged_in'] as int;
    final disabledPct = total > 0 ? disabled / total : 0.0;
    final neverPct = total > 0 ? neverLogged / total : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Overview'),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 450
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
              children: [
                _StatCard(
                  label: 'Total Users',
                  value: '$total',
                  icon: Icons.people_outline,
                  insight: 'Registered in Firebase Auth',
                  isWarning: false,
                ),
                _StatCard(
                  label: 'Disabled Accounts',
                  value: '$disabled  (${(disabledPct * 100).toStringAsFixed(0)}%)',
                  icon: Icons.block_outlined,
                  insight: disabledPct > 0.2
                      ? '⚠ Over 20% disabled — review account policy'
                      : 'Within normal range',
                  isWarning: disabledPct > 0.2,
                ),
                _StatCard(
                  label: 'Never Logged In',
                  value: '$neverLogged  (${(neverPct * 100).toStringAsFixed(0)}%)',
                  icon: Icons.login_outlined,
                  insight: neverPct > 0.3
                      ? '⚠ High — many users never activated'
                      : 'Normal activation rate',
                  isWarning: neverPct > 0.3,
                ),
              ],
            );
          }),
          const SizedBox(height: 28),
          _sectionLabel(context, 'Distribution'),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final roleChart = _DonutCard(
              title: 'By Role',
              items: byRole,
              labelKey: 'role',
              countKey: 'count',
            );
            final statusChart = _DonutCard(
              title: 'By Status',
              items: byStatus,
              labelKey: 'status',
              countKey: 'count',
            );
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: roleChart),
                  const SizedBox(width: 12),
                  Expanded(child: statusChart),
                ],
              );
            }
            return Column(children: [
              roleChart,
              const SizedBox(height: 12),
              statusChart,
            ]);
          }),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String labelKey;
  final String countKey;

  const _DonutCard({
    required this.title,
    required this.items,
    required this.labelKey,
    required this.countKey,
  });

  static const _palette = [
    Color(0xFF4C7CF4),
    Color(0xFF6DB8A0),
    Color(0xFFE8A838),
    Color(0xFF9B72CF),
    Color(0xFFE07070),
    Color(0xFF5BAFD6),
  ];

  @override
  Widget build(BuildContext context) {
    final total =
        items.fold<int>(0, (s, i) => s + (i[countKey] as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: items.asMap().entries.map((e) {
                      final count = e.value[countKey] as int;
                      final pct = total > 0 ? count / total : 0.0;
                      return PieChartSectionData(
                        value: count.toDouble(),
                        color: _palette[e.key % _palette.length],
                        radius: 32,
                        title: pct > 0.08
                            ? '${(pct * 100).toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((e) {
                    final label = e.value[labelKey] as String;
                    final count = e.value[countKey] as int;
                    final color = _palette[e.key % _palette.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(label,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$count',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String insight;
  final bool isWarning;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.insight,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange.shade600 : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(insight,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isWarning
                            ? Colors.orange.shade700
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String text) => Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );

Widget _insightBanner(BuildContext context, String text,
    {bool isWarning = false}) {
  final color = isWarning ? Colors.orange.shade700 : Colors.blue.shade700;
  final bg = isWarning ? Colors.orange.shade50 : Colors.blue.shade50;
  final border = isWarning ? Colors.orange.shade200 : Colors.blue.shade200;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    ),
  );
}

BoxDecoration _cardDeco(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color:
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
    );

Widget _th(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600)));

Widget _td(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis));