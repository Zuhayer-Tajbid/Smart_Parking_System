import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/parking_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _availableCount;
  bool _loadingCount = true;
  String? _error;
  bool _loggingOut = false;

  Booking? _activeBooking;
  bool _loadingBooking = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCount();
    _loadActiveBooking();
  }

  String get _displayName {
    final metadata = AuthService.currentUser?.userMetadata;
    final name = metadata?['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'User';
  }

  Future<void> _loadAvailableCount() async {
    setState(() {
      _loadingCount = true;
      _error = null;
    });

    try {
      final count = await ParkingService.getAvailableSlotCount();
      if (!mounted) return;
      setState(() {
        _availableCount = count;
        _loadingCount = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load available slots. Please try again.';
        _loadingCount = false;
      });
    }
  }

  Future<void> _loadActiveBooking() async {
    setState(() => _loadingBooking = true);

    try {
      final booking = await BookingService.getActiveBooking();
      if (!mounted) return;
      setState(() {
        _activeBooking = booking;
        _loadingBooking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeBooking = null;
        _loadingBooking = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadAvailableCount(),
      _loadActiveBooking(),
    ]);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  void _openParkingSlots() async {
    await Navigator.of(context).pushNamed('/parking-slots');
    if (mounted) _refreshAll();
  }

  void _openMyBooking() async {
    await Navigator.of(context).pushNamed('/my-booking');
    if (mounted) _loadActiveBooking();
  }

  void _openBookingHistory() {
    Navigator.of(context).pushNamed('/booking-history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Parking'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hello, $_displayName 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your parking spot',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildAvailableCard(),
            const SizedBox(height: 24),
            _buildBookingCard(),
            const SizedBox(height: 24),
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_parking, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Available Parking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingCount)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadAvailableCount,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_availableCount',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'slots available',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openParkingSlots,
                child: const Text('Find Parking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bookmark_border, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'My Active Booking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingBooking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_activeBooking != null)
              _buildActiveBookingInfo(_activeBooking!)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No active booking',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openParkingSlots,
                      child: const Text('Find Parking'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingInfo(Booking booking) {
    final slotLabel = booking.slotNumber ?? booking.parkingSlotId;
    final timeRange =
        '${Booking.formatTime(booking.startTime)} - '
        '${Booking.formatTime(booking.endTime)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slotLabel,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          timeRange,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        const Text(
          'Active',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _openMyBooking,
            child: const Text('View Booking'),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history, color: AppTheme.primary),
        title: const Text('Booking History'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openBookingHistory,
      ),
    );
  }
}
