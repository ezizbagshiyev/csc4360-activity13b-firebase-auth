import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    authState = _auth.authStateChanges();
  }
  final FirebaseAuth _auth;
  late final Stream<User?> authState;
  User? get currentUser => _auth.currentUser;
  Future<UserCredential> register(String email, String password) async =>
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
  Future<UserCredential> signIn(String email, String password) async =>
      await _auth.signInWithEmailAndPassword(email: email, password: password);
  Future<void> signOut() async => await _auth.signOut();
  Future<void> updatePassword(String password) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    await user.updatePassword(password);
  }

  Future<void> reauthenticate(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
  }
}

String? validateEmail(String? v) =>
    v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
    ? 'Enter a valid email address.'
    : null;
String? validatePassword(String? v) =>
    v == null || v.length < 6 ? 'Use at least 6 characters.' : null;
String authMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Choose a stronger password that meets the project policy.';
    case 'email-already-in-use':
      return 'Unable to register with these details. Try signing in or use another email.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'user-disabled':
      return 'Unable to sign in with these details. Check your email and password.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Wait before trying again.';
    case 'no-current-user':
      return 'Please sign in again to continue.';
    default:
      return 'The request could not be completed. Please try again.';
  }
}
