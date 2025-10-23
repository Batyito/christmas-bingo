import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore/firestore_service.dart';
import 'sign_in_screen.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../widgets/glassy_panel.dart';

class InviteLandingScreen extends StatefulWidget {
  final String inviteCode;
  const InviteLandingScreen({super.key, required this.inviteCode});

  @override
  State<InviteLandingScreen> createState() => _InviteLandingScreenState();
}

class _InviteLandingScreenState extends State<InviteLandingScreen> {
  final _auth = AuthService();
  final _fs = FirestoreService.instance;
  bool _loading = true;
  String? _error;
  String? _familyId;
  String? _teamId;
  String _familyName = '';
  String _teamName = '';
  final _guestNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await _fs.resolveInviteByCode(widget.inviteCode);
      if (doc == null) throw Exception('A meghívó nem található vagy lejárt.');
      final familyRef = doc.reference.parent.parent!;
      _familyId = familyRef.id;
      final data = doc.data();
      _teamId = data['teamId']?.toString();
      // load names
      final fam = await familyRef.get();
      _familyName = fam.data()?['name']?.toString() ?? 'Család';
      if (_teamId != null) {
        final team = await familyRef.collection('teams').doc(_teamId).get();
        _teamName = team.data()?['name']?.toString() ?? 'Csapat';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime.now().month;
    final themeKey = (month == 10 || month == 11 || month == 12 || month == 1)
        ? 'christmas'
        : 'easter';
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: themeKey,
        title: const Text('Meghívó'),
      ),
      body: Stack(
        children: [
          SeasonalGradientBackground(themeKey: themeKey),
          if (themeKey == 'christmas') ...[
            const IgnorePointer(child: SnowfallOverlay()),
            const IgnorePointer(child: TwinklesOverlay()),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: GlassyPanel(
                  padding: const EdgeInsets.all(20),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Text(_error!,
                              style: const TextStyle(color: Colors.red))
                          : _buildContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = _auth.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Meghívás érkezett:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.family_restroom, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _familyName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
            if (_teamId != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.groups_2, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(_teamName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (user == null) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Go to sign in; after sign in, accept invite and go home
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                    if (result != null) {
                      await _acceptAndFinish();
                    }
                  },
                  child: const Text('Bejelentkezés / Regisztráció'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Vagy folytasd vendégként:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _guestNameController,
            decoration: const InputDecoration(
              labelText: 'Neved',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
                onPressed: () async {
                  final name = _guestNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add meg a neved')));
                    return;
                  }
                  try {
                    await _auth.signInAnonymously();
                    final uid = _auth.currentUser!.uid;
                    await FirestoreService.instance.ensureUserProfile(
                      uid: uid,
                      email: '',
                      displayName: name,
                    );
                    await _acceptAndFinish();
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'admin-restricted-operation') {
                      // Anonymous sign-in is disabled for this project
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vendég mód letiltva ezen a projekten. Engedélyezd a Firebase konzolban: Authentication → Sign-in method → Anonymous → Enable, majd frissítsd az oldalt.'),
                          duration: Duration(seconds: 8),
                        ),
                      );
                      return;
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Nem sikerült a vendég csatlakozás: ${e.message ?? e.code}'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Nem sikerült a vendég csatlakozás: $e')));
                  }
                },
                child: const Text('Vendégként csatlakozás')),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _acceptAndFinish,
            child: const Text('Csatlakozás'),
          ),
        ],
      ],
    );
  }

  Future<void> _acceptAndFinish() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _familyId == null) return;
    try {
      final res =
          await _fs.acceptInviteWithCode(code: widget.inviteCode, uid: uid);
      // Navigate home afterwards
      if (!mounted) return;
      // Return to root so MyApp's _AuthGateHome rebuilds Home with the
      // correct theme/effects wiring (instead of constructing HomeScreen here).
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      // Optional: show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['teamJoined'] == true
              ? 'Sikeresen csatlakoztál a csapathoz.'
              : 'Családhoz csatlakozva.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hiba: $e')));
      }
    }
  }
}
