import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => _auth.currentUser;
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<firebase_auth.UserCredential> signInEmailPassword(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<firebase_auth.UserCredential> registerEmailPassword(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    throw UnimplementedError(
      'Google sign-in is not configured in this scaffold',
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }
}
