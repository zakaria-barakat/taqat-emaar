import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient client;

  AuthService(this.client);

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
      },
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Profile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    final updateData = <String, dynamic>{
      'full_name': fullName.trim(),
    };
    if (phone != null) {
      updateData['phone'] = phone.trim();
    }

    final response = await client
        .from('profiles')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
