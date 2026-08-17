import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking_system/models/booking.dart';

void main() {
  group('Booking.fromJson', () {
    test('parses all fields', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'user_id': 'u1',
        'parking_slot_id': 's1',
        'booking_date': '2026-08-16',
        'start_time': '10:00:00',
        'end_time': '12:00:00',
        'status': 'active',
        'created_at': '2026-08-15T10:00:00Z',
        'parking_slots': {
          'slot_number': 'P04',
          'location': 'Main Parking Area',
        },
      });

      expect(booking.id, 'b1');
      expect(booking.userId, 'u1');
      expect(booking.parkingSlotId, 's1');
      expect(booking.bookingDate, DateTime(2026, 8, 16));
      expect(booking.startTime, '10:00:00');
      expect(booking.endTime, '12:00:00');
      expect(booking.status, 'active');
      expect(booking.slotNumber, 'P04');
      expect(booking.location, 'Main Parking Area');
    });

    test('handles null optional fields', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'user_id': 'u1',
        'parking_slot_id': 's1',
        'status': 'cancelled',
      });

      expect(booking.bookingDate, isNull);
      expect(booking.startTime, isNull);
      expect(booking.endTime, isNull);
      expect(booking.createdAt, isNull);
      expect(booking.slotNumber, isNull);
      expect(booking.location, isNull);
    });
  });

  group('Booking status getters', () {
    test('detect active, cancelled, completed', () {
      Booking withStatus(String status) => Booking.fromJson({
            'id': 'b1',
            'user_id': 'u1',
            'parking_slot_id': 's1',
            'status': status,
          });

      expect(withStatus('active').isActive, isTrue);
      expect(withStatus('cancelled').isCancelled, isTrue);
      expect(withStatus('completed').isCompleted, isTrue);
      expect(withStatus('active').isCancelled, isFalse);
    });
  });

  group('Booking.formatDate', () {
    test('formats a date', () {
      expect(Booking.formatDate(DateTime(2026, 8, 16)), 'August 16, 2026');
    });

    test('returns dash for null', () {
      expect(Booking.formatDate(null), '-');
    });
  });

  group('Booking.formatTime', () {
    test('formats 24h times to 12h', () {
      expect(Booking.formatTime('10:00'), '10:00 AM');
      expect(Booking.formatTime('10:00:00'), '10:00 AM');
      expect(Booking.formatTime('23:45'), '11:45 PM');
      expect(Booking.formatTime('12:00'), '12:00 PM');
      expect(Booking.formatTime('00:30'), '12:30 AM');
    });

    test('returns dash for null or empty', () {
      expect(Booking.formatTime(null), '-');
      expect(Booking.formatTime(''), '-');
      expect(Booking.formatTime('   '), '-');
    });
  });

  group('Booking.toJson', () {
    test('round trips core fields', () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'user_id': 'u1',
        'parking_slot_id': 's1',
        'booking_date': '2026-08-16',
        'start_time': '10:00:00',
        'end_time': '12:00:00',
        'status': 'active',
      });

      final json = booking.toJson();
      expect(json['id'], 'b1');
      expect(json['user_id'], 'u1');
      expect(json['parking_slot_id'], 's1');
      expect(json['status'], 'active');
    });
  });
}
