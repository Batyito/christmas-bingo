import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore/firestore_service.dart';
import 'sign_in_screen.dart';
import '../models/effects_settings.dart';
import 'home_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Meghívó')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Text(_error!, style: const TextStyle(color: Colors.red))
                    : _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = _auth.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
            'Meghívás érkezett:\n$_familyName${_teamId != null ? '  •  $_teamName' : ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
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
          const Text('Vagy folytasd vendégként:'),
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
            child: OutlinedButton(
              onPressed: () async {
                if (_guestNameController.text.trim().isEmpty) return;
                await _auth.signInAnonymously();
                await FirestoreService.instance.ensureUserProfile(
                  uid: _auth.currentUser!.uid,
                  email: '',
                  displayName: _guestNameController.text.trim(),
                );
                await _acceptAndFinish();
              },
              child: const Text('Vendégként csatlakozás'),
            ),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            onThemeChange: (s) {},
            currentThemeKey: 'system',
            effectsSettings: const EffectsSettings(),
            onEffectsChanged: (e) {},
          ),
        ),
        (route) => false,
      );
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
