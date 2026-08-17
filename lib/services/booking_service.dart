import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/parking_slot.dart';

class BookingService {
  BookingService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Booking?> getActiveBooking() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final rows = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return null;
      final booking = Booking.fromJson(rows.first);
      return _attachSlot(booking);
    } catch (e) {
      _log('getActiveBooking', e);
      rethrow;
    }
  }

  static Future<List<Booking>> getBookingHistory() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const <Booking>[];

      final rows = await _client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final bookings = rows
          .map((row) => Booking.fromJson(row))
          .toList();

      if (bookings.isEmpty) return bookings;

      final slotIds = bookings
          .map((b) => b.parkingSlotId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (slotIds.isEmpty) return bookings;

      final slotRows = await _client
          .from('parking_slots')
          .select()
          .inFilter('id', slotIds);

      final slots = <String, ParkingSlot>{};
      for (final row in slotRows) {
        final slot = ParkingSlot.fromJson(row);
        slots[slot.id] = slot;
      }

      return bookings.map((booking) {
        final slot = slots[booking.parkingSlotId];
        if (slot == null) return booking;
        return booking.copyWith(
          slotNumber: slot.slotNumber,
          location: slot.location,
        );
      }).toList();
    } catch (e) {
      _log('getBookingHistory', e);
      rethrow;
    }
  }

  static Future<void> createBooking({
    required String parkingSlotId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException('Not authenticated.');
      }

      await _client.from('bookings').insert({
        'user_id': user.id,
        'parking_slot_id': parkingSlotId,
        'booking_date': _formatDate(bookingDate),
        'start_time': startTime,
        'end_time': endTime,
        'status': 'active',
      }).select().single();

      await _client
          .from('parking_slots')
          .update({'status': 'occupied'})
          .eq('id', parkingSlotId)
          .select()
          .single();
    } catch (e) {
      _log('createBooking', e);
      rethrow;
    }
  }

  static Future<void> cancelBooking(Booking booking) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException('Not authenticated.');
      }
      if (booking.userId != user.id) {
        throw const AuthException('Not authorized.');
      }

      await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', booking.id)
          .eq('user_id', user.id);

      if (booking.parkingSlotId.isNotEmpty) {
        await _client
            .from('parking_slots')
            .update({'status': 'available'})
            .eq('id', booking.parkingSlotId);
      }
    } catch (e) {
      _log('cancelBooking', e);
      rethrow;
    }
  }

  static Future<Booking> _attachSlot(Booking booking) async {
    if (booking.parkingSlotId.isEmpty) return booking;

    final rows = await _client
        .from('parking_slots')
        .select()
        .eq('id', booking.parkingSlotId)
        .limit(1);

    if (rows.isEmpty) return booking;
    final slot = ParkingSlot.fromJson(rows.first);
    return booking.copyWith(slotNumber: slot.slotNumber, location: slot.location);
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static void _log(String method, Object error) {
    final session = Supabase.instance.client.auth.currentSession;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final String message;
    final String code;
    final String details;
    final String hint;

    if (error is PostgrestException) {
      message = error.message;
      code = error.code ?? '';
      details = '${error.details}';
      hint = error.hint ?? '';
    } else {
      message = error.toString();
      code = '';
      details = '';
      hint = '';
    }

    String clean(String? value) => (value ?? '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();

    debugPrint(
      '[BookingService.$method] FAILED'
      ' | type=${error.runtimeType}'
      ' | message=${clean(message)}'
      ' | code=${clean(code)}'
      ' | details=${clean(details)}'
      ' | hint=${clean(hint)}'
      ' | session=${session != null}'
      ' | user=${userId ?? '-'}',
    );
  }
}
