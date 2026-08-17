class Booking {
  final String id;
  final String userId;
  final String parkingSlotId;
  final DateTime? bookingDate;
  final String? startTime;
  final String? endTime;
  final String status;
  final DateTime? createdAt;

  final String? slotNumber;
  final String? location;

  const Booking({
    required this.id,
    required this.userId,
    required this.parkingSlotId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.createdAt,
    this.slotNumber,
    this.location,
  });

  bool get isActive => status.toLowerCase() == 'active';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final slot = json['parking_slots'];
    return Booking(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      parkingSlotId: json['parking_slot_id']?.toString() ?? '',
      bookingDate: json['booking_date'] != null
          ? DateTime.tryParse(json['booking_date'].toString())
          : null,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      slotNumber: slot is Map<String, dynamic>
          ? slot['slot_number']?.toString()
          : null,
      location: slot is Map<String, dynamic> ? slot['location']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'parking_slot_id': parkingSlotId,
      'booking_date': bookingDate?.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Booking copyWith({String? slotNumber, String? location}) {
    return Booking(
      id: id,
      userId: userId,
      parkingSlotId: parkingSlotId,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      status: status,
      createdAt: createdAt,
      slotNumber: slotNumber ?? this.slotNumber,
      location: location ?? this.location,
    );
  }

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parts = raw.trim().split(':');
    if (parts.isEmpty) return raw.trim();
    final hour = int.tryParse(parts[0]);
    if (hour == null) return raw.trim();
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }
}
