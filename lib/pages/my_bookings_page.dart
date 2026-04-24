import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/auth_service.dart';
import '../services/booking_api_service.dart';
import '../widgets/booking/bookings_table.dart';
import '../widgets/custom/custom_select_field.dart';
import '../widgets/booking/booking_search_bar.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  String _selectedDateFilter = 'this_month';

  String _searchQuery = '';
  int _currentPage = 0;

  final List<String> _statusOptions = [
    'All',
    'Confirmed',
    'Pending',
    'PartiallyPaid',
    'Cancelled',
    'Failed',
  ];

  final List<String> _dateFilterOptions = [
    'Today',
    'This week',
    'This month',
    'Past',
    'All time',
  ];

  final Map<String, String> _dateFilterMap = {
    'Today': 'today',
    'This week': 'this_week',
    'This month': 'this_month',
    'Past': 'past',
    'All time': 'all_time',
  };

  final Map<String, String> _dateFilterReverseMap = {
    'today': 'Today',
    'this_week': 'This week',
    'this_month': 'This month',
    'past': 'Past',
    'all_time': 'All time',
  };

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);
      final bookings = await api.getBookings(
        status: _selectedStatus,
        dateFilter: _selectedDateFilter,
      );
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _canCancel(Map<String, dynamic> booking) {
    final status = booking['booking_status_name'] as String? ?? '';
    final cancellableStatuses = ['Confirmed', 'Pending', 'PartiallyPaid'];
    if (!cancellableStatuses.contains(status)) return false;

    final departsRaw = booking['departs_datetime'];
    if (departsRaw == null) return false;
    final departs = DateTime.tryParse(departsRaw.toString());
    if (departs == null) return false;

    return departs.isAfter(DateTime.now().add(const Duration(hours: 3)));
  }

  Future<void> _handleCancel(Map<String, dynamic> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Booking'),
          content: Text(
            'Are you sure you want to cancel booking #${booking['booking_number']}?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);
      await api.cancelBooking(booking['booking_id'] as int);
      if (mounted) {
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ResponsiveLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All bookings for your airline',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadBookings,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: BookingSearchBar(
                    value: _searchQuery,
                    onChanged: (q) => setState(() {
                      _searchQuery = q;
                      _currentPage = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: CustomSelectField(
                    label: 'Status',
                    value: _selectedStatus ?? 'All',
                    icon: Icons.filter_list,
                    items: _statusOptions,
                    onChanged: (val) {
                      setState(() => _selectedStatus = val == 'All' ? null : val);
                      _loadBookings();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: CustomSelectField(
                    label: 'Period',
                    value: _dateFilterReverseMap[_selectedDateFilter] ?? 'This month',
                    icon: Icons.calendar_today_outlined,
                    items: _dateFilterOptions,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _selectedDateFilter = _dateFilterMap[val] ?? 'this_month');
                      _loadBookings();
                    },
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: colors.error),
                              const SizedBox(height: 16),
                              Text(_error!),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadBookings,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _bookings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 64,
                                      color: colors.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No bookings found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : BookingsTable(
                              bookings: _bookings,
                              onCancel: _handleCancel,
                              canCancel: _canCancel,
                              searchQuery: _searchQuery
                            ),
            ),
          ),

          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                '${_bookings.length} booking${_bookings.length != 1 ? 's' : ''} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}