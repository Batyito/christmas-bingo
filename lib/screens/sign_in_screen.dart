import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore/firestore_service.dart';
import 'game_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  final _auth = AuthService();
  final _firestore = FirestoreService.instance;
  final _joinCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Register' : 'Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // Panel container for better contrast on colorful themes
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _fieldDecoration(
                                  label: 'Email',
                                  hint: 'you@example.com',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Email required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: _fieldDecoration(label: 'Password'),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Min 6 chars'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              if (_error != null)
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.18),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _isRegister ? 'Create account' : 'Sign in',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(
                                        () => _isRegister = !_isRegister),
                                child: Text(
                                  _isRegister
                                      ? 'Have an account? Sign in'
                                      : 'New here? Create an account',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Or join a game as guest',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _joinCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _fieldDecoration(
                            label: 'Team join code',
                            hint: 'Enter code provided by host',
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.white),
                            onPressed: _loading ? null : _joinAsGuest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            label: const Text('Join as guest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final pass = _passwordController.text;
      UserCredential cred;
      if (_isRegister) {
        cred = await _auth.registerWithEmail(email, pass);
      } else {
        cred = await _auth.signInWithEmail(email, pass);
      }
      // Ensure user profile exists / update lastSignInAt
      final user = cred.user;
      if (user != null) {
        await _firestore.ensureUserProfile(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(cred.user);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Authentication error';
      // Log for diagnostics (dev only)
      // ignore: avoid_print
      print('Auth error code: ${e.code}; message: ${e.message}');
      // Provide clearer hints for common setup issues
      if (e.code == 'internal-error') {
        msg =
            'Sign-in failed due to a backend configuration issue. Please check that Email/Password is enabled in Firebase Authentication and that your app is connected.';
        // Note: fetchSignInMethodsForEmail has been removed in latest SDKs.
        // We avoid probing and provide a general guidance instead.
      } else if (e.code == 'operation-not-allowed') {
        msg =
            'Email/Password is not enabled for this project. Enable it in Firebase Console > Authentication > Sign-in method.';
      } else if (e.code == 'network-request-failed') {
        msg =
            'Network error. Please check your internet connection and try again.';
      } else if (e.code == 'weak-password') {
        msg = 'Password should be at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use. Try signing in instead.';
      } else if (e.code == 'invalid-email') {
        msg = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        msg = 'This account has been disabled.';
      } else {
        // Include code to help diagnose unexpected cases
        msg = '${msg} (code: ${e.code})';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinAsGuest() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a join code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final ids = await _firestore.findTeamByJoinCode(code);
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Auth error, please try again');
      await _firestore.joinTeamByCode(joinCode: code, uid: uid);
      if (!mounted) return;
      // Navigate straight into the game
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            gameId: ids['gameId']!,
            teamId: ids['teamId']!,
            // use defaults: auto theme and default effects
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
