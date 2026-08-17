import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/parking_slot.dart';

class ParkingService {
  ParkingService._();

  static Future<List<ParkingSlot>> getParkingSlots() async {
    try {
      final response = await Supabase.instance.client
          .from('parking_slots')
          .select()
          .order('slot_number', ascending: true);
      return _parseSlots(response);
    } catch (e) {
      _log('getParkingSlots', e);
      rethrow;
    }
  }

  static Future<List<ParkingSlot>> getAvailableSlots() async {
    try {
      final response = await Supabase.instance.client
          .from('parking_slots')
          .select()
          .eq('status', 'available')
          .order('slot_number', ascending: true);
      return _parseSlots(response);
    } catch (e) {
      _log('getAvailableSlots', e);
      rethrow;
    }
  }

  static Future<int> getAvailableSlotCount() async {
    final slots = await getAvailableSlots();
    return slots.length;
  }

  static Future<ParkingSlot?> getParkingSlotById(String id) async {
    try {
      final response = await Supabase.instance.client
          .from('parking_slots')
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) return null;
      return ParkingSlot.fromJson(response.first);
    } catch (e) {
      _log('getParkingSlotById', e);
      rethrow;
    }
  }

  static List<ParkingSlot> _parseSlots(dynamic response) {
    return (response as List)
        .map((item) => ParkingSlot.fromJson(item as Map<String, dynamic>))
        .toList();
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
      '[ParkingService.$method] FAILED'
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
