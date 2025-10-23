import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Lazily access Auth to avoid pre-initialization access on web
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }
}
