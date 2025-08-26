// lib/services/rfid_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class RFIDService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUserCards() async {
    try {
      final response = await supabase
          .from('rfid_cards')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id);
      return response;
    } catch (e) {
      print('Error getting user cards: $e');
      return [];
    }
  }

  Future<String?> addCard(String uid, String name) async {
    try {
      await supabase.from('rfid_cards').insert({
        'uid': uid,
        'user_id': supabase.auth.currentUser!.id,
        'name': name.isNotEmpty ? name : 'Unnamed Card',
      });
      return null; // No error
    } catch (e) {
      print('Error adding card: $e');
      return 'Failed to add card. Please try again.';
    }
  }

  Future<List<Map<String, dynamic>>> getTapHistory(String cardId) async {
    try {
      final response = await supabase
          .from('tap_events')
          .select()
          .eq('card_uid', cardId)
          .order('tapped_at', ascending: false);
      return response;
    } catch (e) {
      print('Error getting tap history: $e');
      return [];
    }
  }
}
