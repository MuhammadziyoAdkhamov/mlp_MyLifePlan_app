import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  final AuthService _authService = AuthService();

  @override
  User? build() {
    // Listen to Firebase Auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}

@riverpod
bool isGuestUser( ref) {
  // Logic for guest user will be expanded here
  return false;
}
