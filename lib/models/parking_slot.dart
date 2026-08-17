class ParkingSlot {
  final String id;
  final String slotNumber;
  final String? location;
  final String status;
  final DateTime? createdAt;

  const ParkingSlot({
    required this.id,
    required this.slotNumber,
    this.location,
    required this.status,
    this.createdAt,
  });

  bool get isAvailable => status.toLowerCase() == 'available';

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      id: json['id']?.toString() ?? '',
      slotNumber: json['slot_number']?.toString() ?? '',
      location: json['location'] as String?,
      status: json['status']?.toString() ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slot_number': slotNumber,
      'location': location,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
