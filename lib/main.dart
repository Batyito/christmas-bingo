import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:christmas_bingo/services/init_service.dart';
import 'package:christmas_bingo/theme.dart';
import 'package:christmas_bingo/screens/home_screen.dart';
import 'package:christmas_bingo/screens/invite_screen.dart';
import 'package:christmas_bingo/screens/collaborate_pack_screen.dart';
import 'package:christmas_bingo/screens/contribute_by_code_screen.dart';
import 'firebase_options.dart';
import 'models/effects_settings.dart';
import 'services/auth_service.dart';
import 'screens/sign_in_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Ensure platform-specific Firebase config
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _currentTheme = _getThemeForCurrentDate();
  String _currentThemeKey = _detectThemeKeyForCurrentDate();
  EffectsSettings _effects = const EffectsSettings();
  bool _didRunInit = false;

  static ThemeData _getThemeForCurrentDate() {
    final DateTime now = DateTime.now();
    final int month = now.month;

    // Christmas theme: October (10) through January (1)
    if (month == 10 || month == 11 || month == 12 || month == 1) {
      return AppThemes.christmasTheme;
    }

    // Otherwise Easter theme (Feb-Sep)
    return AppThemes.easterTheme;
  }

  static String _detectThemeKeyForCurrentDate() {
    final DateTime now = DateTime.now();
    final int month = now.month;
    if (month == 10 || month == 11 || month == 12 || month == 1) {
      return 'christmas';
    }
    return 'easter';
  }

  @override
  Widget build(BuildContext context) {
    // Kick off any startup initialization that touches plugins (e.g., Firestore)
    // only after the first frame, to ensure the engine and platform threads are ready.
    if (!_didRunInit) {
      _didRunInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // On Windows, add a tiny delay to avoid executing too early during startup.
          if (defaultTargetPlatform == TargetPlatform.windows) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          final initService = InitService();
          await initService.initializeDefaultData();
        } catch (e) {
          // Best-effort init; ignore failures in release, but log in debug.
          assert(() {
            // ignore: avoid_print
            print('InitService initializeDefaultData error: $e');
            return true;
          }());
        }
      });
    }
    return MaterialApp(
      title: 'Christmas Bingo',
      theme: _currentTheme,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path == '/invite') {
          final code = uri.queryParameters['c'] ?? '';
          return MaterialPageRoute(
            builder: (_) => InviteLandingScreen(inviteCode: code),
            settings: settings,
          );
        }
        if (uri.path == '/contribute') {
          final code =
              uri.queryParameters['code'] ?? uri.queryParameters['c'] ?? '';
          return MaterialPageRoute(
            builder: (_) => ContributeByCodeScreen(initialCode: code),
            settings: settings,
          );
        }
        if (uri.path == '/collab') {
          final packId = uri.queryParameters['packId'];
          return MaterialPageRoute(
            builder: (_) => CollaboratePackScreen(initialPackId: packId),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => _AuthGateHome(
            onThemeChange: _updateTheme,
            currentThemeKey: _currentThemeKey,
            effectsSettings: _effects,
            onEffectsChanged: _updateEffects,
          ),
          settings: settings,
        );
      },
    );
  }

  void _updateTheme(String themeKey) {
    setState(() {
      switch (themeKey) {
        case 'system':
          _currentTheme = _getThemeForCurrentDate();
          _currentThemeKey = _detectThemeKeyForCurrentDate();
          break;
        case 'christmas':
          _currentTheme = AppThemes.christmasTheme;
          _currentThemeKey = 'christmas';
          break;
        case 'easter':
          _currentTheme = AppThemes.easterTheme;
          _currentThemeKey = 'easter';
          break;
        case 'dark':
        default:
          _currentTheme = AppThemes.darkTheme;
          _currentThemeKey = 'dark';
          break;
      }
    });
  }

  void _updateEffects(EffectsSettings next) {
    setState(() {
      _effects = next;
    });
  }
}

class _AuthGateHome extends StatefulWidget {
  final ValueChanged<String> onThemeChange;
  final String currentThemeKey;
  final EffectsSettings effectsSettings;
  final ValueChanged<EffectsSettings> onEffectsChanged;
  _AuthGateHome({
    required this.onThemeChange,
    required this.currentThemeKey,
    required this.effectsSettings,
    required this.onEffectsChanged,
  });

  @override
  State<_AuthGateHome> createState() => _AuthGateHomeState();
}

class _AuthGateHomeState extends State<_AuthGateHome> {
  final _auth = AuthService();
  StreamSubscription? _authSub;
  Timer? _poller;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    // Workaround for Windows: avoid auth streams which can crash due to
    // platform-thread channel issues in desktop plugins. Poll instead.
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _poller = Timer.periodic(const Duration(milliseconds: 700), (_) {
        final u = _auth.currentUser;
        if (u?.uid != _user?.uid) {
          setState(() => _user = u);
        }
      });
    } else {
      _authSub = _auth.authState.listen((u) {
        setState(() => _user = u);
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const SignInScreen();
    }
    return HomeScreen(
      onThemeChange: widget.onThemeChange,
      currentThemeKey: widget.currentThemeKey,
      effectsSettings: widget.effectsSettings,
      onEffectsChanged: widget.onEffectsChanged,
    );
  }
}
