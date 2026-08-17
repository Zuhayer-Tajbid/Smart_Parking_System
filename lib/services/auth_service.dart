import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;

  static Session? get currentSession => _auth.currentSession;

  static Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    final trimmedPhone = phone?.trim();
    return _auth.signUp(
      email: email,
      password: password,
      data: {
        'name': fullName.trim(),
        if (trimmedPhone != null && trimmedPhone.isNotEmpty)
          'phone': trimmedPhone,
      },
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
