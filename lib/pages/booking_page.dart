import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/parking_slot.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/parking_service.dart';
import '../theme/app_theme.dart';

class BookingPage extends StatefulWidget {
  final ParkingSlot slot;

  const BookingPage({super.key, required this.slot});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _bookingDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;

  String get _slotNumber => widget.slot.slotNumber;

  String get _location => widget.slot.location ?? 'Parking Area';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserve Parking')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Smart Parking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reserve Parking',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _buildSlotCard(),
                const SizedBox(height: 24),
                _buildPickerField(
                  label: 'Date',
                  value: _bookingDate == null
                      ? ''
                      : Booking.formatDate(_bookingDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                _buildPickerField(
                  label: 'Start Time',
                  value: _startTime == null ? '' : _timeLabel(_startTime!),
                  icon: Icons.schedule,
                  onTap: _pickStartTime,
                ),
                const SizedBox(height: 16),
                _buildPickerField(
                  label: 'End Time',
                  value: _endTime == null ? '' : _timeLabel(_endTime!),
                  icon: Icons.schedule,
                  onTap: _pickEndTime,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _confirm,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Reservation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_parking, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _slotNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _location,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value.isEmpty ? 'Select' : value,
          style: TextStyle(
            color: value.isEmpty ? Colors.grey : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _bookingDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  String _timeLabel(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return Booking.formatTime('$hour:$minute');
  }

  String _toHms(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirm() async {
    if (_loading) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_bookingDate == null) {
      _showMessage('Please select a booking date.');
      return;
    }
    if (_bookingDate!.isBefore(today)) {
      _showMessage('Please select a valid future date.');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showMessage('Please select a start and end time.');
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      _showMessage('End time must be after start time.');
      return;
    }

    if (AuthService.currentUser == null) {
      _showMessage('You must be logged in to make a reservation.');
      return;
    }

    setState(() => _loading = true);

    try {
      final existing = await BookingService.getActiveBooking();
      if (existing != null) {
        if (!mounted) return;
        _showActiveBookingDialog();
        return;
      }

      final latest = await ParkingService.getParkingSlotById(widget.slot.id);
      if (latest == null || !latest.isAvailable) {
        if (!mounted) return;
        _showMessage('This parking slot is no longer available.');
        return;
      }

      await BookingService.createBooking(
        parkingSlotId: widget.slot.id,
        bookingDate: _bookingDate!,
        startTime: _toHms(_startTime!),
        endTime: _toHms(_endTime!),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation confirmed.')),
      );
      Navigator.of(context).pushReplacementNamed('/my-booking');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to complete your reservation. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showActiveBookingDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Already Booked'),
        content: const Text('You already have an active booking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacementNamed('/my-booking');
            },
            child: const Text('View Booking'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
