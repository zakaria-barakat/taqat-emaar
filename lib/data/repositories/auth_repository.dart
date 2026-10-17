import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  User? get currentUser => authService.currentUser;
  Session? get currentSession => authService.currentSession;
  Stream<AuthState> get authStateChanges => authService.authStateChanges;
  bool get isAuthenticated => authService.isAuthenticated;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return authService.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<void> signOut() {
    return authService.signOut();
  }

  Future<Profile?> getProfile(String userId) {
    return authService.getProfile(userId);
  }

  Future<Profile> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) {
    return authService.updateProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
    );
  }
}
