import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:christmas_bingo/services/init_service.dart';
import 'package:christmas_bingo/theme.dart';
import 'package:christmas_bingo/screens/home_screen.dart';
import 'package:christmas_bingo/screens/invite_screen.dart';
import 'firebase_options.dart';
import 'models/effects_settings.dart';
import 'services/auth_service.dart';
import 'screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Ensure platform-specific Firebase config
  );

  final initService = InitService();
  await initService.initializeDefaultData();

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

class _AuthGateHome extends StatelessWidget {
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

  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authState,
      builder: (context, snapshot) {
        final user = _auth.currentUser;
        if (user == null) {
          return const SignInScreen();
        }
        return HomeScreen(
          onThemeChange: onThemeChange,
          currentThemeKey: currentThemeKey,
          effectsSettings: effectsSettings,
          onEffectsChanged: onEffectsChanged,
        );
      },
    );
  }
}
